-- Strolling — migration #2: the business layer.
-- Creator profiles + social accounts, business offers, posts (published
-- content), and the claim lifecycle (perk_status grows en_route/arrived/posted).
--
-- ID DOMAIN (deliberate): the hackathon API has no auth — user ids are free
-- strings like 'demo-user'. Tables the marketplace API writes (profiles,
-- social_accounts, posts, perks) therefore use TEXT user ids with no FK to
-- auth.users. strolls/captures keep uuid ids for the future real-auth wiring.
-- TODO(REAL:auth): tighten back to uuid + auth.users FKs once JWTs land.
--
-- NOTE: the ALTER TYPE ... ADD VALUE statements MUST come first, each its own
-- statement. Postgres 12+ allows ADD VALUE inside a transaction as long as the
-- new value is not used as an enum literal later in the same transaction —
-- policies below compare status::text against string literals for exactly
-- that reason.

-- ---------------------------------------------------------------------------
-- perk_status: pending → en_route → arrived → posted → approved → redeemed
-- ---------------------------------------------------------------------------
alter type public.perk_status add value if not exists 'en_route' before 'approved';
alter type public.perk_status add value if not exists 'arrived'  before 'approved';
alter type public.perk_status add value if not exists 'posted'   before 'approved';

-- ---------------------------------------------------------------------------
-- New enums
-- ---------------------------------------------------------------------------
create type public.social_platform as enum ('instagram','facebook','tiktok');
create type public.offer_type      as enum ('in_kind','cash');

-- ---------------------------------------------------------------------------
-- profiles — one row per creator (text id: no-auth hackathon contract)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id         text primary key,
  name       text,
  city       text,
  interests  text[] default '{}',
  score      numeric(3,1) not null default 4.2,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "select own profile" on public.profiles for select
  to authenticated using ( (select auth.uid())::text = id );
create policy "insert own profile" on public.profiles for insert
  to authenticated with check ( (select auth.uid())::text = id );
create policy "update own profile" on public.profiles for update
  to authenticated
  using ( (select auth.uid())::text = id )
  with check ( (select auth.uid())::text = id );
create policy "delete own profile" on public.profiles for delete
  to authenticated using ( (select auth.uid())::text = id );

-- ---------------------------------------------------------------------------
-- social_accounts — connected creator handles (one per platform per user)
-- ---------------------------------------------------------------------------
create table public.social_accounts (
  id           uuid primary key default gen_random_uuid(),
  user_id      text not null,
  platform     public.social_platform not null,
  handle       text not null,
  followers    int not null default 0,
  connected_at timestamptz default now(),
  unique (user_id, platform)
);

create index social_accounts_user_idx on public.social_accounts (user_id);

alter table public.social_accounts enable row level security;

create policy "select own social accounts" on public.social_accounts for select
  to authenticated using ( (select auth.uid())::text = user_id );
create policy "insert own social accounts" on public.social_accounts for insert
  to authenticated with check ( (select auth.uid())::text = user_id );
create policy "update own social accounts" on public.social_accounts for update
  to authenticated
  using ( (select auth.uid())::text = user_id )
  with check ( (select auth.uid())::text = user_id );
create policy "delete own social accounts" on public.social_accounts for delete
  to authenticated using ( (select auth.uid())::text = user_id );

-- ---------------------------------------------------------------------------
-- businesses — gains an owner (business portal), verification flag, cover.
-- Existing seeded businesses stay owner-less (service-role managed).
-- ---------------------------------------------------------------------------
alter table public.businesses add column if not exists owner_id uuid references auth.users (id);
alter table public.businesses add column if not exists verified boolean not null default true;
alter table public.businesses add column if not exists cover_img text;

-- ---------------------------------------------------------------------------
-- offers — what a business puts on the marketplace for creators
-- ---------------------------------------------------------------------------
create table public.offers (
  id              uuid primary key default gen_random_uuid(),
  business_id     text not null references public.businesses (id) on delete cascade,
  perk_title      text not null,
  perk_value      int not null check (perk_value >= 0),
  offer_type      public.offer_type not null default 'in_kind',
  deliverable     text not null,
  min_followers   int not null default 0 check (min_followers >= 0),
  slots_total     int not null default 10 check (slots_total > 0),
  slots_remaining int not null default 10 check (slots_remaining >= 0),
  active          boolean not null default true,
  created_at      timestamptz default now()
);

create index offers_business_idx on public.offers (business_id);

alter table public.offers enable row level security;

-- Anyone can browse active offers; owners also see their paused ones (needed
-- both for the portal list and because UPDATE ... RETURNING must be able to
-- see the post-update row).
create policy "active offers are readable by everyone" on public.offers for select
  to anon, authenticated using ( active );
create policy "business owners read own offers" on public.offers for select
  to authenticated using (
    exists (select 1 from public.businesses b
            where b.id = business_id and b.owner_id = (select auth.uid()))
  );
create policy "business owners insert offers" on public.offers for insert
  to authenticated with check (
    exists (select 1 from public.businesses b
            where b.id = business_id and b.owner_id = (select auth.uid()))
  );
create policy "business owners update offers" on public.offers for update
  to authenticated
  using (
    exists (select 1 from public.businesses b
            where b.id = business_id and b.owner_id = (select auth.uid()))
  )
  with check (
    exists (select 1 from public.businesses b
            where b.id = business_id and b.owner_id = (select auth.uid()))
  );

