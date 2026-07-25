// The script template engine — server side. A template turns the influencer's
// picks into a per-stop shooting script: themed scene, staging direction, a line
// to deliver, the perk deliverable woven in, and the exact capture actions to
// open (photo / video / voice / text). Required actions come from the perk
// deliverable and gate posting.
//
// This mock generator mirrors frontend/lib/core/script_templates.dart exactly —
// the shapes are the contract. TODO(COMMIT-3): swap the body of generateScript
// for Claude (SCRIPT_DIRECTOR_PROMPT + businesses) while keeping this as the
// mock branch.

import { STROLL_BUSINESSES } from "./seed";
import type {
  BusinessCategory,
  ScriptAction,
  ScriptStep,
  ScriptTemplateInfo,
  StrollBusiness,
} from "./types";

export const SCRIPT_TEMPLATES: ScriptTemplateInfo[] = [
  {
    id: "wes",
    name: "The Symmetrist",
    tagline: "à la Wes Anderson",
    emoji: "🎀",
    color: "#E98FA6",
    vibe: "Centered frames, level horizons, deadpan captions.",
  },
  {
    id: "kubrick",
    name: "One-Point Stare",
    tagline: "à la Kubrick",
    emoji: "🔴",
    color: "#C03A2B",
    vibe: "One-point perspective, slow push-ins, long holds.",
  },
  {
    id: "doku",
    name: "Der Doku",
    tagline: "documentary",
    emoji: "🎙️",
    color: "#B8860B",
    vibe: "Handheld, real sound, first takes. Details over drama.",
  },
  {
    id: "viral",
    name: "Whatever's Viral",
    tagline: "trend format",
    emoji: "⚡",
    color: "#6C63E8",
    vibe: "Hook first, fast cuts, POV captions, loopable endings.",
  },
];

export function businessById(id: string): StrollBusiness | undefined {
  return STROLL_BUSINESSES.find((b) => b.id === id);
}

export function generateScript(
  stopIds: string[],
  templateId: string,
): ScriptStep[] {
  const template = SCRIPT_TEMPLATES.some((t) => t.id === templateId)
    ? templateId
    : "doku";
  const stops = stopIds
    .map(businessById)
    .filter((b): b is StrollBusiness => b !== undefined);
  return stops.map((b, i) => scene(template, i, b));
}

function scene(t: string, index: number, b: StrollBusiness): ScriptStep {
  const perkCallout =
    b.perkTitle != null
      ? `Deliver ${b.deliverable} → ${b.perkTitle} (€${b.perkValue})`
      : null;

  const required = requiredFromDeliverable(t, b);
  const extras = flavor(t).filter(
    (a) => !required.some((r) => r.kind === a.kind),
  );

  return {
    businessId: b.id,
    sceneTitle: `SCENE ${index + 1} · ${sceneName(t, b.category)}`,
    direction: direction(t, b.category),
    line: line(t, b.name),
    perkCallout,
    actions: [...required, ...extras],
  };
}

/** "1 photo + 1 story post" / "1 reel + tag us" → required capture actions. */
function requiredFromDeliverable(t: string, b: StrollBusiness): ScriptAction[] {
  const d = (b.deliverable ?? "").toLowerCase();
  const out: ScriptAction[] = [];
  if (d.includes("photo")) {
    out.push({ kind: "photo", prompt: photoPrompt(t), required: true });
  }
  if (d.includes("reel") || d.includes("story") || d.includes("video")) {
    out.push({ kind: "video", prompt: videoPrompt(t), required: true });
  }
  return out;
}

function flavor(t: string): ScriptAction[] {
  switch (t) {
    case "wes":
      return [
        { kind: "photo", prompt: photoPrompt(t), required: false },
        {
          kind: "text",
          prompt: "One deadpan sentence, no filler.",
          required: false,
        },
      ];
    case "kubrick":
      return [
        { kind: "video", prompt: videoPrompt(t), required: false },
        { kind: "photo", prompt: photoPrompt(t), required: false },
      ];
    case "doku":
      return [
        {
          kind: "voice",
          prompt: "30 seconds, first take: what is this place actually like?",
          required: false,
        },
        { kind: "photo", prompt: photoPrompt(t), required: false },
      ];
    default:
      return [
        { kind: "video", prompt: videoPrompt(t), required: false },
        {
          kind: "text",
          prompt: "POV caption, present tense, one line.",
          required: false,
        },
      ];
  }
}

