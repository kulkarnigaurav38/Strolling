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
      // The simple synchronous shape: pictures + their script parts.
      shots?: { mediaUrl: string; kind?: "photo" | "clip"; script?: string }[];
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

    // --- Path B: synchronous "send pictures + scripts → get the video back" ---
    // The frontend POSTs { shots: [{ mediaUrl, kind, script }] } (or legacy
    // captures/reviews) and gets { videoUrl } once the render finishes.
    const shots = shotsFromPayload(body);

    // ⚠️ MOCK fast-path — ONLY when no real shots were sent (keeps teammates who
    // just want the response shape unblocked). A real request always renders.
    if (shots.length === 0 && config.mock && req.query.force === undefined) {
      const result: RenderResult = { videoUrl: "/mock/sample.mp4" };
      res.json(result);
      return;
    }

    const input: RenderInput = {
      shots: shots.length > 0 ? shots : MOCK_SHOTS,
      business: body.business,
      voiceoverUrl: body.voiceoverUrl,
    };
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

/**
 * Build shots from the request. Preferred shape is a direct `shots` array
 * ({ mediaUrl, kind, script }); legacy callers can still send captures + reviews
 * paired by taskId.
 */
function shotsFromPayload(
  body: Partial<RenderRequest> & {
    shots?: { mediaUrl: string; kind?: "photo" | "clip"; script?: string }[];
  },
): Shot[] {
  // Preferred: pictures + their script parts, already paired.
  if (Array.isArray(body.shots) && body.shots.length > 0) {
    return body.shots
      .filter((s) => s && s.mediaUrl)
      .map((s) => ({
        media: { url: s.mediaUrl, kind: s.kind === "clip" ? "clip" : "photo" },
        script: (s.script ?? "").trim(),
      }));
  }

  // Legacy: captures + reviews paired by taskId.
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
