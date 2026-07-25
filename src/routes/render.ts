import { Router } from "express";
import { config } from "../config";
import { MOCK_SHOTS } from "../lib/mockAssets";
import * as supabase from "../lib/supabase";
import type { RenderRequest, RenderResult } from "../lib/types";
import { processJobById } from "../services/jobWorker";
import { renderVideo, type RenderInput, type Shot } from "../services/renderPipeline";

export const renderRouter = Router();

// POST /api/render
//
//   Async job (recommended):   { jobId }
//     → reads the Supabase job row, renders in the BACKGROUND (renders take
//       minutes), and writes { status, video_url } back to the row. Responds 202
//       immediately; the frontend watches the row via Supabase Realtime.
//
//   Direct payload (testing):   { captures, reviews, business }
//     → renders synchronously and returns { videoUrl }.
//
// Either way the script arrives in PARTS: each review is tied to its capture by
// `taskId` → a shot. Real creator data always wins; with none, ⚠️ MOCK_SHOTS stand in.
renderRouter.post("/", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as Partial<RenderRequest> & {
      jobId?: string;
      voiceoverUrl?: string;
    };

    // --- Path A: async Supabase job (optional trigger) ---
    // Note: the background worker (services/jobWorker) already auto-renders any
    // queued row, so the frontend can just insert a row and skip this call. This
    // endpoint just nudges a specific job to render immediately; claimJob makes
    // sure the worker and this trigger never double-process it.
    if (body.jobId) {
      if (!supabase.isSupabaseEnabled()) {
        res.status(400).json({ error: "supabase_not_configured" });
        return;
      }
      const jobId = String(body.jobId);
      res.status(202).json({ jobId, status: "processing" });
      void processJobById(jobId);
      return;
    }

    // --- Path B: direct payload (for testing / non-Supabase callers) ---
    const shots = shotsFromPayload(body);
    const input: RenderInput = {
      shots: shots.length > 0 ? shots : MOCK_SHOTS,
      business: body.business,
      voiceoverUrl: body.voiceoverUrl,
    };

    // ⚠️ MOCK fast-path (direct payload only): MOCK=1 returns a pre-baked sample so
    // teammates aren't blocked. Use ?force=1 (or MOCK=0) to run the real pipeline.
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

/** Pair captures with their script parts (by taskId) into shots. */
function shotsFromPayload(body: Partial<RenderRequest>): Shot[] {
  const partByTask = new Map<string, string>(
    (body.reviews ?? [])
      .filter((r) => r && r.taskId)
      .map((r) => [r.taskId, (r.transcript ?? "").trim()] as [string, string]),
  );
  return (body.captures ?? [])
    .filter((c) => c && c.mediaUrl)
    .map((c) => ({
      media: { url: c.mediaUrl, kind: c.kind },
      script: partByTask.get(c.taskId) ?? "",
    }));
}
