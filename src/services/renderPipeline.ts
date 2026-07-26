import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { config } from "../config";
import * as elevenlabs from "../lib/elevenlabs";
import * as falApi from "../lib/fal";
import * as ff from "../lib/ffmpeg";
import { fail, log, startStep, warn } from "../lib/log";
import { setProgress } from "../lib/progress";
import { cleanScript } from "../lib/scriptCleaner";
import * as supabase from "../lib/supabase";
import type { Business } from "../lib/types";

// The post-creation (render) workflow, synced shot by shot.
//
// The influencer's script arrives in PARTS — each part tied to one photo/clip.
// For every shot we clean its part, voice it (ElevenLabs), and make that shot's
// visual last exactly as long as its narration. So the voiceover for shot 1 plays
// over shot 1 and ends with it, shot 2's part plays over shot 2, and so on.
//
//   shot i:  photo → fal image-to-video ┐            (clip fit to |audio_i|)
//            clip  → normalized          ├─ audio_i ─┘
//            part_i → LLM clean → ElevenLabs voice  → audio_i
//
//   concat(clips) + concat(audio_i, in order) → mux → upload   (aligned per shot)
//
// REAL integrations (used when the keys are set): fal image-to-video, fal storage,
// fal LLM (script cleaning), ElevenLabs TTS. Everything below tagged "⚠️ FALLBACK"
// only runs when a key is missing, so the pipeline still works with zero keys —
// remove/ignore those branches once every key is guaranteed in your environment.

export interface MediaItem {
  url: string; // remote URL (real capture) or local path (mock fixture)
  kind: "photo" | "clip";
}

/** localhost / LAN hosts fal.ai can't reach — re-upload those to fal storage. */
function isPrivateHost(url: string): boolean {
  try {
    const { hostname } = new URL(url);
    return (
      hostname === "localhost" ||
      hostname === "127.0.0.1" ||
      hostname === "0.0.0.0" ||
      hostname.startsWith("10.") ||
      hostname.startsWith("192.168.") ||
      hostname.endsWith(".local")
    );
  } catch {
    return false;
  }
}

/** One shot: a photo/clip and the raw script part that belongs to it. */
export interface Shot {
  media: MediaItem;
  script: string;
}

export interface RenderInput {
  shots: Shot[];
  business?: Business;
  /** A single pre-made narration track for the whole video (bypasses per-shot TTS). */
  voiceoverUrl?: string;
  /** Creator's RAW voice note → transcribed → cleaned → re-voiced as the narration. */
  voiceNoteUrl?: string;
  /** Optional id for live progress reporting (see lib/progress). */
  renderId?: string;
}

export interface RenderPipelineResult {
  videoUrl: string;
  usedFal: boolean;
  voiceoverEngine: string;
  cleanedScript?: string;
}

interface ShotAudio {
  path: string;
  dur: number;
  engine: string;
  text: string;
}
interface ProcessedShot {
  clip: string;
  audio: ShotAudio;
}

const PAD_SECONDS = 0.35; // breathing room appended to each shot's narration
const DEFAULT_SHOT_SECONDS = 3.5; // a shot with no script gets a silent beat
const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

