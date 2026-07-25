import type { NextFunction, Request, Response } from "express";

// Minimal in-process rate limiter for the unauthenticated hackathon API.
// Not distributed, not persistent — just keeps a curl loop from flooding the
// store. TODO(REAL:auth): replace with per-user limits once auth exists.
const WINDOW_MS = 60_000;
const MAX_WRITES_PER_WINDOW = 30;

const hits = new Map<string, { count: number; resetAt: number }>();

export function writeRateLimit(req: Request, res: Response, next: NextFunction): void {
  const key = req.ip ?? "unknown";
  const now = Date.now();
  const entry = hits.get(key);
  if (!entry || now >= entry.resetAt) {
    hits.set(key, { count: 1, resetAt: now + WINDOW_MS });
    next();
    return;
  }
  entry.count += 1;
  if (entry.count > MAX_WRITES_PER_WINDOW) {
    res.status(429).json({ error: "rate_limited", retryAfterMs: entry.resetAt - now });
    return;
  }
  next();
}
