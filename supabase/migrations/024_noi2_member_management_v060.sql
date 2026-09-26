-- v0.60 — Noi ♡ 2.0 member visibility and owner member management.
-- Reuses existing shared_spaces / space_members ownership semantics and RLS.

create or replace function private.list_shared_space_members_impl(p_space_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $func$
declare
  v_user uuid := (select auth.uid());
  v_result jsonb;
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
    raise exception 'space_membership_required';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_id', sm.user_id,
        'role', sm.role,
        'display_name', coalesce(
          nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
          nullif(trim(u.raw_user_meta_data ->> 'name'), ''),
          'Persona'
        ),
        'avatar_url', coalesce(
          nullif(trim(u.raw_user_meta_data ->> 'avatar_url'), ''),
          nullif(trim(u.raw_user_meta_data ->> 'picture'), ''),
          ''
        )
      )
      order by
        case when sm.role = 'owner' then 0 else 1 end,
        lower(coalesce(
          nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
          nullif(trim(u.raw_user_meta_data ->> 'name'), ''),
          'Persona'
        )),
        sm.user_id
    ),
    '[]'::jsonb
  )
  into v_result
  from public.space_members sm
  join auth.users u on u.id = sm.user_id
  where sm.space_id = p_space_id;

  return v_result;
end;
$func$;

create or replace function public.list_shared_space_members(p_space_id uuid)
returns jsonb
language sql
security invoker
set search_path = public, private
as $func$
  select private.list_shared_space_members_impl(p_space_id);
$func$;

create or replace function private.remove_shared_space_member_impl(
  p_space_id uuid,
  p_user_id uuid
)
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

  select owner_id
  into v_owner
  from public.shared_spaces
  where id = p_space_id
  for update;

  if v_owner is null then
    raise exception 'shared_space_not_found';
  end if;

  if v_owner is distinct from v_user then
    raise exception 'only_owner_can_remove_member';
  end if;

  if p_user_id = v_owner then
    raise exception 'owner_cannot_be_removed';
  end if;

  delete from public.space_members
  where space_id = p_space_id
    and user_id = p_user_id;

  if not found then
    raise exception 'member_not_found';
  end if;
end;
$func$;

create or replace function public.remove_shared_space_member(
  p_space_id uuid,
  p_user_id uuid
)
returns void
language sql
security invoker
set search_path = public, private
as $func$
  select private.remove_shared_space_member_impl(p_space_id, p_user_id);
$func$;

revoke all on function private.list_shared_space_members_impl(uuid) from public;
revoke all on function private.remove_shared_space_member_impl(uuid, uuid) from public;
grant execute on function private.list_shared_space_members_impl(uuid) to authenticated;
grant execute on function private.remove_shared_space_member_impl(uuid, uuid) to authenticated;

revoke all on function public.list_shared_space_members(uuid) from public, anon;
revoke all on function public.remove_shared_space_member(uuid, uuid) from public, anon;
grant execute on function public.list_shared_space_members(uuid) to authenticated;
grant execute on function public.remove_shared_space_member(uuid, uuid) to authenticated;
