create table if not exists public.web_push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  user_agent text,
  app_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists web_push_subscriptions_user_id_idx
  on public.web_push_subscriptions(user_id);

create index if not exists web_push_subscriptions_updated_at_idx
  on public.web_push_subscriptions(updated_at desc);

alter table public.web_push_subscriptions enable row level security;

drop policy if exists "web_push_subscriptions_select_own"
  on public.web_push_subscriptions;
create policy "web_push_subscriptions_select_own"
  on public.web_push_subscriptions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "web_push_subscriptions_insert_own"
  on public.web_push_subscriptions;
create policy "web_push_subscriptions_insert_own"
  on public.web_push_subscriptions
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "web_push_subscriptions_update_own"
  on public.web_push_subscriptions;
create policy "web_push_subscriptions_update_own"
  on public.web_push_subscriptions
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "web_push_subscriptions_delete_own"
  on public.web_push_subscriptions;
create policy "web_push_subscriptions_delete_own"
  on public.web_push_subscriptions
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete
  on public.web_push_subscriptions
  to authenticated;

create table if not exists public.web_push_config (
  id text primary key,
  public_key text not null,
  private_key text not null,
  subject text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.web_push_config enable row level security;
revoke all on public.web_push_config from anon, authenticated;
grant select, insert, update on public.web_push_config to service_role;

alter table public.push_delivery_events
  add column if not exists fcm_device_count integer not null default 0,
  add column if not exists web_subscription_count integer not null default 0,
  add column if not exists fcm_delivered_count integer not null default 0,
  add column if not exists web_delivered_count integer not null default 0;
