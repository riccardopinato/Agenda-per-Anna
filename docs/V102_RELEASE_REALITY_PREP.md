# Anna's Diary — v1.02-A/C/D Release Reality Preparation

Status: **SOFTWARE PREPARED — external evidence remains BLOCKED**

Factory baseline:
- App-Factory-Core `47c47f49a7b46812e3bd6f1231c3524f2b52b826`
- Master v26.6
- Golden Index v18
- Release Reality / Physical Validation process candidate
- Entitlement Contract v1 provider-agnostic Golden

## Purpose

Prepare Anna's Diary so native physical certification and Google Play /
RevenueCat QA can be attached to one exact artifact identity without converting
build success into physical, distribution or Store evidence.

## Generic Release Reality

`tool/create_release_reality.py` emits a non-secret record containing:

- project / repository;
- version and build number;
- source ref and immutable source SHA;
- variant and package ID;
- artifact filename and SHA-256;
- signing-certificate SHA-256;
- workflow run;
- distribution channel;
- evidence level;
- UTC validation timestamp.

Candidate workflows are deliberately emitted as `ARTIFACT_BUILT`.

A later operator/device/store exercise may produce higher evidence, but it must
refer back to the exact artifact bytes/signing identity rather than editing the
candidate record into a fabricated PASS.

## v1.02-A — Native Physical Certification

The stable-signed ARM64 sideload workflow continues to generate
`PHYSICAL_CERTIFICATION_MANIFEST.json`.

The manifest now embeds the generic Release Reality identity while preserving
the existing D7 physical contract and `physicalVerification.status=PENDING`.

Real certification still requires the existing DS-01..DS-06,
VAULT-01..VAULT-04, NOI-01..NOI-03 and NATIVE-01..NATIVE-03 physical matrix,
including two distinct owner/member devices for the Noi ♡ gate.

No CI/AppLab result promotes this to PHYSICAL DEVICE VERIFIED.

## v1.02-C — Google Play / RevenueCat Real QA

The Premium Store QA workflow now emits:
- exact signed AAB;
- `STORE_QA_RELEASE_REALITY.json`;
- operator checklist;
- SHA-256 checksum.

`docs/V102_STORE_QA_EVIDENCE_TEMPLATE.json` is fail-closed and starts PENDING.

`tool/validate_v102_store_qa_evidence.py` accepts PASS only when:
- evidence, Release Reality and supplied AAB bytes match;
- signing identity matches;
- install source is Google Play Internal Testing, not sideload;
- a non-secret tester reference exists;
- STORE-01..STORE-09 are all explicitly executed PASS with observed results
  and evidence references.

Required Store scenarios cover catalog readiness, Monthly, Lifetime, restart,
reinstall/restore, no-grant failure/cancel/pending behavior and idempotent
re-delivery/restore.

CI can prepare the candidate. It cannot execute the purchase authority of
Google Play.

## v1.02-D — Stable Release Candidate

Stable release promotion remains blocked until both:
- v1.02-A physical evidence passes on exact candidate bytes; and
- v1.02-C Internal Testing evidence passes on exact Store AAB bytes.

The preferred release process is:

`build once -> record identity -> verify exact bytes -> distribute exact bytes`.

Rebuilding after physical/distribution verification creates a new artifact and
therefore requires evidence reconciliation or revalidation.

## Evidence ceiling

Current software preparation can become TESTED / CI GREEN / ARTIFACT BUILT /
TRUSTED RUNTIME VERIFIED as applicable.

It cannot claim:
- PHYSICAL DEVICE VERIFIED;
- DISTRIBUTION VERIFIED;
- STORE READY;
- PRODUCTION RELEASED.

Those levels require the corresponding real external execution.
