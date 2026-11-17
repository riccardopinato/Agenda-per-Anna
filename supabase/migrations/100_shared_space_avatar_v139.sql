-- Owner-managed photo for an existing Noi shared space.
-- Apply before shipping a client that selects shared_spaces.avatar_path.
-- Media stays inside the existing private bucket and can be downloaded
-- only by current members. No changes to space identifiers or invitations.
alter table public.shared_spaces
  add column if not exists avatar_path text not null default '';

-- Preserve deterministic media permissions for existing diary photos while
-- reserving /__space_avatar/ exclusively for the space owner.
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
  if v_user is null or array_length(v_parts, 1) < 2 then
    return false;
  end if;
  begin
    v_space := v_parts[1]::uuid;
  exception when others then
    return false;
  end;
  v_entry_id := v_parts[2];

  if v_entry_id = '__space_avatar' then
    -- Prevent other members from uploading/updating/deleting the picture.
    if array_length(v_parts, 1) <> 2 or
       p_name !~ ('^' || v_space::text ||
         '/__space_avatar/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]jpg$') then
      return false;
    end if;
    return exists (
      select 1 from public.shared_spaces
      where id = v_space and owner_id = v_user
    );
  end if;

  if not private.is_space_member(v_space) then
    return false;
  end if;
  select ar.payload into v_payload
  from public.agenda_records ar
  where ar.space_id = v_space
    and ar.visibility = 'shared'
    and ar.entity_type = 'shared_entry'
    and ar.entity_id = v_entry_id
    and ar.deleted_at is null
  order by ar.client_updated_at desc
  limit 1;
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

create or replace function private.set_shared_space_avatar_impl(
  p_space_id uuid, p_avatar_path text
)
returns text
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_path text := btrim(coalesce(p_avatar_path, ''));
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;
  select owner_id into v_owner
  from public.shared_spaces
  where id = p_space_id
  for update;
  if v_owner is null then
    raise exception 'shared_space_not_found';
  end if;
  if v_owner is distinct from v_user then
    raise exception 'only_owner_can_update_space_avatar';
  end if;
  if v_path <> '' and v_path !~
    ('^' || p_space_id::text ||
    '/__space_avatar/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]jpg$') then
    raise exception 'invalid_shared_space_avatar_path';
  end if;
  update public.shared_spaces
  set avatar_path = v_path
  where id = p_space_id;
  return v_path;
end;
$func$;

create or replace function public.set_shared_space_avatar(
  p_space_id uuid, p_avatar_path text
)
returns text
language sql
security invoker
set search_path = ''
as $func$
  select private.set_shared_space_avatar_impl(p_space_id, p_avatar_path);
$func$;

revoke all on function private.set_shared_space_avatar_impl(uuid, text)
  from public, anon;
revoke all on function public.set_shared_space_avatar(uuid, text)
  from public, anon;
grant execute on function private.set_shared_space_avatar_impl(uuid, text)
  to authenticated;
grant execute on function public.set_shared_space_avatar(uuid, text)
  to authenticated;
