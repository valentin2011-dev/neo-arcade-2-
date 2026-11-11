-- NEO ARCADE V2 — Supabase schema
-- Run this file in Supabase SQL Editor. Never put the service_role key in the browser.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username = lower(username) and username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null default '',
  avatar_id integer not null default 1 check (avatar_id between 1 and 10),
  theme_id integer not null default 1 check (theme_id between 1 and 10),
  rgb_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

-- Remove this unused field if an earlier draft of the schema created it.
-- Profiles are publicly readable, so private contact details must not live here.
alter table public.profiles drop column if exists recovery_email;

create table if not exists public.player_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  xp integer not null default 0 check (xp >= 0),
  games_played integer not null default 0 check (games_played >= 0),
  bests jsonb not null default '{"reaction":null,"memory":null,"rush":null,"snake":null,"aim":null}'::jsonb,
  wins jsonb not null default '{}'::jsonb,
  achievements jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.game_scores (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  game text not null check (game in ('reaction','memory','rush','snake','aim')),
  score numeric not null check (score >= 0),
  created_at timestamptz not null default now()
);

create index if not exists game_scores_game_score_idx on public.game_scores(game, score);
create index if not exists game_scores_user_created_idx on public.game_scores(user_id, created_at desc);

create table if not exists public.battles (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  guest_id uuid references auth.users(id) on delete set null,
  game text not null default 'reaction' check (game in ('reaction')),
  status text not null default 'waiting' check (status in ('waiting','active','completed','cancelled')),
  host_score numeric,
  guest_score numeric,
  winner_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.profiles enable row level security;
alter table public.player_progress enable row level security;
alter table public.game_scores enable row level security;
alter table public.battles enable row level security;

drop policy if exists "Profiles are visible to everyone" on public.profiles;
create policy "Profiles are visible to everyone" on public.profiles for select using (true);
drop policy if exists "Players can create their profile" on public.profiles;
create policy "Players can create their profile" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "Players can update their profile" on public.profiles;
create policy "Players can update their profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Progress is private to its owner" on public.player_progress;
create policy "Progress is private to its owner" on public.player_progress for select using (auth.uid() = user_id);
drop policy if exists "Players can create their progress" on public.player_progress;
create policy "Players can create their progress" on public.player_progress for insert with check (auth.uid() = user_id);
drop policy if exists "Players can update their progress" on public.player_progress;
create policy "Players can update their progress" on public.player_progress for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Scores are public" on public.game_scores;
create policy "Scores are public" on public.game_scores for select using (true);
drop policy if exists "Players can submit their own scores" on public.game_scores;
create policy "Players can submit their own scores" on public.game_scores for insert with check (auth.uid() = user_id);

drop policy if exists "Battle participants can view battles" on public.battles;
create policy "Battle participants can view battles" on public.battles for select using (auth.uid() = host_id or auth.uid() = guest_id);
drop policy if exists "Players can create battles" on public.battles;
create policy "Players can create battles" on public.battles for insert with check (auth.uid() = host_id);
drop policy if exists "Participants can update battles" on public.battles;
create policy "Participants can update battles" on public.battles for update using (auth.uid() = host_id or auth.uid() = guest_id) with check (auth.uid() = host_id or auth.uid() = guest_id);

-- Create a private profile and progress row automatically after signup.
-- The app must pass { username: "<lowercase_handle>" } in signup user metadata.
create or replace function public.handle_new_neo_arcade_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_username text;
begin
  chosen_username := lower(coalesce(new.raw_user_meta_data ->> 'username', ''));

  if chosen_username !~ '^[a-z0-9_]{3,20}$' then
    raise exception 'Invalid NEO ARCADE username';
  end if;

  insert into public.profiles (id, username, display_name)
  values (new.id, chosen_username, chosen_username);

  insert into public.player_progress (user_id)
  values (new.id);

  return new;
end;
$$;

drop trigger if exists on_neo_arcade_user_created on auth.users;
create trigger on_neo_arcade_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_neo_arcade_user();

-- Enable Realtime for online duels, only if not already published.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'battles'
  ) then
    alter publication supabase_realtime add table public.battles;
  end if;
end $$;
