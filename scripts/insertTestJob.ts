import { createClient } from "@supabase/supabase-js";
import { config } from "../src/config";

// Inserts one queued render job into the reels table and prints its id — proves
// the table exists (and gives a visible row in the dashboard). Reused to drive
// the end-to-end job test.
async function main(): Promise<void> {
  const sb = createClient(config.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false },
  });
  const shots = [
    {
      mediaUrl: "https://picsum.photos/seed/strolltest/720/1280",
      kind: "photo",
      script:
        "um this is like a quick test of the strolling pipeline you know, the vibe is good",
    },
  ];
  const { data, error } = await sb
    .from(config.supabaseTable)
    .insert({ status: "queued", shots })
    .select()
    .single();
  if (error) {
    console.error("INSERT FAILED ✗:", error.message, error.details ?? "", error.hint ?? "");
    process.exit(1);
  }
  console.log("inserted job row ✓");
  console.log("  id     :", data.id);
  console.log("  status :", data.status);
  console.log("  shots  :", JSON.stringify(data.shots));

  const { count } = await sb
    .from(config.supabaseTable)
    .select("*", { count: "exact", head: true });
  console.log("  reels table row count:", count);
  console.log("\nJOB_ID=" + data.id);
}

main().catch((e) => {
  console.error(e?.message ?? e);
  process.exit(1);
});
