create extension if not exists pgcrypto;
create extension if not exists pg_net;
create extension if not exists pg_cron;

alter table public.web_push_config
  add column if not exists cron_token text;

update public.web_push_config
set cron_token = encode(gen_random_bytes(32), 'hex')
where cron_token is null or cron_token = '';

alter table public.web_push_config
  alter column cron_token set default encode(gen_random_bytes(32), 'hex');

create table if not exists public.web_push_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  stable_id text not null,
  title text not null,
  body text not null,
  scheduled_at timestamptz not null,
  status text not null default 'pending'
    check (status in ('pending', 'delivered', 'failed', 'no_subscription')),
  attempts integer not null default 0,
  last_error text,
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, stable_id)
);

create index if not exists web_push_reminders_due_idx
  on public.web_push_reminders(status, scheduled_at)
  where status = 'pending';

alter table public.web_push_reminders enable row level security;

drop policy if exists "web_push_reminders_select_own"
  on public.web_push_reminders;
create policy "web_push_reminders_select_own"
  on public.web_push_reminders
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "web_push_reminders_insert_own"
  on public.web_push_reminders;
create policy "web_push_reminders_insert_own"
  on public.web_push_reminders
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "web_push_reminders_update_own"
  on public.web_push_reminders;
create policy "web_push_reminders_update_own"
  on public.web_push_reminders
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "web_push_reminders_delete_own"
  on public.web_push_reminders;
create policy "web_push_reminders_delete_own"
  on public.web_push_reminders
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete
  on public.web_push_reminders
  to authenticated;

create or replace function public.invoke_annas_diary_web_push_reminders()
returns void
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  token text;
begin
  select cron_token
  into token
  from public.web_push_config
  where id = 'default';

  if token is null or token = '' then
    return;
  end if;

  perform net.http_post(
    url := 'https://pxsxlorntswypdbeerzw.supabase.co/functions/v1/send-shared-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-token', token
    ),
    body := '{"action":"send_due_web_reminders"}'::jsonb,
    timeout_milliseconds := 20000
  );
end;
$$;

revoke all on function public.invoke_annas_diary_web_push_reminders()
  from public, anon, authenticated;

do $$
declare
  existing_job bigint;
begin
  for existing_job in
    select jobid
    from cron.job
    where jobname = 'annas-diary-web-push-reminders'
  loop
    perform cron.unschedule(existing_job);
  end loop;
end
$$;

select cron.schedule(
  'annas-diary-web-push-reminders',
  '* * * * *',
  'select public.invoke_annas_diary_web_push_reminders();'
);
