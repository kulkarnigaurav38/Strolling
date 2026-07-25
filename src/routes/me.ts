import { Router } from "express";
import { DbNotReadyError, getStore } from "../lib/store";
import { badString } from "../lib/validate";
import { writeRateLimit } from "../middleware/rateLimit";
import type { SocialPlatform } from "../lib/types";

export const meRouter = Router();

const SOCIAL_PLATFORMS: SocialPlatform[] = ["instagram", "facebook", "tiktok"];

// GET /api/me/perks?userId= → the user's claims/perks (wallet). ⚠️ MOCK auth:
// userId is a query param, default 'demo-user'.
meRouter.get("/perks", async (req, res, next) => {
  try {
    const userId =
      typeof req.query.userId === "string" && req.query.userId !== ""
        ? req.query.userId
        : "demo-user";
    const claims = await getStore().listUserClaims(userId);
    res.json(claims);
  } catch (err) {
    if (err instanceof DbNotReadyError) {
      res.status(503).json({ error: "db_not_ready" });
      return;
    }
    next(err);
  }
});

// POST /api/me/social-accounts { userId?, platform, handle }
// → { platform, handle, followers }. ⚠️ MOCK: the follower count is a
// deterministic hash of the handle (800..48000) — no real OAuth connect.
// TODO(REAL:social): Instagram/TikTok/Facebook OAuth + Graph API follower read.
meRouter.post("/social-accounts", writeRateLimit, async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as {
      userId?: string;
      platform?: string;
      handle?: string;
    };
    const userId = body.userId || "demo-user";
    if (!SOCIAL_PLATFORMS.includes(body.platform as SocialPlatform)) {
      res.status(400).json({
        error: `platform must be one of ${SOCIAL_PLATFORMS.join(", ")}`,
      });
      return;
    }
    const invalid = badString(body.handle, "handle", { required: true, max: 60 });
    if (invalid) {
      res.status(400).json({ error: invalid });
      return;
    }
    const account = await getStore().connectSocialAccount(
      userId,
      body.platform as SocialPlatform,
      body.handle!,
    );
    res.status(201).json({
      platform: account.platform,
      handle: account.handle,
      followers: account.followers,
    });
  } catch (err) {
    if (err instanceof DbNotReadyError) {
      res.status(503).json({ error: "db_not_ready" });
      return;
    }
    next(err);
  }
});
