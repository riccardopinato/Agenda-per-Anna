-- STAGING ONLY: authenticated linked-account recovery after app restart.
-- Existing private quota table, no new public endpoint or RLS grants.
-- Do not execute on production pxsxlorntswypdbeerzw.
alter table gcal_stage.oauth_request_budget
  drop constraint oauth_request_budget_action_check;
alter table gcal_stage.oauth_request_budget
  add constraint oauth_request_budget_action_check
  check (action in ('start','preview','confirm','disconnect','connections'));
