import { Business, Task } from "./types";

// Default business + shot list. In COMMIT-3 the tasks become Claude-generated
// from the business seed; this stays the fallback.

export const BUSINESS: Business = {
  slug: "cursor-stuttgart",
  name: "Cursor Hackathon Stuttgart",
  venue: "Infomotion · Friedrichstr. 6, 70174 Stuttgart · 4th floor",
  incentive: "🍹 Free drink at the bar — show your finished video",
  vibe: "AI hackathon, 60 builders, laptops everywhere, sponsor stickers, city view",
  style: "energetic mini-doc, warm colors, quick cuts, authentic not polished",
};

export const FALLBACK_TASKS: Task[] = [
  {
    id: "t1",
    order: 1,
    type: "photo",
    title: "📸 The entrance",
    instruction: "Sign or door at Friedrichstr. 6, low angle, logo sharp.",
    suggestedLine: "So this is where 60 people are building for one day…",
  },
  {
    id: "t2",
    order: 2,
    type: "clip",
    title: "🎬 The floor (2–3s)",
    instruction: "Slow pan across the hacking floor — laptops, teams, energy.",
    suggestedLine: "The energy in here is honestly unreal.",
  },
  {
    id: "t3",
    order: 3,
    type: "photo",
    title: "📸 Mid-build moment",
    instruction: "Over someone's shoulder: Cursor open, code flowing.",
    suggestedLine: "Everyone here is shipping something today.",
  },
  {
    id: "t4",
    order: 4,
    type: "clip",
    title: "🎬 The incentive (2–3s)",
    instruction: "The drinks / coffee moment — the reward in frame.",
    suggestedLine: "And yes — this video literally pays for my drink.",
  },
  {
    id: "t5",
    order: 5,
    type: "photo",
    title: "📸 The closer",
    instruction: "4th-floor window view or a team selfie mid-pitch.",
    suggestedLine: "If you're wondering whether to come next time — come.",
  },
];
