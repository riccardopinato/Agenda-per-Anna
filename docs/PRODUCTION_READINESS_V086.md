# Anna's Diary — v0.86 Production Readiness

v0.86 is a security/governance hardening release. It keeps the established local-first architecture and does not add a parallel persistence system or generative-AI dependency.

## Release scope

- atomic owner claim for the Noi ♡ shared-password key fingerprint;
- revision-safe shared credential create/update/delete under row locking;
- server-authoritative shared credential modification timestamps;
- atomic one-shot pairing-envelope consumption;
- database rejection of plaintext shared credential fields and invalid encrypted/tombstone payloads;
- explicit rejection of protected password writes through the legacy generic merge RPC;
- immediate local key/mirror purge after authoritative membership reconciliation when the Vault is unlocked;
- encrypted E2EE recovery package kept outside ordinary backup;
- Private Vault password-wrap hardening with backward-compatible upgrade;
- explicit Web security-boundary disclosure;
- Vault/shared-password localization alignment;
- canonical Product Bible and v0.86 documentation alignment.

## Required technical gates

The release candidate is mergeable only when the current PR head reports success for:

1. Development checks — locked dependencies, static analysis, full Flutter test suite and Web release build.
2. Web build/deploy validation required by the repository workflow.
3. Android production-equivalent ARM64 size audit.
4. AppLab Production Gate and Trusted Verify.
5. Release metadata check for v0.86.0+96.

A green build is necessary but is not by itself evidence of a complete multi-device E2EE lifecycle.

## Shared-password automated evidence

Repository tests must keep proving:

- encrypted Vault mirror revision persistence;
- 600,000-iteration KDF for new Vault wraps;
- compatibility path for legacy 180,000-iteration Vault metadata;
- atomic key-claim RPC contract;
- compare-and-swap revision propagation through shared UI and Vault mirrors;
- protected-record rejection through the generic merge path;
- atomic pairing-envelope consume contract;
- server-authoritative modification timestamps;
- plaintext shared credential fields rejected at the database boundary;
- recovery package APIs remain outside normal backup;
- authoritative membership refresh invokes local shared-password reconciliation;
- Web security-boundary warning remains visible on Vault/password surfaces.

## Transactional Supabase verification — 30 September 2026

Migration `027_shared_password_hardening_v086.sql` and the two-user backend contract were executed against the real Anna's Diary Supabase project inside a single transaction followed by `ROLLBACK`.

The verification used two existing authenticated identities without persisting test data and passed all of these invariants:

- first owner key claim succeeds;
- a second different owner key claim cannot replace the first fingerprint;
- a non-owner cannot claim shared-password key metadata;
- first credential mutation commits revision 1;
- a stale update is rejected with the revision-conflict contract;
- a valid update advances revision 1 → 2;
- a stale delete is rejected;
- a valid delete advances revision 2 → 3;
- the legacy generic merge endpoint cannot mutate a protected shared credential;
- a pairing envelope is returned once and cannot be consumed a second time;
- a deliberately future client timestamp is not accepted as the authoritative commit timestamp;
- after member removal, that member cannot create another shared credential.

Because the transaction was rolled back, migration 027 is **not yet deployed to production** by this verification.

This proves the database authorization/concurrency contract on the live backend. It does not simulate two physical app installations, clipboard behavior, local Android Keystore state, or UI pairing across two devices.

## Remaining runtime boundary

AppLab now includes the Private Vault surface in its critical journey and verifies release-mode Android stability around the local security UI.

A true two-device, two-account client exercise remains the final end-to-end evidence for:

`owner device → pairing code → second device import → create → concurrent edit conflict → delete → membership removal → reconnect/local purge`.

Until that physical/client-level exercise is executed, the correct statement is:

**backend multi-user security contract VERIFIED; full two-device client E2EE lifecycle NOT VERIFIED.**

## Backend migration sequencing

Migration 027 changes the Password Noi ♡ write contract. Older v0.85 clients are not revision-aware and must not be treated as compatible writers after deployment.

Safe rollout order:

1. finish and merge the v0.86 client after all repository gates are green;
2. produce the signed v0.86 Android artifact and stable Web build;
3. make v0.86 available to the intended test users/devices;
4. deploy migration 027 to the production Supabase project;
5. run Supabase security/performance advisors;
6. run the physical two-account/two-device lifecycle test;
7. only then mark the shared-password lifecycle production-certified.

## Android signing

Stable-signing workflows and GitHub secret contracts are functional.

Public/store release still requires deliberate signing-key custody. If a signing private key has been exposed outside its intended secure custody boundary before the public release lineage is established, rotate it once before public distribution, update the protected repository secrets and preserve the replacement key offline.

A successful CI-signed APK proves signing configuration, not private-key custody.

## Dependency forward compatibility

The current dependency graph is buildable with Flutter 3.47.5.

Some upstream Android plugins may still emit Flutter's Built-in Kotlin migration warning. `firebase_core` and `flutter_timezone` are already on their current package versions for this baseline; `flutter_image_compress` resolves to 2.5.1, which includes its Android Gradle/Kotlin-mode compatibility fix.

Do not add local forks merely to hide a forward-compatibility warning. Re-evaluate these plugins before the next Flutter/Gradle toolchain upgrade.

## Store readiness

A public Play release additionally requires, as applicable:

- current Privacy Policy / Data Safety declarations;
- AAB production build;
- Play Internal Testing installation/update verification;
- retained obfuscation symbols for diagnostics;
- final permissions review;
- accepted signing-key custody;
- production migration 027 deployed;
- Supabase advisors reviewed after deployment;
- physical two-device shared-password verification.

## Current decision

v0.86 can merge when the current PR head is fully green because migration 027 is versioned in source and is not automatically deployed by the merge.

Store/public certification remains a separate gate.
