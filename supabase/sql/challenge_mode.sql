-- Challenge Mode leaderboard table.
-- Run this once in the Supabase SQL Editor.

create table public.challenge_results (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null,
  user_id uuid not null references auth.users(id),
  display_name text not null,
  seconds integer not null,
  created_at timestamptz not null default now(),
  -- GameLanguage.code: 'en' | 'tr2' | 'de' | 'es' | 'pt' — each language is
  -- a separate "parallel game" with its own leaderboard per day.
  language text not null default 'en',
  unique (challenge_date, user_id, language)
);

alter table public.challenge_results enable row level security;

-- Anyone can read the leaderboard.
create policy "challenge_results_select_all"
  on public.challenge_results for select
  using (true);

-- Only real (non-anonymous) signed-in users can submit their own result
-- for today's date.
create policy "challenge_results_insert_own_real_user"
  on public.challenge_results for insert
  with check (
    auth.uid() = user_id
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    and challenge_date = current_date
  );

-- Migration for an existing table created before `language` support was
-- added. Run this instead of the `create table` above if
-- `public.challenge_results` already exists.
--
-- alter table public.challenge_results add column language text not null default 'en';
-- alter table public.challenge_results drop constraint challenge_results_challenge_date_user_id_key;
-- alter table public.challenge_results add constraint challenge_results_challenge_date_user_id_language_key
--   unique (challenge_date, user_id, language);
