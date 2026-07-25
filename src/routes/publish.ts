import { Router } from "express";
import { config } from "../config";
import type { PublishRequest, PublishResult } from "../lib/types";

export const publishRouter = Router();

// POST /api/publish { videoUrl, transcript } → { postUrl, caption, hashtags }
publishRouter.post("/", async (req, res) => {
  const body = (req.body ?? {}) as Partial<PublishRequest>;

  if (config.mock) {
    // ⚠️ MOCK: fake post URL + canned caption/hashtags — nothing is published.
    // TODO(COMMIT-5) REPLACE WITH: POST { videoUrl, transcript } to the n8n webhook
    // (config.n8nWebhookUrl) → it uploads a YouTube Short and returns the real
    // postUrl + generated caption/hashtags. Map that response into PublishResult.
    const result: PublishResult = {
      postUrl: "https://youtube.com/shorts/mock",
      caption:
        "Walked into a room of 60 builders in Stuttgart and left with a film about it. " +
        "One day, one city, a lot of shipping. 🍹 #hackathon",
      hashtags: ["#hackathon", "#stuttgart", "#cursor", "#buildinpublic", "#strolling"],
    };
    res.json(result);
    return;
  }

  // TODO(COMMIT-5): real publish (n8n → YouTube Short) goes here (see above).
  void body;
  res.status(501).json({ error: "not_implemented", route: "publish" });
});
