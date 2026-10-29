# Anna's Diary — v1.05.x UI4 Navigation Dedup & Prominent Private/Shared Spaces

Status: **MERGED / SOFTWARE COMPLETE — PR #146; 4/4 exact-head gates PASS; main Web/ARM64/Development PASS.** Physical-device, Play and screenshot-level visual QA remain NOT VERIFIED.
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

## AppLab blocking remediation — 29 October 2026

Two exact-head AppLab attempts failed D2's encrypted-payload assertion after a deliberately wrong unlock. Evidence from the trusted runtime's UI hierarchy shows the Vault remained **locked**, displayed **Incorrect password**, and had a populated obscured password input after the second attempt. The encrypted sentinel was successfully created and visible before relock. This is not evidence of data deletion.

The password field retained its rejected credential; Maestro's `eraseText: 64` may fail to fully replace an obscured value. The UI now clears a rejected password on failed unlock or exception. D2's test inputs the correct password without erasing. Wrong-password locking, KDF strength, payload persistence across relock and restart, Vault encryption and key management remain unchanged and mandatory. The change is credential-hygiene and reliability remediation, **not** a gate bypass. Re-run all four exact-head gates and a new Codex review before merge.

## Final closure — 29 October 2026

PR #146 exact reviewed head `0c52b170b25ab82f0d7e5e7938f82dd19e0642f3` squash-merged to `main@0c96c75e71b84b9470521979369602e387166417` at 09:43:57 UTC. Exact-head Development [40847528484], Web [40847528481], Android size [40847528537], AppLab [40847530142] **PASS**; Codex review **CLEAN**, 0 unresolved threads. Trusted Maestro and encrypted-persistence/restart verification **PASS**; visual/performance/resource warnings remain non-blocking and are not physical certification.

Main push Development [40851937020], Web Pages [40851936762] and stable-signed ARM64 [40851936804] **PASS**. APK version `1.0.0-rc.2+111`, SHA-256 `c4ad87a533eb0f45cd05383e1cc5f5d94c83d116ab7bd0a4a15d4bd7cf533724`, certificate `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3` (stable vs prior main). Physical-device install/native security, Play submission and pixel-faithful UI acceptance **NOT VERIFIED**. No v1.06 scope.
