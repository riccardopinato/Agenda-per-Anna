-- v0.29 - allow authenticated members to replace the deterministic
-- media object for an entry while preserving private bucket RLS.

drop policy if exists shared_media_update_members on storage.objects;
create policy shared_media_update_members
on storage.objects
for update
to authenticated
using (
  bucket_id = 'shared-media'
  and array_length(storage.foldername(name), 1) >= 1
  and private.is_space_member(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'shared-media'
  and array_length(storage.foldername(name), 1) >= 1
  and private.is_space_member(((storage.foldername(name))[1])::uuid)
);
