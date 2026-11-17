# Anna's Diary — Impeccable visual QA pilot (17 November 2026)

**Status:** PILOT IN PROGRESS / VISUAL ACCEPTANCE NOT VERIFIED
**Fixed input source:** `main@e769b2173e9e391615b26c872a7e691f621f9dd7` (before this documentation PR). Any newer PR must be evaluated against its own exact head.
**Central authority:** App-Factory-Core Master v27, Golden Index v29; `contracts/DESIGN_VISUAL_QA_PROCESS_v1.md` (Core PR #100, pending); existing Theme M3 COPY-READY / App Shell Visual QA DRAFT / AppLab source/runtime split.
**Curated reference:** Design-App Impeccable DSK-002, PR #34 and proposed process PR #35.

## Product & owner boundaries

- Product Bible: `docs/PRODUCT_BIBLE.md`. Roadmap: `docs/ROADMAP.md`.
- Keep Organic iOS Journal/pastello contemporaneo, Manrope/Lora, rose user palette + HSV, dark/system, Classic reversible, existing Today/Calendar/Memories/More navigation.
- Exclude Vault private content and all real personal data. No changes to sync, account, media storage, writes, notification reliability, purchases or production release.
- Existing active design/Today PR #333, draft #254 and editorial issue #327 remain independently owned; this QA pilot does not replace them or certify their versions.
- Calendar v136 Product Bible and Roadmap specify **12 real Flutter screenshots** (empty/populated month/agenda/week/seven-day views). Reuse rather than duplicate the existing capture harness.

## Evidence capture (actual Flutter renderer; synthetic fixtures only)

Already implemented:
- `test/calendar_notebook_visual_capture_test.dart`: 12 empty/populated CalendarHub, Month, week/agenda views. CI harness `.github/workflows/calendar-notebook-visual-evidence.yml`.
- `test/organic_journal_visual_capture_test.dart`: More, Settings and Memories empty/populated. CI harness `.github/workflows/organic-journal-visual-review.yml`.
- `test/calendar_v136_notebook_visual_test.dart`: source and 320dp/1.6x behavior, light/dark.
- `docs/V107_C2_VISUAL_REGRESSION.md`: canonical 70-pair matrix and non-mutating comparator, **not** an approved baseline until real captures/review exist.

This pilot safely allows the two existing PR-only visual workflows to run for this **documentation pilot branch**. They generate candidate PNGs as CI artifacts; **they do not update approved baselines or change deployed UI**. Visual captures still require review of the actual PNGs, and the workflow cannot prove real device touch, Web PWA behavior or physical performance.

## Review matrix / expected checks

| Screen | Source capture | Main design concern | Status |
|---|---|---|---|
| Today | Existing v135/organic shell + PR #333 owner | First important task and diary content, unblocked accessibility navigation, no card-within-card noise | NOT_VERIFIED |
| Calendar Month | Flutter notebook month empty/populated | Correct 31-day display when applicable, readable markers/selection, no clipped labels | NOT_VERIFIED |
| Calendar Week / Agenda | Flutter notebook week/day and scrolled agenda | 7 day sections, readable real events, truthful empty state | NOT_VERIFIED |
| Memories | Organic journal memory empty/populated | No fake photo-sized hero for text-only entry; full original-media proportions where relevant | NOT_VERIFIED |
| More / Settings | Organic journal secondary screen captures | Consistent editorial typography, clear destinations, large-text resilience | NOT_VERIFIED |

## Acceptance / QA gates

1. Pin PR exact source head and screenshots from the same source and synthetic fixture.
2. Check screenshot inventory and inspect PNGs (not merely that CI passed).
3. Record actual issues under BLOCKING/MAJOR/MINOR/OPTIONAL with screen, locale, device dimensions and remediation.
4. Apply IWC-01..IWC-08 without substituting Web detector for Android testing.
5. Compare baseline/candidate **only after** independent accepted baseline exists. Never auto-promote generated PNG to accepted design.
6. Verify light/dark, rose/custom HSV, font 1.6x, 320dp and 390dp, IT/EN plus elongated strings, offline/error/sync and keyboard/insets where pertinent.
7. Production PWA, real Android/TalkBack, two-account sync and physical image playback remain independently **NOT VERIFIED** until separate tests are executed.

**Release truth:** This PR contains only visual QA setup/documentation. CI/screenshot availability never automatically implies user visual approval or signed APK, and no new app capability is claimed.
