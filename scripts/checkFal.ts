import { config } from "../src/config";
import { isFalEnabled, uploadToStorage } from "../src/lib/fal";

// Cheap fal sanity check: confirms the key loads and authenticates by uploading a
// few bytes to fal storage. Does NOT run a paid image-to-video render.
async function main(): Promise<void> {
  const key = config.falKey;
  console.log("FAL_KEY loaded :", isFalEnabled() ? `yes (len ${key.length}, ${key.slice(0, 4)}…)` : "NO");
  console.log("MOCK           :", config.mock, config.mock ? "(render uses /mock/sample.mp4 unless ?force=1)" : "(pipeline always runs)");
  console.log("I2V model      :", config.falI2vModel);
  console.log("TTS model      :", config.falTtsModel || "(none — narration via say/silent)");

  if (!isFalEnabled()) {
    console.log("\nNo FAL_KEY set — add it to .env to check auth.");
    return;
  }

  process.stdout.write("\nUploading a tiny file to fal storage… ");
  const bytes = Buffer.from(`strolling fal auth check ${new Date().toISOString()}`);
  const url = await uploadToStorage(bytes, "strolling-auth-check.txt");
  console.log("OK ✓");
  console.log("→", url);
  console.log("\nAuth works. The image-to-video model slug is NOT verified here (that needs a paid job).");
}

main().catch((err) => {
  console.error("\nfal check FAILED ✗");
  console.error(err?.message ?? err);
  console.error("\nLikely causes: wrong FAL_KEY, no network, or an SDK/API mismatch.");
  process.exit(1);
});
