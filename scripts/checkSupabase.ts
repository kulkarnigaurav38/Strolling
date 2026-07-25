import { createClient } from "@supabase/supabase-js";
import { config } from "../src/config";
import { isSupabaseEnabled, uploadReel } from "../src/lib/supabase";

// Verifies the Supabase setup end to end (cheap): checks the config, that the
// reels bucket accepts an upload, and that the jobs table is reachable.
async function main(): Promise<void> {
  console.log("Supabase configured :", isSupabaseEnabled());
  console.log("URL                 :", config.supabaseUrl || "(missing)");
  console.log("table               :", config.supabaseTable);
  console.log("buckets             :", config.supabaseReelsBucket, "/", config.supabaseCapturesBucket);
  if (!isSupabaseEnabled()) {
    console.log("\nSet SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY in .env first.");
    return;
  }

  process.stdout.write("\nUploading a tiny test file to the reels bucket… ");
  const url = await uploadReel(
    Buffer.from("strolling supabase check"),
    "_healthcheck.txt",
  );
  console.log("OK ✓\n→", url);

  process.stdout.write(`Reading the "${config.supabaseTable}" table… `);
  const admin = createClient(config.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false },
  });
  // A real select (not HEAD) so a missing table surfaces as an error.
  const { error } = await admin.from(config.supabaseTable).select("id").limit(1);
  if (error) {
    throw new Error(
      `${error.message} — run supabase/schema.sql to create the "${config.supabaseTable}" table`,
    );
  }
  console.log("OK ✓");
  console.log("\nSupabase is ready. Frontend inserts a job row → POST /api/render { jobId }.");
}

main().catch((err) => {
  console.error("\nSupabase check FAILED ✗");
  console.error(err?.message ?? err);
  console.error(
    "\nCheck: URL + service_role key, that the bucket + table exist (run supabase/schema.sql).",
  );
  process.exit(1);
});