-- ---------------------------------------------------------------------------
-- posts — published creator content. reach/likes/comments are SERVER-OWNED:
-- clients may insert only the content columns (column-level grant below), so
-- metrics always start at their defaults and only the service role updates
-- them. Prevents creators inflating the business dashboard stats.
-- ---------------------------------------------------------------------------
create table public.posts (
  id          uuid primary key default gen_random_uuid(),
  user_id     text not null,
  business_id text not null references public.businesses (id),
  platform    public.post_platform not null,
  url         text,
  caption     text,
  reach       int not null default 0,
  likes       int not null default 0,
  comments    int not null default 0,
  posted_at   timestamptz default now()
);

create index posts_user_idx     on public.posts (user_id);
create index posts_business_idx on public.posts (business_id);

alter table public.posts enable row level security;

revoke insert, update on table public.posts from anon, authenticated;
grant insert (user_id, business_id, platform, url, caption)
  on table public.posts to authenticated;

create policy "select own posts" on public.posts for select
  to authenticated using ( (select auth.uid())::text = user_id );
create policy "business owners read business posts" on public.posts for select
  to authenticated using (
    exists (select 1 from public.businesses b
            where b.id = business_id and b.owner_id = (select auth.uid()))
  );
create policy "insert own posts" on public.posts for insert
  to authenticated with check ( (select auth.uid())::text = user_id );

-- ---------------------------------------------------------------------------
-- perks — align user_id with the text id domain, link claims to offers, and
-- harden the status policies. Migration #1's policies compare uuid ids and
-- must be dropped before the column type can change.
-- ---------------------------------------------------------------------------
drop policy if exists "select own perks" on public.perks;
drop policy if exists "insert own perks" on public.perks;
drop policy if exists "redeem own approved perks" on public.perks;

alter table public.perks drop constraint if exists perks_user_id_fkey;
alter table public.perks alter column user_id type text using user_id::text;

alter table public.perks add column if not exists offer_id uuid references public.offers (id);

-- Clients may only ever touch the status column (stops user_id/business_id
-- reassignment through policy OR-fusion). The service role is unaffected.
revoke update on table public.perks from anon, authenticated;
grant update (status) on table public.perks to authenticated;

create policy "select own perks" on public.perks for select
  to authenticated using ( (select auth.uid())::text = user_id );
create policy "insert own perks" on public.perks for insert
  to authenticated with check (
    (select auth.uid())::text = user_id and status::text = 'pending'
  );
-- Creators: redeem their own approved perk — nothing else. Both sides carry
-- the identity check so this cannot fuse with the owner-approve policy below.
create policy "redeem own approved perks" on public.perks for update
  to authenticated
  using  ( (select auth.uid())::text = user_id and status::text = 'approved' )
  with check ( (select auth.uid())::text = user_id and status::text = 'redeemed' );
-- Business owners: approve posted claims on their own business.
-- (status compared as ::text so the new enum values are never used as enum
-- literals inside this transaction — see header note.)
create policy "business owners approve perks" on public.perks for update
  to authenticated
  using (
    status::text = 'posted'
    and exists (select 1 from public.businesses b
                where b.id = business_id and b.owner_id = (select auth.uid()))
  )
  with check (
    status::text = 'approved'
    and exists (select 1 from public.businesses b
                where b.id = business_id and b.owner_id = (select auth.uid()))
  );

-- ---------------------------------------------------------------------------
-- Seed: the hackathon venue (the stage-demo stop) …
-- ---------------------------------------------------------------------------
insert into public.businesses
  (id, name, category, description, walk_minutes, rating, lat, lng, narration,
   perk_title, perk_value, deliverable)
values
  ('cursor-hackathon', 'Cursor Hackathon @ INFOMOTION', 'culture',
   '60 builders, one day, fourth floor at Friedrichstraße 6. The bar opens when the demos end.',
   0, 4.9, 48.78397, 9.17796,
   'You are already here. Sixty people building at once — capture the room before the demos start.',
   'Free drink at the bar', 6, '1 photo + 1 story post')
on conflict (id) do nothing;

-- … and one live offer per perk-carrying business.
-- offers has no natural key, so guard with NOT EXISTS on (business_id, perk_title).
insert into public.offers
  (business_id, perk_title, perk_value, offer_type, deliverable,
   min_followers, slots_total, slots_remaining)
select v.business_id, v.perk_title, v.perk_value, v.offer_type::public.offer_type,
       v.deliverable, v.min_followers, v.slots_total, v.slots_total
from (values
  ('cursor-hackathon',         'Free drink at the bar', 6,  'in_kind', '1 photo + 1 story post',    0,    60),
  ('brot-roesterei',           '2 free coffees',     7,  'in_kind', '1 photo + 1 story post',    0,    20),
  ('alte-kanzlei',             'Free lunch special', 18, 'in_kind', '1 reel + tag @altekanzlei', 5000, 10),
  ('palmengarten',             'Free entry + latte', 6,  'in_kind', '1 photo',                   0,    30),
  ('markthalle',               'Tasting basket',     15, 'in_kind', '1 photo + 1 story post',    0,    15),
  ('biergarten-schlossgarten', '2 craft beers',      14, 'in_kind', '1 reel',                    0,    20)
) as v(business_id, perk_title, perk_value, offer_type, deliverable, min_followers, slots_total)
where not exists (
  select 1 from public.offers o
  where o.business_id = v.business_id and o.perk_title = v.perk_title
);
