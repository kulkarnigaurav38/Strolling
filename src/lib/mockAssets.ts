import path from "node:path";
import type { Shot } from "../services/renderPipeline";

// ⚠️ MOCK DATA. Stand-in shots for the render pipeline while the capture/interview
// parts are still in progress. Each mock picture is paired with the raw script PART
// for that shot — exactly the shape real data arrives in.
//
// REPLACE: nothing here needs editing. `POST /api/render` uses these ONLY when the
// request has no `captures`; as soon as the real parts send `captures` + `reviews`,
// the route builds shots from those instead (real data always wins).
//
// The parts are intentionally raw (fillers, false starts) to exercise the LLM
// cleaning step.

const picturesDir = path.join(process.cwd(), "public", "mock", "pictures");
const pic = (f: string) => path.join(picturesDir, f);

export const MOCK_SHOTS: Shot[] = [
  {
    media: { url: pic("shot1.jpg"), kind: "photo" },
    script:
      "um so this is like the entrance you know, kinda unassuming for whats going on inside",
  },
  {
    media: { url: pic("shot2.jpg"), kind: "photo" },
    script:
      "and uh the floor, its just packed, everyone heads down coding, the energy is unreal honestly",
  },
  {
    media: { url: pic("shot3.jpg"), kind: "photo" },
    script:
      "over here someones building live with cursor, like the code just pours out its wild",
  },
  {
    media: { url: pic("shot4.jpg"), kind: "photo" },
    script:
      "and um the coffee corner, thats where like half the ideas actually happen i think",
  },
  {
    media: { url: pic("shot5.jpg"), kind: "photo" },
    script:
      "and the view from up here, it honestly makes the whole day feel kinda cinematic you know",
  },
];
