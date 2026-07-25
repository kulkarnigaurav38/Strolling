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
  /** Clip length the i2v model generates. Model-specific — kling accepts "5"|"10".
   *  ffmpeg trims each clip to the narration pacing afterwards, so this is just
   *  the raw generation length. */
  falI2vDuration: process.env.FAL_I2V_DURATION ?? "5",
  /** Optional fal text-to-speech model for narration. Empty → local/say fallback. */
  falTtsModel: process.env.FAL_TTS_MODEL ?? "",

  // --- voiceover: an LLM cleans the raw script, then ElevenLabs speaks it ---
  /** fal-hosted LLM used to polish the raw voiceover transcript. */
  falLlmModel: process.env.FAL_LLM_MODEL ?? "fal-ai/any-llm",
  /** Clean the raw script before TTS. Set CLEAN_SCRIPT=0 to speak it verbatim. */
  cleanScript: process.env.CLEAN_SCRIPT !== "0",
  /** ElevenLabs voice + model for the narration audio. */
  elevenLabsVoiceId: process.env.ELEVENLABS_VOICE_ID ?? "21m00Tcm4TlvDq8ikWAM", // Rachel
  elevenLabsModel: process.env.ELEVENLABS_MODEL ?? "eleven_multilingual_v2",
  /** Where composed videos are written and served from (local fallback). */
  rendersDir: path.join(process.cwd(), "public", "renders"),
  /** Absolute base for returned URLs (e.g. https://api.strolling.app). Empty → relative. */
  publicBaseUrl: process.env.PUBLIC_BASE_URL ?? "",
};

export type Config = typeof config;
