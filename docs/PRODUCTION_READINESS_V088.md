# Anna's Diary — v0.88 Production Readiness

v0.88 is a certification-hardening release over the v0.87 Web Vault hotfix.
It does not introduce a parallel persistence engine, new cloud ownership model
or generative-AI dependency.

## Release scope

- real Chrome/IndexedDB Private Vault persistence and unlock E2E regression;
- wrong-password preservation regression on the real browser storage path;
- explicit personal-Vault local-only/data-loss contract in UI and Product Bible;
- separation between personal Vault data and the existing Noi ♡ E2EE recovery contract;
- accessibility gate for touch targets, semantics, contrast and 200% text scaling;
- repository-wide Dart formatting gate;
- v0.88 release/security/documentation alignment.

## Private Vault recovery decision

Personal Vault notes and personal passwords remain intentionally device-local.
They are excluded from ordinary cloud sync, global search and ordinary backup.

v0.88 does **not** add a generic Vault recovery package because the same Vault
payload can contain Noi ♡ local mirrors and shared-space keys. A stale generic
Vault restore path could weaken the existing shared revocation model.

The product contract is therefore explicit:

- personal Vault content is unrecoverable after local/browser/device data loss;
- this limitation is disclosed before Vault creation and while the Vault is open;
- Noi ♡ credentials remain governed by their separate E2EE pairing/recovery and
  authoritative membership-reconciliation contract.

## Browser Vault acceptance

The release candidate must prove in Chrome that the production Web path can:

1. create a 600,000-iteration Vault;
2. persist encrypted content in the IndexedDB-backed local store;
3. discard all in-memory Vault state;
4. reopen the persisted state as after a browser/PWA reload;
5. derive the password key through browser Web Crypto;
6. decrypt the existing payload;
7. recover the expected private note and personal credential;
8. reject a wrong password without erasing or mutating the stored Vault.

This is separate from the existing PBKDF2 compatibility-vector test.

## Accessibility acceptance

The core shell must pass Flutter's automated:

- Android touch-target guideline;
- labeled-tap-target guideline;
- text-contrast guideline;
- 200% text-scaling smoke without layout exceptions.

Automated accessibility checks do not replace real screen-reader testing, but
they are now a mandatory repository gate rather than an undocumented assumption.

## Backend state

The production Supabase project reports migration
`shared_password_hardening_v086` as applied on 1 October 2026. The previous
v0.86 note that migration 027 was only transactionally verified is therefore
superseded.

The current Supabase security advisor reports two warnings:

1. `pg_net` extension in `public` — retained intentionally because the
   installed extension is non-relocatable and the current Web Push path relies
   on the supported `net` API. Do not break production Web Push to silence a
   generic advisor.
2. leaked-password protection disabled — Supabase documents this feature as
   available on Pro Plan and above. It belongs to the hosted Auth configuration,
   not Flutter or SQL. The current ChatGPT Supabase connector can inspect this
   advisor but does not expose Auth-config mutation, so repository code must not
   fake remediation.

Google-first/passwordless authentication remains preferred. The legacy
email/password compatibility path keeps the advisor as an external hardening
item until the hosted Auth setting can be enabled on a supporting plan.

## Android signing

CI validates signing configuration without printing secret material. Store
certification additionally requires human custody of the production private
key and offline recovery copies. Repository automation can prove that a key is
usable; it cannot prove where a human stores every copy.

This custody boundary is documented rather than falsely marked as automated.

## Required gates

Before v0.88 is promoted to `main`, all of the following must be green:

1. locked dependency resolution;
2. repository-wide Dart formatting;
3. Flutter analyze;
4. complete Flutter test suite, including accessibility regressions;
5. Chrome PBKDF2 compatibility test;
6. Chrome persisted-Vault E2E test;
7. Web release build and deploy;
8. Android production-equivalent ARM64 size audit;
9. AppLab release build and Trusted Verify.

## Certification semantics

A green v0.88 repository head means the application code/runtime baseline is
release-candidate certified against the automated SHOS gates above.

It does **not** claim that plan-gated hosted Auth settings, private-key physical
custody or a two-physical-device user exercise were automatically performed by
CI. Those external/human boundaries must remain stated explicitly.

## Release metadata

- Version: v0.88.0
- Build: 98
