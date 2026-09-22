-- v0.30.1 - tighten Data API privileges, protect shared record identity,
-- support heart upserts, and automatically clean interactions on delete.

revoke all privileges on table public.agenda_records from anon, authenticated;
revoke all privileges on table public.shared_spaces from anon, authenticated;
revoke all privileges on table public.space_members from anon, authenticated;
revoke all privileges on table public.space_invites from anon, authenticated;
revoke all privileges on table public.push_devices from anon, authenticated;
revoke all privileges on table public.push_delivery_events from anon, authenticated;
revoke all privileges on table public.shared_entry_comments from anon, authenticated;
revoke all privileges on table public.shared_entry_reactions from anon, authenticated;
revoke all privileges on table public.space_member_reads from anon, authenticated;

grant select, insert, update, delete on table public.agenda_records to authenticated;
grant select on table public.shared_spaces to authenticated;
grant select on table public.space_members to authenticated;
grant select, insert, update, delete on table public.push_devices to authenticated;
grant select, insert, update, delete on table public.shared_entry_comments to authenticated;
grant select, insert, update, delete on table public.shared_entry_reactions to authenticated;
grant select, insert, update on table public.space_member_reads to authenticated;

revoke execute on function public.create_shared_space(text) from public, anon;
revoke execute on function public.create_space_invite(uuid) from public, anon;
revoke execute on function public.join_shared_space(text) from public, anon;
revoke execute on function public.leave_shared_space(uuid) from public, anon;
revoke execute on function public.delete_shared_space(uuid) from public, anon;
revoke execute on function public.merge_agenda_record(text,uuid,uuid,text,text,text,jsonb,timestamptz,timestamptz) from public, anon;

grant execute on function public.create_shared_space(text) to authenticated;
grant execute on function public.create_space_invite(uuid) to authenticated;
grant execute on function public.join_shared_space(text) to authenticated;
grant execute on function public.leave_shared_space(uuid) to authenticated;
grant execute on function public.delete_shared_space(uuid) to authenticated;
grant execute on function public.merge_agenda_record(text,uuid,uuid,text,text,text,jsonb,timestamptz,timestamptz) to authenticated;

drop policy if exists shared_entry_reactions_update_own
on public.shared_entry_reactions;
create policy shared_entry_reactions_update_own
on public.shared_entry_reactions
for update
to authenticated
using (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
)
with check (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

create or replace function private.guard_agenda_record_identity()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.record_key is distinct from old.record_key
     or new.owner_id is distinct from old.owner_id
     or new.space_id is distinct from old.space_id
     or new.visibility is distinct from old.visibility
     or new.entity_type is distinct from old.entity_type
     or new.entity_id is distinct from old.entity_id then
    raise exception 'agenda_record_identity_is_immutable';
  end if;
  return new;
end;
$$;

drop trigger if exists agenda_records_guard_identity
on public.agenda_records;
create trigger agenda_records_guard_identity
before update on public.agenda_records
for each row
execute function private.guard_agenda_record_identity();

create or replace function private.cleanup_shared_entry_interactions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.visibility = 'shared'
     and old.entity_type = 'shared_entry'
     and (
       tg_op = 'DELETE'
       or (
         tg_op = 'UPDATE'
         and new.deleted_at is not null
         and old.deleted_at is distinct from new.deleted_at
       )
     ) then
    delete from public.shared_entry_comments
    where space_id = old.space_id
      and entry_id = old.entity_id;

    delete from public.shared_entry_reactions
    where space_id = old.space_id
      and entry_id = old.entity_id;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists agenda_records_cleanup_interactions
on public.agenda_records;
create trigger agenda_records_cleanup_interactions
after update of deleted_at or delete on public.agenda_records
for each row
execute function private.cleanup_shared_entry_interactions();
