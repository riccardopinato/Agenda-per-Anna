-- v0.67 — Lifecycle & Reference Integrity
--
-- Shared entries are represented by tombstoned agenda_records rows. Comments
-- and reactions intentionally have their own RLS/ownership model, so an entry
-- tombstone must cascade server-side to remove every collaborator's child rows.

create or replace function private.cleanup_shared_entry_interactions_on_tombstone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  should_cleanup boolean := false;
begin
  if new.visibility = 'shared'
     and new.entity_type = 'shared_entry'
     and new.deleted_at is not null
     and new.space_id is not null
  then
    if tg_op = 'INSERT' then
      should_cleanup := true;
    elsif tg_op = 'UPDATE' then
      should_cleanup := old.deleted_at is distinct from new.deleted_at;
    end if;
  end if;

  if should_cleanup then
    delete from public.shared_entry_comments
    where space_id = new.space_id
      and entry_id = new.entity_id;

    delete from public.shared_entry_reactions
    where space_id = new.space_id
      and entry_id = new.entity_id;
  end if;

  return new;
end;
$$;

revoke all on function private.cleanup_shared_entry_interactions_on_tombstone()
from public, anon, authenticated;

drop trigger if exists cleanup_shared_entry_interactions_on_tombstone
on public.agenda_records;

create trigger cleanup_shared_entry_interactions_on_tombstone
after insert or update of deleted_at on public.agenda_records
for each row
execute function private.cleanup_shared_entry_interactions_on_tombstone();
