# Security Baseline — v0.86

Anna's Diary uses a layered security model across Flutter, Supabase Auth, Row Level Security, Edge Functions and Storage.

## Private Vault and shared-password security

v0.86 keeps the existing Vault and Noi ♡ storage boundaries and hardens their cryptographic/concurrency contracts.

- New Vault password wraps use PBKDF2-HMAC-SHA256 with 600,000 iterations and a 12-character minimum. Existing 180,000-iteration wraps remain readable and are upgraded after a successful password unlock.
- The Vault payload remains AES-GCM encrypted under a random 256-bit master key and remains excluded from ordinary cloud sync, global search and standard backup.
- Android keeps Keystore wrapping and secure-screen protection. Web keeps encrypted-at-rest payloads but cannot provide the same native Keystore/screenshot boundary; this difference is disclosed in-product.
- An unlocked Vault is re-locked after five minutes without pointer interaction, on app background/inactive states and when leaving the Password Noi ♡ surface. Explicit manual lock remains available.
- Password Noi ♡ credential plaintext is encrypted client-side with AES-256-GCM and AAD bound to shared-space and credential identity.
- The server stores only ciphertext metadata plus a SHA-256 key fingerprint, never the raw shared password key.
- Migration 027 makes key metadata an atomic owner-only first claim and immutable afterwards.
- Shared credential writes and deletions use revision checks under row locking. Stale mutations fail instead of replacing a newer secret.
- Shared credential timestamps are generated at commit time by PostgreSQL; client clocks do not define the authoritative “last updated” value.
- The legacy generic merge RPC and direct Data API writes reject all protected shared-password entity types (credential, key metadata and pairing envelope), so mutations cannot bypass their dedicated RPC contracts.
- Pairing-envelope creation is owner-only through a dedicated RPC; redemption uses a row-locked atomic consume RPC that returns a live envelope once and tombstones it in the same transaction.
- The database rejects plaintext credential fields and invalid encrypted/tombstone payload shapes.
- One-time pairing remains explicit and short-lived. v0.86 also supports an explicitly created recovery package encrypted with a separate recovery password; it is not part of ordinary backup.
- Successful authoritative membership refresh purges stale local shared-password keys and mirrors when the Vault is unlocked. Offline devices cannot be remotely wiped; purge occurs at the next successful reconnect/reconcile.

## Account deletion

- `delete-account` requires a valid user JWT and an explicit `DELETE_MY_ACCOUNT` marker.
- The function resolves the user with Supabase Auth before using service-role capabilities.
- Service-role credentials are never embedded in the Flutter client.
- Shared Storage deletion is constrained to:
  - complete folders of spaces owned by the deleting user; or
  - media paths referenced by that user's shared records **only when the path begins with the record's own `space_id/` prefix**.
- The Auth user deletion remains the authoritative cascade boundary for account-owned database rows.

This prefix constraint is mandatory because JSON payloads are mutable user data and must never be treated as an unrestricted Storage path when executing with service-role privileges.

## Web Push tables

`web_push_reminders` and `web_push_subscriptions`:

- keep RLS enabled;
- expose user-owned CRUD policies only to `authenticated`;
- no longer grant table privileges to `anon`;
- remain available to privileged backend delivery through the service role.

## Shared-space functions

The internal `private.*_impl` functions use `SECURITY DEFINER`, but authentication and ownership checks are performed inside the functions themselves.

The public RPC wrappers are `SECURITY INVOKER`. Their current ability to call the private implementations is intentional; revoking the private execution grants without redesigning the wrappers would break the production RPC path.

## pg_net advisor warning

Supabase currently reports `extension_in_public` for `pg_net`.

For the installed version:

- `pg_net` is reported as non-relocatable;
- its operational API is created under the dedicated `net` namespace;
- Supabase documentation describes `create extension pg_net` as the supported enablement path and notes that the extension creates its own `net` schema.

v0.50 therefore does **not** drop/recreate or forcibly relocate the extension. That would risk the Web Push cron path for a generic linter warning.

## Leaked-password advisor warning

Supabase currently reports `auth_leaked_password_protection` disabled.

Anna's Diary is Google-first and does not expose new email/password registration in the current account UI; email/password remains a compatibility sign-in path for older accounts.

The platform setting should still be enabled when a supported authenticated project-configuration control is available. It is not simulated client-side because leaked-password screening belongs at the Auth service boundary, not in Flutter.

## Release gate

Every v0.50 merge requires:

- locked dependencies;
- Flutter analyze;
- full tests;
- Web release build;
- Android ARM64 release build;
- Android size audit;
- AppLab release APK build;
- trusted Android runtime verification;
- Maestro visual journey;
- screenshot/UI hierarchy checks;
- Logcat + crash/ANR scan.
