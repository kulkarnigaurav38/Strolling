import { Router } from "express";
import {
  ClaimTransitionError,
  DbNotReadyError,
  OfferUnavailableError,
  getStore,
} from "../lib/store";
import { writeRateLimit } from "../middleware/rateLimit";

export const claimsRouter = Router();
claimsRouter.use(writeRateLimit);

// POST /api/claims { userId?, offerId } → { id, userId, businessId, offerId,
// status: 'en_route', etaMin }. ⚠️ MOCK auth: no auth for the hackathon —
// userId comes from the body and defaults to 'demo-user'.
claimsRouter.post("/", async (req, res, next) => {
  try {
    const body = (req.body ?? {}) as { userId?: string; offerId?: string };
    const userId = body.userId || "demo-user";
    if (!body.offerId) {
      res.status(400).json({ error: "offerId is required" });
      return;
    }
    const claim = await getStore().createClaim(userId, body.offerId);
    if (!claim) {
      res.status(404).json({ error: "offer_not_found" });
      return;
    }
    res.status(201).json(claim);
  } catch (err) {
    if (err instanceof OfferUnavailableError) {
      res.status(409).json({ error: "offer_unavailable" });
      return;
    }
    if (err instanceof DbNotReadyError) {
      res.status(503).json({ error: "db_not_ready" });
      return;
    }
    next(err);
  }
});

// PATCH /api/claims/:id { status: 'arrived' | 'posted' | 'redeemed' }
// → updated claim. Transitions only move forward; 'redeemed' requires the
// claim to be 'approved' first (invalid moves → 409 invalid_transition).
claimsRouter.patch("/:id", async (req, res, next) => {
  try {
    const { status } = (req.body ?? {}) as { status?: string };
    if (status !== "arrived" && status !== "posted" && status !== "redeemed") {
      res
        .status(400)
        .json({ error: "status must be 'arrived', 'posted' or 'redeemed'" });
      return;
    }
    const claim = await getStore().updateClaimStatus(req.params.id, status);
    if (!claim) {
      res.status(404).json({ error: "claim_not_found" });
      return;
    }
    res.json(claim);
  } catch (err) {
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
});
