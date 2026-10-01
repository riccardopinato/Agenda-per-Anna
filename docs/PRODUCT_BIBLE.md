# Anna's Diary — Product Bible

**Status:** canonical product source of truth  
**Current release line:** v0.92  
**Last aligned:** 1 October 2026

This document defines what Anna's Diary is, what it is not, and the product/security invariants that future work must preserve. Implementation details belong in `docs/ARCHITECTURE.md`; execution sequencing belongs in `docs/ROADMAP.md`.

## 1. Product identity

Anna's Diary is a **personal-life diary, lightweight personal agenda and memory space** designed for low-friction capture and later recall.

Its primary promise is:

> Capture the important parts of everyday life quickly, keep them accessible offline, and bring them back in useful personal context without turning private life into a work-management system.

The product includes a deliberately bounded shared area, **Noi ♡**, for memories, agenda content and explicitly shared utilities between trusted members.

## 2. Product boundaries

### In scope

- personal agenda, reminders and recurring life events;
- daily timeline / "My day";
- private diary: text, photo, voice and sketch;
- people, birthdays and lightweight place references;
- deterministic memories / resurfacing / life archive;
- private shopping and workout history/plans at lightweight personal scope;
- local-first search and organization;
- one-way explicit copy toward Notes-compatible text;
- Noi ♡ shared agenda, memories, interactions and lightweight shared utilities;
- encrypted Private Vault and Password Vault;
- private menstrual-cycle tracking inside the encrypted Vault, with deterministic estimates and no health diagnosis;
- E2EE Noi ♡ shared passwords.

### Out of scope

Anna's Diary must not become:

- a Notion/workspace/project-management clone;
- a CRM/contact-management system;
- a professional task/database platform;
- a health diagnosis or psychological profiling system;
- an autonomous life narrator;
- a system that silently exports intimate data to another product.

Work/study knowledge management belongs to **Notes-Ecosistema**. Reusable code may be shared; private datasets, keys and authorization scopes must remain separate.

## 3. Core product architecture

The product follows four rules:

1. **One capture path where practical.**
2. **Canonical domain data stays in its owning store; derived views do not duplicate ownership.**
3. **Views such as Today, Memories, People, Places, Search and Life Archive project existing data.**
4. **Privacy, sync, backup and search are service layers, not competing content silos.**

New features must extend existing models/services before introducing parallel persistence or duplicate write paths.

## 4. Local-first and offline trust

Ordinary personal content is local-first and must remain usable without a cloud account.

Cloud services are optional for:

- multi-device private synchronization;
- Noi ♡ collaboration;
- remote push/web-push delivery;
- authenticated account/data-rights operations.

Login or network loss must not block access to ordinary local content already owned by the user.

Noi ♡ shared passwords are intentionally different: an encrypted local mirror can be read offline after Vault unlock, while authoritative modification/deletion requires an authenticated connection so concurrent secret changes cannot silently diverge.

## 5. Data ownership and lifecycle

### Ordinary private content

User-creatable private entities use the established account-scoped Trash model where applicable:

`live → Trash → restore or permanent purge`.

Permanent purge must respect references, reminders and media cleanup and create the established safety recovery point where required.

### Shared Noi ♡ content

Shared content is collaboratively owned and therefore does not enter private Trash. It uses shared tombstones, authorization and deterministic synchronization.

Leaving a space affects the current member. Deleting an owned space is destructive for all members and remains owner-authorized.

### Private Vault

The Private Vault is a distinct local security boundary:

- encrypted at rest;
- excluded from ordinary cloud sync;
- excluded from global search;
- excluded from ordinary backup;
- permanent deletion is explicit;
- an explicit portable encrypted recovery package may be created and restored by the user; it is not part of ordinary backup or cloud sync;
- recovery must verify the original Vault password and ciphertext integrity before replacing local Vault state;
- menstrual-cycle data belongs to this same Vault boundary and must not enter ordinary sync, search or backup;
- cycle/fertility estimates are deterministic projections over user-entered data and must never be presented as contraception, diagnosis or medical advice.

Personal credentials are never automatically promoted to Noi ♡.

## 6. Shared-password security contract

Password Noi ♡ must preserve all of these invariants:

