-- Staging-only migration already applied to Supabase pdanpljacyozslrutsor.
-- DO NOT apply to production Supabase pxsxlorntswypdbeerzw.
create table if not exists gcal_stage.oauth_completions (
  handle_hash text primary key check (handle_hash ~ '^[0-9a-f]{64}$'),
  app_account_hash text not null check (app_account_hash ~ '^[0-9a-f]{64}$'),
  envelope jsonb not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists gcal_stage_completion_expiry
 on gcal_stage.oauth_completions (expires_at);
alter table gcal_stage.oauth_completions enable row level security;
revoke all on gcal_stage.oauth_completions from public, anon, authenticated;
grant select, insert, update, delete on gcal_stage.oauth_completions to service_role;
-- Zero RLS policies intentional: only backend privileged role accesses
-- short-lived encrypted Google consent transactions.