export async function renderVideo(
  input: RenderInput,
): Promise<RenderPipelineResult> {
  if (input.shots.length === 0) throw new Error("render: no shots to work with");
  const usedFal = falApi.isFalEnabled();
  const id = input.renderId;
  const total = input.shots.length;
  const t0 = Date.now();

  log("render", "start", {
    shots: total,
    engine: usedFal ? "fal" : "ffmpeg-local",
    tts: elevenlabs.isElevenLabsEnabled() ? "elevenlabs" : config.falTtsModel ? "fal-tts" : "say/silent",
    business: input.business?.slug ?? input.business?.name,
  });
  // Warn early about the two most common "it just hangs" causes.
  if (usedFal) log("render", "fal image-to-video is enabled — each photo takes ~1-2 min to animate");
  else warn("render", "FAL_KEY not set — using local Ken Burns fallback (no AI motion)");

  const work = await ff.makeWorkDir();
  setProgress(id, 5, "Preparing render");

  try {
    let clips: string[] = [];
    let narration = "";
    let engine = "";
    let cleaned = "";

    // Narration source, in priority order:
    //   1. voiceNoteUrl — the creator's RAW voice, transcribed → cleaned → re-voiced
    //      (their own opinions, in the AI voice). Whole-video track; shots pace to it.
    //   2. voiceoverUrl — a ready-made narration track, used as-is.
    //   3. per-shot script — each shot's text cleaned + voiced (the default).
    let voiceNarration: { path: string; text: string } | null = null;
    if (input.voiceNoteUrl && elevenlabs.isElevenLabsEnabled()) {
      try {
        voiceNarration = await narrateFromVoiceNote(input.voiceNoteUrl, work, id);
      } catch (err) {
        warn("render", "voice-note narration failed → falling back to script TTS", {
          why: (err as Error).message,
        });
      }
    }

    if (voiceNarration || input.voiceoverUrl) {
      // Whole-video narration → pace shots evenly across its length.
      if (voiceNarration) {
        narration = voiceNarration.path;
        cleaned = voiceNarration.text;
        engine = "elevenlabs (from your voice)";
      } else {
        setProgress(id, 12, "Preparing narration track");
        const whole = await ff.download(input.voiceoverUrl!, path.join(work, "voice_whole"));
        narration = await ff.padAndNormalizeAudio(
          whole,
          path.join(work, "narration.m4a"),
          0,
        );
        engine = "provided";
      }
      setProgress(id, 45, `Building ${total} clip(s)`);
      const per = clamp((await ff.probeDuration(narration)) / total, 2, 8);
      let done = 0;
      clips = await Promise.all(
        input.shots.map((s, i) =>
          buildClip(s.media, path.join(work, `clip_${i}.mp4`), per, work, input, i).then((c) => {
            done += 1;
            setProgress(id, 45 + Math.round((27 * done) / total), `Clip ${done}/${total} ready`);
            return c;
          }),
        ),
      );
    } else {
      // Per-shot: each part is cleaned + voiced, and its clip is fit to that audio.
      setProgress(id, 10, `Animating ${total} shot(s)`);
      let done = 0;
      const processed = await Promise.all(
        input.shots.map((s, i) =>
          processShot(s, i, work, input).then((p) => {
            done += 1;
            setProgress(id, 10 + Math.round((62 * done) / total), `Shot ${done}/${total} ready`);
            return p;
          }),
        ),
      );
      clips = processed.map((p) => p.clip);
      const doneNarration = startStep("render", "stitching narration");
      narration = await ff.concatAudio(
        processed.map((p) => p.audio.path),
        path.join(work, "narration.m4a"),
        work,
      );
      doneNarration();
      engine =
        processed.find((p) => p.audio.engine !== "none")?.audio.engine ?? "none";
      cleaned = processed.map((p) => p.audio.text).filter(Boolean).join(" ");
    }

    const video = path.join(work, "video.mp4");
    // Crossfade transitions between shots (not hard cuts).
    setProgress(id, 78, "Composing video (crossfades)");
    const doneCompose = startStep("render", "composing video", { clips: clips.length });
    await ff.xfadeCompose(clips, video, 0.4);
    doneCompose();

    const finalPath = path.join(work, "final.mp4");
    setProgress(id, 88, "Mixing audio + video");
    const doneMux = startStep("render", "muxing audio + video");
    await ff.mux(video, narration, finalPath);
    doneMux();

    setProgress(id, 93, "Uploading the finished reel");
    const donePublish = startStep("render", "publishing");
    const videoUrl = await publish(finalPath);
    donePublish(videoUrl);

    log("render", "done", {
      engine: usedFal ? "fal" : "ffmpeg-local",
      shots: total,
      voiceover: engine,
      totalMs: Date.now() - t0,
      url: videoUrl,
    });
    if (cleaned) log("render", `narration → ${cleaned}`);
    return {
      videoUrl,
      usedFal,
      voiceoverEngine: engine,
      cleanedScript: cleaned || undefined,
    };
  } catch (err) {
    fail("render", "pipeline failed", err);
    throw err;
  } finally {
    await rm(work, { recursive: true, force: true }).catch(() => {});
  }
}

/**
 * The creator's raw voice note → finished narration audio.
 *
 *   voice note → transcribe (ElevenLabs Scribe) → polish into a script (LLM)
 *              → speak it (ElevenLabs TTS)
 *
 * The WORDS/opinions are the creator's; only the grammar-fixing and the delivery
 * voice are AI. Returns the narration audio path plus the final narration text.
 */
