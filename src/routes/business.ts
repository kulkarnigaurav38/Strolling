import { Router } from "express";
import {
  ClaimTransitionError,
  DbNotReadyError,
  getStore,
  type OfferPatch,
} from "../lib/store";
import { badBool, badInt, badString } from "../lib/validate";
import { writeRateLimit } from "../middleware/rateLimit";
import type { OfferType } from "../lib/types";

// Business portal API. ⚠️ MOCK auth: no auth for the hackathon — the business
// id in the path is trusted. Mock business id 'demo' maps to the seeded demo
// dashboard data; real ids are business slugs (e.g. 'brot-roesterei').

export const businessRouter = Router();
// Only rate-limit writes. The dashboard fires four GETs on every open/refresh,
// so a router-wide limiter would 429 the portal after a few refreshes.
businessRouter.use((req, res, next) =>
  req.method === "GET" ? next() : writeRateLimit(req, res, next),
);

const OFFER_TYPES: OfferType[] = ["in_kind", "cash"];

function handleError(
  err: unknown,
  res: import("express").Response,
  next: import("express").NextFunction,
): void {
  if (err instanceof ClaimTransitionError) {
    res.status(409).json({ error: "invalid_transition", detail: err.message });
    return;
  }
  if (err instanceof DbNotReadyError) {
    res.status(503).json({ error: "db_not_ready" });
    return;
  }
  next(err);
}

/** Shared field validation for offer create/patch bodies. */
function badOfferFields(body: Record<string, unknown>): string | null {
  return (
    badString(body.perkTitle, "perkTitle", { max: 120 }) ??
    badInt(body.perkValue, "perkValue", { min: 0, max: 100_000 }) ??
    badString(body.deliverable, "deliverable", { max: 200 }) ??
    badInt(body.minFollowers, "minFollowers", { min: 0, max: 100_000_000 }) ??
    badInt(body.slotsTotal, "slotsTotal", { min: 1, max: 100_000 }) ??
    badInt(body.slotsRemaining, "slotsRemaining", { min: 0, max: 100_000 }) ??
    badBool(body.active, "active")
  );
}

// POST /api/business/register { name, email } → { businessId, verified: false }
businessRouter.post("/register", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as { name?: string; email?: string };
    const invalid =
      badString(body.name, "name", { required: true, max: 80 }) ??
      badString(body.email, "email", { required: true, max: 120 });
    if (invalid) {
      res.status(400).json({ error: invalid });
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email!)) {
      res.status(400).json({ error: "email must be a valid address" });
      return;
    }
    const result = await getStore().registerBusiness(body.name!, body.email!);
    res.status(201).json(result);
  } catch (err) {
    handleError(err, res, next);
  }
});

// POST /api/business/verify { businessId } → { businessId, verified: true }
// ⚠️ MOCK verification — TODO(REAL): Google Business Profile API ownership check.
businessRouter.post("/verify", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as { businessId?: string };
    if (!body.businessId) {
      res.status(400).json({ error: "businessId is required" });
      return;
    }
    const result = await getStore().verifyBusiness(body.businessId);
    if (!result) {
      res.status(404).json({ error: "business_not_found" });
      return;
    }
    res.json(result);
  } catch (err) {
    handleError(err, res, next);
  }
});

// PATCH /api/business/offers/:offerId { active?, slotsRemaining?, ... } → offer
businessRouter.patch("/offers/:offerId", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as Record<string, unknown>;
    if (
      body.offerType !== undefined &&
      !OFFER_TYPES.includes(body.offerType as OfferType)
    ) {
      res
        .status(400)
        .json({ error: `offerType must be one of ${OFFER_TYPES.join(", ")}` });
      return;
    }
    const invalid = badOfferFields(body);
    if (invalid) {
      res.status(400).json({ error: invalid });
      return;
    }
    const patch: OfferPatch = {
      perkTitle: body.perkTitle as string | undefined,
      perkValue: body.perkValue as number | undefined,
      offerType: body.offerType as OfferType | undefined,
      deliverable: body.deliverable as string | undefined,
      minFollowers: body.minFollowers as number | undefined,
      slotsTotal: body.slotsTotal as number | undefined,
      slotsRemaining: body.slotsRemaining as number | undefined,
      active: body.active as boolean | undefined,
    };
    const offer = await getStore().updateOffer(req.params.offerId, patch);
    if (!offer) {
      res.status(404).json({ error: "offer_not_found" });
      return;
    }
    res.json(offer);
  } catch (err) {
    handleError(err, res, next);
  }
});

