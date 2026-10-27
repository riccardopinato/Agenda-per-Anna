# v1.05-B4 — Polish & QA

## Purpose

Close the v1.05 Memories & Recall 3.0 line only after B1, B2 and B3 are present
on the final integrated base and the same exact B4 head passes every required
FULL/CERTIFIED gate.

B2 PR #129 and B3 PR #130 are now merged. The earlier PR #131 was closed without merge; final PR #132 was rebuilt from the
integrated `main` and contains only the bounded B4 Polish & QA delta. Earlier
pre-integration green evidence is historical only; final closure requires a
fresh review and certification on the current exact B4 head.

## Factory baseline

- App-Factory-Core: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Master: v26.6
- Golden Index: v22
- Factory Mode: `ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

## Integrated scope

B4 verifies one coherent projection architecture:

- B0 For You / Timeline remain bounded deterministic views over canonical
  `DiaryBlockReference` records.
- B1 Memory Map / Then & Now remain derived from existing place/diary metadata.
- B2 Year in Review 2.0 reuses the existing Year screen and canonical
  Diary/Life Archive data.
- B3 Collections persist only bounded filter definitions in existing
  `AgendaPreferences`; Life Threads remain ephemeral.
- No Memory, Year, Collections or LifeThread database/repository is introduced.

## Polish fixes

### Memory Map collision accessibility

Coordinate markers may overlap on the compact map. B4 therefore keeps the
visual map while adding a second selectable list containing every mapped place.
A marker collision can no longer make a coordinate-backed place unreachable.

### Year-date correctness

Annual Life Archive bucketing treats diary entries by
`diaryReference.date`, not `DiaryBlock.createdAt`. A memory added later to a
past diary day therefore remains in the correct diary month/year.

### Collections correctness

- invalid non-integer years fail inline before save;
- collection result lists re-derive on journal changes;
- overview collections, counts, saved views and Life Threads subscribe to existing settings/journal revisions so cloud-sync changes rebuild the open screen;
- remote preferences apply `memoryCollections`, including an empty list for
  deletion propagation, while older payloads that omit the field remain
  compatible.

## QA dimensions

The consolidated regression suite covers:

- bounded/derived architecture and forbidden duplicate stores;
- Memory Map, Then & Now, Collections and Year semantics;
- en/it/es/fr/pt B2/B3 copy;
- trusted Memories and Calendar journey coverage;
- existing preferences sync ownership;
- App Factory baseline/documentation coherence.

## Closure contract

v1.05 remains **IN PROGRESS** until the final B4 head, rebuilt on the merged
B1+B2+B3 `main`, has:

1. Development checks PASS;
2. Web deploy PASS;
3. Android size audit PASS;
4. AppLab Production Gate PASS;
5. no unresolved real review blocker on that same head.

Physical-device, Play/Store and other distribution evidence remain separate and
must not be inferred from CI/AppLab.
