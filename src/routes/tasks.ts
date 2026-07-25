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
    await delay(800); // pretend the model took a beat
    // ⚠️ MOCK: hard-coded shot list from lib/seed.ts (ignores `business`).
    // TODO(COMMIT-3) REPLACE WITH: Anthropic — Claude generates the shot list from
    // the business seed + DIRECTOR_SYSTEM_PROMPT, validated against the Task[]
    // contract. Just fill in the branch below and flip MOCK=0.
    res.json(FALLBACK_TASKS);
    return;
  }

  // TODO(COMMIT-3): real task generation goes here (see above).
  void business;
  res.status(501).json({ error: "not_implemented", route: "tasks" });
});
