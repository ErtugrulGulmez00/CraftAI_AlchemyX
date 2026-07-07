-- Server-side Challenge Mode timing (July 2026 security audit).
-- Run this once in the Supabase SQL Editor.
--
-- Before: the client measured its own elapsed time and inserted `seconds`
-- directly into challenge_results — trivially spoofable. Now the server
-- records when a player STARTS today's challenge (challenge_runs) and
-- computes the elapsed seconds itself when they finish (finish_challenge),
-- also taking the display name from the auth record instead of the client.

-- ── 1. Start-of-run table ───────────────────────────────────────────────────

create table if not exists public.challenge_runs (
  user_id uuid not null references auth.users(id),
  challenge_date date not null,
  language text not null default 'en',
  started_at timestamptz not null default now(),
  primary key (user_id, challenge_date, language)
);

alter table public.challenge_runs enable row level security;

-- A real user can register their own start for today. No UPDATE policy on
-- purpose: the first start of the day is final (restarting the app doesn't
-- reset the clock — same behaviour the local timer already had).
create policy "challenge_runs_insert_own_real_user"
  on public.challenge_runs for insert
  with check (
    auth.uid() = user_id
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    and challenge_date = current_date
  );

create policy "challenge_runs_select_own"
  on public.challenge_runs for select
  using (auth.uid() = user_id);

-- ── 2. Server-computed finish ───────────────────────────────────────────────

create or replace function public.finish_challenge(p_date date, p_language text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_started timestamptz;
  v_seconds integer;
  v_name text;
begin
  if v_user is null
     or coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
    raise exception 'sign-in required';
  end if;
  if p_date <> current_date then
    raise exception 'challenge date must be today';
  end if;

  select started_at into v_started
  from challenge_runs
  where user_id = v_user and challenge_date = p_date and language = p_language;
  if v_started is null then
    raise exception 'no run started for today';
  end if;

  v_seconds := greatest(1, ceil(extract(epoch from (now() - v_started)))::integer);

  select coalesce(
    raw_user_meta_data ->> 'full_name',
    raw_user_meta_data ->> 'name',
    email,
    'Player'
  ) into v_name
  from auth.users where id = v_user;

  insert into challenge_results
    (challenge_date, user_id, display_name, seconds, language)
  values (p_date, v_user, v_name, v_seconds, p_language)
  on conflict (challenge_date, user_id, language) do nothing;

  return v_seconds;
end $$;

-- ── 3. Close the direct-insert hole ─────────────────────────────────────────
-- Results now only enter through finish_challenge (security definer), so
-- drop the old client INSERT policy on challenge_results.

do $$
declare r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'challenge_results'
      and cmd = 'INSERT'
  loop
    execute format('drop policy %I on %I.%I',
                   r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;
