# Strolling — backend

**Walk in. Talk for 20 minutes. Walk out with a published video.**

The API behind Strolling: a guided micro-shoot where der Regisseur (a warm German
film director) walks a creator through five shots of a place, interviews them, then
cuts, captions, and publishes a vertical mini-doc.

**Monorepo:** the **backend API** is at the repo root; **[`frontend/`](./frontend)** is the
Flutter client (its own README). A Figma design is the frontend's visual reference.

## Tracer bullet

Every endpoint is **mocked and runs with zero keys** (`MOCK=1`, the default). The shapes
are the real contract (`src/lib/types.ts`); only the implementations are fake. Each later
commit replaces one mock with one real integration — grep for `TODO(COMMIT-n)`.

## Run

```bash
npm install
cp .env.example .env      # optional — defaults are fine
npm run dev               # tsx watch, http://localhost:3000

npm run typecheck         # tsc --noEmit
npm run build && npm start
```

## Endpoints

| Method & path            | Body                              | Returns                              | Real in |
| ------------------------ | --------------------------------- | ------------------------------------ | ------- |
| `GET  /health`           | —                                 | `{ ok, mock }`                       | —       |
| `POST /api/tasks`        | `{ business }`                    | `Task[]` (the 5 shots)               | COMMIT-3 |
| `POST /api/media/upload` | multipart `file`                  | `{ mediaUrl }`                       | COMMIT-3 |
| `POST /api/render`       | `{ captures, reviews, business }` | `{ videoUrl }`                       | COMMIT-4 ✅ |
| `POST /api/publish`      | `{ videoUrl, transcript }`        | `{ postUrl, caption, hashtags }`     | COMMIT-5 |

`/mock/sample.mp4` is served statically so a mocked `videoUrl` actually resolves.

### Render pipeline (`POST /api/render`)

Turns the creator's **shots** — each a photo/clip plus its own **script part** — into a
vertical video where each part's voiceover plays over its own shot. Parts are paired to
photos by `taskId`; each part is cleaned by a fal LLM, voiced by ElevenLabs, and its shot
is rendered to exactly that narration's length (trim / freeze-frame) so audio and visuals
stay locked in sync. Real `captures`/`reviews` are used when present; otherwise the mock
shots stand in (`src/lib/mockAssets.ts`) — **real data always wins**.

- `MOCK=1` (default) → instant `/mock/sample.mp4`. Add `?force=1` to run the pipeline once.
- `MOCK=0` → always runs. With `FAL_KEY` it uses **fal** (image-to-video + storage);
  without a key it falls back to a **local ffmpeg** render (Ken Burns + macOS `say`
  narration), served from `/renders/*`. Requires `ffmpeg`/`ffprobe` on `PATH`.

```bash
# real pipeline, no keys needed (local ffmpeg + say):
MOCK=0 npm run dev
curl -s -X POST localhost:3000/api/render -d '{}' -H 'content-type: application/json'
# → { "videoUrl": "/renders/render-<uuid>.mp4" }  (GET it to watch)
```

See [CLAUDE.md](./CLAUDE.md#render-pipeline-the-post-creation-workflow--srcservicesrenderpipelinets)
for the full design.

### Try it

```bash
curl localhost:3000/health
curl -X POST localhost:3000/api/tasks -H 'content-type: application/json' -d '{"business":{}}'
curl -X POST localhost:3000/api/render -H 'content-type: application/json' -d '{}'
curl -X POST localhost:3000/api/publish -H 'content-type: application/json' -d '{}'
curl -X POST localhost:3000/api/media/upload -F file=@some.jpg
```

## Layout

```
src/
  index.ts              Express app (createApp) + static /mock + route mounting
  config.ts             MOCK flag, PORT, env keys
  lib/
    types.ts            the contract (Task, Capture, Review, RenderResult, …)
    seed.ts             BUSINESS + FALLBACK_TASKS
    director.ts         DIRECTOR_SYSTEM_PROMPT
    mock.ts             latency helper
  routes/               tasks · render · publish · media
  services/
    renderPipeline.ts   the post-creation workflow (fal i2v + ffmpeg compose)
  lib/
    fal.ts              fal client wrapper (image-to-video, storage, LLM, TTS)
    supabase.ts         Supabase jobs + reels storage (service role)
    elevenlabs.ts       ElevenLabs text-to-speech (the narration voice)
    scriptCleaner.ts    raw script part → polished voiceover text (fal LLM / heuristic)
    ffmpeg.ts           media plumbing (fit-to-duration, concat, mux, narration)
    mockAssets.ts       MOCK_SHOTS — mock pictures paired with raw script parts
  middleware/           errorHandler
public/mock/sample.mp4  stand-in rendered film
public/mock/pictures/   mock stills for the render pipeline
supabase/schema.sql     Supabase buckets + jobs table setup (run once)
frontend/               Flutter client (see frontend/README.md)
```

See [CLAUDE.md](./CLAUDE.md) for architecture and the full commit roadmap.
