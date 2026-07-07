-- "Community suggestion" table (English + Turkish): signed-in users propose
-- "Element A + Element B = suggested result" for whichever language they're
-- currently playing in, the admin reviews and approves them, and approval
-- overrides the result for that pair in the matching per-language
-- combinations table (see SupabaseService._tableFor / combinationKey).
-- Run this once in the Supabase SQL Editor.

create table public.combination_suggestions (
  id uuid primary key default gen_random_uuid(),
  element_a text not null,
  element_b text not null,
  suggested_name text not null,
  suggested_emoji text not null,
  suggested_by uuid not null references auth.users(id),
  suggested_by_name text not null,
  status text not null default 'pending', -- 'pending' | 'approved' | 'rejected'
  -- GameLanguage.code: 'en' | 'tr2' | 'de' | 'es' | 'pt'.
  language text not null default 'tr2',
  created_at timestamptz not null default now()
);

-- Migration for a table created before `language` support was added. Run
-- this instead of the `create table` above if the table already exists.
--
-- alter table public.combination_suggestions add column language text not null default 'tr2';

alter table public.combination_suggestions enable row level security;

-- Real (non-anonymous) signed-in users can submit their own suggestions.
create policy "combination_suggestions_insert_own_real_user"
  on public.combination_suggestions for insert
  with check (
    auth.uid() = suggested_by
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
  );

-- Users see their own suggestions; the admin sees everything.
create policy "combination_suggestions_select_own_or_admin"
  on public.combination_suggestions for select
  using (auth.uid() = suggested_by or auth.uid() = 'edabc320-2a65-453d-bdb5-343758d00a33'::uuid);

-- Only the admin can update status (approve/reject).
create policy "combination_suggestions_update_admin_only"
  on public.combination_suggestions for update
  using (auth.uid() = 'edabc320-2a65-453d-bdb5-343758d00a33'::uuid);

-- Lets the admin override/insert a result in `combinations` (English) when
-- approving a suggestion. The existing insert policy already allows any
-- authenticated user to insert; this adds the UPDATE half needed for
-- upsert-on-conflict.
create policy "combinations_admin_override"
  on public.combinations for update
  using (auth.uid() = 'edabc320-2a65-453d-bdb5-343758d00a33'::uuid);

-- Same, but for `v2_combinations` — the live Turkish table (GameLanguage
-- .turkishV2). Without this, approving a Turkish suggestion would silently
-- fail to update an existing row.
create policy "v2_combinations_admin_override"
  on public.v2_combinations for update
  using (auth.uid() = 'edabc320-2a65-453d-bdb5-343758d00a33'::uuid);
