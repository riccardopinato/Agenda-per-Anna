-- v0.41 — persistent, reusable 24-hour shared-space invites.
-- The raw short-lived code is stored only in a table that is not directly
-- granted to authenticated clients; access remains RPC-only.

alter table public.space_invites
  add column if not exists code_value text,
  add column if not exists revoked_at timestamptz;

-- Legacy invites cannot reveal their original plaintext code. Retire only
-- still-active legacy rows; consumed/history rows remain available for audit.
update public.space_invites
set revoked_at = coalesce(revoked_at, now())
where code_value is null
  and consumed_at is null
  and expires_at > now();

create index if not exists space_invites_space_expiry_idx
  on public.space_invites(space_id, expires_at desc);

create or replace function private.get_or_create_space_invite_impl(
  p_space_id uuid,
  p_force_new boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_code text;
  v_hash text;
  v_expires timestamptz;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  select owner_id into v_owner
  from public.shared_spaces
  where id = p_space_id;

  if v_owner is distinct from v_user then
    raise exception 'only_owner_can_invite';
  end if;

  if p_force_new then
    update public.space_invites
    set revoked_at = now()
    where space_id = p_space_id
      and revoked_at is null
      and expires_at > now();
  else
    select code_value, expires_at
    into v_code, v_expires
    from public.space_invites
    where space_id = p_space_id
      and revoked_at is null
      and expires_at > now()
      and code_value is not null
    order by created_at desc
    limit 1;

    if found then
      return jsonb_build_object(
        'code', v_code,
        'expires_at', v_expires,
        'reused', true
      );
    end if;
  end if;

  loop
    v_code := upper(substr(encode(extensions.gen_random_bytes(5), 'hex'), 1, 8));
    v_hash := encode(extensions.digest(v_code, 'sha256'), 'hex');
    exit when not exists (
      select 1
      from public.space_invites
      where code_hash = v_hash
    );
  end loop;

  v_expires := now() + interval '24 hours';

  insert into public.space_invites(
    space_id,
    created_by,
    code_hash,
    code_value,
    expires_at,
    consumed_at,
    revoked_at
  )
  values (
    p_space_id,
    v_user,
    v_hash,
    v_code,
    v_expires,
    null,
    null
  );

  return jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires,
    'reused', false
  );
end;
$func$;

create or replace function public.get_or_create_space_invite(
  p_space_id uuid,
  p_force_new boolean default false
)
returns jsonb
language sql
security invoker
set search_path = public, private
as $func$
  select private.get_or_create_space_invite_impl(p_space_id, p_force_new);
$func$;

create or replace function private.create_space_invite_impl(p_space_id uuid)
returns text
language plpgsql
security definer
set search_path = public, auth, extensions
as $func$
declare
  v_payload jsonb;
begin
  v_payload := private.get_or_create_space_invite_impl(p_space_id, false);
  return upper(v_payload ->> 'code');
end;
$func$;

create or replace function public.create_space_invite(p_space_id uuid)
returns text
language sql
security invoker
set search_path = public, private
as $func$
  select private.create_space_invite_impl(p_space_id);
$func$;

create or replace function private.join_shared_space_impl(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $func$
declare
  v_user uuid := (select auth.uid());
  v_hash text;
  v_invite public.space_invites%rowtype;
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  v_hash := encode(
    extensions.digest(upper(trim(p_code)), 'sha256'),
    'hex'
  );

  select *
  into v_invite
  from public.space_invites
  where code_hash = v_hash
    and code_value is not null
    and revoked_at is null
    and expires_at > now()
  order by created_at desc
  limit 1
  for update;

  if not found then
    raise exception 'invalid_or_expired_invite';
  end if;

  insert into public.space_members(space_id, user_id, role)
  values (v_invite.space_id, v_user, 'member')
  on conflict (space_id, user_id) do nothing;

  -- Multi-use for the full TTL: do not consume the invite on first join.
  return v_invite.space_id;
end;
$func$;

revoke all on function private.get_or_create_space_invite_impl(uuid, boolean)
  from public;
grant usage on schema private to authenticated;
grant execute on function private.get_or_create_space_invite_impl(uuid, boolean)
  to authenticated;

revoke all on function public.get_or_create_space_invite(uuid, boolean)
  from public, anon;
grant execute on function public.get_or_create_space_invite(uuid, boolean)
  to authenticated;

revoke all on function public.create_space_invite(uuid) from public, anon;
grant execute on function public.create_space_invite(uuid) to authenticated;

revoke all on function public.join_shared_space(text) from public, anon;
grant execute on function public.join_shared_space(text) to authenticated;
