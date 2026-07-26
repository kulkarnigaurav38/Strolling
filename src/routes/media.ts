import { randomUUID } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { Router } from "express";
import multer from "multer";
import { config } from "../config";
import * as falApi from "../lib/fal";
import { log, startStep, warn } from "../lib/log";
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

/** Persist capture bytes so /api/render can fetch them.
 *
 *  Stills go to fal storage (Kling, on the public internet, must fetch them to
 *  animate them). VIDEOS do NOT: a clip is processed entirely by local ffmpeg,
 *  so uploading it to fal is pure latency — a 24MB clip took ~137s that way and
 *  blew the client's upload timeout. Videos are written to local /uploads and
 *  the render pipeline reads them straight back over localhost. */
async function persistUpload(
  buffer: Buffer,
  originalname: string,
  mimetype: string,
): Promise<string> {
  const safeName = originalname.replace(/[^\w.\-]/g, "_") || "capture.bin";
  const filename = `${randomUUID()}-${safeName}`;
  // Only STILLS need a public (fal) URL — Kling, on the internet, fetches them
  // to animate. Videos (local ffmpeg) and voice notes (transcribed on the
  // backend) are read straight off local disk, so they skip the slow fal hop.
  const needsPublicUrl = mimetype.startsWith("image/");

  if (needsPublicUrl && falApi.isFalEnabled()) {
    try {
      const done = startStep("upload", "→ fal storage (public URL for Kling)", { file: safeName });
      const url = await falApi.uploadToStorage(buffer, filename);
      done(url);
      return url;
    } catch (err) {
      warn("upload", "fal upload failed → saving locally instead", {
        why: (err as Error).message,
      });
    }
  }

  await mkdir(config.uploadsDir, { recursive: true });
  await writeFile(path.join(config.uploadsDir, filename), buffer);
  const url = publicUrl(`/uploads/${filename}`);
  log("upload", needsPublicUrl ? "→ local /uploads" : "→ local /uploads (stays local)", {
    file: safeName,
    url,
  });
  return url;
}

// POST /api/media/upload  (multipart/form-data, field "file") → { mediaUrl }
mediaRouter.post("/upload", upload.single("file"), async (req, res, next) => {
  try {
    if (!req.file) {
      warn("upload", "rejected — no file in request");
      res.status(400).json({ error: "no_file", hint: "send multipart field 'file'" });
      return;
    }

    log("upload", "received", {
      name: req.file.originalname,
      type: req.file.mimetype,
      sizeKB: Math.round(req.file.size / 1024),
    });
    const mediaUrl = await persistUpload(
      req.file.buffer,
      req.file.originalname,
      req.file.mimetype,
    );
    const result: UploadResult = { mediaUrl };
    res.json(result);
  } catch (err) {
    next(err);
  }
});
