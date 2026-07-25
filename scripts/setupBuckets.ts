import { createClient } from "@supabase/supabase-js";
import { config } from "../src/config";

// Creates the storage buckets the render pipeline needs (idempotent). The jobs
// TABLE still comes from supabase/schema.sql — buckets are all we can make from
// the client.
async function main(): Promise<void> {
  if (!config.supabaseUrl || !config.supabaseServiceKey) {
    throw new Error("SUPABASE_URL + SUPABASE_SECRET_KEY must be set in .env");
  }
  const sb = createClient(config.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false },
  });
  for (const bucket of [config.supabaseReelsBucket, config.supabaseCapturesBucket]) {
    const { error } = await sb.storage.createBucket(bucket, { public: true });
    if (error && !/already exists/i.test(error.message)) {
      throw new Error(`create bucket "${bucket}": ${error.message}`);
    }
    console.log(`bucket "${bucket}": ${error ? "already exists" : "created"} ✓ (public)`);
  }
  console.log("\nBuckets ready. Still run supabase/schema.sql for the `reels` jobs table.");
}

main().catch((err) => {
  console.error("setup buckets FAILED ✗:", err?.message ?? err);
  process.exit(1);
});
