import { Router } from "express";
import { DbNotReadyError, getStore } from "../lib/store";
import { badString } from "../lib/validate";
import { writeRateLimit } from "../middleware/rateLimit";
import type { PostPlatform } from "../lib/types";

export const postsRouter = Router();
postsRouter.use(writeRateLimit);

const PLATFORMS: PostPlatform[] = ["instagram", "tiktok", "facebook"];

// POST /api/posts { userId?, businessId, platform, url?, caption? }
// → { post, claim }. Creates the post row with ⚠️ MOCK metrics (reach
// 1200..45000) and advances the user's claim at that business to 'posted'
// (creating one at 'posted' if none exists). ⚠️ MOCK auth: userId defaults
// to 'demo-user'.
postsRouter.post("/", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as {
      userId?: string;
      businessId?: string;
      platform?: string;
      url?: string;
      caption?: string;
    };
    const userId = body.userId || "demo-user";
    if (!body.businessId) {
      res.status(400).json({ error: "businessId is required" });
      return;
    }
    if (!PLATFORMS.includes(body.platform as PostPlatform)) {
      res
        .status(400)
        .json({ error: `platform must be one of ${PLATFORMS.join(", ")}` });
      return;
    }
    const invalid =
      badString(body.url, "url", { max: 500 }) ??
      badString(body.caption, "caption", { max: 2000 });
    if (invalid) {
      res.status(400).json({ error: invalid });
      return;
    }
    const result = await getStore().createPost({
      userId,
      businessId: body.businessId,
      platform: body.platform as PostPlatform,
      url: body.url,
      caption: body.caption,
    });
    if (!result) {
      res.status(404).json({ error: "business_not_found" });
      return;
    }
    res.status(201).json(result);
  } catch (err) {
    if (err instanceof DbNotReadyError) {
      res.status(503).json({ error: "db_not_ready" });
      return;
    }
    next(err);
  }
});
