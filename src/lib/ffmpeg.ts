import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { copyFile, mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import { config } from "../config";

// Local media plumbing for the render pipeline: normalize every source into a
// uniform portrait clip, concatenate, and mux narration. Prefers system ffmpeg;
// falls back to the ffmpeg-static binary when PATH has none.

const runRaw = promisify(execFile);

function bin(name: "ffmpeg" | "ffprobe"): string {
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const mod = require(`${name}-static`) as string | { path?: string } | null;
    if (typeof mod === "string" && mod) return mod;
    if (mod && typeof mod === "object" && typeof mod.path === "string") {
      return mod.path;
    }
  } catch {
    /* package not installed */
  }
  return name;
}

const FFMPEG = bin("ffmpeg");
const FFPROBE = bin("ffprobe");

async function run(
  cmd: string,
  args: string[],
): Promise<{ stdout: string; stderr: string }> {
  return runRaw(cmd, args);
}

export const WIDTH = 1080;
export const HEIGHT = 1920;
export const FPS = 30;

export function isRemote(s: string): boolean {
  return /^https?:\/\//i.test(s);
}

export async function makeWorkDir(): Promise<string> {
  return mkdtemp(path.join(os.tmpdir(), "strolling-render-"));
}

/** Map /uploads|/renders|/mock URLs to files under public/, else leave as-is. */
function localPublicPath(url: string): string | null {
  try {
    const pathname = isRemote(url) ? new URL(url).pathname : url;
    if (pathname.startsWith("/uploads/")) {
      return path.join(config.uploadsDir, pathname.slice("/uploads/".length));
    }
    if (pathname.startsWith("/renders/")) {
      return path.join(config.rendersDir, pathname.slice("/renders/".length));
    }
    if (pathname.startsWith("/mock/")) {
      return path.join(process.cwd(), "public", "mock", pathname.slice("/mock/".length));
    }
  } catch {
    /* ignore bad URLs */
  }
  return null;
}

export async function download(url: string, dest: string): Promise<string> {
  const local = localPublicPath(url);
  if (local) {
    await copyFile(local, dest);
    return dest;
  }
  if (!isRemote(url) && path.isAbsolute(url)) {
    await copyFile(url, dest);
    return dest;
  }
  const resolved =
    url.startsWith("/") && !isRemote(url)
      ? `${(config.publicBaseUrl || `http://localhost:${config.port}`).replace(/\/$/, "")}${url}`
      : url;
  const res = await fetch(resolved);
  if (!res.ok) throw new Error(`download ${resolved} → HTTP ${res.status}`);
  await writeFile(dest, Buffer.from(await res.arrayBuffer()));
  return dest;
}

export async function probeDuration(file: string): Promise<number> {
  const { stdout } = await run(FFPROBE, [
    "-v", "error",
    "-show_entries", "format=duration",
    "-of", "default=noprint_wrappers=1:nokey=1",
    file,
  ]);
  const d = Number.parseFloat(stdout.trim());
  return Number.isFinite(d) ? d : 0;
}

const COVER = (w: number, h: number) =>
  `scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h}`;

/** A still image → a portrait clip with a gentle Ken Burns zoom. */
export async function imageToClip(
  image: string,
  out: string,
  seconds: number,
): Promise<string> {
  const frames = Math.max(1, Math.round(seconds * FPS));
  const zoomVf =
    `${COVER(Math.round(WIDTH * 1.5), Math.round(HEIGHT * 1.5))},` +
    `zoompan=z='min(zoom+0.0012,1.12)':d=${frames}:s=${WIDTH}x${HEIGHT}:fps=${FPS},` +
    `format=yuv420p`;
  const base = ["-y", "-loop", "1", "-i", image, "-t", String(seconds), "-r", String(FPS)];
  const enc = ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", out];
  try {
    await run(FFMPEG, [...base, "-vf", zoomVf, ...enc]);
  } catch {
    // zoompan can be finicky — fall back to a static (still) clip.
    await run(FFMPEG, [...base, "-vf", `${COVER(WIDTH, HEIGHT)},format=yuv420p`, ...enc]);
  }
  return out;
}