- credential plaintext is encrypted client-side before reaching the backend;
- AES-256-GCM protects credential payloads;
- AAD binds ciphertext to the shared-space ID and credential ID;
- the backend must not receive service, username, email, password or notes in plaintext;
- each shared space has one authoritative 256-bit password key;
- key initialization is atomic: first valid owner claim wins;
- the server stores only a key fingerprint, never the raw space key;
- additional devices obtain the key only through an explicit E2EE pairing or encrypted recovery package;
- credential updates/deletions are revision-checked; stale writes must fail instead of overwriting silently;
- shared credential modification time is server-authoritative after commit;
- pairing envelopes are consumed atomically and cannot be redeemed twice through the supported client path;
- Noi ♡ is authoritative and the Private Vault mirror must not diverge;
- authoritative membership reconciliation removes stale local shared-password keys and mirrors;
- removed/offline devices cannot be remotely wiped while disconnected; local purge happens at the next successful authoritative membership reconciliation while the Vault is available.

Any future change that weakens these invariants requires an explicit security review.

## 7. Privacy and permissions

- Android device/application backup for local diary data remains disabled.
- Sensitive Vault screens use secure-screen protection on supported native platforms.
- Web cannot provide Android Keystore or screenshot blocking; this reduced protection must be disclosed in the UI.
- Permissions must be requested just in time and only for active product capabilities.
- External calendar integration is read-only.
- Service-role and other privileged backend secrets must never enter the Flutter client or repository.
- Account deletion remains authenticated server-side and separate from local Vault deletion.

## 8. AI policy

The v0.86 product does **not** depend on generative AI.

Current intelligent/derived functionality may include deterministic logic and on-device processing such as local photo OCR. Original user content remains authoritative.

Future AI may assist with capture, retrieval or organization only when it provides clear user value and preserves privacy. It must not:

- silently rewrite diary entries;
- present psychological/emotional inference as fact;
- make cloud AI mandatory for core diary/search/offline use;
- bypass authorization or private-scope boundaries.

## 9. Free/Premium status

As of v0.91 Premium capability checks are centralized behind one RevenueCat-backed entitlement service using the entitlement identifier `premium`. Monthly/lifetime pricing is owned by the active RevenueCat Offering and is not duplicated in app code. A custom Flutter paywall is the shared Android/iOS/Web presentation layer. Existing diary, agenda, Private Vault and v0.88 cycle-core capabilities remain FREE; losing Premium must never delete, rewrite or hide user-owned historical data. From v0.92, Premium preview is not implicitly enabled in release builds. Debug builds and explicit QA channels may enable preview, while a store release must set `ANNA_STORE_RELEASE=true`, keep `ANNA_PREMIUM_PREVIEW=false`, and provide the RevenueCat platform key. A store release with preview enabled or a missing RevenueCat key is invalid by product contract.

If monetization is introduced later:

- Free must remain useful and reliable.
- Premium must unlock genuine added value, capacity, automation or convenience.
- Entitlements must be centralized rather than hardcoded across UI screens.
- Losing an entitlement must never delete user-owned data.

## 10. Platforms and localization

Primary implementation: Flutter/Dart.

Supported product surfaces:

- Android native application;
- Web/PWA for supported flows and cross-platform access.

Native-only functionality may degrade or be unavailable on Web, but the limitation must be explicit rather than simulated.

Supported app languages:

- English;
- Italian;
- Spanish;
- French;
- Portuguese.

Device-language selection, manual selection and English fallback remain the localization contract.

## 11. Accessibility and friction

New work must minimize taps, duplicate decisions and setup burden.

Required principles:

- clear default paths;
- progressive disclosure for advanced/security functions;
- meaningful loading/empty/error states;
- standard touch targets;
- semantic labels and logical focus order;
- destructive actions proportionate to their impact;
- privacy/security steps may add friction only when they materially reduce risk.

## 12. Performance and size

Performance, battery and application size are product requirements.

Avoid duplicate listeners, polling, unbounded caches and unnecessary background work. Large dependencies must justify their value.

The product does **not** sacrifice meaningful local capability merely to save a small number of megabytes. On-device OCR is currently an intentional capability with a measurable binary-size cost.

## 13. Release invariants

A green build is not equivalent to a verified feature.

A release candidate must, as applicable, pass:

- locked dependency resolution;
- formatting/static analysis;
- full Flutter test suite;
- Web release build;
- production-equivalent Android ARM64 build/size audit;
- AppLab runtime/visual gate;
- signed Android artifact validation;
- release metadata alignment;
- documentation alignment.

Public/store release additionally requires valid signing custody, store privacy/Data Safety review and the appropriate Play distribution validation.

## 14. Source-of-truth hierarchy

When documents disagree, use:

1. **Product Bible** — product identity, scope, privacy and approved behavior.
2. **Current implementation** — what the application actually does.
3. **Roadmap** — execution status and future sequence.
4. **Architecture / Security / Release documentation** — implementation contracts.
5. **README** — release summary.
6. Historical discussions/backlog — ideas only until approved.

The roadmap or backlog must never silently redefine the product against this Bible.
