-- v0.28 - private shared media bucket for Noi ♡.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'shared-media',
  'shared-media',
  false,
  2097152,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy shared_media_select_members
on storage.objects
for select
to authenticated
using (
  bucket_id = 'shared-media'
  and array_length(storage.foldername(name), 1) >= 1
  and private.is_space_member(((storage.foldername(name))[1])::uuid)
);

create policy shared_media_insert_members
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'shared-media'
  and array_length(storage.foldername(name), 1) >= 1
  and private.is_space_member(((storage.foldername(name))[1])::uuid)
);

create policy shared_media_delete_members
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'shared-media'
  and array_length(storage.foldername(name), 1) >= 1
  and private.is_space_member(((storage.foldername(name))[1])::uuid)
);
