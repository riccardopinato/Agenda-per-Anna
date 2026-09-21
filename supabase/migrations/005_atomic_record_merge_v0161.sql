-- v0.16.1: atomically reject stale client writes.
-- Record identity/scope remain immutable after creation.

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
begin
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
  where excluded.client_updated_at >= agenda_records.client_updated_at;

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
