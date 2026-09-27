-- v0.65 — extend Permissions Lite to deterministic shared-photo objects.
-- Reading remains available to every space member. Mutating an existing media
-- object follows the same membersCanEdit/editOwnerId contract as its entry.

create or replace function private.can_edit_shared_media_object(p_name text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_parts text[] := storage.foldername(p_name);
  v_space uuid;
  v_entry_id text;
  v_payload jsonb;
  v_restricted boolean := false;
  v_owner text := '';
begin
  if v_user is null then
    return true;
  end if;

  if array_length(v_parts, 1) < 2 then
    return false;
  end if;

  begin
    v_space := v_parts[1]::uuid;
  exception when others then
    return false;
  end;
  v_entry_id := v_parts[2];

  if not private.is_space_member(v_space) then
    return false;
  end if;

  select ar.payload
    into v_payload
  from public.agenda_records ar
  where ar.space_id = v_space
    and ar.visibility = 'shared'
    and ar.entity_type = 'shared_entry'
    and ar.entity_id = v_entry_id
    and ar.deleted_at is null
  order by ar.client_updated_at desc
  limit 1;

  -- New photo uploads happen before the matching shared_entry is queued.
  if not found or v_payload is null then
    return true;
  end if;

  v_restricted :=
    coalesce((v_payload ->> 'membersCanEdit')::boolean, true) = false;
  v_owner := coalesce(v_payload ->> 'editOwnerId', '');

  return not v_restricted or v_owner = '' or v_owner = v_user::text;
end;
$func$;

revoke all on function private.can_edit_shared_media_object(text)
from public, anon;
grant execute on function private.can_edit_shared_media_object(text)
to authenticated;

drop policy if exists shared_media_insert_members on storage.objects;
create policy shared_media_insert_members
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'shared-media'
  and private.can_edit_shared_media_object(name)
);

drop policy if exists shared_media_update_members on storage.objects;
create policy shared_media_update_members
on storage.objects
for update
to authenticated
using (
  bucket_id = 'shared-media'
  and private.can_edit_shared_media_object(name)
)
with check (
  bucket_id = 'shared-media'
  and private.can_edit_shared_media_object(name)
);

drop policy if exists shared_media_delete_members on storage.objects;
create policy shared_media_delete_members
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'shared-media'
  and private.can_edit_shared_media_object(name)
);
