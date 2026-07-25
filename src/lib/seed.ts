import { Business, StrollBusiness, Task } from "./types";

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

// ---------------------------------------------------------------------------
// Strolling seed — the Stuttgart businesses on the map. Perk stops carry a
// deliverable; roam-only stops have none. Mirrors frontend/lib/core/seed.dart.
// ---------------------------------------------------------------------------

export const STROLL_BUSINESSES: StrollBusiness[] = [
  {
    id: "brot-roesterei",
    name: "Brot & Rösterei",
    category: "cafe",
    description:
      "Specialty coffee and sourdough bakery in the Bohnenviertel. Open from 7am.",
    walkMinutes: 4,
    rating: 4.8,
    lat: 48.7737,
    lng: 9.1862,
    perkTitle: "2 free coffees",
    perkValue: 7,
    deliverable: "1 photo + 1 story post",
    narration:
      "A bakery corner in the Bohnenviertel that fills with regulars before the rest of the city wakes up.",
  },
  {
    id: "alte-kanzlei",
    name: "Alte Kanzlei",
    category: "food",
    description:
      "Swabian restaurant on Schillerplatz — Maultaschen, Spätzle, terrace facing the Old Castle.",
    walkMinutes: 7,
    rating: 4.6,
    lat: 48.7772,
    lng: 9.1794,
    perkTitle: "Free lunch special",
    perkValue: 18,
    deliverable: "1 reel + tag @altekanzlei",
    narration:
      "Schillerplatz has been the city's front room for four centuries. The kitchen here cooks the classics straight.",
  },
  {
    id: "palmengarten",
    name: "Palmengarten Kiosk",
    category: "culture",
    description:
      "Greenhouse café at the edge of Rosensteinpark — plants, records, flat whites.",
    walkMinutes: 9,
    rating: 4.5,
    lat: 48.8009,
    lng: 9.2028,
    perkTitle: "Free entry + latte",
    perkValue: 6,
    deliverable: "1 photo",
    narration:
      "A glasshouse from the Kaiser era, still full of palms. The café came later.",
  },
  {
    id: "markthalle",
    name: "Markthalle Stuttgart",
    category: "market",
    description:
      "Art-nouveau market hall from 1914 — about 40 stalls of produce, spices and delicatessen.",
    walkMinutes: 6,
    rating: 4.7,
    lat: 48.7756,
    lng: 9.1822,
    perkTitle: "Tasting basket",
    perkValue: 15,
    deliverable: "1 photo + 1 story post",
    narration:
      "The market hall has run daily since 1914. Forty stalls under one art-nouveau roof.",
  },
  {
    id: "biergarten-schlossgarten",
    name: "Biergarten im Schlossgarten",
    category: "drinks",
    description:
      "Beer garden in the palace gardens — 1,200 seats under chestnut trees, local Pils, pretzels.",
    walkMinutes: 8,
    rating: 4.4,
    lat: 48.7841,
    lng: 9.1856,
    perkTitle: "2 craft beers",
    perkValue: 14,
    deliverable: "1 reel",
    narration:
      "End of the route: 1,200 seats in the Schlossgarten shade. Order at the counter.",
  },
  {
    id: "stadtbibliothek",
    name: "Stadtbibliothek",
    category: "culture",
    description:
      "The white cube city library by Eun Young Yi. The upper atrium is one of Germany's most photographed rooms.",
    walkMinutes: 11,
    rating: 4.7,
    lat: 48.7908,
    lng: 9.1811,
    narration:
      "Nine storeys of white geometry. The atrium light changes by the hour.",
  },
  {
    id: "feuersee",
    name: "Feuersee & Johanneskirche",
    category: "culture",
    description:
      "Neo-gothic church standing in a small lake; the spire was lost in the war and never rebuilt.",
    walkMinutes: 13,
    rating: 4.6,
    lat: 48.7735,
    lng: 9.1655,
    narration:
      "The church kept its broken spire as a war memorial. Best light in the evening.",
  },
  {
    id: "weissenburgpark",
    name: "Weißenburgpark Teehaus",
    category: "cafe",
    description:
      "Marble tea house on the hillside with a wide view over the city bowl.",
    walkMinutes: 16,
    rating: 4.8,
    lat: 48.7647,
    lng: 9.1868,
    narration:
      "The climb pays off at the top — the whole city bowl in one view.",
  },
];
