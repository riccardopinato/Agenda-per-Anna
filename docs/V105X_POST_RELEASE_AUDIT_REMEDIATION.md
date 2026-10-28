# Anna's Diary — v1.05.x audit remediation

Status: **IMPLEMENTED CANDIDATE — exact-head gates pending**

Baseline: v1.05 Completed `7bb4a672b8ec3eabc7cbae5f8dc2ab764837de03`.
Factory baseline: App-Factory-Core `7b84e33df715cf2a48bda7c7495d0690819bff0f`; Master 26.6; Golden Index 23.
PR: #134. No v1.06 scope.

## Findings and corrective intent

| ID | Audit severity | Scope and status |
| --- | --- | --- |
| A-01 | P1 | Template picker opens note editor with draft text; no pre-save |
| A-02 | P1 | Re-entrancy guard while selecting/editing/saving; cancelled attempts do not write |
| A-03 | P1 | Three-way journal merge: unchanged local fields retain remote updates; competing same-field edits require an explicit decision; account/date revalidated |
| A-04 | P1 | Failed journal persistence restores pre-write RAM state and in-memory sync projections; snapshot failure no longer falsely reports committed data as failed |
| A-05 | P2 | Widget test: picker -> editor -> cancel/save plus domain and conflict tests; physical UI remains separate |
| A-06 | P2 | Stable canonical preset tags for new entries; existing localized tags remain untouched and readable |
| A-07 | P2 | Index people by ID and use per-thread Set to deduplicate in linear time; no new store/cache owner |
| A-08 | P2 | Collection details resolve current filter by ID and subscribe to settings/journal revisions |
| A-09 | P2 | Template editor turns Unicode prompt squares into ordinary bullets; explicitly a writing guide rather than interactive checkbox |
| A-10 | Release | Bump `1.0.0-rc.1+110` -> `1.0.0-rc.2+111` for an in-place upgrade candidate; preserve Android package ID and stable-signing workflow |

## Non-regression invariants

- Existing `DiaryBlock` models, preferences, backup schema, cloud sync owner, account scope and media store remain unchanged.
- No new database, AI feature, third-party SDK or background loop.
- Existing diary templates are not migrated destructively; historical translated tags remain as authored.
- All P0/P1/P2 software claims require exact-head Development, Web, Android size and AppLab PASS plus clean review.
- Physical-device install/update, cross-device sync, keyboard/large-font, picker and Play purchase/restore are **NOT VERIFIED** until executed on real devices against the *exact* artifact bytes.
- Do not promote `ARTIFACT_BUILT` to `PHYSICAL_DEVICE_VERIFIED` or `STORE_READY`.

## Required final checks

1. `flutter analyze` and full `flutter test`, including v105x regression tests.
2. Web build/deploy exact-head checks.
3. Android size audit and AppLab trusted runtime exact-head verification.
4. Codex review of exact head, no unresolved blockers.
5. After merge, produce a stable-signed ARM64 sideload artifact with manifest, checksum, source SHA and signing certificate identity.
6. Manual test on an actual preexisting installation before claiming in-place upgrade PASS.
7. Keep v1.06 PLANNED. Store/physical certification is an external gate, never inferred from CI.
