import { createClient } from "@supabase/supabase-js";
import { config } from "../src/config";

// Fast proof: insert a queued job and make NO API call. If the background worker
// flips it to "processing" within a few seconds, auto-pickup works. (The render
// itself is the same path already verified end-to-end.) Cleans up the test row.
async function main(): Promise<void> {
  const sb = createClient(config.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false },
  });
  const ins = await sb
    .from(config.supabaseTable)
    .insert({
      status: "queued",
      shots: [
        {
          mediaUrl: "https://picsum.photos/seed/claimtest/720/1280",
          kind: "photo",
          script: "quick worker pickup test",
        },
      ],
    })
    .select()
    .single();
  if (ins.error) throw new Error(ins.error.message);
  const id = ins.data.id as string;
  console.log("inserted queued job (NO api call):", id);

  const t0 = Date.now();
  for (let i = 0; i < 20; i++) {
    await new Promise((r) => setTimeout(r, 1000));
    const { data } = await sb
      .from(config.supabaseTable)
      .select("status")
      .eq("id", id)
      .single();
    if (data && data.status !== "queued") {
      const s = ((Date.now() - t0) / 1000).toFixed(0);
      console.log(`✓ worker auto-picked it up in ~${s}s → status=${data.status}`);
      await sb.from(config.supabaseTable).delete().eq("id", id);
      console.log("cleaned up the test row");
      return;
    }
  }
  console.log("✗ worker did not pick it up within 20s");
  process.exit(1);
}

main().catch((e) => {
  console.error(e?.message ?? e);
  process.exit(1);
});
