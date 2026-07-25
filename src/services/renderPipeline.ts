import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { config } from "../config";
import * as falApi from "../lib/fal";
import * as ff from "../lib/ffmpeg";
import type { Business } from "../lib/types";

// The post-creation (render) workflow. Turns the creator's pictures + voiceover
// script into a finished vertical video:
//
//   photo → fal image-to-video (animated clip)        ┐
//   clip  → normalized as-is                          ├─ concat → mux narration → upload
//   script → narration audio (fal TTS / say / none)   ┘
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
    const audio = await buildVoiceover(input, work);
    const audioDur = audio ? await ff.probeDuration(audio) : 0;
    const perClip =
      audioDur > 0 ? clamp(audioDur / input.media.length, 2.5, 6) : 3.5;

    // 2. Each media item → a normalized portrait clip.
    const clips: string[] = [];
    for (let i = 0; i < input.media.length; i++) {
      const out = path.join(work, `clip_${i}.mp4`);
      clips.push(await buildClip(input.media[i], out, perClip, work, input));
    }

    // 3. Concatenate, then lay the narration.
    const silentVideo = path.join(work, "video.mp4");
    await ff.concat(clips, silentVideo, work);
    const finalPath = path.join(work, "final.mp4");
    await ff.mux(silentVideo, audio, finalPath);

    // 4. Publish the result.
    const videoUrl = await publish(finalPath);
    return { videoUrl, usedFal };
  } finally {
    await rm(work, { recursive: true, force: true }).catch(() => {});
  }
}

async function buildVoiceover(
  input: RenderInput,
  work: string,
): Promise<string | null> {
  const out = path.join(work, "voice.m4a");

  // 1. Narration provided by another part (e.g. ElevenLabs) — use it verbatim.
  if (input.voiceoverUrl) {
    return ff.download(input.voiceoverUrl, out);
  }
  // 2. fal TTS, if a model is configured.
  const script = input.script.trim();
  if (script && falApi.isFalEnabled() && config.falTtsModel) {
    const url = await falApi.textToSpeech(script);
    if (url) return ff.download(url, out);
  }
  // 3. Local macOS `say` so the mock script is audible with zero keys.
  if (script) {
    const said = await ff.sayVoiceover(script, out);
    if (said) return said;
  }
  // 4. No narration — the video is composed silent.
  return null;
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
