# v1.05-A5 — Visual / Performance Baselines

## Goal

Freeze the v1.05 UX foundation before Memories & Recall 3.0 with one explicit
visual-regression policy and one bounded performance contract.

This step does not add product state, persistence, sync, routing or a new
performance subsystem.

## Factory baseline

- App-Factory-Core: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Master: v26.6
- Golden Index: v22
- Factory Mode: `ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

## Canonical visual surfaces

The existing AppLab visual journey remains the runtime source for screenshots
and UI hierarchy evidence.

A5 adds `.maestro/applab-visual.json` and classifies checkpoints by stability:

- **strict**: More, Settings Hub, Backup, Account, Personalization;
- **standard**: Today, People, Shared, Trash, functional navigation;
- **dynamic**: Calendar, Week, Memories, Life Archive.

Dynamic views retain layout/regression coverage without treating expected
date/content churn as a strict static screenshot.

The new `settings-hub` checkpoint covers the v1.05-A4 category-first Settings
surface and asserts the existing semantic route identifiers.

Private Vault remains intentionally outside screenshot baselines because its
`FLAG_SECURE` boundary is part of the security contract.

## Performance baseline

A5 reuses the existing deterministic 10,000-memory regression in
`test/v100_golden_core_cleanup_test.dart`.

The contract remains:

- 10,000 diary memories;
- derive memory references;
- run canonical personal search;
- run Life Archive projection;
- complete the combined hot path in less than 10 seconds in the Flutter test
  environment.

No FTS database, secondary search index or parallel memory store is introduced.

AppLab continues to own runtime performance evidence for the exact APK:

- cold/warm startup;
- process PSS;
- janky-frame percentage;
- APK size;
- regression comparison against the previous passing baseline.

A passing A5 AppLab run may establish/update the trusted-runtime performance
baseline for the exact source/artifact pair.

## Physical performance boundary

A5 does **not** infer real-device performance from Flutter tests, Web, CI or an
emulator.

Real-device startup, scroll/jank, memory and interaction measurements remain
**NOT VERIFIED** until recorded against a physical device and exact artifact.
That evidence can be added without changing product code.

## Acceptance

Software baseline preparation is complete when:

- the visual policy validates;
- Settings Hub is part of the canonical visual journey;
- the 10,000-memory performance guard remains enforced;
- Development and AppLab pass on the same final SHA;
- Web and Android size audit are N/A for this step unless runtime/build inputs change,
  because A5 modifies only test, Maestro and documentation contracts;
- the first eligible AppLab run promotes valid visual/performance baselines.

Physical performance remains a separate evidence lane and is never fabricated.
