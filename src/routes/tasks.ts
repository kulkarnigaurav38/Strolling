import { Router } from "express";
import { config } from "../config";
import { delay } from "../lib/mock";
import { FALLBACK_TASKS } from "../lib/seed";
import type { GenerateTasksRequest } from "../lib/types";

export const tasksRouter = Router();

// POST /api/tasks { business } → Task[]  (the 5-shot list for this venue)
tasksRouter.post("/", async (req, res) => {
  const { business } = (req.body ?? {}) as Partial<GenerateTasksRequest>;

  if (config.mock) {
    await delay(800);
    res.json(FALLBACK_TASKS);
    return;
  }

  // TODO(COMMIT-3): call Anthropic (DIRECTOR context + business seed) to generate
  // the shot list, validate against the Task[] contract, and return it.
  void business;
  res.status(501).json({ error: "not_implemented", route: "tasks" });
});
