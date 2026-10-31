-- Approved mock-up #6 follow-up: owner can rename a shared space without
-- recreating it or touching members, record IDs, invites, encryption or sync.
-- Deploy via the normal reviewed Supabase migrations BEFORE distributing the
-- Android client that exposes this owner-only operation.

create or replace function private.rename_shared_space_impl(
  p_space_id uuid,
  p_name text
)
returns text
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_user uuid := (select auth.uid());
  v_owner uuid;
  v_name text := btrim(regexp_replace(coalesce(p_name, ''), '[[:space:]]+', ' ', 'g'));
begin
  if v_user is null then
    raise exception 'authentication_required';
  end if;

  if char_length(v_name) < 1 or char_length(v_name) > 60 then
    raise exception 'invalid_shared_space_name';
  end if;

  select owner_id
  into v_owner
  from public.shared_spaces
  where id = p_space_id
  for update;

  if v_owner is null then
    raise exception 'shared_space_not_found';
  end if;

  if v_owner is distinct from v_user then
    raise exception 'only_owner_can_rename_space';
  end if;

  update public.shared_spaces
  set name = v_name
  where id = p_space_id;

  return v_name;
end;
$func$;

create or replace function public.rename_shared_space(
  p_space_id uuid,
  p_name text
)
returns text
language sql
security invoker
set search_path = ''
as $func$
  select private.rename_shared_space_impl(p_space_id, p_name);
$func$;

revoke all on function private.rename_shared_space_impl(uuid, text)
  from public, anon;
revoke all on function public.rename_shared_space(uuid, text)
  from public, anon;
grant execute on function private.rename_shared_space_impl(uuid, text)
  to authenticated;
grant execute on function public.rename_shared_space(uuid, text)
  to authenticated;
