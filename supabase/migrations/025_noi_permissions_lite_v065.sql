-- v0.65 — Noi ♡ Permissions Lite.
-- Shared creative entries may opt into creator-only editing through the
-- backward-compatible payload flag ownerOnlyEdit. The existing agenda_records
-- owner_id remains the authoritative creator identity.

drop policy if exists "agenda_records_update" on public.agenda_records;
create policy "agenda_records_update"
on public.agenda_records
for update
to authenticated
using (
  (
    visibility = 'private'
    and owner_id = (select auth.uid())
  )
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
    and (
      owner_id = (select auth.uid())
      or coalesce(payload ->> 'ownerOnlyEdit', 'false') <> 'true'
    )
  )
)
with check (
  (
    visibility = 'private'
    and owner_id = (select auth.uid())
    and space_id is null
  )
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
    and (
      owner_id = (select auth.uid())
      or coalesce(payload ->> 'ownerOnlyEdit', 'false') <> 'true'
    )
  )
);

drop policy if exists "agenda_records_delete" on public.agenda_records;
create policy "agenda_records_delete"
on public.agenda_records
for delete
to authenticated
using (
  (
    visibility = 'private'
    and owner_id = (select auth.uid())
  )
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
    and (
      owner_id = (select auth.uid())
      or coalesce(payload ->> 'ownerOnlyEdit', 'false') <> 'true'
    )
  )
);

create or replace function public.merge_agenda_record(
  p_record_key text,
  p_owner_id uuid,
  p_space_id uuid,
  p_visibility text,
  p_entity_type text,
  p_entity_id text,
  p_payload jsonb,
  p_client_updated_at timestamptz,
  p_deleted_at timestamptz
)
returns boolean
language plpgsql
security invoker
set search_path = public
as $func$
declare
  v_user uuid := (select auth.uid());
  v_rows integer;
  v_existing_owner uuid;
  v_existing_payload jsonb;
  v_existing_deleted_at timestamptz;
  v_existing_updated_at timestamptz;
  v_existing_visibility text;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  select
    owner_id,
    payload,
    deleted_at,
    client_updated_at,
    visibility
  into
    v_existing_owner,
    v_existing_payload,
    v_existing_deleted_at,
    v_existing_updated_at,
    v_existing_visibility
  from public.agenda_records
  where record_key = p_record_key;

  if found then
    if v_existing_visibility = 'shared'
       and v_existing_owner is distinct from v_user
       and coalesce(v_existing_payload ->> 'ownerOnlyEdit', 'false') = 'true'
    then
      raise exception 'shared_entry_read_only';
    end if;

    if v_existing_visibility = 'shared'
       and v_existing_owner is distinct from v_user
       and coalesce(p_payload ->> 'ownerOnlyEdit', 'false') = 'true'
    then
      raise exception 'only_creator_can_lock_shared_entry';
    end if;

    if v_existing_updated_at = p_client_updated_at then
      return v_existing_payload is not distinct from p_payload
         and v_existing_deleted_at is not distinct from p_deleted_at;
    end if;
  elsif p_visibility = 'shared' and p_owner_id is distinct from v_user then
    raise exception 'shared_entry_creator_mismatch';
  end if;

  insert into public.agenda_records(
    record_key,
    owner_id,
    space_id,
    visibility,
    entity_type,
    entity_id,
    payload,
    client_updated_at,
    deleted_at
  )
  values (
    p_record_key,
    p_owner_id,
    p_space_id,
    p_visibility,
    p_entity_type,
    p_entity_id,
    p_payload,
    p_client_updated_at,
    p_deleted_at
  )
  on conflict (record_key) do update
  set
    payload = excluded.payload,
    client_updated_at = excluded.client_updated_at,
    deleted_at = excluded.deleted_at
  where excluded.client_updated_at > agenda_records.client_updated_at;

  get diagnostics v_rows = row_count;
  return v_rows > 0;
end;
$func$;

revoke all on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) from public, anon;

grant execute on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) to authenticated;
