import { readFile } from "node:fs/promises";
import path from "node:path";
import { uploadToStorage } from "../src/lib/fal";
import { renderVideo } from "../src/services/renderPipeline";

// One-off: render the 3 real media in ~/Downloads/cursor_pics into a final reel.
//   photo → fal image-to-video · video → clip · audio → the voiceover track.
const DIR = "/Users/gaurav/Downloads/cursor_pics";
const IMG = path.join(DIR, "WhatsApp Image 2026-07-25 at 15.57.34.jpeg");
const VID = path.join(DIR, "WhatsApp Video 2026-07-25 at 15.57.34.mp4");
const AUD = path.join(DIR, "WhatsApp Audio 2026-07-25 at 15.57.38.opus");

async function main(): Promise<void> {
  console.log("1) uploading the creator's voiceover to fal storage…");
  const voiceoverUrl = await uploadToStorage(await readFile(AUD), "voiceover.opus");
  console.log("   voiceover:", voiceoverUrl);

  console.log("2) rendering (photo → fal i2v, video → clip, real audio → narration)…");
  const t0 = Date.now();
  const { videoUrl, usedFal } = await renderVideo({
    shots: [
      { media: { url: IMG, kind: "photo" }, script: "" },
      { media: { url: VID, kind: "clip" }, script: "" },
    ],
    voiceoverUrl,
  });
  console.log(`   done in ${((Date.now() - t0) / 1000).toFixed(0)}s · engine=${usedFal ? "fal" : "ffmpeg-local"}`);
  console.log("VIDEO_URL=" + videoUrl);
}

main().catch((e) => {
  console.error(e?.message ?? e);
  process.exit(1);
});
