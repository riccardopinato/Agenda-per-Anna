-- v0.27 - Noi ♡ interactions: comments, heart reactions and read state.

create table if not exists public.shared_entry_comments (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.shared_spaces(id) on delete cascade,
  entry_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null default '',
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists shared_entry_comments_space_entry_created_idx
  on public.shared_entry_comments(space_id, entry_id, created_at);

alter table public.shared_entry_comments enable row level security;

create policy shared_entry_comments_select
on public.shared_entry_comments for select to authenticated
using (private.is_space_member(space_id));

create policy shared_entry_comments_insert
on public.shared_entry_comments for insert to authenticated
with check (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

create policy shared_entry_comments_update_own
on public.shared_entry_comments for update to authenticated
using (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
)
with check (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

create policy shared_entry_comments_delete_own
on public.shared_entry_comments for delete to authenticated
using (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

grant select, insert, update, delete
  on public.shared_entry_comments to authenticated;

create table if not exists public.shared_entry_reactions (
  space_id uuid not null references public.shared_spaces(id) on delete cascade,
  entry_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null default 'heart' check (kind = 'heart'),
  created_at timestamptz not null default now(),
  primary key (space_id, entry_id, user_id, kind)
);

create index if not exists shared_entry_reactions_space_entry_idx
  on public.shared_entry_reactions(space_id, entry_id);

alter table public.shared_entry_reactions enable row level security;

create policy shared_entry_reactions_select
on public.shared_entry_reactions for select to authenticated
using (private.is_space_member(space_id));

create policy shared_entry_reactions_insert
on public.shared_entry_reactions for insert to authenticated
with check (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

create policy shared_entry_reactions_delete_own
on public.shared_entry_reactions for delete to authenticated
using (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

grant select, insert, delete
  on public.shared_entry_reactions to authenticated;

create table if not exists public.space_member_reads (
  space_id uuid not null references public.shared_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_seen_at timestamptz not null default now(),
  primary key (space_id, user_id)
);

create index if not exists space_member_reads_space_seen_idx
  on public.space_member_reads(space_id, last_seen_at desc);

alter table public.space_member_reads enable row level security;

create policy space_member_reads_select
on public.space_member_reads for select to authenticated
using (private.is_space_member(space_id));

create policy space_member_reads_insert_own
on public.space_member_reads for insert to authenticated
with check (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

create policy space_member_reads_update_own
on public.space_member_reads for update to authenticated
using (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
)
with check (
  user_id = (select auth.uid())
  and private.is_space_member(space_id)
);

grant select, insert, update
  on public.space_member_reads to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_entry_comments'
  ) then
    alter publication supabase_realtime add table public.shared_entry_comments;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_entry_reactions'
  ) then
    alter publication supabase_realtime add table public.shared_entry_reactions;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'space_member_reads'
  ) then
    alter publication supabase_realtime add table public.space_member_reads;
  end if;
end $$;