// POST /api/business/perks/:perkId/approve → perk/claim with status 'approved'
businessRouter.post("/perks/:perkId/approve", async (req, res, next) => {
  try {
    const claim = await getStore().approvePerk(req.params.perkId);
    if (!claim) {
      res.status(404).json({ error: "perk_not_found" });
      return;
    }
    res.json(claim);
  } catch (err) {
    handleError(err, res, next);
  }
});

// GET /api/business/:id/offers → the business's offers (active + paused)
businessRouter.get("/:id/offers", async (req, res, next) => {
  try {
    const offers = await getStore().listBusinessOffers(req.params.id);
    res.json(offers);
  } catch (err) {
    handleError(err, res, next);
  }
});

// POST /api/business/:id/offers { perkTitle, perkValue, offerType,
// deliverable, minFollowers?, slotsTotal? } → created offer
businessRouter.post("/:id/offers", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as {
      perkTitle?: string;
      perkValue?: number;
      offerType?: string;
      deliverable?: string;
      minFollowers?: number;
      slotsTotal?: number;
    };
    if (!OFFER_TYPES.includes(body.offerType as OfferType)) {
      res
        .status(400)
        .json({ error: `offerType must be one of ${OFFER_TYPES.join(", ")}` });
      return;
    }
    const invalid =
      badString(body.perkTitle, "perkTitle", { required: true, max: 120 }) ??
      badInt(body.perkValue, "perkValue", { required: true, min: 0, max: 100_000 }) ??
      badString(body.deliverable, "deliverable", { required: true, max: 200 }) ??
      badInt(body.minFollowers, "minFollowers", { min: 0, max: 100_000_000 }) ??
      badInt(body.slotsTotal, "slotsTotal", { min: 1, max: 100_000 });
    if (invalid) {
      res.status(400).json({ error: invalid });
      return;
    }
    const offer = await getStore().createBusinessOffer(req.params.id, {
      perkTitle: body.perkTitle!,
      perkValue: body.perkValue!,
      offerType: body.offerType as OfferType,
      deliverable: body.deliverable!,
      minFollowers: body.minFollowers,
      slotsTotal: body.slotsTotal,
    });
    res.status(201).json(offer);
  } catch (err) {
    handleError(err, res, next);
  }
});

// The portal's showcase id. 'demo' aggregates every business so a creator who
// posts about any stop shows up on the dashboard during the stage demo.
// TODO(REAL:auth): scope this to the signed-in owner's businesses.

// GET /api/business/:id/creators → live creators
// [{ name, handle, followers, status: 'en_route'|'arrived'|'posted', etaMin }]
businessRouter.get("/:id/creators", async (req, res, next) => {
  try {
    const creators = await getStore().listBusinessCreators(req.params.id);
    res.json(creators);
  } catch (err) {
    handleError(err, res, next);
  }
});

// GET /api/business/:id/posts → posts about the business (+ creatorHandle)
businessRouter.get("/:id/posts", async (req, res, next) => {
  try {
    const posts = await getStore().listBusinessPosts(req.params.id);
    res.json(posts);
  } catch (err) {
    handleError(err, res, next);
  }
});

// GET /api/business/:id/stats → { creatorsHosted, posts, totalReach, costEur }
businessRouter.get("/:id/stats", async (req, res, next) => {
  try {
    const stats = await getStore().getBusinessStats(req.params.id);
    res.json(stats);
  } catch (err) {
    handleError(err, res, next);
  }
});
