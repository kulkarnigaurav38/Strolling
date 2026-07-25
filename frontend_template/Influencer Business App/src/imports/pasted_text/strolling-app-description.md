# Strolling — UI/UX Description

## 1. Concept in one paragraph

**Strolling** is a mobile, map-first app that connects **creators** (influencers, tourists, locals with a phone) with **local businesses**. The creator opens a map, sees nearby businesses that registered on the platform, picks a few, and the app generates an AI-written walking route + narration script. At each stop the creator completes a step by taking a photo, a video, or a voice note. When the route is finished, the app auto-assembles a post (collage/edit + caption) that the creator publishes to Instagram / Facebook / TikTok — and in exchange gets the perk the business offered (free drinks, food, or money).

Two products in one app: **Creator app** (mobile) and **Business dashboard** (mobile + web).

---

## 2. Creator app

### 2.1 Login / onboarding
- Login options: **Facebook / Instagram** (primary — gives us follower count and reach), **Google** (fallback, no social data attached).
- After login: connect social accounts screen — shows which are linked, which unlock which rewards. TikTok = future.
- Short profile setup: name, photo, city, interests (food / nightlife / culture / outdoors).

### 2.2 Home — Map screen (main screen)
- **Full-screen map**, user location centred.
- **Pins** = registered businesses near the user. Pin style differs for "perk available" vs "just a place".
- **Bottom card ("my cart")** — a small persistent sheet under the map showing: the user's avatar/about-me, and the stops they've picked so far (0–5), with a primary button **"Create my route"**.
- **Mode switch at the top — two choices:**
  - **Explore the city** — all places, no obligations, pure discovery.
  - **Earn perks** — filters the map to businesses with an active offer *that this creator is eligible for*.
- Filter chips: category, distance, perk type.

### 2.3 Business preview (bottom sheet)
Tapping a pin opens a short sheet — deliberately brief, "the bit":
- Cover photo, business name, category, distance / walk time.
- 2–3 lines of description.
- Perk badge (e.g. "3 free beers", "€25", "free lunch").
- What's required: e.g. 1 photo + 1 story post.
- Buttons: **Add to route** and **See more**.

### 2.4 Route generation
After 3–4 stops are picked, tapping "Create my route" opens the **Journey view**:
- Timeline / list of stops in walking order, with a route line drawn on a mini-map.
- Total distance and estimated time.
- Starting point is the user's real location, described in words: *"You're at Stuttgart Hbf. Step out of the main exit and turn left…"*
- Each stop shows: photo, name, perk, and its narration snippet.
- **Script scope is the user's choice:** one script per business, or one continuous script that ties all the stops into a single city story. Toggle at the top of this screen.
- The script is AI-generated and includes local colour — odd bits of the town's history, what to look at on the way.
- Button: **Start journey**.

### 2.5 Step screen (the core loop)
One screen per step, swipeable, progress bar at the top ("Step 2 of 7"):
- **Narration text** — what to do, what to say, what's interesting here.
- **Photo/video button** — opens the camera directly, capture is stored inside the app (not just the camera roll).
- **Voice button** — record a voice note.
- **Write instead** — type the text and the app does text-to-speech in the creator's own voice style. Speech ↔ text works both directions.
- A step is marked **complete** when a photo, video, or voice note exists for it.
- Small "skip" / "do later" option.
- Bottom: **Next step**.

### 2.6 Finish & post builder
When all steps are done:
- Celebration state + **"Create my post"**.
- The app assembles a **collage / short edit** from the captured media, with the AI caption and hashtags pre-filled.
- Two output options: **one post per business** or **one post for the whole route** (a mini city guide).
- Editable: reorder media, swap cover, edit caption.
- **Share sheet:** Instagram, Facebook, TikTok. (Auto-posting depends on API access — see open questions.)

### 2.7 Perk redemption
- After posting, the perk moves to a **"My perks"** wallet: QR / code to show at the venue, or payout status if it's money.
- Status chips: pending verification → approved → redeemed.

### 2.8 Profile
- Connected accounts, follower/reach numbers pulled from Instagram.
- History of completed routes and posts.
- Ranking / score based on social performance (open: how public this is).

---

## 3. Business side

### 3.1 Sign-up & verification
- Register with business email or **Google Business Profile** (used to verify the business is legit and to pull address, hours, photos).
- Verification status shown clearly; unverified businesses don't appear on the map.

### 3.2 Offer setup
- Choose perk type: **in-kind** (drinks, food, entry) or **money**.
- Define quantity/value and how many creators per week/month.
- Define what the creator must deliver (e.g. 1 post + 1 story).
- **Eligibility rules:** minimum followers / minimum reach. Typical: no minimum for in-kind perks, a threshold (e.g. 10k followers) for cash. Filtering is fully automatic — only eligible creators ever see the offer, the business never reviews applications manually.

### 3.3 Dashboard
Keep it light — this is not a CRM:
- Active offers and remaining slots.
- Creators currently on route to them / arrived.
- Posts published about them, with reach and engagement (Instagram collaborator metrics).
- Redemption approvals (scan code / confirm).
- Simple totals: creators hosted, posts, total reach, cost.

### 3.4 Optional (later)
- Invite a specific creator directly to a bit.
- Sponsored placement on the map.

---

## 4. Navigation map

```
Strolling — Creator app
  Login → Connect socials → Profile setup
  Tabs: Map | My route | Perks | Profile
    Map → Business sheet → Add to route → Journey view → Step screens → Post builder → Share → Perk wallet

Strolling for Business
  Sign up → Verify (Google Business) → Create offer → Dashboard
    Dashboard: Offers | Creators | Posts & reach | Redemptions
```

---

## 5. Design direction

- Mobile-first, one-hand use. The camera and the map are the two things that must never be more than one tap away.
- Map-centric home; content lives in bottom sheets rather than full pages.
- Big, obvious capture buttons on step screens — the creator is standing outside on a street, in sunlight, probably in a hurry.
- Short text everywhere. The narration script is the only long-form text and should be readable in glances.
- Playful, travel-guide tone rather than corporate. The business dashboard can be plainer and denser.
- The name sets the voice: unhurried, wandering, on foot. Copy should sound like a walk, not a task list — "start strolling" instead of "begin quest", "your stroll" instead of "your route", stops rather than tasks. A route generated by the app can simply be called **a Stroll**. Business-facing product reads as **Strolling for Business**.
- States to design for: empty map (no businesses nearby), no eligible perks yet, offline mid-route, media upload failing, perk sold out.

---

## 6. Open questions

- Instagram/TikTok APIs: can we actually auto-publish, or do we hand off to the native share sheet?
- How much automated video editing do we do vs. leaving it to the creator?
- Is the creator ranking public (leaderboard) or private (just a metric businesses see)?
- Cash perks: who holds the money — platform escrow or business pays after the post goes live?
- How do we confirm a creator physically visited (GPS check-in, staff-scanned code, or both)?