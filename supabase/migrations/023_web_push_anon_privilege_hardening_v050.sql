-- v0.50 Security & Production Hardening
--
-- Web Push records are account-scoped. Client RLS policies exist only for
-- authenticated users and privileged delivery uses the service role, so anon
-- does not need direct table privileges.

revoke all privileges on table public.web_push_reminders from anon;
revoke all privileges on table public.web_push_subscriptions from anon;