function sceneName(t: string, c: BusinessCategory): string {
  const noun = {
    cafe: "CAFÉ",
    food: "RESTAURANT",
    drinks: "BIERGARTEN",
    culture: "LANDMARK",
    market: "MARKET HALL",
  }[c];
  switch (t) {
    case "wes":
      return `THE ${noun}, CENTERED`;
    case "kubrick":
      return `THE ${noun}, ONE POINT`;
    case "doku":
      return `THE ${noun}, AS IT IS`;
    default:
      return `THE ${noun}, ON LOOP`;
  }
}

const DIRECTIONS: Record<string, Record<BusinessCategory, string>> = {
  wes: {
    cafe: "Face the counter straight on. Cups in a row, one person centered, horizon level.",
    food: "Top-down on the set table, cutlery parallel. Then one straight-on of the entrance.",
    drinks:
      "Center yourself on the longest bench row. Glass at dead center, hold still.",
    culture:
      "Face the facade straight on and center it. Wait for one person to cross the frame.",
    market: "One stall, front-on. Produce stacked, vendor centered.",
  },
  kubrick: {
    cafe: "Find the longest sightline inside. One-point perspective, slow push-in, no talking.",
    food: "Shoot the arcade columns vanishing to a point. Hold the frame three seconds longer than feels right.",
    drinks:
      "Use the tree rows as a corridor. Walk the center line, camera level, even steps.",
    culture:
      "Center the doorway and push in slowly until the room fills the frame.",
    market:
      "The central aisle at eye level, dead center. Let people pass through the frame.",
  },
  doku: {
    cafe: "Handheld: hands at work, steam, the first sip. Then record yourself, one take.",
    food: "Film plates leaving the kitchen. Then say on tape what this food means here.",
    drinks:
      "One wide of the crowd, one close of a glass. Record the background noise for ten seconds.",
    culture:
      "Ten seconds of ambience before you speak. Then one honest observation.",
    market:
      "Follow one ingredient from stall to stall. Record the vendors answering.",
  },
  viral: {
    cafe: "Hook in the first half second: pour or latte art hitting the table. Whip-pan to your reaction.",
    food: "Food shot first, context later. Jump cuts, trend audio.",
    drinks:
      "POV: glass raised into frame at golden hour. Cut on the clink, loop the ending.",
    culture:
      "Doorway transition: outside/inside on one step. Save the best angle for the beat drop.",
    market:
      "Run the tasting-basket challenge stall to stall, prices as text overlays.",
  },
};

function direction(t: string, c: BusinessCategory): string {
  return (DIRECTIONS[t] ?? DIRECTIONS.doku)[c];
}

function line(t: string, name: string): string {
  switch (t) {
    case "wes":
      return `This is ${name}. It has not moved in some time.`;
    case "kubrick":
      return "Say nothing. Let the frame hold.";
    case "doku":
      return `What surprised me about ${name} is — finish it honestly.`;
    default:
      return `Nobody talks about ${name}. That ends today.`;
  }
}

function photoPrompt(t: string): string {
  switch (t) {
    case "wes":
      return "Facade centered, horizon level.";
    case "kubrick":
      return "One-point perspective still, vanishing point centered.";
    case "doku":
      return "The detail people walk past — hands, signs, wear.";
    default:
      return "The angle that reads at thumbnail size.";
  }
}

function videoPrompt(t: string): string {
  switch (t) {
    case "wes":
      return "4 seconds, locked off. One thing moves.";
    case "kubrick":
      return "Slow push-in, 6 seconds, no cuts.";
    case "doku":
      return "10 seconds handheld, real sound, no filter.";
    default:
      return "Hook, whip-pan, reveal — under 7 seconds, loopable.";
  }
}
