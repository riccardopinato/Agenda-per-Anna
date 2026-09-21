-- Agenda per Anna - v0.15 Cloud Sync schema
-- Designed now so v0.16 can add shared spaces without changing personal records.

create extension if not exists pgcrypto;

create table if not exists public.shared_spaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Spazio condiviso',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.space_members (
  space_id uuid not null references public.shared_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member'
    check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (space_id, user_id)
);

create table if not exists public.space_invites (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.shared_spaces(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  code_hash text not null unique,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.agenda_records (
  record_key text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  space_id uuid references public.shared_spaces(id) on delete cascade,
  visibility text not null default 'private'
    check (visibility in ('private', 'shared')),
  entity_type text not null,
  entity_id text not null,
  payload jsonb,
  client_updated_at timestamptz not null,
  deleted_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint agenda_records_scope_check check (
    (visibility = 'private' and space_id is null)
    or
    (visibility = 'shared' and space_id is not null)
  )
);

create index if not exists agenda_records_owner_idx
  on public.agenda_records(owner_id, updated_at);

create index if not exists agenda_records_space_idx
  on public.agenda_records(space_id, updated_at)
  where space_id is not null;

create index if not exists agenda_records_entity_idx
  on public.agenda_records(entity_type, entity_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists agenda_records_set_updated_at
  on public.agenda_records;
create trigger agenda_records_set_updated_at
before update on public.agenda_records
for each row execute function public.set_updated_at();

drop trigger if exists shared_spaces_set_updated_at
  on public.shared_spaces;
create trigger shared_spaces_set_updated_at
before update on public.shared_spaces
for each row execute function public.set_updated_at();

alter table public.agenda_records enable row level security;
alter table public.shared_spaces enable row level security;
alter table public.space_members enable row level security;
alter table public.space_invites enable row level security;

create or replace function public.is_space_member(target_space_id uuid)
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
      and sm.user_id = auth.uid()
  );
$func$;

revoke all on function public.is_space_member(uuid) from public;
grant execute on function public.is_space_member(uuid) to authenticated;

-- Personal records: only their owner.
-- Shared records: any current member of that shared space.
drop policy if exists "agenda_records_select" on public.agenda_records;
create policy "agenda_records_select"
on public.agenda_records
for select
to authenticated
using (
  (visibility = 'private' and owner_id = auth.uid())
  or
  (
    visibility = 'shared'
    and public.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "agenda_records_insert" on public.agenda_records;
create policy "agenda_records_insert"
on public.agenda_records
for insert
to authenticated
with check (
  (visibility = 'private' and owner_id = auth.uid() and space_id is null)
  or
  (
    visibility = 'shared'
    and owner_id = auth.uid()
    and public.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "agenda_records_update" on public.agenda_records;
create policy "agenda_records_update"
on public.agenda_records
for update
to authenticated
using (
  (visibility = 'private' and owner_id = auth.uid())
  or
  (
    visibility = 'shared'
    and public.is_space_member(agenda_records.space_id)
  )
)
with check (
  (visibility = 'private' and owner_id = auth.uid() and space_id is null)
  or
  (
    visibility = 'shared'
    and public.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "agenda_records_delete" on public.agenda_records;
create policy "agenda_records_delete"
on public.agenda_records
for delete
to authenticated
using (
  (visibility = 'private' and owner_id = auth.uid())
  or
  (
    visibility = 'shared'
    and public.is_space_member(agenda_records.space_id)
  )
);

drop policy if exists "shared_spaces_select" on public.shared_spaces;
create policy "shared_spaces_select"
on public.shared_spaces
for select
to authenticated
using (
  owner_id = auth.uid()
  or public.is_space_member(shared_spaces.id)
);

drop policy if exists "shared_spaces_insert" on public.shared_spaces;
create policy "shared_spaces_insert"
on public.shared_spaces
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "shared_spaces_update_owner" on public.shared_spaces;
create policy "shared_spaces_update_owner"
on public.shared_spaces
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "space_members_select" on public.space_members;
create policy "space_members_select"
on public.space_members
for select
to authenticated
using (
  user_id = auth.uid()
  or public.is_space_member(space_members.space_id)
);

-- Membership and invite writes are intentionally reserved for v0.16 RPCs.
-- This prevents users from self-adding to arbitrary spaces before the
-- invitation-code flow is implemented.

grant select, insert, update, delete
  on public.agenda_records to authenticated;
grant select, insert, update
  on public.shared_spaces to authenticated;
grant select
  on public.space_members to authenticated;

revoke all on public.space_invites from anon, authenticated;
