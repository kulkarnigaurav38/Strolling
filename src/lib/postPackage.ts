// Builds the social post package that wraps a finished render.
// Caption / hashtags are deterministic mocks for now — swap for an LLM later.

import type { Business, RenderResult } from "./types";

const DEFAULT_HASHTAGS = [
  "#strolling",
  "#stuttgart",
  "#walkandshoot",
  "#minidoc",
  "#localgems",
];

export function buildPostPackage(opts: {
  videoUrl: string;
  script?: string;
  text?: string;
  business?: Business | { name?: string; vibe?: string; venue?: string };
}): RenderResult {
  const script = (opts.script ?? opts.text ?? "").trim();
  const name =
    opts.business && "name" in opts.business && opts.business.name
      ? String(opts.business.name)
      : "Stuttgart";
  const vibe =
    opts.business && "vibe" in opts.business && opts.business.vibe
      ? String(opts.business.vibe)
      : "";

  const hook = script
    ? script.split(/(?<=[.!?])\s+/)[0]!.slice(0, 140)
    : vibe
      ? `A stroll through ${name} — ${vibe}.`
      : `Walked through ${name} and left with a film about it.`;

  const caption = script
    ? `${hook}${hook.endsWith(".") ? "" : "."} 📍 ${name}\n\n${DEFAULT_HASHTAGS.join(" ")}`
    : `${hook} ${DEFAULT_HASHTAGS.join(" ")}`;

  return {
    videoUrl: opts.videoUrl,
    caption,
    hashtags: [...DEFAULT_HASHTAGS],
    script: script || `A short film from ${name}.`,
  };
}
