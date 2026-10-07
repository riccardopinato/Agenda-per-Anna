# Security Baseline — v0.94

Anna's Diary uses a layered security model across Flutter, Supabase Auth, Row Level Security, Edge Functions and Storage.

## Private Vault and shared-password security

v0.86 keeps the existing Vault and Noi ♡ storage boundaries and hardens their cryptographic/concurrency contracts.

- New Vault password wraps use PBKDF2-HMAC-SHA256 with 600,000 iterations and a 12-character minimum. Existing 180,000-iteration wraps remain readable and are upgraded after a successful password unlock.
- The Vault payload remains AES-GCM encrypted under a random 256-bit master key and remains excluded from ordinary cloud sync, global search and standard backup.
- Android keeps Keystore wrapping and secure-screen protection. Web keeps encrypted-at-rest payloads but cannot provide the same native Keystore/screenshot boundary; this difference is disclosed in-product.
- v0.87 runs Web Vault PBKDF2-HMAC-SHA256 derivation through asynchronous browser Web Crypto. KDF parameters and the encrypted Vault format remain unchanged, so this is a responsiveness/runtime fix rather than a cryptographic migration or downgrade.
- The v0.88 cycle tracker stores intimate-health logs only as a nested object in the same AES-GCM encrypted Vault payload. It has no ordinary sync/search/backup path; lock clears the decrypted in-memory cycle state together with notes, credentials and shared-password mirrors.
- v0.89 extends the same Vault boundary to basal temperature, cervical mucus, sexual-activity observations, ovulation-test results, custom symptoms and derived insights. The private report is created locally and reaches the clipboard only after an explicit user action; it has no automatic network/export path.
- v0.90 recovery packages preserve the existing password-wrapped master key and AES-GCM Vault envelope without exporting plaintext. The device-bound biometric wrap is removed. Restore verifies the package, password-derived key and authenticated payload before replacing local state, and invalid attempts are non-destructive.
- Recovery packages and cycle reports use best-effort clipboard compare-and-clear after 60 seconds. Ordinary cloud sync, global search and standard backup remain excluded.
- v0.91 RevenueCat integration receives only purchase/entitlement context and, when signed in, the existing Supabase UUID as App User ID. Email, display name, diary, agenda, Vault, passwords and menstrual-cycle content are not forwarded to the Premium service.
- RevenueCat public platform API keys are supplied through build-time defines. No secret API key is committed to the client. Premium access derives from RevenueCat CustomerInfo entitlement state, never from a locally editable preference.
- Anonymous purchase identity is permitted before login; subsequent Supabase login is linked through RevenueCat `logIn`, avoiding email-based or guessable identity.
- v0.92 makes Premium preview fail-closed for release builds. Store release mode rejects preview and rejects missing RevenueCat platform configuration before entitlement initialization.
- Signed store builds validate Premium configuration before compilation and receive the public RevenueCat Android SDK key only through GitHub Actions secrets; no private RevenueCat API credential is stored in the repository.
- QA preview builds (Pages, sideload and AppLab) intentionally omit the store key and are explicitly marked non-store so a test channel cannot be mistaken for production billing.
- v0.94 Store QA mode never grants Premium and never re-enables Preview. Entitlement remains derived only from RevenueCat CustomerInfo.
- Store QA diagnostics exclude RevenueCat API keys and raw App User IDs. The copyable QA report contains only release/build metadata, readiness booleans, Offering/product metadata, entitlement state and non-secret error text.
- The Internal Testing AAB uses the existing stable signing identity and receives the RevenueCat Android public SDK key only through GitHub Actions secrets. No Play service-account credential or RevenueCat private key is introduced.
- Real purchase testing is intentionally performed only through Google Play Internal Testing/license-tester infrastructure; a sideloaded APK is not accepted as billing proof.
- v0.93 cycle onboarding, multi-day period entry, daily check-ins, contraceptive reminder preferences and prediction-v2 inputs remain inside the same encrypted Private Vault payload. No cycle/health content is added to ordinary backup, global search, cloud sync, RevenueCat or analytics.
- Cycle notification content remains discreet by default. The optional explicit contraceptive reminder stores only enabled/time preferences; no medication name is required or persisted by this feature.
- Recurring cycle reminders reuse the existing local notification channel and do not create a remote notification profile.



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


## v1.00-D live backend and native-certification boundary — 7 October 2026

- The live Supabase project `agenda-per-anna` reports migration `20261001075952 shared_password_hardening_v086`, closing the previous uncertainty about production deployment of migration 027.
- The repository two-user transactional contract in `supabase/tests/027_shared_password_hardening_contract.sql` was executed against the live project and completed without error. It uses existing authenticated identities and rolls back all test rows.
- This proves the live backend contract for atomic key claim, pairing-envelope ownership/one-shot use, revision conflicts, dedicated RPC enforcement, delete semantics and removed-member rejection. It does **not** prove the two-device Flutter/Keystore client lifecycle.
- Supabase security advisors still report `auth_leaked_password_protection` disabled. The available connector cannot mutate Auth dashboard configuration, so this remains an explicit external configuration gate before Store Ready.
- The existing `pg_net` advisor warning remains accepted for the documented non-relocatable Web Push configuration; it must not be force-moved or removed merely to silence the advisor.
- Unused-index advisor items are informational and are not deleted without workload evidence.
- Physical Android certification must use a stable-signed artifact with recorded APK SHA-256, signing certificate SHA-256, commit, version/build, workflow run, device and OS evidence.

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
- dedicated Chrome Web Vault PBKDF2 compatibility test;
- Web release build;
- Android ARM64 release build;
- Android size audit;
- AppLab release APK build;
- trusted Android runtime verification;
- Maestro visual journey;
- screenshot/UI hierarchy checks;
- Logcat + crash/ANR scan.
