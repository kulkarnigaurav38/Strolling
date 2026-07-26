// In-memory render progress registry.
//
// A synchronous /api/render POST blocks for minutes while fal + ElevenLabs +
// ffmpeg do their work. To drive a HONEST progress bar on the frontend, the
// pipeline reports its stage here (keyed by a client-supplied renderId) and the
// frontend polls GET /api/render/progress/:id in parallel with the POST.
//
// This is deliberately in-memory: a single dev/backend process serves both the
// blocking POST and the poll GETs, and progress is ephemeral. Entries self-prune
// after TTL_MS so the map can't grow without bound.

export interface RenderProgress {
  id: string;
  pct: number; // 0..100 — monotonic, capped at 99 until done
  stage: string; // human-readable current step
  done: boolean;
  error: string | null;
  startedAt: number;
  updatedAt: number;
}

const store = new Map<string, RenderProgress>();
const TTL_MS = 15 * 60 * 1000; // forget a render 15 min after its last update

function prune(): void {
  const now = Date.now();
  for (const [id, p] of store) {
    if (now - p.updatedAt > TTL_MS) store.delete(id);
  }
}

function ensure(id: string): RenderProgress {
  let p = store.get(id);
  if (!p) {
    const now = Date.now();
    p = { id, pct: 0, stage: "Preparing", done: false, error: null, startedAt: now, updatedAt: now };
    store.set(id, p);
  }
  return p;
}

/** Begin tracking a render. No-op when id is falsy (progress is opt-in). */
export function startProgress(id?: string, stage = "Preparing render"): void {
  if (!id) return;
  prune();
  const now = Date.now();
  store.set(id, { id, pct: 1, stage, done: false, error: null, startedAt: now, updatedAt: now });
}

/** Report progress. Monotonic (never goes backwards) and capped below 100 until done. */
export function setProgress(id: string | undefined, pct: number, stage: string): void {
  if (!id) return;
  const p = store.get(id);
  if (!p || p.done) return;
  p.pct = Math.min(99, Math.max(p.pct, Math.round(pct)));
  p.stage = stage;
  p.updatedAt = Date.now();
}

export function finishProgress(id?: string, stage = "Ready"): void {
  if (!id) return;
  const p = ensure(id);
  p.pct = 100;
  p.stage = stage;
  p.done = true;
  p.error = null;
  p.updatedAt = Date.now();
}

export function failProgress(id?: string, error = "render failed"): void {
  if (!id) return;
  const p = ensure(id);
  p.done = true;
  p.error = error;
  p.stage = "Failed";
  p.updatedAt = Date.now();
}

export function getProgress(id: string): RenderProgress | undefined {
  return store.get(id);
}
