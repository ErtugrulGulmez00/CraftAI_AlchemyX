-- Per-user cloud backup of discovered elements, so a real (signed-in)
-- player's progress survives a reinstall / new device.
-- Run this once in the Supabase SQL Editor.

create table public.user_progress (
  user_id uuid not null references auth.users(id),
  session_id text not null,
  element_key text not null,
  element_name text not null,
  element_emoji text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, session_id, element_key)
);

alter table public.user_progress enable row level security;

-- Only real (non-anonymous) signed-in users can read/write their own rows.
create policy "user_progress_select_own_real_user"
  on public.user_progress for select
  using (
    auth.uid() = user_id
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
  );

create policy "user_progress_upsert_own_real_user"
  on public.user_progress for insert
  with check (
    auth.uid() = user_id
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
  );

create policy "user_progress_update_own_real_user"
  on public.user_progress for update
  using (
    auth.uid() = user_id
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
  );
