import { Router } from "express";
import { DbNotReadyError, getStore } from "../lib/store";

export const offersRouter = Router();

// GET /api/offers?followers=N → active offers, each joined with the business
// pin ({ id, name, category, lat, lng }). With ?followers=N only offers whose
// minFollowers <= N are returned.
offersRouter.get("/", async (req, res, next) => {
  try {
    const raw = req.query.followers;
    const followers =
      typeof raw === "string" && raw !== "" ? Number(raw) : undefined;
    if (followers !== undefined && !Number.isFinite(followers)) {
      res.status(400).json({ error: "followers must be a number" });
      return;
    }
    const offers = await getStore().listOffers(followers);
    res.json(offers);
  } catch (err) {
    if (err instanceof DbNotReadyError) {
      res.status(503).json({ error: "db_not_ready" });
      return;
    }
    next(err);
  }
});
