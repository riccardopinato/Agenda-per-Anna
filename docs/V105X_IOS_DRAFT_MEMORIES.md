# Anna's Diary — Memories B — Diario contemporaneo

Status: **DRAFT / INDEPENDENT VALIDATION PENDING**, v1.05.x only.

## Implemented first cut
Lora editorial title, featured actual-memory hero before browsing links, dedicated text/voice fallback (no fake photo), preserve search/map/collections/filter/timeline.

## Test contract
Each lane includes a source regression test for semantic IDs, routes and ordered UI composition. This is not complete visual/device certification. Flutter analyze, unit tests, Web build, ARM64 size audit, AppLab runtime and exact-head Codex review must all be checked.

## Parallel dependency policy
- Required upstream #138 HSV picker, then #139 iOS shared design system. Both must be certified and merged first.
- This draft temporarily targets main **solely to trigger CI**. Do not merge drafts into main while parent gates are unverified.
- Performance of memory projections and media privacy must be checked; avoid fabricated image placeholders.
- Shared data store, backup, cloud sync, private Vault, paid entitlements, language preferences, four-tab shell and v1.06 are explicitly out of scope.

## Evidence ceiling
No signed APK or real-device/store certification is asserted. All code and docs are checked into the dedicated screen branch for protected review.
