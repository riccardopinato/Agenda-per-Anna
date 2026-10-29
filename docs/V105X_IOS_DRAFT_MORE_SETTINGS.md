# Anna's Diary — More C and Settings A

Status: **SOFTWARE COMPLETED — PR #143 merged into main bf9feef; four exact-head gates PASS.**

## Integrated evidence
The iOS-like grouped More/Settings UI, HSV appearance route, original stable navigation destinations and attention/backup/account/privacy paths were integrated with Today/Calendar/Memories. The combined five-screen QA PR #145 was checked and intentionally closed unmerged. The final main push passed Development, Web Pages and stable-signed ARM64 build. Physical visual/Store validation remains NOT VERIFIED.

## UI4 follow-up (navigation-only)
The duplicate-navigation audit found repeated links to personalization in More/Explore/Settings, and repeated Today life entry previews. Reduce redundant affordances while preserving a reversible PersonalizationScreen route from Settings, contextual Explore access, semantic stability for core safety routes and privacy-first feature ownership. Make **Spazio condiviso (Noi ♡)** and **Cassaforte privata** prominent but conditional on existing module-visibility settings; preserve existing underlying shared-space/Private Vault identities and data.

## Historical D4 implementation contract
## Implemented first cut
iOS-like grouped headings/cards, direct AppearanceColorsScreen route, preserve stable semantic IDs, sync attention, backup and premium links.

## Test contract
Each lane includes a source regression test for semantic IDs, routes and ordered UI composition. This is not complete visual/device certification. Flutter analyze, unit tests, Web build, ARM64 size audit, AppLab runtime and exact-head Codex review must all be checked.

## Parallel dependency policy
- Required upstream #138 HSV picker, then #139 iOS shared design system. Both must be certified and merged first.
- This draft temporarily targets main **solely to trigger CI**. Do not merge drafts into main while parent gates are unverified.
- Legacy pastel tests have been adapted for new headings; verify all previous routes and hidden-state behavior.
- Shared data store, backup, cloud sync, private Vault, paid entitlements, language preferences, four-tab shell and v1.06 are explicitly out of scope.

## Evidence ceiling
No signed APK or real-device/store certification is asserted. All code and docs are checked into the dedicated screen branch for protected review.
