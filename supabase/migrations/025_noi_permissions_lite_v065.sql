-- v0.65 — Noi ♡ Permissions Lite.
-- Shared creative memories stay collaborative by default. When a memory is
-- marked read-only for other members, server-side triggers protect edits and
-- deletes even if a client bypasses the Flutter UI/RPC helper.

create or replace function private.guard_shared_entry_edit_permissions()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_old_restricted boolean := false;
  v_old_owner text := '';
  v_new_restricted boolean := false;
  v_new_owner text := '';
begin
  -- Trusted server/database maintenance is not a user edit.
  if v_user is null then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_op <> 'INSERT' then
    if old.visibility = 'shared'
       and old.entity_type = 'shared_entry'
       and old.deleted_at is null then
      v_old_restricted :=
        coalesce((old.payload ->> 'membersCanEdit')::boolean, true) = false;
      v_old_owner := coalesce(old.payload ->> 'editOwnerId', '');

      if v_old_restricted
         and v_old_owner <> ''
         and v_old_owner <> v_user::text then
        raise exception 'shared_entry_read_only';
      end if;
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  if new.visibility = 'shared'
     and new.entity_type = 'shared_entry'
     and new.deleted_at is null
     and new.payload is not null then
    v_new_restricted :=
      coalesce((new.payload ->> 'membersCanEdit')::boolean, true) = false;
    v_new_owner := coalesce(new.payload ->> 'editOwnerId', '');

    -- Any explicit owner must be stable once established. Legacy rows without
    -- an owner may acquire one when a current member edits them.
    if tg_op = 'UPDATE'
       and coalesce(old.payload ->> 'editOwnerId', '') <> ''
       and v_new_owner is distinct from coalesce(old.payload ->> 'editOwnerId', '') then
      raise exception 'shared_entry_edit_owner_immutable';
    end if;

    if v_new_owner <> ''
       and tg_op = 'INSERT'
       and v_new_owner <> v_user::text then
      raise exception 'invalid_shared_entry_edit_owner';
    end if;

    if tg_op = 'UPDATE'
       and coalesce(old.payload ->> 'editOwnerId', '') = ''
       and v_new_owner <> ''
       and v_new_owner <> v_user::text then
      raise exception 'invalid_shared_entry_edit_owner';
    end if;

    if v_new_restricted then
      if v_new_owner = '' or v_new_owner <> v_user::text then
        raise exception 'shared_entry_read_only_requires_owner';
      end if;
    end if;
  end if;

  return new;
end;
$func$;

revoke all on function private.guard_shared_entry_edit_permissions() from public, anon;
grant execute on function private.guard_shared_entry_edit_permissions() to authenticated;

drop trigger if exists agenda_records_shared_entry_permissions
on public.agenda_records;

create trigger agenda_records_shared_entry_permissions
before insert or update or delete on public.agenda_records
for each row
execute function private.guard_shared_entry_edit_permissions();
