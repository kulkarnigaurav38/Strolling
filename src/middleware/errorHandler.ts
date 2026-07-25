import type { NextFunction, Request, Response } from "express";
import { MulterError } from "multer";

// Central error handler. Multer surfaces upload problems (e.g. file too large)
// here; everything else becomes a 500.
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
  console.error("[strolling] unhandled error:", err);
  const message = err instanceof Error ? err.message : "internal_error";
  res.status(500).json({ error: "internal_error", message });
}
