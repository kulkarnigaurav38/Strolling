-- Strolling — Supabase setup for the render pipeline.
-- Run this in the Supabase SQL editor (Dashboard → SQL). One-time.

-- 1) Storage buckets ---------------------------------------------------------
--    captures = input photos/clips (public so fal can fetch them)
--    reels    = finished videos (public so the frontend can play/post them)
insert into storage.buckets (id, name, public)
values ('captures', 'captures', true), ('reels', 'reels', true)
on conflict (id) do update set public = excluded.public;

-- Let anyone read the buckets; let the frontend (anon/auth) upload captures.
-- The backend uses the service_role key and bypasses these policies.
create policy "public read captures" on storage.objects
  for select using (bucket_id = 'captures');
create policy "public read reels" on storage.objects
  for select using (bucket_id = 'reels');
create policy "anyone upload captures" on storage.objects
  for insert with check (bucket_id = 'captures');

-- 2) Jobs table --------------------------------------------------------------
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

-- Frontend (anon/auth) can create jobs and read them. Backend uses service_role.
create policy "anyone insert reels" on public.reels for insert with check (true);
create policy "anyone read reels"   on public.reels for select using (true);

-- 3) Realtime ----------------------------------------------------------------
alter publication supabase_realtime add table public.reels;

-- Frontend flow:
--   1. upload files to the `captures` bucket → get public URLs
--   2. insert into reels (shots) values ('[{"mediaUrl":"...","kind":"photo","script":"..."}]')
--   3. POST /api/render { jobId } to the backend
--   4. subscribe to the row; when status = 'done', use video_url
