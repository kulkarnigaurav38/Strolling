# CLAUDE.md

Guidance for Claude Code (and humans) working in this repo.

## What this is

**Strolling** is a guided micro-shoot product: *walk in, talk for ~20 minutes, walk out
with a published vertical mini-doc.* A warm German film director persona ("der Regisseur")
directs the creator through five shots, interviews them, then the pipeline renders and
publishes the film.

This repo is the **backend API only**. The frontend is built separately from a Figma
design and consumes these endpoints — do **not** add UI here.

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
| `POST /api/render`       | `/mock/sample.mp4` after 3s      | COMMIT-4 | fal image-to-video + ffmpeg compose + narration    |
| `POST /api/publish`      | canned caption/hashtags + mock URL | COMMIT-5 | n8n webhook → YouTube Short                         |

The Regisseur voice agent (ElevenLabs) is **COMMIT-2** and lives on the frontend
(conversational WebSocket); the backend only holds the shared `DIRECTOR_SYSTEM_PROMPT`.

## Environment

All optional while mocked. See `.env.example`. Keys: `PORT`, `MOCK`, `ANTHROPIC_API_KEY`,
`FAL_KEY`, `ELEVENLABS_AGENT_ID`, `ELEVENLABS_API_KEY`, `N8N_WEBHOOK_URL`. `.env` is
gitignored — never commit real keys.

## Commit roadmap

- **1** ✅ backend skeleton, all routes mocked (this commit)
- **2** the Regisseur agent live (frontend WS; backend shares the prompt)
- **3** fal storage for uploads + Claude-generated tasks
- **4** real render (fal i2v + ffmpeg compose, real-voice narration)
- **5** n8n publish → YouTube Short
- **6** venue hardening + polish

## Conventions

- Keep the diff small and the mock branch alive when adding a real integration.
- Match the existing style: one router per resource, typed request/response via
  `src/lib/types.ts`, `config` for anything environmental.
- Don't add a database, auth, or a frontend unless a task explicitly calls for it.
