# CLAUDE.md

Guidance for Claude Code (and humans) working in this repo.

## What this is

**Strolling** is a guided micro-shoot product: *walk in, talk for ~20 minutes, walk out
with a published vertical mini-doc.* A warm German film director persona ("der Regisseur")
directs the creator through five shots, interviews them, then the pipeline renders and
publishes the film.

This is a **monorepo**:

- **backend API** at the repository root (`src/`, `package.json`, …) — the focus of this file.
- **`frontend/`** — the Flutter (Dart) client, with its own tooling and `frontend/README.md`.

The guidance below is for the **backend**. Don't add UI to the backend (`src/`) — it belongs
in `frontend/`. The frontend also has a Figma design as its visual reference.

## Core principle: tracer bullet

The whole API is **mocked and runs with zero credentials** (`MOCK=1`, the default). The
request/response **shapes are the real contract** (`src/lib/types.ts`); only the
implementations are fake. Each future commit swaps exactly one mock for one real
integration. This keeps the backend runnable and the frontend unblocked at every step.

- Never break the response shape of an endpoint — the frontend codes against it.
- Comment tags to grep for: **`⚠️ MOCK`** = fake data/behavior to replace; **`⚠️ FALLBACK`**
  = a no-key degraded path; **`TODO(COMMIT-n)`** = what/how to swap in the real thing.
- No external network calls while `MOCK` is on. The API must always boot with no `.env`.

## Status: what's real vs mocked (right now)

| Piece | State | To make real / where |
| ----- | ----- | -------------------- |
| **Render — image-to-video** | ✅ REAL (fal) | needs `FAL_KEY` + `MOCK=0`; `src/lib/fal.ts` |
| **Render — storage upload** | ✅ REAL (fal) | `uploadToStorage` in `src/lib/fal.ts` |
| **Voiceover — script cleaning** | ✅ REAL (fal LLM) | `src/lib/scriptCleaner.ts` (`FAL_LLM_MODEL`) |
| **Voiceover — TTS** | ✅ REAL (ElevenLabs) | `src/lib/elevenlabs.ts` (`ELEVENLABS_API_KEY`) |
| **Render inputs (shots)** | ⚠️ MOCK when absent | send real `captures`+`reviews`; `src/lib/mockAssets.ts` |
| `POST /api/render` (MOCK=1) | ⚠️ MOCK fast-path | returns `/mock/sample.mp4`; use `?force=1`/`MOCK=0` |
| `POST /api/tasks` | ⚠️ MOCK | Claude — `src/routes/tasks.ts` TODO(COMMIT-3) |
| `POST /api/media/upload` | ⚠️ MOCK | fal `uploadToStorage` — `src/routes/media.ts` TODO(COMMIT-3) |
| `POST /api/publish` | ⚠️ MOCK | n8n webhook — `src/routes/publish.ts` TODO(COMMIT-5) |
| No-key render path | ⚠️ FALLBACK | local ffmpeg (Ken Burns + `say`) when keys missing |

## Commands

```bash
npm install
npm run dev         # tsx watch on src/index.ts (http://localhost:3000)
npm run typecheck   # tsc --noEmit — the CI gate; keep it clean
npm run build       # tsc → dist/
npm start           # node dist/index.js
```

There is no test runner yet; verify changes by hitting the endpoints with `curl`
(examples in README.md) and by keeping `npm run typecheck` green.

## Architecture

- **Express + TypeScript (CommonJS)**. Entry is `src/index.ts` → `createApp()` builds the
  app (importable without listening); it only calls `listen()` when run directly.
- **One router per resource** in `src/routes/` (`tasks`, `render`, `publish`, `media`),
  mounted under `/api/*`. Each handler: read body → if `config.mock` return typed mock →
  else the real integration (currently `501 not_implemented` with a `TODO(COMMIT-n)`).
- **Config** is centralized in `src/config.ts` (the `MOCK` flag + all env keys). Read env
  only there; import `config` elsewhere.
- **Contract** lives in `src/lib/types.ts`. `seed.ts` (business + fallback shots) and
  `director.ts` (`DIRECTOR_SYSTEM_PROMPT`) are shared, version-controlled data.
- **Errors** funnel through `src/middleware/errorHandler.ts` (mounted last). Multer upload
  errors become `400`; everything else `500`.
