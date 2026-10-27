# v1.05-B2 — Year in Review 2.0

## Goal

Rebuild the existing `YearScreen` as a deterministic annual retrospective over
Anna's canonical diary and life projections. B2 does not create a second Year
product and does not introduce annual persistence.

## Factory baseline

- App-Factory-Core: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Master: v26.6
- Golden Index: v22
- Factory Mode: `ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

## Architecture

`AgendaStore.yearReviewSnapshot(year)` derives:

- non-archived `DiaryBlockReference` memories for the selected year;
- same-year, non-archived `LifeArchiveEntry` projections;
- twelve month snapshots;
- up to six deterministic monthly highlights, preferring photos when present;
- recurring people and places derived from existing diary metadata.

There is no Year database, repository, sync queue, annual cache owner or copied
memory payload.

## UX

The existing `YearScreen` now provides:

- annual memory, life, workout and active-month totals;
- deterministic highlights that open the original diary day;
- recurring people/place facets;
- a twelve-month summary that opens the existing `MonthScreen`.

The existing Calendar entry point remains canonical.

## Localization and accessibility

All B2 copy resolves through the existing five-language `AnnaStrings` path.
The annual surface exposes the stable `year-review-surface` semantic used by
trusted runtime verification.

## Acceptance

B2 closes only when:

- the review is derived from canonical diary/life projections;
- archived diary content is not resurfaced as a highlight;
- no annual persistence or competing Year product is introduced;
- the five-language regression is green;
- the Calendar trusted journey opens `year-review-surface`;
- required exact-head CI/AppLab gates are green and review has no blocker.

Physical-device and Store/distribution evidence remain separate.
