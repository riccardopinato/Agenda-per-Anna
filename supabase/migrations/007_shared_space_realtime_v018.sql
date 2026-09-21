-- v0.18 Shared Space 2.0: enable Postgres Changes realtime for shared records.
-- The table already has RLS; Realtime will honor the same SELECT policy.

do $$
begin
  if not exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) then
    create publication supabase_realtime;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'agenda_records'
  ) then
    alter publication supabase_realtime add table public.agenda_records;
  end if;
end
$$;

create index if not exists agenda_records_shared_revision_idx
  on public.agenda_records(space_id, client_updated_at desc)
  where visibility = 'shared';
