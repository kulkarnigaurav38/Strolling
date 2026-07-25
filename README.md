# Strolling 🚶‍♂️🎬

**Walk the city, get rewarded, and turn your raw clips into a finished reel.**

Strolling is a two-sided app: **creators** get paid in real perks (a free coffee, a meal, a drink) for making content at **local businesses**, and those businesses get authentic, proof-of-visit content they know is real. The app guides the creator stop-by-stop — telling them what to shoot and say — then its engine turns the raw photos, video, and voice into a polished, postable vertical video automatically.

---

## How it works

1. **Discover** — a map of nearby local businesses, each with a perk and a deliverable ("1 photo + 1 story").
2. **Get a script** — pick a style (Wes / Kubrick / Doku / Viral); the app generates a per-stop shooting script telling you exactly what to capture and say.
3. **Capture** — shoot the photos/clips and record your voice at each stop.
4. **Render** — the backend engine turns that raw media + speech into a finished vertical reel.
5. **Claim** — post the reel and redeem your perk.

## The engine (what makes the video)

Raw media + words → a finished reel:

- **Photos** → animated with **fal.ai** image-to-video
- **Video clips** → normalized and cut in
- **Script** → cleaned by an LLM, voiced by **ElevenLabs** (or the creator's own recorded audio is used as-is)
- Everything is composed with **ffmpeg**, each shot synced to its narration, and the finished `.mp4` is uploaded to **Supabase Storage**

The frontend just inserts a job (media + script) into Supabase; a background worker renders it and writes back the video URL. A direct `POST /api/render` (media in → video URL out) is also supported.

## Stack

| Layer | Tech |
| ----- | ---- |
| **Frontend** | Flutter (map, script templates, capture, reel) — `frontend/` |
| **Backend** | Node.js + TypeScript (Express) — repo root |
| **AI video** | fal.ai (image-to-video, storage, LLM cleanup) |
| **Voice** | ElevenLabs TTS |
| **Data + storage + jobs** | Supabase (Postgres + Storage + Realtime) |
| **Compose** | ffmpeg |

## Repo layout

```
/                 backend API (src/, routes, services/renderPipeline.ts)
frontend/         Flutter app
supabase/         schema + migrations
```

## Run the backend

```bash
npm install
cp .env.example .env        # add FAL_KEY, ELEVENLABS_API_KEY, SUPABASE_URL, SUPABASE_SECRET_KEY
npm run dev                 # http://localhost:3000
```

Built at the Cursor Hackathon, Stuttgart.
