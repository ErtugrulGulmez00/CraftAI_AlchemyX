-- Hardening for the craft pipeline (July 2026 security audit).
-- Run this once in the Supabase SQL Editor AFTER deploying the v2
-- craft-element edge function (which now does all combination writes
-- itself with the service role).

-- ── 1. Per-user rate limit counter for craft-element ───────────────────────
-- One row per (user, minute); the edge function bumps it atomically and
-- rejects the request when the count passes its cap. Old rows are cleaned
-- opportunistically on each call so the table never grows.

create table if not exists public.craft_rate_limits (
  user_id uuid not null,
  minute timestamptz not null,
  hits integer not null default 1,
  primary key (user_id, minute)
);

alter table public.craft_rate_limits enable row level security;
-- No policies on purpose: only the service role (which bypasses RLS)
-- ever touches this table.

create or replace function public.bump_craft_rate(p_user uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_minute timestamptz := date_trunc('minute', now());
  v_hits integer;
begin
  insert into craft_rate_limits (user_id, minute, hits)
  values (p_user, v_minute, 1)
  on conflict (user_id, minute)
  do update set hits = craft_rate_limits.hits + 1
  returning hits into v_hits;

  -- Opportunistic cleanup of anything older than 10 minutes.
  delete from craft_rate_limits where minute < now() - interval '10 minutes';

  return v_hits;
end $$;

-- ── 2. Close the data-poisoning hole ───────────────────────────────────────
-- Drop every client INSERT policy on the per-language combination tables.
-- The v2 edge function writes with the service role (bypasses RLS), so
-- after this only the server can create combination rows. SELECT policies
-- are left untouched (stage-2 lookups still read directly).

do $$
declare r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('combinations', 'v2_combinations', 'de_combinations',
                        'es_combinations', 'pt_combinations')
      and cmd = 'INSERT'
  loop
    execute format('drop policy %I on %I.%I',
                   r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

-- ── 3. Let players delete their own cloud backup ───────────────────────────
-- Used when resetting a world (and by account deletion), so a wiped world
-- doesn't resurrect from user_progress on the next sign-in.

create policy "user_progress_delete_own_real_user"
  on public.user_progress for delete
  using (
    auth.uid() = user_id
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
  );
