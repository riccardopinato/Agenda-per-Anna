-- Harden RLS and performance after Supabase advisor review.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.is_space_member(target_space_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $func$
  select exists (
    select 1
    from public.space_members sm
    where sm.space_id = target_space_id
      and sm.user_id = (select auth.uid())
  );
$func$;

revoke all on function private.is_space_member(uuid) from public;
grant execute on function private.is_space_member(uuid) to authenticated;

drop policy if exists "agenda_records_select" on public.agenda_records;
create policy "agenda_records_select"
on public.agenda_records
for select
to authenticated
using (
  (visibility = 'private' and owner_id = (select auth.uid()))
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "agenda_records_insert" on public.agenda_records;
create policy "agenda_records_insert"
on public.agenda_records
for insert
to authenticated
with check (
  (visibility = 'private' and owner_id = (select auth.uid()) and space_id is null)
  or
  (
    visibility = 'shared'
    and owner_id = (select auth.uid())
    and private.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "agenda_records_update" on public.agenda_records;
create policy "agenda_records_update"
on public.agenda_records
for update
to authenticated
using (
  (visibility = 'private' and owner_id = (select auth.uid()))
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
  )
)
with check (
  (visibility = 'private' and owner_id = (select auth.uid()) and space_id is null)
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "agenda_records_delete" on public.agenda_records;
create policy "agenda_records_delete"
on public.agenda_records
for delete
to authenticated
using (
  (visibility = 'private' and owner_id = (select auth.uid()))
  or
  (
    visibility = 'shared'
    and private.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "shared_spaces_select" on public.shared_spaces;
create policy "shared_spaces_select"
on public.shared_spaces
for select
to authenticated
using (
  owner_id = (select auth.uid())
  or private.is_space_member(shared_spaces.id)
);

drop policy if exists "shared_spaces_insert" on public.shared_spaces;
create policy "shared_spaces_insert"
on public.shared_spaces
for insert
to authenticated
with check (owner_id = (select auth.uid()));

drop policy if exists "shared_spaces_update_owner" on public.shared_spaces;
create policy "shared_spaces_update_owner"
on public.shared_spaces
for update
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy if exists "space_members_select" on public.space_members;
create policy "space_members_select"
on public.space_members
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_space_member(space_members.space_id)
);

drop policy if exists "space_invites_deny_select" on public.space_invites;
create policy "space_invites_deny_select"
on public.space_invites
for select
to authenticated
using (false);

drop function if exists public.is_space_member(uuid);

create index if not exists shared_spaces_owner_id_idx
  on public.shared_spaces(owner_id);

create index if not exists space_members_user_id_idx
  on public.space_members(user_id);

create index if not exists space_invites_space_id_idx
  on public.space_invites(space_id);

create index if not exists space_invites_created_by_idx
  on public.space_invites(created_by);
