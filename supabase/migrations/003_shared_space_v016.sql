-- v0.16 Shared Space foundation.
-- Public RPC wrappers remain SECURITY INVOKER; privileged implementations live
-- in the non-exposed private schema.

alter table public.agenda_records
  add column if not exists updated_by uuid references auth.users(id) on delete set null;

create or replace function private.set_agenda_record_audit()
returns trigger
language plpgsql
security invoker
set search_path = public, auth
as $func$
begin
  if tg_op = 'INSERT' then
    new.updated_by := (select auth.uid());
  else
    new.owner_id := old.owner_id;
    new.updated_by := (select auth.uid());
  end if;
  return new;
end;
$func$;

drop trigger if exists agenda_records_audit on public.agenda_records;
create trigger agenda_records_audit
before insert or update on public.agenda_records
for each row execute function private.set_agenda_record_audit();

create or replace function private.create_shared_space_impl(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $func$
declare
  v_user uuid := (select auth.uid());
  v_space uuid;
  v_name text := nullif(trim(p_name), '');
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  insert into public.shared_spaces(owner_id, name)
  values (v_user, coalesce(v_name, 'Noi ♡'))
  returning id into v_space;

  insert into public.space_members(space_id, user_id, role)
  values (v_space, v_user, 'owner');

  return v_space;
end;
$func$;

create or replace function public.create_shared_space(p_name text default 'Noi ♡')
returns uuid
language sql
security invoker
set search_path = public, private
as $func$
  select private.create_shared_space_impl(p_name);
$func$;

create or replace function private.create_space_invite_impl(p_space_id uuid)
returns text
language plpgsql
security definer
set search_path = public, auth, extensions
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
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

  delete from public.space_invites
  where space_id = p_space_id
    and consumed_at is null;

  v_code := upper(substr(encode(extensions.gen_random_bytes(5), 'hex'), 1, 8));
  v_hash := encode(extensions.digest(v_code, 'sha256'), 'hex');

  insert into public.space_invites(
    space_id,
    created_by,
    code_hash,
    expires_at
  )
  values (
    p_space_id,
    v_user,
    v_hash,
    now() + interval '24 hours'
  );

  return v_code;
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
    and consumed_at is null
    and expires_at > now()
  for update;

  if not found then
    raise exception 'invalid_or_expired_invite';
  end if;

  insert into public.space_members(space_id, user_id, role)
  values (v_invite.space_id, v_user, 'member')
  on conflict (space_id, user_id) do nothing;

  update public.space_invites
  set consumed_at = now()
  where id = v_invite.id;

  return v_invite.space_id;
end;
$func$;

create or replace function public.join_shared_space(p_code text)
returns uuid
language sql
security invoker
set search_path = public, private
as $func$
  select private.join_shared_space_impl(p_code);
$func$;

create or replace function private.leave_shared_space_impl(p_space_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
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

  if v_owner = v_user then
    raise exception 'owner_cannot_leave_use_delete';
  end if;

  delete from public.space_members
  where space_id = p_space_id
    and user_id = v_user;
end;
$func$;

create or replace function public.leave_shared_space(p_space_id uuid)
returns void
language sql
security invoker
set search_path = public, private
as $func$
  select private.leave_shared_space_impl(p_space_id);
$func$;

create or replace function private.delete_shared_space_impl(p_space_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $func$
declare
  v_user uuid := (select auth.uid());
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  delete from public.shared_spaces
  where id = p_space_id
    and owner_id = v_user;

  if not found then
    raise exception 'only_owner_can_delete';
  end if;
end;
$func$;

create or replace function public.delete_shared_space(p_space_id uuid)
returns void
language sql
security invoker
set search_path = public, private
as $func$
  select private.delete_shared_space_impl(p_space_id);
$func$;

revoke all on function private.create_shared_space_impl(text) from public;
revoke all on function private.create_space_invite_impl(uuid) from public;
revoke all on function private.join_shared_space_impl(text) from public;
revoke all on function private.leave_shared_space_impl(uuid) from public;
revoke all on function private.delete_shared_space_impl(uuid) from public;

grant usage on schema private to authenticated;
grant execute on function private.create_shared_space_impl(text) to authenticated;
grant execute on function private.create_space_invite_impl(uuid) to authenticated;
grant execute on function private.join_shared_space_impl(text) to authenticated;
grant execute on function private.leave_shared_space_impl(uuid) to authenticated;
grant execute on function private.delete_shared_space_impl(uuid) to authenticated;

revoke all on function public.create_shared_space(text) from public;
revoke all on function public.create_space_invite(uuid) from public;
revoke all on function public.join_shared_space(text) from public;
revoke all on function public.leave_shared_space(uuid) from public;
revoke all on function public.delete_shared_space(uuid) from public;

grant execute on function public.create_shared_space(text) to authenticated;
grant execute on function public.create_space_invite(uuid) to authenticated;
grant execute on function public.join_shared_space(text) to authenticated;
grant execute on function public.leave_shared_space(uuid) to authenticated;
grant execute on function public.delete_shared_space(uuid) to authenticated;