- Handlers return `void`: call `res.json(...)` / `res.status(...).json(...)` then `return;`
  (don't `return res.json(...)` — it fights the Express 4 `RequestHandler` type).

## Endpoints → future integrations

| Route                    | Now (mock)                       | Real in  | Becomes                                            |
| ------------------------ | -------------------------------- | -------- | -------------------------------------------------- |
| `POST /api/tasks`        | `FALLBACK_TASKS` after 800ms     | COMMIT-3 | Anthropic generates the shot list from the business |
| `POST /api/media/upload` | mock storage URL                 | COMMIT-3 | `fal.storage.upload` → durable URL                 |
| `POST /api/render`       | see **Render pipeline** below    | COMMIT-4 ✅ | fal image-to-video + ffmpeg compose + narration    |
| `POST /api/publish`      | canned caption/hashtags + mock URL | COMMIT-5 | n8n webhook → YouTube Short                         |

The Regisseur voice agent (ElevenLabs) is **COMMIT-2** and lives on the frontend
(conversational WebSocket); the backend only holds the shared `DIRECTOR_SYSTEM_PROMPT`.

## Render pipeline (the post-creation workflow) — `src/services/renderPipeline.ts`

Turns the creator's **shots** — each a photo/clip plus its own **script part** — into a
finished vertical video where every part's voiceover plays over its own shot:

```
shot i:  photo  → fal image-to-video ┐  clip fit to |audio_i|
         clip   → normalized         ├──────────────────────► concat clips
         part_i → LLM clean → ElevenLabs voice → audio_i ────► concat audio → mux → upload
```

- **Shots (the key model):** the script arrives in PARTS, one per photo. The route pairs each
  `reviews[]` entry to its `captures[]` entry by **`taskId`** into a `Shot { media, script }`.
  For each shot the clip is rendered to **exactly** the length of that shot's narration
  (`renderClipToDuration` — trim if longer, freeze-frame if shorter), so shot 1's voiceover
  starts and ends with shot 1, then shot 2, and so on. Concatenating clips and audio parts
  (both in shot order, equal per-shot lengths) keeps them locked in sync.
- **Inputs (real vs mock):** **real creator data always wins;** with no `captures`, the mock
  shots in `lib/mockAssets.ts` (`MOCK_SHOTS`) stand in. Nothing here changes when the
  capture/interview parts land — they just start sending `captures` + `reviews`.
- **fal vs local:** if `FAL_KEY` is set, photos go through `fal.subscribe(FAL_I2V_MODEL)` and
  the result uploads to fal storage. With no key it degrades to a **local ffmpeg** render
  (Ken Burns stills + macOS `say` narration), served from `public/renders/`. `lib/fal.ts`
  isolates fal calls; `lib/ffmpeg.ts` the media plumbing.
- **Voiceover (raw part → nice narration):** per shot, `lib/scriptCleaner.ts` cleans the raw
  part via a fal-hosted LLM (`FAL_LLM_MODEL`, `CLEAN_SCRIPT=0` to skip), then
  `lib/elevenlabs.ts` speaks it (`ELEVENLABS_VOICE_ID` / `ELEVENLABS_MODEL`). ElevenLabs is
  voice-only — the *cleaning* is the LLM step, not ElevenLabs.
- **Narration precedence (per shot):** empty part → silent beat; else
  **ElevenLabs** (clean → TTS) → fal TTS (`FAL_TTS_MODEL`) → macOS `say` → silent.
  A whole-video `voiceoverUrl` in the body bypasses per-shot TTS (even pacing instead).
- **Ordering:** within a shot the fal video job and the narration run **concurrently**
  (`Promise.all`); the clip is fit once the audio length is known. Shots run concurrently too.
  A ~0.35s pause is appended to each part so shots don't run into each other.
- **Run behaviour:** `MOCK=1` (default) returns the pre-baked `/mock/sample.mp4` instantly;
  `?force=1` runs the real pipeline once; `MOCK=0` always runs it. Response headers
  `x-render-engine` (`fal` | `ffmpeg-local`), `x-render-inputs` (`creator` | `mock`),
  `x-render-shots`, and `x-voiceover-engine` (e.g. `elevenlabs (clean:fal-llm)`) report
  what happened. The server logs each shot's duration + cleaned part.

To go fully real: `FAL_KEY=… ELEVENLABS_API_KEY=… MOCK=0 npm run dev`. The fal response-shape
extraction in `lib/fal.ts` is defensive — adjust it to the exact model you pick.

## Environment

All optional while mocked. See `.env.example`. Keys: `PORT`, `MOCK`, `ANTHROPIC_API_KEY`,
`FAL_KEY`, `FAL_I2V_MODEL`, `FAL_I2V_DURATION`, `FAL_TTS_MODEL`, `FAL_LLM_MODEL`,
`CLEAN_SCRIPT`, `ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID`, `ELEVENLABS_MODEL`,
`ELEVENLABS_AGENT_ID`, `PUBLIC_BASE_URL`, `N8N_WEBHOOK_URL`. `.env` is gitignored — never
commit real keys.

Runtime note: the render pipeline shells out to **ffmpeg/ffprobe** (and macOS `say` for the
dev narration fallback) — they must be on `PATH`.

## Commit roadmap

- **1** ✅ backend skeleton, all routes mocked
- **2** the Regisseur agent live (frontend WS; backend shares the prompt)
- **3** fal storage for uploads + Claude-generated tasks
- **4** ✅ render pipeline: fal image-to-video + ffmpeg compose + narration (local fallback)
- **5** n8n publish → YouTube Short
- **6** venue hardening + polish

## Frontend (`frontend/`)

Flutter (Dart) client, rebuilt to match the **Strolling** Figma Make design
(map → pick stops → themed script templates → per-stop capture → post → perks).
It is currently **fully mocked** (runs with zero backend). Wiring it to this backend
is future work — note the backend contract below still reflects the earlier Fernweh
mini-doc concept and needs realigning (per-stop publish + script generation instead
of one rendered film). Build/tooling notes live in `frontend/README.md`. It uses
relative imports, Riverpod + go_router, and one `ThemeData`. Platform folders are
git-ignored and regenerated with `flutter create .` — see that README.

## Conventions

- Keep the diff small and the mock branch alive when adding a real integration.
- Match the existing style: one router per resource, typed request/response via
  `src/lib/types.ts`, `config` for anything environmental.
- Don't add a database or auth unless a task explicitly calls for it. Keep backend and
  frontend contracts in sync (`src/lib/types.ts` ↔ `frontend/lib/core/models.dart`).
