# Anna's Diary — v1.05.x UI4 Navigation Dedup & Prominent Private/Shared Spaces

Status: IMPLEMENTED ON FEATURE BRANCH — exact-head PR CI/AppLab and Codex REVIEW PENDING.
Based on main `bf9feef489dfeb8a568fdfe16a7eb653292f0813` (UI3 integrated).
Factory baseline: `b5573840caaf0e92bd7719b7471d49a8e34995c1` (Master v26.8, Golden Index v23).

## Audit classifications
- Confirmed redundant navigation: Personalization directly in More AND Settings; contextual duplicate icon + bottom row in Explore. UI4 removes the redundant More tile and the second Explore affordance, while retaining Settings' canonical route and the single Explore contextual shortcut.
- Confirmed duplicate content preview within Today: `_DayLifeOverviewCard` previews the first three `snapshot.lifeEntries`, and `_DayLifeStream` displays the entire same collection immediately below. UI4 retains count chips and the full interactive stream while removing repeated preview rows and the now-unused row widget.
- Intentional quick access maintained: Search/Inbox, direct Backup and Cloud in More despite equivalent Settings destinations, canonical Capture entry points in Today/Calendar/Inbox, On This Day projection in Today/Memories, and scope-specific Search/Archive queries.
- Future review (NOT CHANGED): Appearance HSV/brightness, Premium entries, nested legacy Settings surfaces, and 'habits' opening Today's planner. These need UX acceptance and regression analysis before consolidation.

## Shared / Vault visibility and naming
- More shows **Spazio condiviso** as the prominent accessible primary label, using the canonical five-language `AnnaStrings.d3('sharedSpace')` translation, with `Noi ♡` in the supporting subtitle. The same primary label appears in Explore and Personalization.
- More displays **Cassaforte privata** using the existing localized private Vault title and subtitle; both destinations are separate soft-accented `AnnaJournalCard` surfaces ahead of Explore.
- Visibility is controlled by existing `AppModule.sharedSpace` and `AppModule.privateVault` preferences; hiding one never deletes it or affects security, encryption or account membership. Personalization remains reachable via More → Settings → Personalization, and Explore → Personalization. Do not expose Vault content without its existing unlock.
- Existing 'Noi ♡' internal branding, backend shared space names, E2EE password names/keys and notification identity are not renamed.

## Regression contract
- Preserve four canonical main tabs, canonical shared/Vault stores, one capture path, no new persistence, original route semantics for Backup/Cloud/Search/Inbox/Settings.
- Update the Personalization Maestro journey for More → Settings → Personalization; retain old auth and storage gate behavior.
- Keep private Vault and shared surfaces hidden if user disables the module, but restorable via Settings.
- Required final PR gates: Development checks, Deploy Anna's Diary Web, Android size audit, AppLab Production Gate, exact-head Codex review, then safe merge.
- Source and PR CI green are not physical-device or Play certification. Do not touch v1.06.

## Backlog for next audits
Review duplicated Appearance/Premium links, direct Backup/Cloud vs settings discoverability, habits destination, other overlapping Today/Calendar date views, and pixel-faithfulness to C/C/B/C/A mockups with screenshots and user feedback. No automatic removal of user-facing capabilities.
