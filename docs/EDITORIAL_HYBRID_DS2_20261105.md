# Anna's Diary — Editorial Hybrid Home DS2 (5 November 2026)

## Approved delivery scope

User approved the next step: Home Editorial Hybrid reale, after DS1 source merge PR #255. The Home uses the same canonical account/day content and actions, with classic mode preserved until explicitly switched. Experiment PR #254 remains separately isolated as DRAFT.

Factory baseline: App-Factory-Core@42ad47a9ebacc55ae901ea55a01a6855e320377d (Master v27 / Golden Index v28). Source start: Agenda-per-Anna main@77ac265cf658f1b827b1c193c69e6538bb9116ce.

## Implemented architecture

- AnnaEditorialTodayMode: device-local opt-in boolean via existing SharedPreferences. Default CLASSIC; no new schema, no cloud/account preferences. Failed local reads fall back to classic; failed writes do not switch the mode.
- Selection: Personalizzazione > Home Editorial Hybrid and a visible switch icon in Oggi. All supporting text/tooltips localized in IT/EN/ES/FR/PT.
- PlannerScreen remains the single canonical Today view. Reads the original dayHubSnapshot(day), memoryRecallSnapshot(day), upcoming and pinned agenda, and refreshes from the existing revision notifiers. No second database, router or service.
- Hybrid header: approved greeting, real account display name, approved selected-day daily wish, calendar shortcut and selected-day navigator, rendered in the shared Lora/Manrope editorial typography.
- AnnaEditorialTodayOverview: hero reads real journal state and opens the existing selected-day PlannerScreen; paired commitment/activity cards show accurate values from the selected day. Privacy masking hides status and numerical values.
- MainShell raised + Crea retains its original canonical menu and all capture actions, and Calendar stays a dedicated route from Today.
- Weekly Review and Realistic Day order, content filters, upcoming/pinned cards, catch-up, wellbeing, existing real diary entries, memory teaser, rituals, tomorrow and hour timeline remain available. Only the redundant classic compact summary is not rendered in Hybrid.
- No new app dependencies, signing keys, storage or user-data migration.

## Release/acceptance boundaries

- Dedicated tests: local style roundtrip, empty/real-day data rendering, privacy masking, five localizations and source-path regressions; exact-head CI on analyze, all tests, Web and AppLab.
- Product release is separate: no new versionCode or signed in-place APK in DS2. Neither emulator/web CI nor source static checks imply screenshot fidelity or actual phone validation.
- Existing attached Material 3 navigation bar stays active for now. A full Editorial dock skin for all sections is the following visual phase, without changing destinations or Create behavior.
- Visual QA remains NOT VERIFIED: small screens, font scale 1.0/1.3/1.6, gesture insets, keyboard, theme dark/custom HSV and real data on physical devices must be checked before treating Hybrid as the final default.

## Next approved boundary

After user testing of the real-data Hybrid Home, extend shared editorial surfaces to Calendar, Ricordi, Messaggi and Altro while preserving the installed Private Vault appearance.

## Refinement — simplified Editorial Hybrid Home (5 November 2026)

Following physical user feedback on the installed signed +126 candidate, hide the visible `Tutto / Personale / Condiviso` filter strip **only on embedded Editorial Hybrid Oggi**. Preserve Classic Oggi and Calendar/Week/Month filter controls. Only when the unfiltered Hybrid Oggi tab is in the foreground (`activeInShell: index == 0`), clear any stale global in-memory agenda content filter to `AgendaContentFilter.all` after the frame, so private or shared items cannot remain silently hidden. `MainShell` uses `IndexedStack`, so an offstage Home must never clear a filter selected in another tab. No records, account data, saved preferences or synchronization are changed. This is a source-level refinement; physical verification on a future signed candidate remains NOT VERIFIED.
