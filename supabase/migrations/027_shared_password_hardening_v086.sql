-- v0.86 — Shared Password Security & Concurrency Hardening.
-- Keeps encrypted credential payloads in agenda_records while making key
-- initialization atomic and credential mutations revision-safe.

create index if not exists agenda_records_shared_password_lookup_idx
on public.agenda_records(space_id, entity_type, entity_id, client_updated_at)
where visibility = 'shared'
  and entity_type in (
    'shared_credential',
    'shared_password_key_meta',
    'shared_password_key_envelope'
  );

-- Protected password entities stay readable to current space members, but
-- every mutation is forced through the dedicated SECURITY DEFINER RPC contract.
create or replace function private.is_shared_password_record_type(
  p_entity_type text
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $func$
  select p_entity_type in (
    'shared_credential',
    'shared_password_key_meta',
    'shared_password_key_envelope'
  );
$func$;

revoke all on function private.is_shared_password_record_type(text)
from public, anon;
grant execute on function private.is_shared_password_record_type(text)
to authenticated;

-- Migration/backfill operations do not carry an end-user JWT. Preserve the
-- previous audit attribution instead of overwriting updated_by with NULL.
create or replace function private.set_agenda_record_audit()
returns trigger
language plpgsql
security invoker
set search_path = public, auth
as $func$
declare
  v_user uuid := (select auth.uid());
begin
  if tg_op = 'INSERT' then
    if v_user is not null then
      new.updated_by := v_user;
    end if;
  else
    new.owner_id := old.owner_id;
    new.updated_by := coalesce(v_user, old.updated_by);
  end if;
  return new;
end;
$func$;

drop policy if exists "agenda_records_insert" on public.agenda_records;
create policy "agenda_records_insert"
on public.agenda_records
for insert
to authenticated
with check (
  (
    visibility = 'private'
    and owner_id = (select auth.uid())
    and space_id is null
  )
  or
  (
    visibility = 'shared'
    and owner_id = (select auth.uid())
    and private.is_space_member(agenda_records.space_id)
    and not private.is_shared_password_record_type(entity_type)
  )
);

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
    and not private.is_shared_password_record_type(entity_type)
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
    and not private.is_shared_password_record_type(entity_type)
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
    and not private.is_shared_password_record_type(entity_type)
    and (
      owner_id = (select auth.uid())
      or coalesce(payload ->> 'ownerOnlyEdit', 'false') <> 'true'
    )
  )
);

-- v0.85 rows did not carry a server-visible revision. Add revision 1 without
-- touching the encrypted ciphertext.
update public.agenda_records
set payload = case
  when deleted_at is not null then
    jsonb_build_object('v', 1, 'revision', 1, 'tombstone', true)
  else
    coalesce(payload, '{}'::jsonb) || jsonb_build_object('revision', 1)
end
where visibility = 'shared'
  and entity_type = 'shared_credential'
  and (
    payload is null
    or not (payload ? 'revision')
  );

create or replace function private.guard_shared_password_records()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_old_revision bigint := 0;
  v_new_revision bigint := 0;
