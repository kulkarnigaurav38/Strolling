import path from "node:path";
import type { MediaItem } from "../services/renderPipeline";

// Stand-in inputs for the render pipeline while the capture/agent parts are still
// in progress. The render route uses these ONLY when the request carries no real
// captures/reviews — real creator data always wins. Replace nothing here when the
// real parts land; just send `captures` + `reviews` in the request.

/** The creator's voiceover text (what the real interview transcript will become). */
export const MOCK_SCRIPT =
  "So this is where sixty people are building for one day. " +
  "The energy in here is honestly unreal — every table a different team, totally locked in. " +
  "Watching someone pair with Cursor live, the code just pours out. " +
  "And yes, this video literally pays for my drink. " +
  "If you're wondering whether to come next time — come.";

const picturesDir = path.join(process.cwd(), "public", "mock", "pictures");

/** Five mock stills, one per shot, shipped in public/mock/pictures/. */
export const MOCK_MEDIA: MediaItem[] = [
  "shot1.jpg",
  "shot2.jpg",
  "shot3.jpg",
  "shot4.jpg",
  "shot5.jpg",
].map((f) => ({ url: path.join(picturesDir, f), kind: "photo" as const }));
