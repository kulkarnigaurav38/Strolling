import { Router } from "express";
import { config } from "../config";
import { delay } from "../lib/mock";
import type { RenderRequest, RenderResult } from "../lib/types";

export const renderRouter = Router();

// POST /api/render { captures, reviews, business } → { videoUrl }
renderRouter.post("/", async (req, res) => {
  const body = (req.body ?? {}) as Partial<RenderRequest>;

  if (config.mock) {
    await delay(3000); // stand in for the real render pipeline's runtime
    const result: RenderResult = { videoUrl: "/mock/sample.mp4" };
    res.json(result);
    return;
  }

  // TODO(COMMIT-4): fal image-to-video on each capture, ffmpeg compose to a
  // vertical cut, lay real-voice narration from the reviews, upload, return URL.
  void body;
  res.status(501).json({ error: "not_implemented", route: "render" });
});
