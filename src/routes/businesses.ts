import { Router } from "express";
import { STROLL_BUSINESSES } from "../lib/seed";

export const businessesRouter = Router();

// GET /api/businesses → StrollBusiness[]  (the pins on the map)
// Static seed for now; a later commit reads these from the business portal.
businessesRouter.get("/", (_req, res) => {
  res.json(STROLL_BUSINESSES);
});
