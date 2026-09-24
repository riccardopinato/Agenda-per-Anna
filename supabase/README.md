# Supabase backend — Anna's Diary

This directory contains the versioned cloud schema used by the current application, including private sync, **Noi ♡** shared spaces, Realtime, interactions, push-device registration and private shared-media Storage.

## Migration order

1. Create the dedicated Supabase project.
2. Apply every SQL file in `supabase/migrations/` in numeric order, starting from `001_cloud_sync.sql` through the latest migration committed in the repository.
3. In Auth enable Google as the primary provider. Keep Email/Password enabled only for existing-account migration/recovery.
4. Google OAuth setup:
   - Supabase callback: `https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback`
   - Site URL / Web return: `https://riccardopinato.github.io/Agenda-per-Anna/`
   - Additional redirect URL: `com.riccardopinato.agendaperanna://login-callback/**`
   - Google scopes: `openid`, email, profile
5. Configure the client with only:
   - Project URL
   - Publishable key
6. Never put the service-role key, Google client secret or other privileged credential in the Flutter client.

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


## v0.41 authentication and invitations

The app calls Supabase Google OAuth from the universal authentication gate. Android returns through the custom scheme configured by `tool/prepare_android_platform.py`; Web returns to the GitHub Pages path.

Migration `016_persistent_multi_member_invites_v041.sql` changes Noi ♡ invitation semantics:
- one owner-visible code is reused until its 24-hour expiry;
- the code is usable by multiple authenticated users;
- reopening the dialog never rotates the active code;
- explicit regeneration revokes the previous invite;
- `space_invites` remains unreadable to authenticated clients through the Data API;
- join lookup still uses the SHA-256 hash and server RPC boundary.