begin
  if tg_op = 'DELETE' then
    if old.visibility = 'shared'
       and old.entity_type in ('shared_credential', 'shared_password_key_meta') then
      -- Physical removal is reserved for space/account cascades. If the parent
      -- space still exists this is a direct delete and must use the versioned
      -- tombstone path instead.
      if exists (
        select 1
        from public.shared_spaces s
        where s.id = old.space_id
      ) then
        raise exception 'shared_password_physical_delete_forbidden';
      end if;
    end if;
    return old;
  end if;

  if new.visibility <> 'shared' then
    return new;
  end if;

  if new.entity_type = 'shared_password_key_meta' then
    select s.owner_id
      into v_owner
    from public.shared_spaces s
    where s.id = new.space_id;

    if v_user is null or v_owner is distinct from v_user then
      raise exception 'shared_password_key_owner_required';
    end if;

    if tg_op = 'UPDATE' then
      raise exception 'shared_password_key_meta_immutable';
    end if;

    if new.entity_id <> 'v1'
       or new.deleted_at is not null
       or new.payload is null
       or coalesce(new.payload ->> 'fingerprint', '') !~ '^[0-9a-f]{64}$' then
      raise exception 'shared_password_key_meta_invalid';
    end if;

    return new;
  end if;

  if new.entity_type <> 'shared_credential' then
    return new;
  end if;

  if new.payload is null
     or coalesce(new.payload ->> 'revision', '') !~ '^[0-9]+$' then
    raise exception 'shared_password_revision_required';
  end if;

  v_new_revision := (new.payload ->> 'revision')::bigint;

  if tg_op = 'INSERT' then
    if new.deleted_at is not null or v_new_revision <> 1 then
      raise exception 'shared_password_initial_revision_invalid';
    end if;
  else
    if coalesce(old.payload ->> 'revision', '') !~ '^[0-9]+$' then
      raise exception 'shared_password_existing_revision_invalid';
    end if;
    v_old_revision := (old.payload ->> 'revision')::bigint;

    if old.deleted_at is not null and new.deleted_at is null then
      raise exception 'shared_password_resurrection_forbidden';
    end if;

    if v_new_revision <> v_old_revision + 1 then
      raise exception 'shared_password_revision_conflict'
        using errcode = '40001';
    end if;
  end if;

  if new.deleted_at is null then
    if coalesce(new.payload ->> 'v', '') <> '1'
       or coalesce(new.payload ->> 'cipher', '') <> 'AES-256-GCM'
       or coalesce(new.payload ->> 'nonce', '') = ''
       or coalesce(new.payload ->> 'data', '') = ''
       or new.payload ?| array['service', 'username', 'email', 'password', 'notes'] then
      raise exception 'shared_password_ciphertext_payload_invalid';
    end if;
  else
    if coalesce((new.payload ->> 'tombstone')::boolean, false) is not true then
      raise exception 'shared_password_tombstone_invalid';
    end if;
  end if;

  return new;
end;
$func$;

revoke all on function private.guard_shared_password_records()
from public, anon;
grant execute on function private.guard_shared_password_records()
to authenticated;

drop trigger if exists agenda_records_shared_password_guard
on public.agenda_records;

create trigger agenda_records_shared_password_guard
before insert or update or delete on public.agenda_records
for each row
execute function private.guard_shared_password_records();

