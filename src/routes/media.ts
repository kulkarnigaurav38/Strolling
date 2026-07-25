import { randomUUID } from "node:crypto";
import { Router } from "express";
import multer from "multer";
import { config } from "../config";
import type { UploadResult } from "../lib/types";

export const mediaRouter = Router();

// Keep bytes in memory — in mock we don't persist; the real handler streams
// straight to fal storage.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB (short clips)
});

// POST /api/media/upload  (multipart/form-data, field "file") → { mediaUrl }
mediaRouter.post("/upload", upload.single("file"), async (req, res) => {
  if (!req.file) {
    res.status(400).json({ error: "no_file", hint: "send multipart field 'file'" });
    return;
  }

  if (config.mock) {
    // TODO(COMMIT-3): fal.storage.upload(req.file.buffer) → durable URL
    const id = randomUUID();
    const safeName = req.file.originalname.replace(/[^\w.\-]/g, "_");
    const result: UploadResult = {
      mediaUrl: `https://mock.storage/strolling/${id}-${safeName}`,
    };
    res.json(result);
    return;
  }

  res.status(501).json({ error: "not_implemented", route: "media/upload" });
});
