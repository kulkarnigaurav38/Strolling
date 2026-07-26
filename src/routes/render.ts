import { Router } from "express";
import { config } from "../config";
import { fail, log } from "../lib/log";
import { MOCK_SHOTS } from "../lib/mockAssets";
import { buildPostPackage } from "../lib/postPackage";
import {
  failProgress,
  finishProgress,
  getProgress,
  startProgress,
} from "../lib/progress";
import * as supabase from "../lib/supabase";
import type {
  RenderRequest,
  RenderResult,
  StrollRenderPart,
} from "../lib/types";
import { processJobById } from "../services/jobWorker";
import { renderVideo, type RenderInput, type Shot } from "../services/renderPipeline";

export const renderRouter = Router();

// GET /api/render/progress/:id — live progress for a synchronous render.
// The frontend polls this in parallel with its (long, blocking) POST /api/render
// so it can show an honest progress bar. Returns 404 until the render starts.
renderRouter.get("/progress/:id", (req, res) => {
  const p = getProgress(req.params.id);
  if (!p) {
    res.status(404).json({ pct: 0, stage: "starting", done: false, error: null });
    return;
  }
  res.json({
    id: p.id,
    pct: p.pct,
    stage: p.stage,
    done: p.done,
    error: p.error,
    elapsedMs: Date.now() - p.startedAt,
  });
});

// POST /api/render
//
//   Async job (recommended):   { jobId }
//     → reads the Supabase job row, renders in the BACKGROUND (renders take
//       minutes), and writes { status, video_url } back to the row. Responds 202
//       immediately; the frontend watches the row via Supabase Realtime.
//
//   Stroll / direct payload:   { images, videoUrl, audioUrl, text, script }
//     or { parts: [...] } or legacy { shots } / { captures, reviews, business }
//     → renders synchronously and returns a post package
//       { videoUrl, caption, hashtags, script }.
//
// Either way the script arrives in PARTS: each part is tied to its media.
// Real creator data always wins; with none, ⚠️ MOCK_SHOTS stand in.
renderRouter.post("/", async (req, res, next) => {
  const body = (req.body ?? {}) as Partial<RenderRequest>;
  const renderId =
    typeof body.renderId === "string" && body.renderId ? body.renderId : undefined;
  try {
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

    // --- Path B: synchronous "media + words → post package" ---
    const { shots, voiceoverUrl, voiceNoteUrl, scriptText } = shotsFromPayload(body);

    log("render", "request received", {
      renderId,
      images: (body.images ?? []).length,
      video: body.videoUrl ? 1 : 0,
      voiceNote: voiceNoteUrl ? "yes (will transcribe)" : "no",
      shots: shots.length || "mock",
      business: body.business?.slug ?? body.business?.name,
      scriptChars: scriptText.length,
    });

    // ⚠️ MOCK fast-path (default MOCK=1): return a contract-shaped post package
    // instantly. Use ?force=1 or MOCK=0 to run the real pipeline.
    if (config.mock && req.query.force === undefined) {
      log("render", "MOCK fast-path — returning sample.mp4 (set MOCK=0 for the real pipeline)");
      finishProgress(renderId, "Ready (mock)");
      const result: RenderResult = buildPostPackage({
        videoUrl: "/mock/sample.mp4",
        script: scriptText,
        text: body.text,
        business: body.business,
      });
      res.json(result);
      return;
    }

    startProgress(renderId, "Preparing render");
    const input: RenderInput = {
      shots: shots.length > 0 ? shots : MOCK_SHOTS,
      business: body.business,
      voiceoverUrl,
      voiceNoteUrl,
      renderId,
    };
    if (shots.length === 0) {
      log("render", "no creator media in request — falling back to MOCK_SHOTS");
    }
    const { videoUrl, usedFal, voiceoverEngine, cleanedScript } =
      await renderVideo(input);
    finishProgress(renderId);
    res.setHeader("x-render-engine", usedFal ? "fal" : "ffmpeg-local");
    res.setHeader("x-render-inputs", shots.length > 0 ? "creator" : "mock");
    res.setHeader("x-render-shots", String(input.shots.length));
    res.setHeader("x-voiceover-engine", voiceoverEngine);
    const result: RenderResult = buildPostPackage({
      videoUrl,
      script: cleanedScript || scriptText,
      text: body.text,
      business: body.business,
    });
    res.json(result);
  } catch (err) {
    fail("render", "request failed", err);
    failProgress(renderId, (err as Error).message);
    next(err);
  }
});

