import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { config } from "../config";
import * as elevenlabs from "../lib/elevenlabs";
import * as falApi from "../lib/fal";
import * as ff from "../lib/ffmpeg";
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
  const work = await ff.makeWorkDir();

  try {
    let clips: string[];
    let narration: string;
    let engine: string;
    let cleaned = "";

    if (input.voiceoverUrl) {
      // A whole-video track was supplied → pace shots evenly across its length.
      const whole = await ff.download(input.voiceoverUrl, path.join(work, "voice_whole"));
      narration = await ff.padAndNormalizeAudio(
        whole,
        path.join(work, "narration.m4a"),
        0,
      );
      const per = clamp(
        (await ff.probeDuration(narration)) / input.shots.length,
        2,
        8,
      );
      clips = await Promise.all(
        input.shots.map((s, i) =>
          buildClip(s.media, path.join(work, `clip_${i}.mp4`), per, work, input),
        ),
      );
      engine = "provided";
    } else {
      // Per-shot: each part is cleaned + voiced, and its clip is fit to that audio.
      const processed = await Promise.all(
        input.shots.map((s, i) => processShot(s, i, work, input)),
      );
      clips = processed.map((p) => p.clip);
      narration = await ff.concatAudio(
        processed.map((p) => p.audio.path),
        path.join(work, "narration.m4a"),
        work,
      );
      engine =
        processed.find((p) => p.audio.engine !== "none")?.audio.engine ?? "none";
      cleaned = processed.map((p) => p.audio.text).filter(Boolean).join(" ");
    }

    const video = path.join(work, "video.mp4");
    await ff.concat(clips, video, work);
    const finalPath = path.join(work, "final.mp4");
    await ff.mux(video, narration, finalPath);

    const videoUrl = await publish(finalPath);
    console.log(
      `[strolling] render: engine=${usedFal ? "fal" : "ffmpeg-local"} shots=${input.shots.length} voiceover=${engine}`,
    );
    if (cleaned) console.log(`[strolling] narration → ${cleaned}`);
    return {
      videoUrl,
      usedFal,
      voiceoverEngine: engine,
      cleanedScript: cleaned || undefined,
    };
  } finally {
    await rm(work, { recursive: true, force: true }).catch(() => {});
  }
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
    generateRawClip(shot.media, work, input),
    buildShotAudio(shot.script, i, work),
  ]);
  const clip = await ff.renderClipToDuration(
    rawClip,
    path.join(work, `clip_${i}.mp4`),
    audio.dur,
  );
  console.log(
    `[strolling] shot ${i + 1}: ${audio.dur.toFixed(2)}s | ${audio.engine} | "${audio.text}"`,
  );
  return { clip, audio };
}

async function buildClip(
  media: MediaItem,
  out: string,
  seconds: number,
  work: string,
  input: RenderInput,
): Promise<string> {
  const raw = await generateRawClip(media, work, input);
  return ff.renderClipToDuration(raw, out, seconds);
}

/** Produce a raw (un-timed) clip for a shot's media. */
async function generateRawClip(
  media: MediaItem,
  work: string,
  input: RenderInput,
): Promise<string> {
  // The creator's own video clip.
  if (media.kind === "clip") {
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
        imageUrl = await falApi.uploadToStorage(
          await readFile(stillPath),
          path.basename(stillPath) || "still.jpg",
        );
      }
      const prompt = input.business?.style
        ? `${input.business.style}, subtle cinematic motion`
        : "subtle cinematic motion, gentle parallax";
      const clipUrl = await falApi.imageToVideo(imageUrl, { prompt });
      return ff.download(clipUrl, path.join(work, `fal-${randomUUID()}.mp4`));
    } catch (err) {
      console.warn(
        "[strolling] fal image-to-video failed, Ken Burns fallback:",
        (err as Error).message,
      );
    }
  }

  // ⚠️ FALLBACK (no FAL_KEY / fal error): local Ken Burns pan on the still.
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
      const mp3 = await elevenlabs.synthesizeSpeech(text);
      await writeFile(`${stem}.mp3`, mp3);
      await ff.padAndNormalizeAudio(`${stem}.mp3`, out, PAD_SECONDS);
      return {
        path: out,
        dur: await ff.probeDuration(out),
        engine: `elevenlabs (clean:${cleaned.cleanedBy})`,
        text,
      };
    } catch (err) {
      console.warn(
        "[strolling] ElevenLabs TTS failed, falling back:",
        (err as Error).message,
      );
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
