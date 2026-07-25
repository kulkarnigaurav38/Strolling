import { Router } from "express";
import { config } from "../config";
import { delay } from "../lib/mock";
import { generateScript, SCRIPT_TEMPLATES } from "../lib/scripts";
import type { GenerateScriptRequest, GenerateScriptResponse } from "../lib/types";

export const scriptsRouter = Router();

// GET /api/scripts/templates → ScriptTemplateInfo[]  (the four styles)
scriptsRouter.get("/templates", (_req, res) => {
  res.json(SCRIPT_TEMPLATES);
});

// POST /api/scripts { stopIds, templateId } → { templateId, steps }
// The per-stop shooting script for the influencer's picks. Perk deliverables
// become required capture actions; every scene ends in the actions to open.
scriptsRouter.post("/", async (req, res) => {
  const { stopIds, templateId } = (req.body ?? {}) as Partial<GenerateScriptRequest>;

  if (!Array.isArray(stopIds) || stopIds.length === 0 || !templateId) {
    res.status(400).json({ error: "bad_request", expected: "{ stopIds: string[], templateId: string }" });
    return;
  }

  if (config.mock) {
    await delay(600);
    const body: GenerateScriptResponse = {
      templateId,
      steps: generateScript(stopIds, templateId),
    };
    res.json(body);
    return;
  }

  // TODO(COMMIT-3): call Anthropic with SCRIPT_DIRECTOR_PROMPT + the picked
  // businesses to write bespoke scenes, validate against ScriptStep[], and
  // return them. The deterministic generator above stays the mock branch.
  res.status(501).json({ error: "not_implemented", route: "scripts" });
});
