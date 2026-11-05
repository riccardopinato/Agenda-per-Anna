# Anna's Diary — Ricordi per luogo (CAP-0159 reuse slice)

Source: canonical `AgendaStore.memoryMapSnapshot()`, `memoryLifeThreadReferences` and private `DiaryBlockReference`.

## Behavior

- Ricordi → Raccolte e Fili della vita now includes **Ricordi per luogo** (all named places, even with a single memory).
- First six groups are previewed; “Vedi tutti i luoghi” opens a lazy list; tapping a place opens its existing derived read-only results list.
- Each group shows the canonical place label, memory count and latest date, without requiring GPS. Saved names are compared by existing normalized keys, not inferred geocoordinates.
- No new persistence, sharing, permission, geolocation request, geocoding, generated summaries, cloud or data migration.
- Does not implement full CAP-0159 DBSCAN/geodesic clustering: that remains an optional higher-risk future enhancement.
- Existing Memories map and Life Threads remain unchanged; these are alternative views over the same private diary.

## Verification

Regression tests: distinct names/singletons/case-normalization, archived exclusion, existing private place reference selection, all five locales, lazy full list and source-only reuse. Exact-head Flutter CI, UI review and physical Android QA are separate gates.