create or replace function private.claim_shared_password_key_meta_impl(
  p_space_id uuid,
  p_fingerprint text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_record public.agenda_records%rowtype;
  v_inserted integer := 0;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  if coalesce(p_fingerprint, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'shared_password_fingerprint_invalid';
  end if;

  select s.owner_id
    into v_owner
  from public.shared_spaces s
  where s.id = p_space_id;

  if not found then
    raise exception 'shared_space_not_found';
  end if;

  if v_owner is distinct from v_user then
    raise exception 'shared_password_key_owner_required';
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
    p_space_id::text || ':shared:shared_password_key_meta:v1',
    v_user,
    p_space_id,
    'shared',
    'shared_password_key_meta',
    'v1',
    jsonb_build_object(
      'v', 1,
      'fingerprint', p_fingerprint,
      'createdAt', now()
    ),
    now(),
    null
  )
  on conflict (record_key) do nothing;

  get diagnostics v_inserted = row_count;

  select ar.*
    into v_record
  from public.agenda_records ar
  where ar.record_key =
    p_space_id::text || ':shared:shared_password_key_meta:v1';

  if not found
     or v_record.visibility <> 'shared'
     or v_record.space_id is distinct from p_space_id
     or v_record.entity_type <> 'shared_password_key_meta'
     or v_record.entity_id <> 'v1'
     or v_record.deleted_at is not null
     or coalesce(v_record.payload ->> 'fingerprint', '') !~ '^[0-9a-f]{64}$' then
    raise exception 'shared_password_key_meta_invalid';
  end if;

  return jsonb_build_object(
    'fingerprint', v_record.payload ->> 'fingerprint',
    'claimed', v_inserted = 1,
    'clientUpdatedAt', v_record.client_updated_at
  );
end;
$func$;

create or replace function public.claim_shared_password_key_meta(
  p_space_id uuid,
  p_fingerprint text
)
returns jsonb
language sql
security invoker
set search_path = ''
as $func$
  select private.claim_shared_password_key_meta_impl(
    p_space_id,
    p_fingerprint
  );
$func$;

create or replace function private.upsert_shared_password_credential_impl(
  p_space_id uuid,
  p_entity_id text,
  p_payload jsonb,
  p_expected_revision bigint,
  p_client_updated_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_record public.agenda_records%rowtype;
  v_record_key text;
  v_current_revision bigint := 0;
  v_next_revision bigint;
  v_at timestamptz := clock_timestamp();
  v_payload jsonb;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.space_members sm
    where sm.space_id = p_space_id
      and sm.user_id = v_user
  ) then
    raise exception 'shared_space_membership_required';
  end if;

  if nullif(trim(p_entity_id), '') is null then
    raise exception 'shared_password_entity_id_required';
  end if;

  if p_expected_revision < 0 then
    raise exception 'shared_password_revision_invalid';
  end if;

  if p_payload is null
     or jsonb_typeof(p_payload) <> 'object'
     or coalesce(p_payload ->> 'v', '') <> '1'
     or coalesce(p_payload ->> 'cipher', '') <> 'AES-256-GCM'
     or coalesce(p_payload ->> 'nonce', '') = ''
     or coalesce(p_payload ->> 'data', '') = ''
     or p_payload ?| array['service', 'username', 'email', 'password', 'notes'] then
    raise exception 'shared_password_ciphertext_payload_invalid';
  end if;

  v_record_key :=
    p_space_id::text || ':shared:shared_credential:' || trim(p_entity_id);

  select ar.*
    into v_record
  from public.agenda_records ar
  where ar.record_key = v_record_key
  for update;

  if found then
    if v_record.space_id is distinct from p_space_id
       or v_record.visibility <> 'shared'
       or v_record.entity_type <> 'shared_credential'
       or v_record.entity_id <> trim(p_entity_id) then
      raise exception 'shared_password_identity_collision';
    end if;

    if v_record.deleted_at is not null then
      raise exception 'shared_password_deleted';
    end if;

    if coalesce(v_record.payload ->> 'revision', '') !~ '^[0-9]+$' then
      raise exception 'shared_password_existing_revision_invalid';
    end if;

    v_current_revision := (v_record.payload ->> 'revision')::bigint;
    if p_expected_revision <> v_current_revision then
      raise exception 'shared_password_revision_conflict'
        using errcode = '40001';
    end if;

    v_next_revision := v_current_revision + 1;
    v_payload :=
      (p_payload - 'revision' - 'tombstone')
      || jsonb_build_object('revision', v_next_revision);

    update public.agenda_records
    set
      payload = v_payload,
      client_updated_at = v_at,
      deleted_at = null
    where record_key = v_record_key;
  else
    if p_expected_revision <> 0 then
      raise exception 'shared_password_revision_conflict'
        using errcode = '40001';
    end if;

    v_next_revision := 1;
    v_payload :=
      (p_payload - 'revision' - 'tombstone')
      || jsonb_build_object('revision', v_next_revision);

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
      v_record_key,
      v_user,
      p_space_id,
      'shared',
      'shared_credential',
      trim(p_entity_id),
      v_payload,
      v_at,
      null
    );
  end if;

  return jsonb_build_object(
    'revision', v_next_revision,
    'clientUpdatedAt', v_at
  );
end;
$func$;

create or replace function public.upsert_shared_password_credential(
  p_space_id uuid,
  p_entity_id text,
  p_payload jsonb,
  p_expected_revision bigint,
  p_client_updated_at timestamptz
)
returns jsonb
language sql
security invoker
set search_path = ''
as $func$
  select private.upsert_shared_password_credential_impl(
    p_space_id,
    p_entity_id,
    p_payload,
    p_expected_revision,
    p_client_updated_at
  );
