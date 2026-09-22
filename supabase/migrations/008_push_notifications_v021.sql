create table if not exists public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  app_version text,
  updated_at timestamptz not null default now()
);

create index if not exists push_devices_user_id_idx
  on public.push_devices(user_id);

alter table public.push_devices enable row level security;

drop policy if exists "push_devices_select_own" on public.push_devices;
create policy "push_devices_select_own"
  on public.push_devices
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "push_devices_insert_own" on public.push_devices;
create policy "push_devices_insert_own"
  on public.push_devices
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "push_devices_update_own" on public.push_devices;
create policy "push_devices_update_own"
  on public.push_devices
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "push_devices_delete_own" on public.push_devices;
create policy "push_devices_delete_own"
  on public.push_devices
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.push_devices to authenticated;

create table if not exists public.push_delivery_events (
  event_id text primary key,
  space_id uuid not null references public.shared_spaces(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists push_delivery_events_created_at_idx
  on public.push_delivery_events(created_at);

alter table public.push_delivery_events enable row level security;

revoke all on public.push_delivery_events from anon, authenticated;
