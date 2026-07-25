import "dotenv/config";

// Central config. The API runs with ZERO keys while MOCK is on (the default),
// mirroring the frontend's tracer-bullet philosophy. Each key below is consumed
// by the commit that makes its route real.
export const config = {
  port: Number(process.env.PORT ?? 3000),

  /** Master mock switch. Set MOCK=0 to route to real integrations. */
  mock: process.env.MOCK !== "0",

  anthropicApiKey: process.env.ANTHROPIC_API_KEY ?? "", // COMMIT-3
  falKey: process.env.FAL_KEY ?? "", // COMMIT-3 / COMMIT-4
  elevenLabsAgentId: process.env.ELEVENLABS_AGENT_ID ?? "", // COMMIT-2
  elevenLabsApiKey: process.env.ELEVENLABS_API_KEY ?? "", // COMMIT-2
  n8nWebhookUrl: process.env.N8N_WEBHOOK_URL ?? "", // COMMIT-5
};

export type Config = typeof config;
