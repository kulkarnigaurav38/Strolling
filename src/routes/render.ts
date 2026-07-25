import { Router } from "express";
import { config } from "../config";
import { MOCK_SHOTS } from "../lib/mockAssets";
import type { RenderRequest, RenderResult } from "../lib/types";
import { renderVideo, type RenderInput, type Shot } from "../services/renderPipeline";

export const renderRouter = Router();

// POST /api/render { captures, reviews, business, voiceoverUrl? } → { videoUrl }
//
// The script arrives in PARTS: each `reviews[]` entry (a script part) is tied to a
// `captures[]` entry by `taskId`. We pair them into shots so each part's voiceover
// plays over its own photo/clip. Real creator data always wins; with no captures,
// the mock shots stand in.
//
//   MOCK=1 (default)     → instant pre-baked /mock/sample.mp4 (unblocks teammates)
//   MOCK=1 with ?force=1  → run the real pipeline once (dev)
//   MOCK=0               → always run the real pipeline
renderRouter.post("/", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as Partial<RenderRequest> & {
      voiceoverUrl?: string;
    };

    // Script part per shot, matched to its capture by taskId.
    const partByTask = new Map<string, string>(
      (body.reviews ?? [])
        .filter((r) => r && r.taskId)
        .map((r) => [r.taskId, (r.transcript ?? "").trim()] as [string, string]),
    );
    const shots: Shot[] = (body.captures ?? [])
      .filter((c) => c && c.mediaUrl)
      .map((c) => ({
        media: { url: c.mediaUrl, kind: c.kind },
        script: partByTask.get(c.taskId) ?? "",
      }));

    const input: RenderInput = {
      shots: shots.length > 0 ? shots : MOCK_SHOTS,
      business: body.business,
      voiceoverUrl: body.voiceoverUrl,
    };

    // Fast path for teammates who just need a valid response shape.
    if (config.mock && req.query.force === undefined) {
      const result: RenderResult = { videoUrl: "/mock/sample.mp4" };
      res.json(result);
      return;
    }

    const { videoUrl, usedFal, voiceoverEngine } = await renderVideo(input);
    res.setHeader("x-render-engine", usedFal ? "fal" : "ffmpeg-local");
    res.setHeader("x-render-inputs", shots.length > 0 ? "creator" : "mock");
    res.setHeader("x-render-shots", String(input.shots.length));
    res.setHeader("x-voiceover-engine", voiceoverEngine);
    const result: RenderResult = { videoUrl };
    res.json(result);
  } catch (err) {
    next(err);
  }
});
