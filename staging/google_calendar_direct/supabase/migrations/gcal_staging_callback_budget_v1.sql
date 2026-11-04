-- Anna's Diary STAGING: global minute callback quota. Staging project only.
-- The small, fixed-count table is backend-only and is NOT a substitute for
-- a trusted upstream ingress/WAF rate limit under a deliberate flood.
create table if not exists gcal_stage.oauth_callback_budget (
  scope text primary key check (scope = 'staging'),
  window_start timestamptz not null,
  request_count integer not null check (request_count > 0 and request_count < 1000000)
);
alter table gcal_stage.oauth_callback_budget enable row level security;
revoke all on gcal_stage.oauth_callback_budget from public, anon, authenticated;
-- No RLS policies: only a privileged, staging-pinned backend may access.