async function narrateFromVoiceNote(
  url: string,
  work: string,
  id?: string,
): Promise<{ path: string; text: string }> {
  setProgress(id, 8, "Transcribing your voice note");
  const local = ff.isRemote(url)
    ? await ff.download(url, path.join(work, `voicenote-${randomUUID()}`))
    : url;

  const doneStt = startStep("render", "voice note: transcribing (ElevenLabs Scribe)");
  const transcript = await elevenlabs.transcribeSpeech(await readFile(local), "voice.m4a");
  doneStt(transcript ? `heard "${transcript.slice(0, 80)}"` : "(empty)");
  if (!transcript) throw new Error("empty transcript from voice note");

  setProgress(id, 18, "Writing narration from your notes");
  const clean = await cleanScript(transcript);
  const text = clean.text || transcript;
  log("render", "voice note → narration", {
    heard: transcript,
    narration: text,
    by: clean.cleanedBy,
  });

  setProgress(id, 28, "Voicing your narration");
  const stem = path.join(work, `voicenote_tts_${randomUUID()}`);
  const mp3 = await elevenlabs.synthesizeSpeech(text);
  await writeFile(`${stem}.mp3`, mp3);
  const out = path.join(work, "narration.m4a");
  await ff.padAndNormalizeAudio(`${stem}.mp3`, out, PAD_SECONDS);
  return { path: out, text };
}

/**
 * One shot end to end. The fal video job and the narration run concurrently
 * (whichever finishes first); the clip is then fit to the narration's length so
 * this shot's voiceover starts and ends with this shot.
 */
async function processShot(
  shot: Shot,
  i: number,
  work: string,
  input: RenderInput,
): Promise<ProcessedShot> {
  const [rawClip, audio] = await Promise.all([
    generateRawClip(shot.media, work, input, i),
    buildShotAudio(shot.script, i, work),
  ]);
  // Fit to the narration length AND burn the shot's caption (TikTok-style).
  const clip = await ff.styleClip(
    rawClip,
    path.join(work, `clip_${i}.mp4`),
    audio.dur,
    audio.text,
  );
  log("render", `shot ${i + 1} composed`, {
    dur: `${audio.dur.toFixed(2)}s`,
    voice: audio.engine,
    caption: audio.text || "(none)",
  });
  return { clip, audio };
}

async function buildClip(
  media: MediaItem,
  out: string,
  seconds: number,
  work: string,
  input: RenderInput,
  i = 0,
): Promise<string> {
  const raw = await generateRawClip(media, work, input, i);
  return ff.styleClip(raw, out, seconds);
}

/** Produce a raw (un-timed) clip for a shot's media. */
async function generateRawClip(
  media: MediaItem,
  work: string,
  input: RenderInput,
  i = 0,
): Promise<string> {
  const tag = `shot ${i + 1}`;

  // The creator's own video clip.
  if (media.kind === "clip") {
    log("render", `${tag}: using creator's own clip`, { remote: ff.isRemote(media.url) });
    return ff.isRemote(media.url)
      ? ff.download(media.url, path.join(work, `src-${randomUUID()}.mp4`))
      : media.url;
  }

  const stillPath = await ensureLocalStill(media.url, work);

  // Photo + fal → animate it. fal needs a public URL; private/LAN hosts get re-uploaded.
  if (falApi.isFalEnabled()) {
    try {
      let imageUrl = media.url;
      if (!ff.isRemote(media.url) || isPrivateHost(media.url)) {
        const doneUp = startStep("render", `${tag}: uploading still to fal storage`);
        imageUrl = await falApi.uploadToStorage(
          await readFile(stillPath),
          path.basename(stillPath) || "still.jpg",
        );
        doneUp();
      }
      const prompt = input.business?.style
        ? `${input.business.style}, subtle cinematic motion`
        : "subtle cinematic motion, gentle parallax";
      const doneFal = startStep("render", `${tag}: fal image-to-video (this is the slow step)`, {
        model: config.falI2vModel,
        seconds: config.falI2vDuration,
      });
      const clipUrl = await falApi.imageToVideo(imageUrl, { prompt });
      doneFal(clipUrl);
      return ff.download(clipUrl, path.join(work, `fal-${randomUUID()}.mp4`));
    } catch (err) {
      warn("render", `${tag}: fal image-to-video failed → Ken Burns fallback`, {
        why: (err as Error).message,
      });
    }
  }

  // ⚠️ FALLBACK (no FAL_KEY / fal error): local Ken Burns pan on the still.
  log("render", `${tag}: local Ken Burns still-to-clip`);
  return ff.imageToClip(stillPath, path.join(work, `kb-${randomUUID()}.mp4`), 8);
}

