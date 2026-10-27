# v1.05-B1 — Memory Map + Then & Now

## Goal

Add spatial and temporal recall to Memories 3.0 without creating a new memory
or places persistence layer.

B1 adds:

- **Memory Map**, a derived geographic projection of existing
  `DiaryPlaceReference` metadata;
- **Then & Now**, deterministic earliest/latest comparisons for places with
  memories on different days;
- stable semantic identifiers and trusted-runtime journey coverage.

## Data architecture

`MemoryMapSnapshot` is ephemeral. It derives exclusively from canonical
`DiaryBlockReference` records and inline `DiaryPlaceReference` values.

Places are grouped by normalized name. Existing valid latitude/longitude values
are reused when present; missing coordinates remain visible as unlocated place
chips and are never synthesized.

`MemoryThenNowPair` chooses the earliest and latest canonical memory for a place.
No generated narrative, inferred coordinates, hidden ranking model, database,
repository or sync queue is introduced.

## UX

The For You surface exposes two secondary recall actions:

- Memory Map;
- Then & Now.

The map plots up to 24 coordinate-backed place clusters on a lightweight local
canvas and keeps non-coordinate places accessible separately. Selecting a place
reuses the existing Timeline search path.

Then & Now lists up to 20 deterministic place comparisons and opens the original
day in the existing Planner flow.

## Privacy and portability

B1 stores no new user data. Existing diary backup, sync, account isolation,
Trash/archive and export behavior remain authoritative.

## Acceptance

B1 closes when grouping/comparison are deterministic, no coordinates are
invented, no parallel persistence exists, five-language copy is complete,
trusted Memories journey reaches both new surfaces, exact-head gates are green,
and review is clean.

Physical-device and Store/distribution evidence remain separate.
