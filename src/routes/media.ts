import { randomUUID } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { Router } from "express";
import multer from "multer";
import { config } from "../config";
import * as falApi from "../lib/fal";
import type { UploadResult } from "../lib/types";

export const mediaRouter = Router();

// Keep bytes in memory, then persist to fal (preferred) or local /uploads.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB (short clips)
});

function publicUrl(relPath: string): string {
  const base = config.publicBaseUrl || `http://localhost:${config.port}`;
  return `${base.replace(/\/$/, "")}${relPath}`;
}

/** Persist capture bytes so /api/render can fetch them. Prefer fal (public URL
 *  reachable by Kling); fall back to local /uploads for keyless / offline. */
async function persistUpload(
  buffer: Buffer,
  originalname: string,
): Promise<string> {
  const safeName = originalname.replace(/[^\w.\-]/g, "_") || "capture.bin";
  const filename = `${randomUUID()}-${safeName}`;

  if (falApi.isFalEnabled()) {
    try {
      return await falApi.uploadToStorage(buffer, filename);
    } catch (err) {
      console.warn(
        "[strolling] fal upload failed, falling back to local:",
        (err as Error).message,
      );
    }
  }

  await mkdir(config.uploadsDir, { recursive: true });
  await writeFile(path.join(config.uploadsDir, filename), buffer);
  return publicUrl(`/uploads/${filename}`);
}

// POST /api/media/upload  (multipart/form-data, field "file") → { mediaUrl }
mediaRouter.post("/upload", upload.single("file"), async (req, res, next) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: "no_file", hint: "send multipart field 'file'" });
      return;
    }

    const mediaUrl = await persistUpload(req.file.buffer, req.file.originalname);
    const result: UploadResult = { mediaUrl };
    res.json(result);
  } catch (err) {
    next(err);
  }
});
