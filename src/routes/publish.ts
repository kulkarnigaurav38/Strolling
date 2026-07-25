import { Router } from "express";
import { config } from "../config";
import type { PublishRequest, PublishResult } from "../lib/types";

export const publishRouter = Router();

// POST /api/publish { videoUrl, transcript } → { postUrl, caption, hashtags }
publishRouter.post("/", async (req, res) => {
  const body = (req.body ?? {}) as Partial<PublishRequest>;

  if (config.mock) {
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

  // TODO(COMMIT-5): POST the finished video to the n8n webhook, which uploads a
  // YouTube Short and returns the live URL + generated caption/hashtags.
  void body;
  res.status(501).json({ error: "not_implemented", route: "publish" });
});
