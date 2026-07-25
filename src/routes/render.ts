import { Router } from "express";
import { config } from "../config";
import { MOCK_MEDIA, MOCK_SCRIPT } from "../lib/mockAssets";
import type { RenderRequest, RenderResult } from "../lib/types";
import {
  renderVideo,
  type MediaItem,
  type RenderInput,
} from "../services/renderPipeline";

export const renderRouter = Router();

// POST /api/render { captures, reviews, business, voiceoverUrl? } → { videoUrl }
//
// Behaviour:
//   MOCK=1 (default)          → instant pre-baked /mock/sample.mp4 (unblocks teammates)
//   MOCK=1 with ?force=1       → run the real pipeline once (dev)
//   MOCK=0                     → always run the real pipeline
//
// Inputs: the creator's `captures` + `reviews` are used when present; otherwise the
// mock pictures + mock script stand in. Real data always wins — nothing to change
// here when the capture/interview parts land.
renderRouter.post("/", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as Partial<RenderRequest> & {
      voiceoverUrl?: string;
    };

    const media: MediaItem[] = (body.captures ?? [])
      .filter((c) => c && c.mediaUrl)
      .map((c) => ({ url: c.mediaUrl, kind: c.kind }));

    const script = (body.reviews ?? [])
      .map((r) => r?.transcript)
      .filter(Boolean)
      .join(" ")
      .trim();

    const input: RenderInput = {
      media: media.length > 0 ? media : MOCK_MEDIA,
      script: script || MOCK_SCRIPT,
      business: body.business,
      voiceoverUrl: body.voiceoverUrl,
    };

    // Fast path for teammates who just need a valid response shape.
    if (config.mock && req.query.force === undefined) {
      const result: RenderResult = { videoUrl: "/mock/sample.mp4" };
      res.json(result);
      return;
    }

    const { videoUrl, usedFal } = await renderVideo(input);
    res.setHeader("x-render-engine", usedFal ? "fal" : "ffmpeg-local");
    res.setHeader(
      "x-render-inputs",
      media.length > 0 ? "creator" : "mock",
    );
    const result: RenderResult = { videoUrl };
    res.json(result);
  } catch (err) {
    next(err);
  }
});
