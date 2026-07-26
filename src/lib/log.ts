// Lightweight structured logging for the render pipeline (and anything else that
// wants readable, timestamped output). One prefix, a wall clock, and small
// key=value tails so a single render's steps are easy to follow in the terminal.
//
//   [strolling 14:02:11.481] render · animating shot 1/3  shot=1 kind=photo
//
// `startStep` returns a `done()` you call when the step finishes; it logs the
// elapsed time so you can immediately see which stage is slow.

function stamp(): string {
  return new Date().toISOString().slice(11, 23); // HH:MM:SS.mmm (UTC)
}

function fmt(extra?: Record<string, unknown>): string {
  if (!extra) return "";
  const parts = Object.entries(extra)
    .filter(([, v]) => v !== undefined && v !== null && v !== "")
    .map(([k, v]) => `${k}=${typeof v === "string" ? v : JSON.stringify(v)}`);
  return parts.length ? "  " + parts.join(" ") : "";
}

function errText(err: unknown): string {
  if (err instanceof Error) return err.message;
  return String(err);
}

export function log(scope: string, msg: string, extra?: Record<string, unknown>): void {
  console.log(`[strolling ${stamp()}] ${scope} · ${msg}${fmt(extra)}`);
}

export function warn(scope: string, msg: string, extra?: Record<string, unknown>): void {
  console.warn(`[strolling ${stamp()}] ${scope} · ⚠ ${msg}${fmt(extra)}`);
}

export function fail(scope: string, msg: string, err?: unknown): void {
  const tail = err ? `  ${errText(err)}` : "";
  console.error(`[strolling ${stamp()}] ${scope} · ✖ ${msg}${tail}`);
}

/**
 * Log the start of a step and return a `done()` that logs how long it took.
 * `done()` may be passed a short result note (e.g. a URL or engine name).
 */
export function startStep(
  scope: string,
  msg: string,
  extra?: Record<string, unknown>,
): (result?: string) => void {
  const t0 = Date.now();
  log(scope, `${msg}…`, extra);
  return (result?: string) => {
    const ms = Date.now() - t0;
    log(scope, `${msg} ✓${result ? " " + result : ""}`, { ms });
  };
}
