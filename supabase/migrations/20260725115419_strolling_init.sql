-- Strolling — initial schema.
-- Businesses (map pins + perks), strolls, per-stop scenes/captures, perk wallet.
-- Every table has RLS; businesses are world-readable, everything else is
-- owner-scoped. Approving perks is a business/service-role action.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.business_category as enum ('cafe','food','drinks','culture','market');
create type public.capture_kind      as enum ('photo','video','voice','text');
create type public.perk_status       as enum ('pending','approved','redeemed');
create type public.post_platform     as enum ('instagram','tiktok','facebook');

-- ---------------------------------------------------------------------------
-- businesses — the catalog behind GET /api/businesses
-- ---------------------------------------------------------------------------
create table public.businesses (
  id           text primary key,                -- slug, e.g. 'brot-roesterei'
  name         text not null,
  category     public.business_category not null,
  description  text not null,
  walk_minutes int  not null,
  rating       numeric(2,1) not null,
  lat          double precision not null,
  lng          double precision not null,
  narration    text not null,
  perk_title   text,                            -- null → roam-only stop
  perk_value   int,
  deliverable  text,
  created_at   timestamptz not null default now()
);

alter table public.businesses enable row level security;

create policy "businesses are readable by everyone"
  on public.businesses for select
  to anon, authenticated
  using ( true );
-- No insert/update/delete policies: catalog writes go through the service role.

-- ---------------------------------------------------------------------------
-- strolls — one row per outing
-- ---------------------------------------------------------------------------
create table public.strolls (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  template_id text not null check (template_id in ('wes','kubrick','doku','viral')),
  created_at  timestamptz not null default now(),
  ended_at    timestamptz
);

create index strolls_user_idx on public.strolls (user_id);

alter table public.strolls enable row level security;

create policy "select own strolls" on public.strolls for select
  to authenticated using ( (select auth.uid()) = user_id );
create policy "insert own strolls" on public.strolls for insert
  to authenticated with check ( (select auth.uid()) = user_id );
create policy "update own strolls" on public.strolls for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );
create policy "delete own strolls" on public.strolls for delete
  to authenticated using ( (select auth.uid()) = user_id );

-- ---------------------------------------------------------------------------
-- stroll_stops — ordered stops; the generated scene (ScriptStep) lives here
-- ---------------------------------------------------------------------------
create table public.stroll_stops (
  id              uuid primary key default gen_random_uuid(),
  stroll_id       uuid not null references public.strolls (id) on delete cascade,
  business_id     text not null references public.businesses (id),
  position        int  not null,
  scene           jsonb not null,               -- { sceneTitle, direction, line, perkCallout, actions[] }
  posted          boolean not null default false,
  posted_platform public.post_platform,
  posted_at       timestamptz,
  unique (stroll_id, position),
  unique (stroll_id, business_id)
);

create index stroll_stops_stroll_idx on public.stroll_stops (stroll_id);

alter table public.stroll_stops enable row level security;

-- Ownership flows through the parent stroll.
create policy "select own stops" on public.stroll_stops for select
  to authenticated using (
    exists (select 1 from public.strolls s
            where s.id = stroll_id and s.user_id = (select auth.uid()))
  );
create policy "insert own stops" on public.stroll_stops for insert
  to authenticated with check (
    exists (select 1 from public.strolls s
            where s.id = stroll_id and s.user_id = (select auth.uid()))
  );
create policy "update own stops" on public.stroll_stops for update
  to authenticated
  using (
    exists (select 1 from public.strolls s
            where s.id = stroll_id and s.user_id = (select auth.uid()))
  )
  with check (
    exists (select 1 from public.strolls s
            where s.id = stroll_id and s.user_id = (select auth.uid()))
  );
create policy "delete own stops" on public.stroll_stops for delete
  to authenticated using (
    exists (select 1 from public.strolls s
            where s.id = stroll_id and s.user_id = (select auth.uid()))
  );

-- ---------------------------------------------------------------------------
-- captures — what the creator shot at a stop (files in the 'captures' bucket)
-- ---------------------------------------------------------------------------
create table public.captures (
  id            uuid primary key default gen_random_uuid(),
  stop_id       uuid not null references public.stroll_stops (id) on delete cascade,
  user_id       uuid not null references auth.users (id) on delete cascade,
  kind          public.capture_kind not null,
  storage_path  text,                           -- photo/video/voice object path
  note_text     text,                           -- kind = 'text'
  voice_seconds int,
  created_at    timestamptz not null default now(),
  check (
    (kind = 'text'  and note_text is not null) or
    (kind = 'voice' and voice_seconds is not null) or
    (kind in ('photo','video') and storage_path is not null)
  )
);

create index captures_stop_idx on public.captures (stop_id);
create index captures_user_idx on public.captures (user_id);

alter table public.captures enable row level security;

create policy "select own captures" on public.captures for select
  to authenticated using ( (select auth.uid()) = user_id );
create policy "insert own captures" on public.captures for insert
  to authenticated with check ( (select auth.uid()) = user_id );