$func$;

create or replace function private.delete_shared_password_credential_impl(
  p_space_id uuid,
  p_entity_id text,
  p_expected_revision bigint
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_record public.agenda_records%rowtype;
  v_record_key text;
  v_current_revision bigint;
  v_next_revision bigint;
  v_at timestamptz := now();
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.space_members sm
    where sm.space_id = p_space_id
      and sm.user_id = v_user
  ) then
    raise exception 'shared_space_membership_required';
  end if;

  v_record_key :=
    p_space_id::text || ':shared:shared_credential:' || trim(p_entity_id);

  select ar.*
    into v_record
  from public.agenda_records ar
  where ar.record_key = v_record_key
  for update;

  if not found then
    raise exception 'shared_password_not_found';
  end if;

  if v_record.space_id is distinct from p_space_id
     or v_record.visibility <> 'shared'
     or v_record.entity_type <> 'shared_credential'
     or v_record.entity_id <> trim(p_entity_id) then
    raise exception 'shared_password_identity_collision';
  end if;

  if coalesce(v_record.payload ->> 'revision', '') !~ '^[0-9]+$' then
    raise exception 'shared_password_existing_revision_invalid';
  end if;

  v_current_revision := (v_record.payload ->> 'revision')::bigint;

  if v_record.deleted_at is not null then
    return jsonb_build_object(
      'revision', v_current_revision,
      'clientUpdatedAt', v_record.client_updated_at,
      'alreadyDeleted', true
    );
  end if;

  if p_expected_revision <> v_current_revision then
    raise exception 'shared_password_revision_conflict'
      using errcode = '40001';
  end if;

  v_next_revision := v_current_revision + 1;

  update public.agenda_records
  set
    payload = jsonb_build_object(
      'v', 1,
      'revision', v_next_revision,
      'tombstone', true
    ),
    client_updated_at = v_at,
    deleted_at = v_at
  where record_key = v_record_key;

  return jsonb_build_object(
    'revision', v_next_revision,
    'clientUpdatedAt', v_at,
    'alreadyDeleted', false
  );
end;
$func$;

create or replace function public.delete_shared_password_credential(
  p_space_id uuid,
  p_entity_id text,
  p_expected_revision bigint
)
returns jsonb
language sql
security invoker
set search_path = ''
as $func$
  select private.delete_shared_password_credential_impl(
    p_space_id,
    p_entity_id,
    p_expected_revision
  );
$func$;



