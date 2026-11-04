-- STAGING ONLY: bounded read-only calendar inventory after user-authorized OAuth.
-- Production Supabase must never receive this migration.
alter table gcal_stage.oauth_request_budget
  drop constraint oauth_request_budget_action_check;
alter table gcal_stage.oauth_request_budget
  add constraint oauth_request_budget_action_check
  check (action in ('start','preview','confirm','disconnect','connections','calendars'));
