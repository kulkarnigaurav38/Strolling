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
      // Real creator shots when present. ⚠️ MOCK: MOCK_SHOTS (lib/mockAssets.ts)
      // stand in when the request has no captures. This needs NO change when the
      // real capture/interview parts ship — they just start POSTing captures +
      // reviews and this uses them automatically.
      shots: shots.length > 0 ? shots : MOCK_SHOTS,
      business: body.business,
      // Optional: a pre-made whole-video narration track (e.g. from another part).
      voiceoverUrl: body.voiceoverUrl,
    };

    // ⚠️ MOCK fast-path: MOCK=1 (default) returns a pre-baked sample video so
    // teammates who only need the response shape aren't blocked / charged.
    // Use ?force=1 (or set MOCK=0) to run the REAL fal + ElevenLabs pipeline.
    if (config.mock && req.query.force === undefined) {
      const result: RenderResult = { videoUrl: "/mock/sample.mp4" }; // served from public/mock/
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
