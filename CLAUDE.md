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
- Every mock that stands in for real work is marked `// TODO(COMMIT-n): <real thing>`.
  When you make one real, guard it behind `config.mock` and keep the mock branch working.
- No external network calls while `MOCK` is on. The API must always boot with no `.env`.

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

Turns the creator's **pictures + voiceover script** into a finished vertical video:

```
photo → fal image-to-video (animated clip)        ┐
clip  → normalized as-is                          ├─ concat → mux narration → upload → { videoUrl }
script → narration (fal TTS / macOS say / none)   ┘
```

- **Inputs (real vs mock):** the route (`routes/render.ts`) builds the input from the
  request — `captures` → media, `reviews[].transcript` → script. **Real creator data always
  wins;** when a field is missing it falls back to `lib/mockAssets.ts` (`MOCK_MEDIA`,
  `MOCK_SCRIPT`). Nothing here changes when the capture/interview parts land — they just
  start sending `captures` + `reviews`.
- **fal vs local:** if `FAL_KEY` is set, photos go through `fal.subscribe(FAL_I2V_MODEL)` and
  the result uploads to fal storage. With no key it degrades to a **local ffmpeg** render
  (Ken Burns stills + macOS `say` narration), served from `public/renders/` — so it runs and
  is testable with zero keys. `lib/fal.ts` isolates all fal calls; `lib/ffmpeg.ts` the media
  plumbing.
- **Narration precedence:** `voiceoverUrl` in the body (e.g. from the ElevenLabs part) →
  fal TTS (`FAL_TTS_MODEL`, opt-in) → macOS `say` (dev) → silent.
- **Run behaviour:** `MOCK=1` (default) returns the pre-baked `/mock/sample.mp4` instantly;
  `?force=1` runs the real pipeline once; `MOCK=0` always runs it. Response headers
  `x-render-engine` (`fal` | `ffmpeg-local`) and `x-render-inputs` (`creator` | `mock`) say
  what happened.

To go fully real: `FAL_KEY=… MOCK=0 npm run dev`, optionally set `FAL_I2V_MODEL` /
`FAL_TTS_MODEL`. The fal response-shape extraction in `lib/fal.ts` is defensive — adjust it
to the exact model you pick.

## Environment

All optional while mocked. See `.env.example`. Keys: `PORT`, `MOCK`, `ANTHROPIC_API_KEY`,
`FAL_KEY`, `FAL_I2V_MODEL`, `FAL_TTS_MODEL`, `PUBLIC_BASE_URL`, `ELEVENLABS_AGENT_ID`,
`ELEVENLABS_API_KEY`, `N8N_WEBHOOK_URL`. `.env` is gitignored — never commit real keys.

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

Flutter (Dart) tracer-bullet client that realizes the same product. It is currently
**fully mocked** (runs with zero backend) — its `ApiClient` returns local mock data. Wiring
it to this backend (set `FERNWEH_MOCK=false` and point the API base URL at the server) is
future work. Build/tooling notes live in `frontend/README.md`. It uses relative imports,
Riverpod + go_router, and one `ThemeData`. Platform folders are git-ignored and regenerated
with `flutter create .` — see that README.

## Conventions

- Keep the diff small and the mock branch alive when adding a real integration.
- Match the existing style: one router per resource, typed request/response via
  `src/lib/types.ts`, `config` for anything environmental.
- Don't add a database or auth unless a task explicitly calls for it. Keep backend and
  frontend contracts in sync (`src/lib/types.ts` ↔ `frontend/lib/core/models.dart`).
