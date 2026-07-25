import { randomUUID } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { MulterError } from "multer";

// Central error handler. Multer surfaces upload problems (e.g. file too large)
// here; everything else becomes a 500.
//
// Never return raw error messages: our store wraps Supabase/Postgres errors
// (DbNotReadyError carries the driver message), so echoing err.message would
// leak schema and driver internals to any caller. Log server-side, hand the
// client an incident id it can quote instead.
export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof MulterError) {
    res.status(400).json({ error: "upload_error", code: err.code });
    return;
  }
  const incidentId = randomUUID();
  console.error(`[strolling] unhandled error [${incidentId}]:`, err);
  res.status(500).json({ error: "internal_error", incidentId });
}
