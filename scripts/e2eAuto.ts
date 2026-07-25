import { createClient } from "@supabase/supabase-js";
import { config } from "../src/config";

// Proves the fully-automatic flow: insert a queued job and make NO API call —
// the background worker should pick it up, render it, and write the reel URL
// back. This is exactly what the frontend does (just insert a row).
async function main(): Promise<void> {
  const sb = createClient(config.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false },
  });

  const shots = [
    {
      mediaUrl: "https://picsum.photos/seed/autotest/720/1280",
      kind: "photo" as const,
      script:
        "so this is like the fully automatic flow you know, the frontend just drops a row and boom the video appears",
    },
  ];
  const ins = await sb
    .from(config.supabaseTable)
    .insert({ status: "queued", shots })
    .select()
    .single();
  if (ins.error) throw new Error(ins.error.message);
  const jobId = ins.data.id as string;
  console.log("inserted job (NO api call):", jobId);
  console.log("waiting for the background worker to pick it up…");

  let last = "";
  for (let i = 1; i <= 140; i++) {
    await new Promise((r) => setTimeout(r, 3000));
    const { data, error } = await sb
      .from(config.supabaseTable)
      .select("status,video_url,error")
      .eq("id", jobId)
      .single();
    if (error) throw new Error(error.message);
    if (data.status !== last) {
      console.log(`  [${i * 3}s] status = ${data.status}`);
      last = data.status;
    }
    if (data.status === "done") {
      console.log("\n✓ AUTO-RENDERED (no endpoint call)");
      console.log("VIDEO_URL=" + data.video_url);
      return;
    }
    if (data.status === "error") {
      console.log("\n✗ error:", data.error);
      process.exit(1);
    }
  }
  console.log("timed out");
  process.exit(1);
}

main().catch((e) => {
  console.error(e?.message ?? e);
  process.exit(1);
});
