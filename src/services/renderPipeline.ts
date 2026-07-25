import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { config } from "../config";
import * as elevenlabs from "../lib/elevenlabs";
import * as falApi from "../lib/fal";
import * as ff from "../lib/ffmpeg";
import { cleanScript } from "../lib/scriptCleaner";
import type { Business } from "../lib/types";

// The post-creation (render) workflow. Turns the creator's pictures/clips +
// a raw voiceover script into a finished vertical video:
//
//   photo → fal image-to-video (animated clip)              ┐
//   clip  → normalized as-is                                ├─ concat → mux narration → upload
//   raw script → LLM clean → ElevenLabs voice (audio)       ┘
//
// When FAL_KEY is set the AI steps use fal; otherwise the whole thing degrades to
// a local ffmpeg render (Ken Burns stills + local narration) so it runs with no
// keys. Inputs come from the request when present and fall back to mock fixtures.

export interface MediaItem {
  url: string; // remote URL (real capture) or local path (mock fixture)
  kind: "photo" | "clip";
}

export interface RenderInput {
  media: MediaItem[];
  script: string;
  business?: Business;
  /** Pre-made narration (e.g. from the ElevenLabs part). Overrides script TTS. */
  voiceoverUrl?: string;
}

export interface RenderPipelineResult {
  videoUrl: string;
  usedFal: boolean;
  voiceoverEngine: string;
  cleanedScript?: string;
}

interface Voiceover {
  path: string | null;
  engine: string;
  script?: string;
}

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

export async function renderVideo(
  input: RenderInput,
): Promise<RenderPipelineResult> {
  if (input.media.length === 0) throw new Error("render: no media to work with");
  const usedFal = falApi.isFalEnabled();
  const work = await ff.makeWorkDir();

  try {
    // 1. Narration first — its length paces the visuals.
    const vo = await buildVoiceover(input, work);
    const audio = vo.path;
    const audioDur = audio ? await ff.probeDuration(audio) : 0;
    const perClip =
      audioDur > 0 ? clamp(audioDur / input.media.length, 2.5, 6) : 3.5;

    // 2. Each media item → a normalized portrait clip (concurrent; order preserved).
    const clips = await Promise.all(
      input.media.map((item, i) =>
        buildClip(item, path.join(work, `clip_${i}.mp4`), perClip, work, input),
      ),
    );

    // 3. Concatenate, then lay the narration.
    const silentVideo = path.join(work, "video.mp4");
    await ff.concat(clips, silentVideo, work);
    const finalPath = path.join(work, "final.mp4");
    await ff.mux(silentVideo, audio, finalPath);

    // 4. Publish the result.
    const videoUrl = await publish(finalPath);
    console.log(
      `[strolling] render: engine=${usedFal ? "fal" : "ffmpeg-local"} voiceover=${vo.engine}`,
    );
    if (vo.script) console.log(`[strolling] voiceover script → ${vo.script}`);
    return { videoUrl, usedFal, voiceoverEngine: vo.engine, cleanedScript: vo.script };
  } finally {
    await rm(work, { recursive: true, force: true }).catch(() => {});
  }
}

async function buildVoiceover(
  input: RenderInput,
  work: string,
): Promise<Voiceover> {
  // 1. Narration provided by another part — use it verbatim.
  if (input.voiceoverUrl) {
    const out = path.join(work, "voice.mp3");
    await ff.download(input.voiceoverUrl, out);
    return { path: out, engine: "provided" };
  }

  const raw = input.script.trim();
  if (!raw) return { path: null, engine: "none" };

  // 2. Clean the raw transcript into a voiceover-worthy script.
  const cleaned = await cleanScript(raw);
  const text = cleaned.text || raw;

  // 3. ElevenLabs speaks the cleaned script (preferred).
  if (elevenlabs.isElevenLabsEnabled()) {
    try {
      const mp3 = await elevenlabs.synthesizeSpeech(text);
      const out = path.join(work, "voice.mp3");
      await writeFile(out, mp3);
      return { path: out, engine: `elevenlabs (clean:${cleaned.cleanedBy})`, script: text };
    } catch (err) {
      console.warn("[strolling] ElevenLabs TTS failed, falling back:", (err as Error).message);
    }
  }

  // 4. fal TTS, if a model is configured.
  if (falApi.isFalEnabled() && config.falTtsModel) {
    const url = await falApi.textToSpeech(text);
    if (url) {
      const out = path.join(work, "voice.mp3");
      await ff.download(url, out);
      return { path: out, engine: `fal-tts (clean:${cleaned.cleanedBy})`, script: text };
    }
  }

  // 5. Local macOS `say` so narration works with zero keys.
  const said = await ff.sayVoiceover(text, path.join(work, "voice.m4a"));
  if (said) return { path: said, engine: `say (clean:${cleaned.cleanedBy})`, script: text };

  // 6. No narration — the video is composed silent.
  return { path: null, engine: "none", script: text };
}

async function buildClip(
  item: MediaItem,
  out: string,
  seconds: number,
  work: string,
  input: RenderInput,
): Promise<string> {
  // The creator's own video clip → normalize and include directly.
  if (item.kind === "clip") {
    const src = ff.isRemote(item.url)
      ? await ff.download(item.url, path.join(work, `src-${randomUUID()}.mp4`))
      : item.url;
    return ff.normalizeClip(src, out, seconds);
  }

  // Photo + fal → animate it. fal needs a public URL, so upload local stills.
  if (falApi.isFalEnabled()) {
    const imageUrl = ff.isRemote(item.url)
      ? item.url
      : await falApi.uploadToStorage(
          await readFile(item.url),
          path.basename(item.url),
        );
    const prompt = input.business?.style
      ? `${input.business.style}, subtle cinematic motion`
      : "subtle cinematic motion, gentle parallax";
    // fal generates a fixed-length clip (config.falI2vDuration); normalizeClip
    // below trims it to `seconds` so the video still paces to the narration.
    const clipUrl = await falApi.imageToVideo(imageUrl, { prompt });
    const local = await ff.download(clipUrl, path.join(work, `fal-${randomUUID()}.mp4`));
    return ff.normalizeClip(local, out, seconds);
  }

  // Photo, no fal → Ken Burns still.
  return ff.imageToClip(item.url, out, seconds);
}

async function publish(finalPath: string): Promise<string> {
  // fal storage → durable URL.
  if (falApi.isFalEnabled()) {
    return falApi.uploadToStorage(
      await readFile(finalPath),
      `strolling-${randomUUID()}.mp4`,
    );
  }
  // Local fallback → serve from public/renders.
  await mkdir(config.rendersDir, { recursive: true });
  const name = `render-${randomUUID()}.mp4`;
  const dest = path.join(config.rendersDir, name);
  try {
    await rename(finalPath, dest);
  } catch {
    // rename can fail across filesystems — copy instead.
    await writeFile(dest, await readFile(finalPath));
  }
  const rel = `/renders/${name}`;
  return config.publicBaseUrl ? `${config.publicBaseUrl}${rel}` : rel;
}