/** An existing video (fal clip or the creator's own clip) → a normalized portrait clip. */
export async function normalizeClip(
  input: string,
  out: string,
  seconds: number,
): Promise<string> {
  await run(FFMPEG, [
    "-y", "-i", input, "-t", String(seconds), "-r", String(FPS),
    "-vf", `${COVER(WIDTH, HEIGHT)},format=yuv420p`,
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", out,
  ]);
  return out;
}

/** Concatenate identically-encoded clips (stream copy). */
export async function concat(
  clips: string[],
  out: string,
  workDir: string,
): Promise<string> {
  const list = path.join(workDir, "concat.txt");
  await writeFile(
    list,
    clips.map((c) => `file '${c.replace(/'/g, "'\\''")}'`).join("\n"),
  );
  await run(FFMPEG, ["-y", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", out]);
  return out;
}

/** Mux a single narration track onto the video (or copy through if none). */
export async function mux(
  video: string,
  audio: string | null,
  out: string,
): Promise<string> {
  if (!audio) {
    await run(FFMPEG, ["-y", "-i", video, "-c", "copy", out]);
    return out;
  }
  await run(FFMPEG, [
    "-y", "-i", video, "-i", audio,
    "-map", "0:v:0", "-map", "1:a:0",
    "-c:v", "copy", "-c:a", "aac", "-b:a", "160k",
    "-shortest", out,
  ]);
  return out;
}

/** macOS `say` narration — a dev fallback so the mock script is audible with no keys. */
export async function sayVoiceover(text: string, out: string): Promise<string | null> {
  try {
    const aiff = path.join(path.dirname(out), `say-${randomUUID()}.aiff`);
    await run("say", ["-o", aiff, text]);
    await run(FFMPEG, ["-y", "-i", aiff, "-c:a", "aac", "-b:a", "160k", out]);
    return out;
  } catch {
    return null; // not macOS / `say` unavailable
  }
}

// --- per-shot helpers: keep every narration part and its clip the same length ---

/** Uniform silence (44.1k stereo AAC) — a silent beat for a shot with no script. */
export async function silence(seconds: number, out: string): Promise<string> {
  await run(FFMPEG, [
    "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
    "-t", String(seconds), "-ar", "44100", "-ac", "2",
    "-c:a", "aac", "-b:a", "160k", out,
  ]);
  return out;
}

/** Normalize a narration part to uniform AAC (so parts concat cleanly) and add a
 *  short trailing pause so shots don't run into each other. */
export async function padAndNormalizeAudio(
  input: string,
  out: string,
  padSeconds: number,
): Promise<string> {
  const args = ["-y", "-i", input];
  if (padSeconds > 0) args.push("-af", `apad=pad_dur=${padSeconds}`);
  args.push("-ar", "44100", "-ac", "2", "-c:a", "aac", "-b:a", "160k", out);
  await run(FFMPEG, args);
  return out;
}

/** Concatenate narration parts (identical AAC params → stream copy). */
export async function concatAudio(
  parts: string[],
  out: string,
  workDir: string,
): Promise<string> {
  const list = path.join(workDir, "concat-audio.txt");
  await writeFile(
    list,
    parts.map((p) => `file '${p.replace(/'/g, "'\\''")}'`).join("\n"),
  );
  await run(FFMPEG, ["-y", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", out]);
  return out;
}

/**
 * Render a source (fal clip, creator clip, or Ken Burns still) into a portrait
 * clip of EXACTLY `target` seconds: trim if it's longer, freeze the last frame if
 * it's shorter. This is what keeps each shot the length of its narration part.
 */
export async function renderClipToDuration(
  input: string,
  out: string,
  target: number,
): Promise<string> {
  const raw = await probeDuration(input);
  const enc = ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", out];
  if (target <= raw + 0.06) {
    await run(FFMPEG, [
      "-y", "-i", input, "-t", target.toFixed(3), "-r", String(FPS),
      "-vf", `${COVER(WIDTH, HEIGHT)},format=yuv420p`, ...enc,
    ]);
  } else {
    const pad = (target - raw).toFixed(3);
    await run(FFMPEG, [
      "-y", "-i", input, "-r", String(FPS),
      "-vf",
      `${COVER(WIDTH, HEIGHT)},tpad=stop_mode=clone:stop_duration=${pad},format=yuv420p`,
      "-t", target.toFixed(3), ...enc,
    ]);
  }
  return out;
}

// --- creative editing: TikTok-style captions + varied transitions ----------

const CAPTION_FONT = "/System/Library/Fonts/Supplemental/Arial.ttf";

/** Greedy word-wrap into short, punchy caption lines. */
export function wrapCaption(text: string, maxLen = 18): string {
  const words = text.replace(/\s+/g, " ").trim().split(" ");
  const lines: string[] = [];
  let cur = "";
  for (const w of words) {
    if (cur && (cur + " " + w).length > maxLen) {
      lines.push(cur);
      cur = w;
    } else {
      cur = cur ? `${cur} ${w}` : w;
    }
  }
  if (cur) lines.push(cur);
  return lines.slice(0, 4).join("\n");
}

/**
 * Portrait clip fit to `target` seconds, with an optional burned-in caption
 * (big, centered lower-third, white with a black outline — the TikTok look).
 */
export async function styleClip(
  input: string,
  out: string,
  target: number,
  caption?: string,
): Promise<string> {
  const raw = await probeDuration(input);
  const base = [COVER(WIDTH, HEIGHT)];
  if (target > raw + 0.06) {
    base.push(`tpad=stop_mode=clone:stop_duration=${(target - raw).toFixed(3)}`);
  }
  const render = (extra: string[]) =>
    run(FFMPEG, [
      "-y", "-i", input, "-r", String(FPS),
      "-vf", [...base, ...extra, "format=yuv420p"].join(","),
      "-t", target.toFixed(3),
      "-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", out,
    ]);

  const cap = (caption ?? "").trim();
  if (cap) {
    try {
      const capFile = path.join(path.dirname(out), `cap-${randomUUID()}.txt`);
      await writeFile(capFile, wrapCaption(cap));
      const escFile = capFile.replace(/'/g, "\\'");
      await render([
        `drawtext=fontfile=${CAPTION_FONT}:textfile='${escFile}':` +
          `fontcolor=white:fontsize=58:borderw=7:bordercolor=black:` +
          `x=(w-text_w)/2:y=h*0.64:line_spacing=14`,
      ]);
      return out;
    } catch {
      // font missing / drawtext unavailable → render without the caption
    }
  }
  await render([]);
  return out;
}

/** Crossfade clips together with a rotating set of transitions (not hard cuts). */
export async function xfadeCompose(
  clips: string[],
  out: string,
  trans = 0.4,
): Promise<string> {
  if (clips.length === 1) {
    await run(FFMPEG, ["-y", "-i", clips[0], "-c", "copy", out]);
    return out;
  }
  const durs: number[] = [];
  for (const c of clips) durs.push(await probeDuration(c));
  const inputs = clips.flatMap((c) => ["-i", c]);
  const kinds = ["fade", "wipeleft", "slideup", "circleopen", "smoothright"];
  let filter = "";
  let prev = "0:v";
  let offset = Math.max(0, durs[0] - trans);
  for (let i = 1; i < clips.length; i++) {
    const label = i === clips.length - 1 ? "vout" : `x${i}`;
    const kind = kinds[(i - 1) % kinds.length];
    filter += `[${prev}][${i}:v]xfade=transition=${kind}:duration=${trans}:offset=${offset.toFixed(3)}[${label}];`;
    prev = label;
    offset += Math.max(0, durs[i] - trans);
  }
  filter = filter.replace(/;$/, "");
  await run(FFMPEG, [
    "-y", ...inputs,
    "-filter_complex", filter,
    "-map", "[vout]", "-r", String(FPS),
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", out,
  ]);
  return out;
}
