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
| `POST /api/render`       | `{ captures, reviews, business }` | `{ videoUrl }`                       | COMMIT-4 |
| `POST /api/publish`      | `{ videoUrl, transcript }`        | `{ postUrl, caption, hashtags }`     | COMMIT-5 |

`/mock/sample.mp4` is served statically so a mocked `videoUrl` actually resolves.

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
  middleware/           errorHandler
public/mock/sample.mp4  stand-in rendered film
frontend/               Flutter client (see frontend/README.md)
```

See [CLAUDE.md](./CLAUDE.md) for architecture and the full commit roadmap.
