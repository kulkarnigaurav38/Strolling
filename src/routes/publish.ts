import { Router } from "express";
import { config } from "../config";
import type { PublishRequest, PublishResult } from "../lib/types";

export const publishRouter = Router();

function mockPublish(body: Partial<PublishRequest>): PublishResult {
  const transcript = (body.transcript ?? "").trim();
  return {
    postUrl: "https://youtube.com/shorts/mock",
    caption:
      transcript ||
      "Walked into a room of 60 builders in Stuttgart and left with a film about it. " +
        "One day, one city, a lot of shipping. 🍹 #hackathon",
    hashtags: ["#hackathon", "#stuttgart", "#cursor", "#buildinpublic", "#strolling"],
  };
}

// POST /api/publish { videoUrl, transcript } → { postUrl, caption, hashtags }
publishRouter.post("/", async (req, res) => {
  const body = (req.body ?? {}) as Partial<PublishRequest>;

  if (config.mock || !config.n8nWebhookUrl) {
    // ⚠️ MOCK / FALLBACK: fake post URL until n8n → YouTube Short is wired.
    // TODO(COMMIT-5) REPLACE WITH: POST { videoUrl, transcript } to the n8n
    // webhook (config.n8nWebhookUrl) → map that response into PublishResult.
    res.json(mockPublish(body));
    return;
  }

  // TODO(COMMIT-5): real publish (n8n → YouTube Short) goes here (see above).
  void body;
  res.status(501).json({ error: "not_implemented", route: "publish" });
});
