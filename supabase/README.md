# Supabase backend — Anna's Diary

This directory contains the versioned cloud schema used by the current application, including private sync, **Noi ♡** shared spaces, Realtime, interactions, push-device registration and private shared-media Storage.

## Migration order

1. Create the dedicated Supabase project.
2. Apply every SQL file in `supabase/migrations/` in numeric order, starting from `001_cloud_sync.sql` through the latest migration committed in the repository.
3. In Auth enable Email/Password.
4. Configure the client with only:
   - Project URL
   - Publishable key
5. Never put the service-role key in the Flutter client.

Do not skip later migrations: they contain RLS hardening, RPC permissions, interaction cleanup, push infrastructure and shared-media policies required by current releases.

## Data model

`agenda_records` stores both private and shared synchronized records.

- `visibility = private` → `space_id IS NULL`, accessible only by the owner.
- `visibility = shared` → `space_id` is set, accessible only to authenticated members of that space.
- `record_key` is the deterministic sync identity.
- `deleted_at` implements tombstones.
- `client_updated_at` is used for deterministic offline conflict resolution.

Noi ♡ also uses dedicated tables for membership, invitations, comments, reactions, read state, push devices/delivery diagnostics and a private `shared-media` Storage bucket.

## Security

RLS is mandatory. Current migrations move membership checks behind the hardened `private.is_space_member()` security-definer helper, restrict Data API grants, protect synchronized record identity and clean shared interactions when an entry is deleted.

Invites and other privileged shared-space mutations are performed through the dedicated authenticated RPC functions defined by the migrations.

## Build configuration

Flutter reads:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

through `--dart-define`. The repository currently also contains production-safe publishable defaults; never add a service-role secret or other privileged credential to source control.

The app remains offline-first when cloud access is unavailable.