/**
 * Build shots from the request. Preferred stroll shapes:
 *   1. parts[] — one entry per scene (images / video / audio / text / script)
 *   2. flat { images, videoUrl, audioUrl, text, script }
 *   3. shots[] — already paired { mediaUrl, kind, script }
 *   4. legacy captures + reviews paired by taskId
 */
function shotsFromPayload(body: Partial<RenderRequest>): {
  shots: Shot[];
  voiceoverUrl?: string;
  voiceNoteUrl?: string;
  scriptText: string;
} {
  // Preferred: pictures + their script parts, already paired.
  if (Array.isArray(body.shots) && body.shots.length > 0) {
    const shots = body.shots
      .filter((s) => s && s.mediaUrl)
      .map((s) => ({
        media: {
          url: s.mediaUrl,
          kind: (s.kind === "clip" ? "clip" : "photo") as "photo" | "clip",
        },
        script: (s.script ?? "").trim(),
      }));
    return {
      shots,
      voiceoverUrl: body.voiceoverUrl ?? body.audioUrl,
      voiceNoteUrl: body.voiceNoteUrl,
      scriptText: shots.map((s) => s.script).filter(Boolean).join(" "),
    };
  }

  // Multi-stop stroll parts.
  if (Array.isArray(body.parts) && body.parts.length > 0) {
    const shots: Shot[] = [];
    const scripts: string[] = [];
    let voiceoverUrl = body.voiceoverUrl;
    let voiceNoteUrl = body.voiceNoteUrl;
    for (const part of body.parts) {
      const { partShots, partVoice, partScript } = shotsFromPart(part);
      shots.push(...partShots);
      if (partScript) scripts.push(partScript);
      if (!voiceoverUrl && partVoice) voiceoverUrl = partVoice;
      if (!voiceNoteUrl && part.voiceNoteUrl) voiceNoteUrl = part.voiceNoteUrl;
    }
    return {
      shots,
      voiceoverUrl,
      voiceNoteUrl,
      scriptText: scripts.join(" ") || (body.script ?? body.text ?? "").trim(),
    };
  }

  // Flat stroll shape: any mix of images / video / audio / text / script.
  if (hasStrollFields(body)) {
    const { partShots, partVoice, partScript } = shotsFromPart({
      images: body.images,
      videoUrl: body.videoUrl,
      audioUrl: body.audioUrl,
      text: body.text,
      script: body.script,
    });
    return {
      shots: partShots,
      voiceoverUrl: body.voiceoverUrl ?? partVoice,
      voiceNoteUrl: body.voiceNoteUrl,
      scriptText: partScript || (body.script ?? body.text ?? "").trim(),
    };
  }

  // Legacy: captures + reviews paired by taskId.
  const partByTask = new Map<string, string>(
    (body.reviews ?? [])
      .filter((r) => r && r.taskId)
      .map((r) => [r.taskId, (r.transcript ?? "").trim()] as [string, string]),
  );
  const shots = (body.captures ?? [])
    .filter((c) => c && c.mediaUrl)
    .map((c) => ({
      media: { url: c.mediaUrl, kind: c.kind },
      script: partByTask.get(c.taskId) ?? "",
    }));
  return {
    shots,
    voiceoverUrl: body.voiceoverUrl ?? body.audioUrl,
    voiceNoteUrl: body.voiceNoteUrl,
    scriptText: shots.map((s) => s.script).filter(Boolean).join(" "),
  };
}

function hasStrollFields(body: Partial<RenderRequest>): boolean {
  return Boolean(
    (body.images && body.images.length > 0) ||
      body.videoUrl ||
      body.audioUrl ||
      body.voiceNoteUrl ||
      body.text ||
      body.script,
  );
}

function shotsFromPart(part: StrollRenderPart): {
  partShots: Shot[];
  partVoice?: string;
  partScript: string;
} {
  const partScript = (part.script ?? part.text ?? "").trim();
  const partShots: Shot[] = [];

  for (const url of part.images ?? []) {
    if (!url) continue;
    partShots.push({
      media: { url, kind: "photo" },
      script: partScript,
    });
  }
  if (part.videoUrl) {
    partShots.push({
      media: { url: part.videoUrl, kind: "clip" },
      script: partScript,
    });
  }

  // Audio alone (no visual) → treat as whole-video voiceover; visuals come from
  // sibling parts / mock shots. Script-only still yields an empty shot list so
  // the mock fast-path can return a post package without rendering.
  return {
    partShots,
    partVoice: part.audioUrl,
    partScript,
  };
}
