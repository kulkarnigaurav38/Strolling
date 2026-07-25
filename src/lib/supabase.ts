import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { config } from "../config";

// Supabase boundary: read render jobs, write status, and store the finished reel.
// Uses the SERVICE-ROLE key (backend only — bypasses RLS). When Supabase isn't
// configured the render pipeline falls back to fal storage / local files, so the
// whole thing still runs with zero Supabase setup.

let client: SupabaseClient | null = null;

export function isSupabaseEnabled(): boolean {
  return Boolean(config.supabaseUrl && config.supabaseServiceKey);
}

function sb(): SupabaseClient {
  if (!isSupabaseEnabled()) throw new Error("Supabase is not configured");
  if (!client) {
    client = createClient(config.supabaseUrl, config.supabaseServiceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}

/** One shot as stored in the job row's `shots` jsonb. */
export interface JobShot {
  mediaUrl: string;
  kind: "photo" | "clip";
  script: string;
}

export interface RenderJob {
  id: string;
  shots: JobShot[];
  business?: unknown;
}

export async function getJob(id: string): Promise<RenderJob> {
  const { data, error } = await sb()
    .from(config.supabaseTable)
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw new Error(`getJob(${id}): ${error.message}`);
  const shots = Array.isArray(data.shots) ? (data.shots as JobShot[]) : [];
  return { id: data.id, shots, business: data.business ?? undefined };
}

/** IDs of jobs waiting to be rendered (oldest first). */
export async function listQueuedJobs(limit = 5): Promise<string[]> {
  const { data, error } = await sb()
    .from(config.supabaseTable)
    .select("id")
    .eq("status", "queued")
    .order("created_at", { ascending: true })
    .limit(limit);
  if (error) throw new Error(`listQueuedJobs: ${error.message}`);
  return (data ?? []).map((r) => r.id as string);
}

/**
 * Atomically claim a job: flip queued → processing only if it's still queued.
 * Returns true if THIS caller won the claim (so it should render it).
 */
export async function claimJob(id: string): Promise<boolean> {
  const { data, error } = await sb()
    .from(config.supabaseTable)
    .update({ status: "processing", updated_at: new Date().toISOString() })
    .eq("id", id)
    .eq("status", "queued")
    .select("id");
  if (error) throw new Error(`claimJob(${id}): ${error.message}`);
  return (data?.length ?? 0) > 0;
}

export async function updateJob(
  id: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const { error } = await sb()
    .from(config.supabaseTable)
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq("id", id);
  if (error) throw new Error(`updateJob(${id}): ${error.message}`);
}

/** Upload the finished reel to the reels bucket; returns its public URL. */
export async function uploadReel(bytes: Buffer, name: string): Promise<string> {
  const bucket = config.supabaseReelsBucket;
  const { error } = await sb()
    .storage.from(bucket)
    .upload(name, bytes, { contentType: "video/mp4", upsert: true });
  if (error) throw new Error(`uploadReel(${name}): ${error.message}`);
  const { data } = sb().storage.from(bucket).getPublicUrl(name);
  return data.publicUrl;
}
