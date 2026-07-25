import { createClient } from "@supabase/supabase-js";
import { config } from "../src/config";

// End-to-end job test: insert a queued render job, POST /api/render { jobId },
// then poll the row until it flips to done (or error). Mirrors the real frontend
// flow. Needs the server running and FAL/ElevenLabs/Supabase keys in .env.
async function main(): Promise<void> {
  const sb = createClient(config.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false },
  });

  const shots = [
    {
      mediaUrl: "https://picsum.photos/seed/strolltest/720/1280",
      kind: "photo" as const,
      script:
        "um this is like a quick test of the strolling pipeline you know, the vibe is honestly great",
    },
  ];
  const ins = await sb
    .from(config.supabaseTable)
    .insert({ status: "queued", shots })
    .select()
    .single();
  if (ins.error) throw new Error("insert: " + ins.error.message);
  const jobId = ins.data.id as string;
  console.log("1) inserted job:", jobId, "(status queued)");

  const port = Number(process.env.API_PORT ?? config.port);
  const res = await fetch(`http://localhost:${port}/api/render`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ jobId }),
  });
  console.log("2) POST /api/render { jobId } →", res.status, (await res.text()).trim());

  console.log("3) polling the reels row…");
  let last = "";
  for (let i = 1; i <= 140; i++) {
    await new Promise((r) => setTimeout(r, 3000));
    const { data, error } = await sb
      .from(config.supabaseTable)
      .select("status,video_url,error")
      .eq("id", jobId)
      .single();
    if (error) throw new Error("poll: " + error.message);
    if (data.status !== last) {
      console.log(`   [${i * 3}s] status = ${data.status}`);
      last = data.status;
    }
    if (data.status === "done") {
      console.log("\n✓ DONE");
      console.log("VIDEO_URL=" + data.video_url);
      return;
    }
    if (data.status === "error") {
      console.log("\n✗ job error:", data.error);
      process.exit(1);
    }
  }
  console.log("timed out waiting for done");
  process.exit(1);
}

main().catch((e) => {
  console.error(e?.message ?? e);
  process.exit(1);
});
