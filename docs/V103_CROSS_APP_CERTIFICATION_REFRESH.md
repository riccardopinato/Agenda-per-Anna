# Anna's Diary — v1.03 Cross-App Certification Refresh

Status: **SOFTWARE PREPARED — BLOCKED ON PAIRED PHYSICAL EVIDENCE**

Factory baseline:
- App-Factory-Core `47c47f49a7b46812e3bd6f1231c3524f2b52b826`
- Master v26.6
- Golden Index v18
- `GOLDEN_CROSS_APP_VERIFICATION_v1_DRAFT`

Verification authority:
- AppLab v4.8 Cross-App Verification
- pinned process donor: `riccardopinato/AppLab@02f25d75b990055521869d75781e93893a6b6cdf`
- canonical verifier: `scripts/cross_app_verification.py`

## Existing historical evidence

Anna v0.96 and Wonderlog already completed a real physical round trip on
5 October 2026. The provenance ledger records exact historical APK hashes and
observed COPY/LINK/idempotency/handoff behavior.

That evidence remains valid for the claims actually observed at v0.96.

It is **not automatically promoted** to a v1.03 / AppLab v4.8 pair PASS because
the new process additionally requires:
- one explicit producer/consumer pair identity;
- complete semantic scenario matrix;
- explicit transport scenario;
- coherent lineage assertions;
- exact pair artifact binding;
- paired physical evidence references with SHA-256;
- trusted AppLab workflow attestation.

Historical PASS != new-process PASS.

## Canonical protocol boundary

Shared Ecosystem Core v1 remains the protocol source of truth. v1.03 does not:
- create another bridge protocol;
- change COPY/LINK semantics;
- add continuous background synchronization;
- share databases/accounts/keys;
- allow private/local media paths.

Anna's existing runtime bridge and domain tests remain authoritative for
single-app behavior.

## Required pair matrix

The AppLab v4.8 session must cover:

Semantic:
- COPY
- LINK
- IDEMPOTENCY
- PROVENANCE
- OWNERSHIP
- FAIL_CLOSED

Transport:
- DEEP_LINK_HANDOFF, or approved FALLBACK_TRANSPORT.

For the current installed-app Anna ↔ Wonderlog path the expected transport is
`deep_link`, therefore paired physical evidence is mandatory.

## Pair identity

Both artifacts must independently bind:
- repository;
- immutable source SHA;
- exact APK SHA-256;
- Android package id;
- versionName/versionCode;
- canonical app id.

The pair must use distinct package IDs and distinct APK bytes.

## Execution contract

1. Build exact signed Anna and Wonderlog candidates.
2. Record each exact artifact identity / Release Reality.
3. Install the exact pair on the physical test device(s).
4. Execute the full scenario matrix without changing the artifacts.
5. Record hashed screenshot/log/video/file/trace/report evidence references.
6. Fill `docs/V103_WONDERLOG_PAIR_SESSION_TEMPLATE.json`.
7. Run the trusted AppLab Cross-App Verification v4.8 workflow.
8. Preserve its pair digest and trusted output.
9. Only a verifier result `PASS` may close v1.03.

## Evidence ceiling

Repository tests can prove protocol compatibility and that the preparation
contract is fail-closed.

They cannot prove the new paired round trip. Until a real session is run:

**v1.03 = BLOCKED ON PAIRED PHYSICAL EVIDENCE**.
