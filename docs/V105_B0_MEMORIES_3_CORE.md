# v1.05-B0 — Memories 3.0 Core

## Goal

Turn Memories from a filter-heavy data browser into a first-class personal
recall surface while preserving Anna's existing local-first diary ownership.

B0 implements only:

- **For You** as the primary deterministic resurfacing surface;
- **Timeline** as the primary chronological memory browser;
- search, content filters and Day / Month / Year browsing behind progressive
  disclosure;
- a bounded `forYou` projection on the existing `MemoryRecallSnapshot`.

B0 deliberately does **not** implement Memory Map, Then & Now, Year in Review,
Collections or Life Threads. Those remain separate v1.05 steps.

## Factory baseline

- App-Factory-Core: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Master: v26.6
- Golden Index: v22
- Factory Mode: `ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

## Data architecture

There is no Memory database, repository, sync queue or lifecycle owner.

`MemoryRecallSnapshot.forYou` is ephemeral and derives from the same
`DiaryBlockReference` stream already used by Recall 2.0.

Selection is deterministic and bounded:

1. On This Day, up to 3;
2. same month in past years, up to 3;
3. representative year highlights, up to 6;
4. duplicate block IDs are removed;
5. the final For You projection is capped at 8 entries.

Archived blocks and records on/after the anchor day remain excluded by the
existing recall boundary.

## UX

The Memories primary modes are now:

- **For You** — hero memory plus deterministic date/person/place resurfacing;
- **Timeline** — chronological, visual feed over canonical memory references.

Secondary browsing remains available through one Browse action:

- Days;
- Months;
- Years.

Search and DiaryBlock type filters remain available but no longer consume
permanent vertical space. They switch into Timeline because they are browsing
operations rather than resurfacing modes.

Stable semantic identifiers cover the new primary surfaces for AppLab.

## Localization

All new B0 labels use the existing AnnaStrings five-language catalog:

- en;
- it;
- es;
- fr;
- pt.

No new localization engine or persisted language state is introduced.

## Explicitly deferred

- v1.05-B1 — Memory Map + Then & Now;
- v1.05-B2 — Year in Review 2.0;
- v1.05-B3 — Collections / Life Threads;
- v1.05-B4 — Polish & QA.

## Acceptance

B0 closes only when:

- For You remains deterministic, bounded and duplicate-free;
- existing memory search/type/day/month/year capabilities remain reachable;
- no Memory DB or parallel persistence is introduced;
- the Memories Maestro checkpoint covers For You and Timeline;
- relevant exact-head CI/AppLab gates are green;
- review is clean on the final PR head.

Physical-device/store evidence remains separate and is not implied by B0.
