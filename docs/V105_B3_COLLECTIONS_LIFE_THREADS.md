# v1.05-B3 — Collections / Life Threads

## Goal

Add saved memory views and deterministic recurring-life stories without copying
canonical diary data or introducing a Memory/Collections database.

## Factory baseline

- App-Factory-Core: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Master: v26.6
- Golden Index: v22
- Factory Mode: `ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

## Saved collections

A `MemoryCollectionDefinition` stores only view criteria:

- person id;
- place label;
- tag;
- DiaryBlock type;
- year.

The small definitions live inside the existing `AgendaPreferences` payload and
therefore inherit its local/cloud/account lifecycle. A definition never stores
DiaryBlock IDs, media, text or a copied result set.

`memoryCollectionReferences(definition)` always re-evaluates the definition
against the current canonical `memoryReferences()` projection.

## Life Threads

`memoryLifeThreads()` is fully ephemeral. It groups non-archived canonical
memory references by recurring:

- people;
- places;
- tags.

Only groups with at least two distinct memories surface. Ordering is
deterministic by count, recency and label.

## UX

Memories / For You exposes one Collections / Life Threads entry. The dedicated
surface lets the user:

- create a saved collection using at least one criterion;
- open live results from the original diary;
- delete only the saved view definition;
- browse automatically derived Life Threads.

Opening a result navigates to its canonical diary day.

## Localization and trusted runtime

All B3 copy follows the existing en/it/es/fr/pt `AnnaStrings` path.
`memories-collections-entry` and `memory-collections-surface` are stable
semantic identifiers covered by the Memories trusted journey.

## Acceptance

B3 closes only when:

- preference roundtrip remains backward-compatible;
- collections contain criteria only and results update with canonical diary
  changes;
- Life Threads are derived and duplicate-free;
- no Memory/Collections/LifeThread database, repository or sync owner exists;
- five-language regressions and trusted runtime entry are green;
- required exact-head CI/AppLab gates and review are green.

Physical-device and Store/distribution evidence remain separate.
