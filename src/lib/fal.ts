import { fal } from "@fal-ai/client";
import { config } from "../config";

// Thin wrapper around the fal.ai client. Everything the render pipeline needs
// from fal lives here so the model slugs and response-shape handling are in one
// place. Real calls; gated on FAL_KEY so the pipeline can fall back to local
// ffmpeg when no key is present.

let configured = false;
function ensure(): void {
  if (!config.falKey) throw new Error("FAL_KEY is not set");
  if (!configured) {
    fal.config({ credentials: config.falKey });
    configured = true;
  }
}

export function isFalEnabled(): boolean {
  return Boolean(config.falKey);
}

/** Upload bytes to fal storage and return a durable, public URL. */
export async function uploadToStorage(
  bytes: Buffer,
  filename: string,
): Promise<string> {
  ensure();
  const file = new File([new Uint8Array(bytes)], filename);
  return await fal.storage.upload(file);
}

export interface ImageToVideoOptions {
  prompt?: string;
  /** Generation length, in the model's own units (kling: "5" | "10"). */
  duration?: string;
}

/**
 * Animate a still image into a short clip via fal image-to-video.
 * `imageUrl` must be publicly reachable (upload local files first).
 * Returns the URL of the generated clip.
 */
export async function imageToVideo(
  imageUrl: string,
  opts: ImageToVideoOptions = {},
): Promise<string> {
  ensure();
  // Response shapes differ per model, so read defensively.
  const result = (await fal.subscribe(config.falI2vModel, {
    input: {
      image_url: imageUrl,
      prompt: opts.prompt ?? "gentle cinematic motion, subtle parallax",
      duration: opts.duration ?? config.falI2vDuration,
    },
    logs: false,
  })) as { data?: Record<string, any> } & Record<string, any>;

  const data = result.data ?? result;
  const url: unknown = data?.video?.url ?? data?.video_url ?? data?.url;
  if (typeof url !== "string") {
    throw new Error("fal image-to-video: no video URL in response");
  }
  return url;
}

/**
 * Optional narration via a fal TTS model. Returns null when no TTS model is
 * configured (the pipeline then falls back to local `say` / silence).
 */
export async function textToSpeech(text: string): Promise<string | null> {
  if (!config.falTtsModel) return null;
  ensure();
  const result = (await fal.subscribe(config.falTtsModel, {
    input: { text },
    logs: false,
  })) as { data?: Record<string, any> } & Record<string, any>;

  const data = result.data ?? result;
  const url: unknown = data?.audio?.url ?? data?.audio_url ?? data?.url;
  return typeof url === "string" ? url : null;
}
