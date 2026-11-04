-- Anna's Diary staging only. No Google events are persisted in this database.
-- Add quota for authenticated, owner-calendar GET-only event previews.
alter table gcal_stage.oauth_request_budget
  drop constraint oauth_request_budget_action_check;
alter table gcal_stage.oauth_request_budget
  add constraint oauth_request_budget_action_check
  check (action in (
    'start','preview','confirm','disconnect','connections','calendars','events'
  ));
