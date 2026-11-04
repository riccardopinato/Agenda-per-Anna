-- STAGING ONLY: applied to Supabase anna-calendar-staging ref pdanpljacyozslrutsor.
-- Never run this against agenda-per-anna production ref pxsxlorntswypdbeerzw.
-- Both tables live outside the PostgREST exposed public schema.
create schema if not exists gcal_stage;
revoke all on schema gcal_stage from public, anon, authenticated;
grant usage on schema gcal_stage to service_role;

create table if not exists gcal_stage.oauth_pending (
  state_hash text primary key check (state_hash ~ '^[0-9a-f]{64}$'),
  envelope jsonb not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists gcal_stage_pending_expiry
  on gcal_stage.oauth_pending (expires_at);

create table if not exists gcal_stage.oauth_links (
  app_account_hash text not null check (app_account_hash ~ '^[0-9a-f]{64}$'),
  google_subject_hash text not null check (google_subject_hash ~ '^[0-9a-f]{64}$'),
  envelope jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (app_account_hash, google_subject_hash)
);
alter table gcal_stage.oauth_pending enable row level security;
alter table gcal_stage.oauth_links enable row level security;
revoke all on all tables in schema gcal_stage from public, anon, authenticated;
grant select, insert, update, delete on all tables in schema gcal_stage to service_role;
-- Intentionally no policies: anon/authenticated must not read/write tokens.
-- Only trusted backend may use privileged connection and atomic DELETE RETURNING.
