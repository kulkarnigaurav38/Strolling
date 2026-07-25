-- Strolling — Supabase setup. Paste into the Supabase SQL editor and Run.
-- Idempotent: safe to run more than once.
--
-- Buckets: run `npm run setup:supabase` (or create `captures` + `reels` as PUBLIC
-- in Storage). This file only needs to create the jobs table.

-- 1) Jobs table (the important part — created first so nothing can block it) ---
create table if not exists public.reels (
  id          uuid primary key default gen_random_uuid(),
  status      text not null default 'queued'
              check (status in ('queued','processing','done','error')),
  -- shots: [{ "mediaUrl": "...", "kind": "photo"|"clip", "script": "raw part" }]
  shots       jsonb not null default '[]'::jsonb,
  business    jsonb,
  video_url   text,
  caption     text,
  hashtags    text[],
  error       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.reels enable row level security;

-- Frontend (publishable/anon key) can create + read jobs. Backend uses the secret
-- key and bypasses RLS.
drop policy if exists "anyone insert reels" on public.reels;
create policy "anyone insert reels" on public.reels for insert with check (true);
drop policy if exists "anyone read reels" on public.reels;
create policy "anyone read reels" on public.reels for select using (true);

-- 2) Realtime (ignore if the table is already in the publication) --------------
do $$
begin
  alter publication supabase_realtime add table public.reels;
exception when duplicate_object then null;
end $$;

-- 3) Storage read/upload policies for the FRONTEND (publishable key). The backend
--    bypasses these. Buckets are already public, so these are optional niceties. --
drop policy if exists "public read captures" on storage.objects;
create policy "public read captures" on storage.objects
  for select using (bucket_id = 'captures');
drop policy if exists "anyone upload captures" on storage.objects;
create policy "anyone upload captures" on storage.objects
  for insert with check (bucket_id = 'captures');

-- Frontend flow:
--   1. upload files to the `captures` bucket → get public URLs
--   2. insert into reels (shots) values ('[{"mediaUrl":"...","kind":"photo","script":"..."}]')
--   3. POST /api/render { jobId } to the backend
--   4. subscribe to the row; when status = 'done', use video_url
