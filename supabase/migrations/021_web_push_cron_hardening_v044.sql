update public.web_push_config
set cron_token = encode(gen_random_bytes(32), 'hex')
where cron_token is null or cron_token = '';

alter table public.web_push_config
  alter column cron_token set not null;

revoke all on public.web_push_config from anon, authenticated;
grant select, insert, update on public.web_push_config to service_role;

revoke all on function public.invoke_annas_diary_web_push_reminders()
  from public, anon, authenticated;