create or replace function private.upsert_shared_password_key_envelope_impl(
  p_space_id uuid,
  p_entity_id text,
  p_payload jsonb,
  p_client_updated_at timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_record_key text;
  v_expires timestamptz;
  v_rows integer;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  select s.owner_id
    into v_owner
  from public.shared_spaces s
  where s.id = p_space_id
  for update;

  if not found then
    raise exception 'shared_space_not_found';
  end if;
  if v_owner is distinct from v_user then
    raise exception 'shared_password_key_owner_required';
  end if;

  if coalesce(p_entity_id, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'shared_password_envelope_id_invalid';
  end if;

  if p_payload is null
     or jsonb_typeof(p_payload) <> 'object'
     or coalesce(p_payload ->> 'v', '') <> '1'
     or coalesce(p_payload ->> 'salt', '') = ''
     or jsonb_typeof(p_payload -> 'wrapped') <> 'object'
     or coalesce(p_payload #>> '{wrapped,nonce}', '') = ''
     or coalesce(p_payload #>> '{wrapped,data}', '') = ''
     or coalesce(p_payload ->> 'expiresAt', '') = '' then
    raise exception 'shared_password_envelope_invalid';
  end if;

  begin
    v_expires := (p_payload ->> 'expiresAt')::timestamptz;
  exception when others then
    raise exception 'shared_password_envelope_expiry_invalid';
  end;

  if v_expires <= clock_timestamp()
     or v_expires > clock_timestamp() + interval '20 minutes' then
    raise exception 'shared_password_envelope_expiry_invalid';
  end if;

  v_record_key :=
    p_space_id::text || ':shared:shared_password_key_envelope:' || p_entity_id;

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
    v_record_key,
    v_user,
    p_space_id,
    'shared',
    'shared_password_key_envelope',
    p_entity_id,
    p_payload,
    coalesce(p_client_updated_at, clock_timestamp()),
    null
  )
  on conflict (record_key) do nothing;

  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception 'shared_password_envelope_already_exists';
  end if;

  return true;
end;
$func$;

create or replace function public.upsert_shared_password_key_envelope(
  p_space_id uuid,
  p_entity_id text,
  p_payload jsonb,
  p_client_updated_at timestamptz
)
returns boolean
language sql
security invoker
set search_path = ''
as $func$
  select private.upsert_shared_password_key_envelope_impl(
    p_space_id,
    p_entity_id,
    p_payload,
    p_client_updated_at
  );
$func$;

create or replace function private.consume_shared_password_key_envelope_impl(
  p_space_id uuid,
  p_entity_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_record public.agenda_records%rowtype;
  v_at timestamptz := clock_timestamp();
  v_payload jsonb;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.space_members sm
    where sm.space_id = p_space_id
      and sm.user_id = v_user
  ) then
    raise exception 'shared_space_membership_required';
  end if;

  select ar.*
    into v_record
  from public.agenda_records ar
  where ar.record_key =
    p_space_id::text || ':shared:shared_password_key_envelope:' || trim(p_entity_id)
  for update;

  if not found
     or v_record.visibility <> 'shared'
     or v_record.space_id is distinct from p_space_id
     or v_record.entity_type <> 'shared_password_key_envelope'
     or v_record.entity_id <> trim(p_entity_id)
     or v_record.deleted_at is not null
     or v_record.payload is null then
    raise exception 'shared_password_pairing_code_unavailable';
  end if;

  v_payload := v_record.payload;

  update public.agenda_records
  set
    payload = jsonb_build_object(
      'v', 1,
      'tombstone', true
    ),
    client_updated_at = v_at,
    deleted_at = v_at
  where record_key = v_record.record_key;

  return v_payload;
end;
$func$;

create or replace function public.consume_shared_password_key_envelope(
  p_space_id uuid,
  p_entity_id text
)
returns jsonb
language sql
security invoker
set search_path = ''
as $func$
  select private.consume_shared_password_key_envelope_impl(
    p_space_id,
    p_entity_id
  );
$func$;

revoke all on function private.upsert_shared_password_key_envelope_impl(
  uuid, text, jsonb, timestamptz
) from public, anon;
grant execute on function private.upsert_shared_password_key_envelope_impl(
  uuid, text, jsonb, timestamptz
) to authenticated;

revoke all on function public.upsert_shared_password_key_envelope(
  uuid, text, jsonb, timestamptz
) from public, anon;
grant execute on function public.upsert_shared_password_key_envelope(
  uuid, text, jsonb, timestamptz
) to authenticated;

revoke all on function private.consume_shared_password_key_envelope_impl(
  uuid, text
) from public, anon;
grant execute on function private.consume_shared_password_key_envelope_impl(
  uuid, text
) to authenticated;

revoke all on function public.consume_shared_password_key_envelope(
  uuid, text
) from public, anon;
grant execute on function public.consume_shared_password_key_envelope(
  uuid, text
) to authenticated;

-- Prevent the legacy/generic merge endpoint and direct Data API writes from
-- bypassing any dedicated shared-password mutation contract.
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
set search_path = ''
as $func$
declare
  v_rows integer;
  v_existing_payload jsonb;
  v_existing_deleted_at timestamptz;
  v_existing_updated_at timestamptz;
begin
  if p_visibility = 'shared'
     and p_entity_type in (
       'shared_credential',
       'shared_password_key_meta',
       'shared_password_key_envelope'
     ) then
    raise exception 'shared_password_dedicated_rpc_required';
  end if;

  select ar.payload, ar.deleted_at, ar.client_updated_at
    into v_existing_payload, v_existing_deleted_at, v_existing_updated_at
  from public.agenda_records ar
  where ar.record_key = p_record_key;

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
  where excluded.client_updated_at > public.agenda_records.client_updated_at;

  get diagnostics v_rows = row_count;
  return v_rows > 0;
end;
$func$;

revoke execute on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) from public, anon;
grant execute on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) to authenticated;

revoke all on function private.claim_shared_password_key_meta_impl(uuid, text)
from public, anon;
revoke all on function private.upsert_shared_password_credential_impl(
  uuid, text, jsonb, bigint, timestamptz
) from public, anon;
revoke all on function private.delete_shared_password_credential_impl(
  uuid, text, bigint
) from public, anon;

grant execute on function private.claim_shared_password_key_meta_impl(uuid, text)
to authenticated;
grant execute on function private.upsert_shared_password_credential_impl(
  uuid, text, jsonb, bigint, timestamptz
) to authenticated;
grant execute on function private.delete_shared_password_credential_impl(
  uuid, text, bigint
) to authenticated;

revoke all on function public.claim_shared_password_key_meta(uuid, text)
from public, anon;
revoke all on function public.upsert_shared_password_credential(
  uuid, text, jsonb, bigint, timestamptz
) from public, anon;
revoke all on function public.delete_shared_password_credential(
  uuid, text, bigint
) from public, anon;

grant execute on function public.claim_shared_password_key_meta(uuid, text)
to authenticated;
grant execute on function public.upsert_shared_password_credential(
  uuid, text, jsonb, bigint, timestamptz
) to authenticated;
grant execute on function public.delete_shared_password_credential(
  uuid, text, bigint
) to authenticated;
 then
    raise exception 'shared_password_envelope_id_invalid';
  end if;

  if p_payload is null
     or jsonb_typeof(p_payload) <> 'object'
     or coalesce(p_payload ->> 'v', '') <> '1'
     or coalesce(p_payload ->> 'salt', '') = ''
     or jsonb_typeof(p_payload -> 'wrapped') <> 'object'
     or coalesce(p_payload #>> '{wrapped,nonce}', '') = ''
     or coalesce(p_payload #>> '{wrapped,data}', '') = ''
     or coalesce(p_payload ->> 'expiresAt', '') = '' then
    raise exception 'shared_password_envelope_invalid';
  end if;

  begin
    v_expires := (p_payload ->> 'expiresAt')::timestamptz;
  exception when others then
    raise exception 'shared_password_envelope_expiry_invalid';
  end;

  if v_expires <= clock_timestamp()
     or v_expires > clock_timestamp() + interval '20 minutes' then
    raise exception 'shared_password_envelope_expiry_invalid';
  end if;

  v_record_key :=
    p_space_id::text || ':shared:shared_password_key_envelope:' || p_entity_id;

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
    v_record_key,
    v_user,
    p_space_id,
    'shared',
    'shared_password_key_envelope',
    p_entity_id,
    p_payload,
    coalesce(p_client_updated_at, clock_timestamp()),
    null
  )
  on conflict (record_key) do nothing;

  if not found then
    raise exception 'shared_password_envelope_already_exists';
  end if;

  return true;
end;
$func$;

create or replace function public.upsert_shared_password_key_envelope(
  p_space_id uuid,
  p_entity_id text,
  p_payload jsonb,
  p_client_updated_at timestamptz
)
returns boolean
language sql
security invoker
set search_path = ''
as $func$
  select private.upsert_shared_password_key_envelope_impl(
    p_space_id,
    p_entity_id,
    p_payload,
    p_client_updated_at
  );
$func$;


create or replace function private.consume_shared_password_key_envelope_impl(
  p_space_id uuid,
  p_entity_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_record public.agenda_records%rowtype;
  v_at timestamptz := clock_timestamp();
  v_payload jsonb;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.space_members sm
    where sm.space_id = p_space_id
      and sm.user_id = v_user
  ) then
    raise exception 'shared_space_membership_required';
  end if;

  select ar.*
    into v_record
  from public.agenda_records ar
  where ar.record_key =
    p_space_id::text || ':shared:shared_password_key_envelope:' || trim(p_entity_id)
  for update;

  if not found
     or v_record.visibility <> 'shared'
     or v_record.space_id is distinct from p_space_id
     or v_record.entity_type <> 'shared_password_key_envelope'
     or v_record.entity_id <> trim(p_entity_id)
     or v_record.deleted_at is not null
     or v_record.payload is null then
    raise exception 'shared_password_pairing_code_unavailable';
  end if;

  v_payload := v_record.payload;

  update public.agenda_records
  set
    payload = jsonb_build_object(
      'v', 1,
      'tombstone', true
    ),
    client_updated_at = v_at,
    deleted_at = v_at
  where record_key = v_record.record_key;

  return v_payload;
end;
$func$;

create or replace function public.consume_shared_password_key_envelope(
  p_space_id uuid,
  p_entity_id text
)
returns jsonb
language sql
security invoker
set search_path = ''
as $func$
  select private.consume_shared_password_key_envelope_impl(
    p_space_id,
    p_entity_id
  );
$func$;

revoke all on function private.consume_shared_password_key_envelope_impl(
  uuid, text
) from public, anon;
grant execute on function private.consume_shared_password_key_envelope_impl(
  uuid, text
) to authenticated;

revoke all on function public.consume_shared_password_key_envelope(
  uuid, text
) from public, anon;
grant execute on function public.consume_shared_password_key_envelope(
  uuid, text
) to authenticated;

-- Prevent the legacy/generic merge endpoint from bypassing the dedicated
-- shared-password compare-and-swap contract. Pairing envelopes remain on the
-- generic channel because they are one-time opaque bootstrap records.
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
set search_path = ''
as $func$
declare
  v_rows integer;
  v_existing_payload jsonb;
  v_existing_deleted_at timestamptz;
  v_existing_updated_at timestamptz;
begin
  if p_visibility = 'shared'
     and p_entity_type in (
       'shared_credential',
       'shared_password_key_meta'
     ) then
    raise exception 'shared_password_dedicated_rpc_required';
  end if;

  select ar.payload, ar.deleted_at, ar.client_updated_at
    into v_existing_payload, v_existing_deleted_at, v_existing_updated_at
  from public.agenda_records ar
  where ar.record_key = p_record_key;

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
  where excluded.client_updated_at > public.agenda_records.client_updated_at;

  get diagnostics v_rows = row_count;
  return v_rows > 0;
end;
$func$;

revoke execute on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) from public, anon;
grant execute on function public.merge_agenda_record(
  text, uuid, uuid, text, text, text, jsonb, timestamptz, timestamptz
) to authenticated;

revoke all on function private.claim_shared_password_key_meta_impl(uuid, text)
from public, anon;
revoke all on function private.upsert_shared_password_credential_impl(
  uuid, text, jsonb, bigint, timestamptz
) from public, anon;
revoke all on function private.delete_shared_password_credential_impl(
  uuid, text, bigint
) from public, anon;

grant execute on function private.claim_shared_password_key_meta_impl(uuid, text)
to authenticated;
grant execute on function private.upsert_shared_password_credential_impl(
  uuid, text, jsonb, bigint, timestamptz
) to authenticated;
grant execute on function private.delete_shared_password_credential_impl(
  uuid, text, bigint
) to authenticated;

revoke all on function public.claim_shared_password_key_meta(uuid, text)
from public, anon;
revoke all on function public.upsert_shared_password_credential(
  uuid, text, jsonb, bigint, timestamptz
) from public, anon;
revoke all on function public.delete_shared_password_credential(
  uuid, text, bigint
) from public, anon;

grant execute on function public.claim_shared_password_key_meta(uuid, text)
to authenticated;
grant execute on function public.upsert_shared_password_credential(
  uuid, text, jsonb, bigint, timestamptz
) to authenticated;
grant execute on function public.delete_shared_password_credential(
  uuid, text, bigint
) to authenticated;
