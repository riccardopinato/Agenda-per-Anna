-- v0.41 — Universal Identity, Persistent Invite & Always-Synced Noi ♡
-- Persistent 24h invites are server objects, not transient UI values.

alter table public.space_invites
  add column if not exists code_value text,
  add column if not exists revoked_at timestamptz,
  add column if not exists uses_count integer not null default 0,
  add column if not exists last_used_at timestamptz;

create index if not exists space_invites_active_space_idx
  on public.space_invites(space_id, expires_at desc)
  where revoked_at is null;

create or replace function private.create_or_get_space_invite_impl(p_space_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_invite public.space_invites%rowtype;
  v_code text;
  v_hash text;
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

  select *
  into v_invite
  from public.space_invites
  where space_id = p_space_id
    and revoked_at is null
    and expires_at > now()
    and code_value is not null
  order by created_at desc
  limit 1;

  if found then
    return jsonb_build_object(
      'code', v_invite.code_value,
      'expires_at', v_invite.expires_at,
      'uses_count', v_invite.uses_count,
      'created_at', v_invite.created_at
    );
  end if;

  update public.space_invites
  set revoked_at = coalesce(revoked_at, now())
  where space_id = p_space_id
    and revoked_at is null
    and (expires_at <= now() or code_value is null);

  loop
    v_code := upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 8));
    v_hash := encode(extensions.digest(v_code, 'sha256'), 'hex');
    exit when not exists (
      select 1 from public.space_invites where code_hash = v_hash
    );
  end loop;

  insert into public.space_invites(
    space_id,
    created_by,
    code_hash,
    code_value,
    expires_at
  )
  values (
    p_space_id,
    v_user,
    v_hash,
    v_code,
    now() + interval '24 hours'
  )
  returning * into v_invite;

  return jsonb_build_object(
    'code', v_invite.code_value,
    'expires_at', v_invite.expires_at,
    'uses_count', v_invite.uses_count,
    'created_at', v_invite.created_at
  );
end;
$func$;

create or replace function public.create_or_get_space_invite(p_space_id uuid)
returns jsonb
language sql
security invoker
set search_path = public, private
as $func$
  select private.create_or_get_space_invite_impl(p_space_id);
$func$;

create or replace function private.regenerate_space_invite_impl(p_space_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, private
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
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

  update public.space_invites
  set revoked_at = now()
  where space_id = p_space_id
    and revoked_at is null
    and expires_at > now();

  return private.create_or_get_space_invite_impl(p_space_id);
end;
$func$;

create or replace function public.regenerate_space_invite(p_space_id uuid)
returns jsonb
language sql
security invoker
set search_path = public, private
as $func$
  select private.regenerate_space_invite_impl(p_space_id);
$func$;

create or replace function private.create_space_invite_impl(p_space_id uuid)
returns text
language plpgsql
security definer
set search_path = public, auth, private
as $func$
declare
  v_payload jsonb;
begin
  v_payload := private.create_or_get_space_invite_impl(p_space_id);
  return v_payload ->> 'code';
end;
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
    and revoked_at is null
    and expires_at > now()
  for update;

  if not found then
    raise exception 'invalid_or_expired_invite';
  end if;

  insert into public.space_members(space_id, user_id, role)
  values (v_invite.space_id, v_user, 'member')
  on conflict (space_id, user_id) do nothing;

  update public.space_invites
  set uses_count = uses_count + 1,
      last_used_at = now()
  where id = v_invite.id;

  return v_invite.space_id;
end;
$func$;

revoke all on function private.create_or_get_space_invite_impl(uuid) from public;
revoke all on function private.regenerate_space_invite_impl(uuid) from public;
grant execute on function private.create_or_get_space_invite_impl(uuid) to authenticated;
grant execute on function private.regenerate_space_invite_impl(uuid) to authenticated;

revoke all on function public.create_or_get_space_invite(uuid) from public, anon;
revoke all on function public.regenerate_space_invite(uuid) from public, anon;
grant execute on function public.create_or_get_space_invite(uuid) to authenticated;
grant execute on function public.regenerate_space_invite(uuid) to authenticated;

-- Keep invite secrets behind RPCs only.
revoke all privileges on table public.space_invites from anon, authenticated;