create policy "update own captures" on public.captures for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );
create policy "delete own captures" on public.captures for delete
  to authenticated using ( (select auth.uid()) = user_id );

-- ---------------------------------------------------------------------------
-- perks — the wallet: pending → approved (by the business) → redeemed
-- ---------------------------------------------------------------------------
create table public.perks (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  business_id text not null references public.businesses (id),
  status      public.perk_status not null default 'pending',
  earned_at   timestamptz not null default now(),
  approved_at timestamptz,
  redeemed_at timestamptz,
  unique (user_id, business_id)
);

create index perks_user_idx on public.perks (user_id);

alter table public.perks enable row level security;

create policy "select own perks" on public.perks for select
  to authenticated using ( (select auth.uid()) = user_id );
create policy "insert own perks" on public.perks for insert
  to authenticated with check (
    (select auth.uid()) = user_id and status = 'pending'
  );
-- Users may only redeem an approved perk. pending → approved is done by the
-- business portal via the service role (bypasses RLS).
create policy "redeem own approved perks" on public.perks for update
  to authenticated
  using  ( (select auth.uid()) = user_id and status = 'approved' )
  with check ( (select auth.uid()) = user_id and status = 'redeemed' );

-- ---------------------------------------------------------------------------
-- Storage: private bucket for capture files, path-scoped to the owner:
--   captures/<user_id>/<stop_id>/<filename>
-- INSERT + SELECT + UPDATE are all required for upsert to work.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('captures', 'captures', false)
on conflict (id) do nothing;

create policy "upload own capture files" on storage.objects for insert
  to authenticated with check (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "read own capture files" on storage.objects for select
  to authenticated using (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "replace own capture files" on storage.objects for update
  to authenticated
  using (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "delete own capture files" on storage.objects for delete
  to authenticated using (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ---------------------------------------------------------------------------
-- Seed: the Stuttgart businesses (mirrors src/lib/seed.ts)
-- ---------------------------------------------------------------------------
insert into public.businesses
  (id, name, category, description, walk_minutes, rating, lat, lng, narration,
   perk_title, perk_value, deliverable)
values
  ('brot-roesterei', 'Brot & Rösterei', 'cafe',
   'Specialty coffee and sourdough bakery in the Bohnenviertel. Open from 7am.',
   4, 4.8, 48.7737, 9.1862,
   'A bakery corner in the Bohnenviertel that fills with regulars before the rest of the city wakes up.',
   '2 free coffees', 7, '1 photo + 1 story post'),
  ('alte-kanzlei', 'Alte Kanzlei', 'food',
   'Swabian restaurant on Schillerplatz — Maultaschen, Spätzle, terrace facing the Old Castle.',
   7, 4.6, 48.7772, 9.1794,
   'Schillerplatz has been the city''s front room for four centuries. The kitchen here cooks the classics straight.',
   'Free lunch special', 18, '1 reel + tag @altekanzlei'),
  ('palmengarten', 'Palmengarten Kiosk', 'culture',
   'Greenhouse café at the edge of Rosensteinpark — plants, records, flat whites.',
   9, 4.5, 48.8009, 9.2028,
   'A glasshouse from the Kaiser era, still full of palms. The café came later.',
   'Free entry + latte', 6, '1 photo'),
  ('markthalle', 'Markthalle Stuttgart', 'market',
   'Art-nouveau market hall from 1914 — about 40 stalls of produce, spices and delicatessen.',
   6, 4.7, 48.7756, 9.1822,
   'The market hall has run daily since 1914. Forty stalls under one art-nouveau roof.',
   'Tasting basket', 15, '1 photo + 1 story post'),
  ('biergarten-schlossgarten', 'Biergarten im Schlossgarten', 'drinks',
   'Beer garden in the palace gardens — 1,200 seats under chestnut trees, local Pils, pretzels.',
   8, 4.4, 48.7841, 9.1856,
   'End of the route: 1,200 seats in the Schlossgarten shade. Order at the counter.',
   '2 craft beers', 14, '1 reel'),
  ('stadtbibliothek', 'Stadtbibliothek', 'culture',
   'The white cube city library by Eun Young Yi. The upper atrium is one of Germany''s most photographed rooms.',
   11, 4.7, 48.7908, 9.1811,
   'Nine storeys of white geometry. The atrium light changes by the hour.',
   null, null, null),
  ('feuersee', 'Feuersee & Johanneskirche', 'culture',
   'Neo-gothic church standing in a small lake; the spire was lost in the war and never rebuilt.',
   13, 4.6, 48.7735, 9.1655,
   'The church kept its broken spire as a war memorial. Best light in the evening.',
   null, null, null),
  ('weissenburgpark', 'Weißenburgpark Teehaus', 'cafe',
   'Marble tea house on the hillside with a wide view over the city bowl.',
   16, 4.8, 48.7647, 9.1868,
   'The climb pays off at the top — the whole city bowl in one view.',
   null, null, null)
on conflict (id) do nothing;
