import path from "node:path";
import cors from "cors";
import express from "express";
import { config } from "./config";
import { errorHandler } from "./middleware/errorHandler";
import { mediaRouter } from "./routes/media";
import { publishRouter } from "./routes/publish";
import { renderRouter } from "./routes/render";
import { tasksRouter } from "./routes/tasks";

export function createApp(): express.Express {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: "2mb" }));

  // Serve the mock render output so /api/render's videoUrl actually resolves.
  app.use("/mock", express.static(path.join(__dirname, "..", "public", "mock")));
  // Serve locally-rendered videos (fal-less fallback output).
  app.use("/renders", express.static(config.rendersDir));

  app.get("/health", (_req, res) => {
    res.json({ ok: true, mock: config.mock });
  });

  app.use("/api/tasks", tasksRouter);
  app.use("/api/render", renderRouter);
  app.use("/api/publish", publishRouter);
  app.use("/api/media", mediaRouter);

  app.use(errorHandler);
  return app;
}

// Only listen when run directly (keeps createApp importable for tests).
if (require.main === module) {
  const app = createApp();
  app.listen(config.port, () => {
    // eslint-disable-next-line no-console
    console.log(
      `[strolling] listening on http://localhost:${config.port}  (mock=${config.mock})`,
    );
  });
}
