import { config } from "../config";
import { isFalEnabled, runLLM } from "./fal";

// Turns a raw, rambling voiceover transcript into a crisp narration worthy of a
// short vertical video. Uses a fal-hosted LLM when available; otherwise a light
// heuristic so it still runs with no keys.

const SYSTEM_PROMPT = `You are a scriptwriter polishing a raw, rambling voiceover transcript into a crisp,
natural, first-person narration for a short vertical social video (about 15-25 seconds, ~40-70 words).
Keep the speaker's authentic voice and every real fact. Remove filler words (um, uh, like, you know),
false starts, and repetition. Make it flow and land with a little warmth and momentum.
Return ONLY the finished narration text — no quotes, no preamble, no notes.`;

export type CleanedBy = "fal-llm" | "heuristic" | "none";

export interface CleanResult {
  text: string;
  cleanedBy: CleanedBy;
}

export async function cleanScript(raw: string): Promise<CleanResult> {
  const input = raw.trim();
  if (!input) return { text: "", cleanedBy: "none" };
  if (!config.cleanScript) return { text: input, cleanedBy: "none" };

  if (isFalEnabled()) {
    try {
      const out = await runLLM(`Raw transcript:\n"""${input}"""`, {
        system: SYSTEM_PROMPT,
      });
      const text = stripWrappingQuotes(out);
      if (text.length > 0) return { text, cleanedBy: "fal-llm" };
    } catch {
      // fall through to the heuristic
    }
  }
  return { text: heuristicClean(input), cleanedBy: "heuristic" };
}

function stripWrappingQuotes(s: string): string {
  return s.trim().replace(/^["'“”]+|["'“”]+$/g, "").trim();
}

/** Keyless fallback: strip fillers, tidy punctuation/spacing, sentence-case. */
export function heuristicClean(raw: string): string {
  let t = raw.replace(/\s+/g, " ").trim();
  t = t.replace(
    /\b(um+|uh+|erm+|like|you know|i mean|kind of|sort of|basically|literally|actually)\b/gi,
    "",
  );
  t = t
    .replace(/\s+([,.!?])/g, "$1")
    .replace(/([,.!?])\1+/g, "$1")
    .replace(/\s+/g, " ")
    .trim();
  if (t && !/[.!?]$/.test(t)) t += ".";
  return t.length > 0 ? t.charAt(0).toUpperCase() + t.slice(1) : t;
}
