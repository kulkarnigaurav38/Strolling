import { config } from "../config";
import * as supabase from "../lib/supabase";
import type { Business } from "../lib/types";
import { renderVideo, type Shot } from "./renderPipeline";

// Background worker: watches the reels table for new `queued` jobs and renders
// them automatically — so the frontend just inserts a row and the finished reel
// shows up on that row. No API call needed.
//
// A poller (not Realtime) so it's robust: it survives reconnects/restarts and
// catches any rows inserted while the server was down. Jobs are claimed
// atomically (claimJob) so each renders exactly once, even with the /api/render
// {jobId} trigger firing at the same time.

const inFlight = new Set<string>();
let started = false;

export function startJobWorker(): void {
  if (started) return;
  if (!config.jobWorker) {
    console.log("[strolling] job worker disabled (JOB_WORKER=0)");
    return;
  }
  if (!supabase.isSupabaseEnabled()) {
    console.log("[strolling] job worker OFF (Supabase not configured)");
    return;
  }
  started = true;
  console.log(
    `[strolling] job worker ON — polling "${config.supabaseTable}" every ${config.jobPollMs}ms (max ${config.jobMaxConcurrent} concurrent)`,
  );
  const tick = async () => {
    try {
      await pollOnce();
    } catch (err) {
      console.error("[strolling] worker poll error:", (err as Error).message);
    } finally {
      setTimeout(tick, config.jobPollMs);
    }
  };
  void tick();
}

async function pollOnce(): Promise<void> {
  if (inFlight.size >= config.jobMaxConcurrent) return;
  const capacity = config.jobMaxConcurrent - inFlight.size;
  const queued = await supabase.listQueuedJobs(capacity);
  for (const jobId of queued) {
    if (inFlight.size >= config.jobMaxConcurrent) break;
    void processJobById(jobId);
  }
}

/**
 * Claim + render one job, then write the result to its row. Safe to call from
 * both the poller and the /api/render {jobId} endpoint — claimJob guarantees it
 * runs once. Never throws (errors land on the row).
 */
export async function processJobById(jobId: string): Promise<void> {
  if (inFlight.has(jobId)) return;
  let claimed = false;
  try {
    claimed = await supabase.claimJob(jobId);
  } catch (err) {
    console.error(`[strolling] claim ${jobId} failed:`, (err as Error).message);
    return;
  }
  if (!claimed) return; // someone else took it, or it isn't queued

  inFlight.add(jobId);
  try {
    const job = await supabase.getJob(jobId);
    const shots: Shot[] = (job.shots ?? [])
      .filter((s) => s && s.mediaUrl)
      .map((s) => ({
        media: { url: s.mediaUrl, kind: s.kind },
        script: s.script ?? "",
      }));
    if (shots.length === 0) throw new Error("job has no shots");

    const { videoUrl } = await renderVideo({
      shots,
      business: job.business as Business | undefined,
    });
    await supabase.updateJob(jobId, { status: "done", video_url: videoUrl });
    console.log(`[strolling] job ${jobId} done → ${videoUrl}`);
  } catch (err) {
    const message = (err as Error).message;
    console.error(`[strolling] job ${jobId} failed:`, message);
    await supabase
      .updateJob(jobId, { status: "error", error: message })
      .catch(() => {});
  } finally {
    inFlight.delete(jobId);
  }
}