/** Download remote stills so ffmpeg can read them as local files. */
async function ensureLocalStill(url: string, work: string): Promise<string> {
  if (!ff.isRemote(url)) return url;
  const ext = path.extname(new URL(url).pathname) || ".jpg";
  return ff.download(url, path.join(work, `still-${randomUUID()}${ext}`));
}

/** Clean + voice one shot's script part; returns the audio and its duration. */
async function buildShotAudio(
  script: string,
  i: number,
  work: string,
): Promise<ShotAudio> {
  const out = path.join(work, `audio_${i}.m4a`);
  const raw = script.trim();

  // No script for this shot → a short silent beat keeps A/V aligned.
  if (!raw) {
    await ff.silence(DEFAULT_SHOT_SECONDS, out);
    return { path: out, dur: DEFAULT_SHOT_SECONDS, engine: "none", text: "" };
  }

  const cleaned = await cleanScript(raw);
  const text = cleaned.text || raw;
  const stem = path.join(work, `audio_${i}_raw`);

  // 1. ElevenLabs (preferred).
  if (elevenlabs.isElevenLabsEnabled()) {
    try {
      const doneTts = startStep("render", `shot ${i + 1}: ElevenLabs voiceover`);
      const mp3 = await elevenlabs.synthesizeSpeech(text);
      await writeFile(`${stem}.mp3`, mp3);
      await ff.padAndNormalizeAudio(`${stem}.mp3`, out, PAD_SECONDS);
      doneTts();
      return {
        path: out,
        dur: await ff.probeDuration(out),
        engine: `elevenlabs (clean:${cleaned.cleanedBy})`,
        text,
      };
    } catch (err) {
      warn("render", `shot ${i + 1}: ElevenLabs TTS failed → falling back`, {
        why: (err as Error).message,
      });
    }
  }
  // 2. ⚠️ FALLBACK: fal TTS, only if a fal TTS model is configured.
  if (falApi.isFalEnabled() && config.falTtsModel) {
    const url = await falApi.textToSpeech(text);
    if (url) {
      await ff.download(url, `${stem}.mp3`);
      await ff.padAndNormalizeAudio(`${stem}.mp3`, out, PAD_SECONDS);
      return {
        path: out,
        dur: await ff.probeDuration(out),
        engine: `fal-tts (clean:${cleaned.cleanedBy})`,
        text,
      };
    }
  }
  // 3. ⚠️ FALLBACK (no ElevenLabs / no fal TTS): macOS `say` voice (dev only).
  const said = await ff.sayVoiceover(text, `${stem}.m4a`);
  if (said) {
    await ff.padAndNormalizeAudio(said, out, PAD_SECONDS);
    return {
      path: out,
      dur: await ff.probeDuration(out),
      engine: `say (clean:${cleaned.cleanedBy})`,
      text,
    };
  }
  // 4. Silent.
  await ff.silence(DEFAULT_SHOT_SECONDS, out);
  return { path: out, dur: DEFAULT_SHOT_SECONDS, engine: "none", text };
}

async function publish(finalPath: string): Promise<string> {
  const name = `strolling-${randomUUID()}.mp4`;

  // 1. Supabase reels bucket — the app's real destination.
  if (supabase.isSupabaseEnabled()) {
    return supabase.uploadReel(await readFile(finalPath), name);
  }
  // 2. fal storage → durable URL (when Supabase isn't configured).
  if (falApi.isFalEnabled()) {
    return falApi.uploadToStorage(await readFile(finalPath), name);
  }
  // ⚠️ FALLBACK (no Supabase / no FAL_KEY): save locally and serve from /renders.
  // Fine for dev; not durable for production.
  await mkdir(config.rendersDir, { recursive: true });
  const dest = path.join(config.rendersDir, name);
  try {
    await rename(finalPath, dest);
  } catch {
    await writeFile(dest, await readFile(finalPath));
  }
  const rel = `/renders/${name}`;
  return config.publicBaseUrl ? `${config.publicBaseUrl}${rel}` : rel;
}
