import path from "node:path";
import "dotenv/config";

// Central config. The API runs with ZERO keys while MOCK is on (the default),
// mirroring the frontend's tracer-bullet philosophy. Each key below is consumed
// by the commit that makes its route real.
export const config = {
  port: Number(process.env.PORT ?? 3000),

  /** Master mock switch. Set MOCK=0 to run the real render pipeline. */
  mock: process.env.MOCK !== "0",

  anthropicApiKey: process.env.ANTHROPIC_API_KEY ?? "", // COMMIT-3
  falKey: process.env.FAL_KEY ?? "", // COMMIT-3 / COMMIT-4
  elevenLabsAgentId: process.env.ELEVENLABS_AGENT_ID ?? "", // COMMIT-2
  elevenLabsApiKey: process.env.ELEVENLABS_API_KEY ?? "", // COMMIT-2
  n8nWebhookUrl: process.env.N8N_WEBHOOK_URL ?? "", // COMMIT-5

  // --- fal render pipeline (COMMIT-4) ---
  /** fal image-to-video model. Swap the exact slug to taste. */
  falI2vModel:
    process.env.FAL_I2V_MODEL ?? "fal-ai/kling-video/v1/standard/image-to-video",
  /** Optional fal text-to-speech model for narration. Empty → local/say fallback. */
  falTtsModel: process.env.FAL_TTS_MODEL ?? "",
  /** Where composed videos are written and served from (local fallback). */
  rendersDir: path.join(process.cwd(), "public", "renders"),
  /** Absolute base for returned URLs (e.g. https://api.strolling.app). Empty → relative. */
  publicBaseUrl: process.env.PUBLIC_BASE_URL ?? "",
};

export type Config = typeof config;
