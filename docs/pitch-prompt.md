# Jury pitch-deck prompt — Cursor Hackathon Stuttgart

Paste everything below the line into Claude (design/artifact mode).
Every fact is verified as of 2026-07-25 — the model must not invent beyond them.

---

Design a **jury pitch deck** for our hackathon project. Output a single
self-contained HTML presentation: **exactly 5 slides**, 16:9, arrow-key/scroll
navigation, each slide readable from the back of a room. Include short
**speaker notes** under each slide (collapsible or a presenter view).

Five slides is a hard limit — no appendix, no bonus slides. Each slide carries
one idea; push supporting detail into the speaker notes rather than onto the
slide.

## Brand — match the product exactly
- Typeface: **SF Pro** (fall back to -apple-system / system-ui). Tight letter-spacing on headings.
- Palette: cream `#F8F5F0` (page) · ink navy `#241E38` (headings, dark panels) ·
  coral `#F1512D` (primary/CTA) · amber `#F6A50B` (perk value) · green `#23B26D`
  (confirmed/approved) · indigo `#6C63E8` · muted `#8D8798` · white cards,
  22px radius, soft shadows.
- Hero gradient (use once, on the title slide): top-to-bottom `#F9A13B → #F05423 → #E23A2E`.
- **No emoji.** Use clean line icons (SF-Symbols-like). No stock-photo collages,
  no clip art, no gradient-on-everything. Generous whitespace, one idea per slide.
- Feel: a warm travel-guide product, not a corporate SaaS deck.

## We are scored on this rubric — weight the deck accordingly
| Weight | Category | What they look for |
| --- | --- | --- |
| 30% | Real Problem Solving | Does this help content creators in a real way? |
| 30% | Technical Innovation & AI | Creative use of AI? Strong sponsor tool integration? Novel approach? |
| 25% | Execution & Working Demo | Does it actually work? How complete? Stable during the demo? |
| 15% | Presentation | Clear problem story? Engaging video? Well-structured pitch? |

With only 5 slides: slide 1 carries the problem (30%), slide 2 the novelty (30%),
slide 3 the AI stack (part of that 30%), slide 4 the proof it runs (25%), slide 5
the demo hook + honest edges. Presentation (15%) is earned by the craft of the
deck itself. Every claim on a slide must be something we can show live — no
roadmap dressed as achievement.

## Slide plan (exactly 5 — follow it, but improve the wording)

**1 — The problem, with the product named at the end.** Sunset gradient band or
panel carrying the wordmark **Strolling** and *"Walk the city. Get rewarded."*,
but the slide's substance is the problem:
- A local café cannot afford an influencer agency. There is nothing between a
  €5k campaign and doing nothing.
- The creator's blocker is **not** distribution — it's the blank page: standing
  outside that café with no idea what to film or say.
- Land it in one sentence: *the demand and the supply walk past each other every day.*
- Then one line of what we built: a map-first marketplace where creators pick
  stops, get a written script, publish, and get paid in perks — and businesses
  pay only when a post exists (perks run €6–€25 per stop).
Small credit line: Cursor Hackathon Stuttgart.

**2 — The novel bit: scripts that compile the contract.** This is the
differentiator, give it the most design care.
- Four themed directors: **The Symmetrist** (Wes Anderson) · **One-Point Stare**
  (Kubrick) · **Der Doku** (documentary) · **Whatever's Viral** (trend format).
- Each stop becomes a scene: themed title, staging direction written for that
  business's category, a line to say verbatim, the perk callout.
- The punchline to feature visually: **the perk deliverable compiles into required
  capture actions.** "1 photo + 1 story post" → a required photo AND video; the
  Post button stays locked until both exist. The business's contract is enforced
  by the app, not by trust.
- Show one real generated scene as a card, e.g.:
  `SCENE 1 · THE CAFÉ, AS IT IS` — *"Handheld: hands at work, steam, the first
  sip. Then record yourself, one take."* — deliver 1 photo + 1 story post →
  2 free coffees (€7).

**3 — The AI + sponsor stack.** A pipeline diagram, left to right, one line each:
- **Claude** writes the per-stop scripts (deterministic engine as offline fallback)
- **fal** image-to-video turns stills into clips, and hosts the media
- a **fal-hosted LLM** cleans each raw script part
- **ElevenLabs** speaks it — and each shot's clip is rendered to exactly its own
  narration length, so voiceover and picture stay locked per shot
- **ffmpeg** composes the vertical cut · **n8n** publishes
- **Supabase** Postgres + row-level security + storage + job queue
- Built end-to-end in **Cursor**; map is OpenStreetMap via flutter_map
One closing line: every integration sits behind a single mock flag, so the same
code path runs with zero credentials or fully live.

**4 — It actually runs (proof, with real numbers).** Design as a verification
panel, monospace numbers, green ticks:
- Flutter app (iOS/Android/web) on a real OSM map at real Stuttgart coordinates
- Express + TypeScript API: offers, claims, posts, perk wallet, business portal
- **Real Supabase Postgres with RLS applied** — verified live: claim → publish →
  business approves → creator redeems, all persisted; offer slots **60 → 59**;
  dashboard **€6 cost / 17,784 reach**; an illegal backwards status change
  correctly rejected (**HTTP 409**)
- React business dashboard on the same API
- **Cannot die on stage:** backend unreachable → the app writes the script
  on-device; no fal/ElevenLabs keys → local ffmpeg + system TTS; DB not ready →
  seeded fallback. Both paths rehearsed.
- One quiet line of rigour: an adversarial multi-agent review found 20 issues,
  18 confirmed and fixed (including an RLS self-approval hole and
  client-settable reach metrics).

**5 — The demo hook + honest edges (one slide, split).** Dominant left two-thirds,
full-bleed and minimal: **this venue is stop #1 on the map.** INFOMOTION,
Friedrichstraße 6 — offer: *Free drink at the bar, €6, deliver 1 photo + 1 story
post.* Six beats as a numbered strip: open the map on this building → add the
venue + Biergarten im Schlossgarten (€14, 7-min walk) → pick "Whatever's Viral" →
shoot **the jury** as the required photo → publish → on the projector the business
dashboard shows the post with reach, click **Approve**, the phone's perk flips to
approved with a QR that is a real free drink at the bar behind you.
Closing line, large: *every business, coordinate and euro you just saw is real.*

Right third, small and matter-of-fact — a short "what's not real yet" column
(this earns trust with a technical jury rather than costing us):
- no real auth yet — the demo user id is explicit; Supabase Auth is next
- follower counts and post reach are simulated; the Instagram/TikTok reads are seams
- Google Business Profile verification is designed and stubbed (API access takes days)
- auto-publishing depends on platform API access; today we hand off to the share sheet

## Writing style
Confident, concrete, zero buzzwords. Short lines a nervous person can read aloud.
Name sponsor tools where they actually do work — never as a logo salad. Open with
the problem in human words, not with the product name.
