drop policy if exists "web_push_config_deny_clients"
  on public.web_push_config;

create policy "web_push_config_deny_clients"
  on public.web_push_config
  for all
  to anon, authenticated
  using (false)
  with check (false);

revoke all on public.web_push_config from anon, authenticated;
grant select, insert, update on public.web_push_config to service_role;
