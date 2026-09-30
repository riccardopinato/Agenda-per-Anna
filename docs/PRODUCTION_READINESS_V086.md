# Anna's Diary — v0.86 Production Readiness

v0.86 is a security/governance hardening release. It does not introduce a second persistence architecture or a generative-AI dependency.

## Release scope

- atomic owner claim for the Noi ♡ shared-password key;
- server-checked revisions for shared credential update/delete;
- database validation of encrypted shared-password envelopes;
- immediate local purge on authoritative membership reconciliation when the Vault is unlocked;
- encrypted E2EE recovery package;
- Private Vault password-wrap hardening with backward-compatible upgrade;
- explicit Web security-boundary disclosure;
- complete Vault/shared-password localization coverage for the v0.86 security flows;
- canonical Product Bible and documentation realignment.

## Required technical gates

The release candidate is mergeable only when the current PR head reports success for:

1. Development checks — locked dependencies, static analysis, full Flutter test suite and Web release build.
2. Web build/deploy validation required by the repository workflow.
3. Android production-equivalent ARM64 size audit.
4. AppLab Production Gate and Trusted Verify.
5. Release metadata check for v0.86.0+96.

A green build alone is not sufficient evidence for the live two-user E2EE path.

## Shared-password evidence requirements

Automated repository tests must prove:

- encrypted Vault mirror revision persistence;
- 600,000-iteration KDF for new Vault wraps;
- compatibility path for older Vault metadata remains present;
- atomic key-claim RPC contract exists;
- credential mutations require expected revisions;
- stale mutations are rejected by the backend contract;
- plaintext shared credential fields are rejected at the database boundary;
- recovery package APIs exist and remain outside ordinary backup;
- authoritative membership refresh invokes local shared-password reconciliation;
- Shared Password and mirrored Vault UI propagate revisions.

## Runtime verification boundary

AppLab can verify application/runtime stability and the local security surfaces available in its test journey. A true two-account, two-device Supabase exercise remains a separate integration requirement unless CI is explicitly provisioned with isolated test identities and a disposable backend.

Until that live path is executed, the correct status is:

**repository/runtime hardening verified; two-client production E2EE lifecycle NOT VERIFIED.**

The application must not claim otherwise.

## Backend migration sequencing

Migration `027_shared_password_hardening_v086.sql` changes the write contract for Password Noi ♡.

Safe rollout order:

1. produce and validate the v0.86 client/release candidate;
2. make the updated client available to the intended users;
3. deploy migration 027 to the production Supabase project;
4. run a live two-member pairing → create → concurrent-edit conflict → delete → member-removal test;
5. only then treat the shared-password lifecycle as production-certified.

Older v0.85 clients are not revision-aware, so migration 027 should not be deployed prematurely.

## Android signing

The repository now has working stable-signing workflow contracts. Public/store release additionally requires a deliberate signing-key custody decision.

If a signing private key has been exposed outside the intended secure custody boundary before public distribution, rotate it before establishing the public release lineage. Rotation requires replacing the corresponding protected repository signing secrets and preserving the new key offline.

This custody action is operational and cannot be considered complete merely because CI can build a signed APK.

## Store readiness

A public Play release also requires, as applicable:

- current Privacy Policy / Data Safety declarations;
- AAB production build;
- Play Internal Testing installation/update verification;
- symbol retention for obfuscated crash diagnostics;
- final permissions review;
- signing custody accepted;
- live backend migration and two-user shared-password verification.

## Current decision

v0.86 may be merged after repository gates are green because migration 027 is versioned in source and is not automatically deployed by merge.

Store/public certification remains separate from merge readiness.
