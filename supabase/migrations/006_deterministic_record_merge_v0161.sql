-- v0.16.1 follow-up: equal timestamps are idempotent, never a reason
-- to overwrite an already persisted revision from another client.

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
  v_rows integer;
  v_existing_payload jsonb;
  v_existing_deleted_at timestamptz;
  v_existing_updated_at timestamptz;
begin
  select payload, deleted_at, client_updated_at
    into v_existing_payload, v_existing_deleted_at, v_existing_updated_at
  from public.agenda_records
  where record_key = p_record_key;

  if found and v_existing_updated_at = p_client_updated_at then
    return v_existing_payload is not distinct from p_payload
       and v_existing_deleted_at is not distinct from p_deleted_at;
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
) from public;

grant execute on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) to authenticated;
