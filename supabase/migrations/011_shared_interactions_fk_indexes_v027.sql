-- Cover foreign keys added by v0.27 interaction tables.

create index if not exists shared_entry_comments_user_id_idx
  on public.shared_entry_comments(user_id);

create index if not exists shared_entry_reactions_user_id_idx
  on public.shared_entry_reactions(user_id);

create index if not exists space_member_reads_user_id_idx
  on public.space_member_reads(user_id);
