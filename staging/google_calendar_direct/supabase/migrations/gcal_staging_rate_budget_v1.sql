-- SOURCE ONLY. Apply to isolated anna-calendar-staging after review and
-- before any live OAuth handler deployment. Never apply to production.
create table if not exists gcal_stage.oauth_request_budget (
  app_account_hash text not null check(app_account_hash ~ '^[a-f0-9]{64}$'),
  action text not null check(action in ('start','preview','confirm','disconnect')),
  window_start timestamptz not null,
  request_count integer not null check(request_count > 0 and request_count < 1000000),
  primary key(app_account_hash, action)
);
alter table gcal_stage.oauth_request_budget enable row level security;
revoke all on gcal_stage.oauth_request_budget from public, anon, authenticated;
-- Intentionally no RLS policies: privileged staging backend only.
-- Callback floods require separate trusted-edge ingress protection; this
-- table rate-limits only operations after verified production app identity.
