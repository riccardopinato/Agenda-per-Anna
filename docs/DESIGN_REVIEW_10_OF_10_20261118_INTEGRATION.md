# Anna's Diary — approved interactive redesign 10/10 (18 November 2026)
## Design-App crosswalk and gated integration contract

**State:** DESIGN_APPROVED_10_OF_10 / INTEGRATION_PLAN_PROPOSED / CODE_NOT_IMPLEMENTED_BY_THIS_PR / VISUAL_QA_NOT_VERIFIED / PHYSICAL_QA_NOT_VERIFIED.

**Approval provenance:** ten successive, explicitly approved interactive Chat mock-ups on 18 November 2026, under the same App Factory design-review session. This is a **new, dated design contract**, not a rewrite of the historical `APPROVED_10_MOCKUPS_IMPLEMENTATION_CONTRACT.md` (31 October 2026) or `V108_MOTION_VISUAL_POLISH_FINAL_DESIGN_CONTRACT.md`. No screenshot from these Chat prototypes proves Flutter rendering.

**Immutable review anchors**
- Product `riccardopinato/Agenda-per-Anna@cd9494f2050da2fb64a6be491b56338c215a0177` (`main` at comparison).
- Design library `riccardopinato/Design-App@f8b5cd3b3374d2340815967ccaa2657fea24a5b2` (`main` at comparison).
- Factory baseline already resolved in the same continuous mock-up review: `riccardopinato/App-Factory-Core@a8d20ceb71ce9e9e16e6756d257d611fa6f1e0ec`. Resolve a **new** factory baseline only if the central source explicitly changes or a new work session is started; don't silently substitute historical baselines in older documents.
- Product owner: `docs/PRODUCT_BIBLE.md`, `docs/ROADMAP.md`, `AGENTS.md`. No automatic cross-repo copying or hierarchy inversion.

## 1. Approval ledger — NEW 18 November cycle

| ID | Approved mock-up | Visual/interaction decision | Canonical source surface; required guard |
| --- | --- | --- | --- |
| N18-01 | Oggi | Warm Organic/Journal home; real meaningful first content, compact date/context, restrained illustrations | Existing `PlannerScreen` and Organic/Editorial Today; preserve data-derived cards, selected day, Classic rollback |
| N18-02 | Calendario | Notebook month/week/day visual continuity, compact markers and consistent detail routes | Existing calendar/planner; no replacement event store, selection loss, date misalignment or forced empty timeline |
| N18-03 | Impegni | Compact daily list by default, optional hourly timeline, tasks/appointments independently legible | Existing planner and agenda items; task completion and event creation use canonical writers |
| N18-04 | Crea + | Intention-first, grouped entry surface: quick Scrivi/Foto/Impegno and discoverable advanced actions | Reuse `showUnifiedCapture`/`unified_capture.dart`; preserve all existing actions, dates, permission gates, save ownership. New grouping supersedes **only the older menu presentation/order**, not actions or behavior |
| N18-05 | Diario e Ricordi | Image-led memories at natural ratio; text-only pages with appropriate density; existing six discovery areas | `DiaryMemoriesScreen`; no invented entries, media duplication, clipped original photos or second archive |
| N18-06 | Insieme | Navigation label `Insieme`, existing shared space identity `Noi ♡`; coordinated feed/agenda/memories | Shared-space owner/stores/invites/ACL unchanged. New label supersedes older `Messaggi` **label only**, not stable IDs, membership or sync; maintain disabled-module path |
| N18-07 | Altro ed Esplora | Compact grouped navigation, shortcut/findability, clear favorites and active-module visibility | `MoreScreen`, `ExploreScreen`, existing `Qw2FavoritesSection`; no duplicated router or silently enabled modules |
| N18-08 | Impostazioni e Personalizzazione | Journal settings, separate appearance/privacy/data; 5 presets + custom HSV and live reversible draft preview | `SettingsHubScreen`, `AppearanceColorsScreen`, `PersonalizationScreen`; preserve draft/apply semantics, stored prefs, light/dark/system and Classic |
| N18-09 | Cerca e Inbox | Canonical search with type/archives/sort and evidence; grouped pinned/ordinary Inbox, tag/manage/convert flow | `PersonalSearchConnectionsScreen`, `InboxScreen`; preserve privacy/search predicates, original tags, guarded conversions, archive/trash/account ownership |
| N18-10 | Cross-screen experience | Coherent dock, typography, responsive layout, contextual navigation, undo for reversible demo actions, truthful empty/offline/error/loading states, reduced-motion | Flutter shared primitives only; do not claim sync/save success until canonical operation confirms it, do not create new persistence |

**Interaction precedence:** Source-of-truth user data and protected access > canonical behavior > accessibility > latest approved appearance > optional decoration. A mock-up's unimplemented demo interaction does not create a new product capability. Prior 31 October approval for Vault remains **NO REDESIGN**. Prior shared QR/24h and v1.08 motion contracts retain their separate backend/acceptance boundaries; the 18 November aesthetic approval is not an authorization for backend, authentication, or billing rewrites.

## 2. Design-App-first visual crosswalk (READ at pinned library SHA)

Evidence is the library's **catalog/dossier and provenance records**; the underlying image binaries and actual Flutter before/after screenshots have **not** passed a same-fixture visual comparison here. References are candidates for implementation, not evidence of licensed/code-tested consumer assets.

| Design-App reference | Match to N18 proposal | Decision and priority | Admission / reuse status |
| --- | --- | --- | --- |
| `UIX-STYLE-004` NEO-APPLE and `UIX-STYLE-007` PASTEL UI; `STYLE-A` Editorial Personal | N18-01/02/05/06/07/08/10 | **P0: product visual direction** — own rose/sage/cream tokens, Lora/Manrope, editorial rhythm and restrained translucent dock. Must respect custom palettes | REFERENCE aesthetic; adapt from existing first-party Flutter design primitives, not copy an external UI |
| Historical `UIR-0003/0014/0021/0029` (12 Nov Anna priority set) | N18-01/05/08 | **P1 intent only, BLOCKED exact asset**: the 12 Nov classification says these JPG originals were **not published**; the named files do not exist at corresponding current `main` paths. Their descriptive ideas (mint/pink Soft 3D, peach/blue kit, botanical accents and restrained soft depth) remain user-curated priorities, **not importable image sources** | REFERENCE_ONLY / MISSING_BINARY_AT_CITED_PATH; do not claim pixel-level comparison or replace their IDs silently |
| Current archived 13 Nov images, including `UIR-0051/0052/0076` under Soft 3D plus current `PALETTE` and `EDITORIAL UI` folders | N18-01/05/08 | **P1 inspection queue**: verify each real file/visual and its own app mapping in `UI-UX/IMPORT_MAP_2026-11-13.json` / `GALLERIA_VISIVA_2026-11-13.md` before treating it as a substitute for an older reference | IMAGE_EXISTS_IN_REPO, but specific visual fit, ownership and re-use NOT_VERIFIED; no one-to-one ID remap inferred |
| `MOCK-STYLE-001` Aesthetic, `005` Polaroid, `008` Organic, `010` Illustrated | N18-01/05 | **P1:** restrained journal/album accents. Polaroid framing only when real media dimensions remain intact; no fake scrapbook data | REFERENCE; don't treat category directories as ready-made illustrations |
| `DCL-001/002/004/006/007/011` (Dribbble+Collect UI crosswalk) | N18-01/02/05/07/10 | **P1 design critique**: content-led hero, progressive disclosure, navigation, media, usable feedback; no blanket re-skin | PROPOSED_ONLY; portals are discovery, not an asset license |
| `WML-001` Carousel Slider, `WML-004` Range Selection | N18-05 | **P2 optional** only where existing memories/date controls benefit. Honor full-photo ratio and accessible alternatives | SOURCE_FILE_READ in external React; Flutter consumer NOT_IMPLEMENTED |
| `WML-007` Dialog Stack; `DSP-001` Theme Toggle | N18-06/08 | **P2** visual guidance for invitations/theme, with real permission/ThemeMode operations | REFERENCE; do not replace native owner paths |
| `AMX-004` Scroll Reveal; `DBM-016` Skeleton; `DSP-002` Card Stack Peel | N18-05/10 | **P2** brief, conditional motion/load states; never animate fake loading or the whole history | PROPOSED_ONLY; use native Flutter and reduced-motion fallback |
| `UIV-009` book card; `UIV-023` radio; selected Uiverse cards/toggles | N18-05/08 | **P3** concept-level comparison if more polished than existing Journal widgets | HTML/CSS originals, not a Flutter library. License and accessibility review before copying; prefer independent adaptation |
| Gentleface `ICO-002`, `ICO-008`, `ICO-014`, `ICO-017`, `ICO-023` | N18-02/05/06/09/10 | **P2:** semantic icon coherence (calendar/photos/confirmed save/cloud/privacy) | Catalog/site verification ≠ asset-level right or tested Flutter animated icon; no direct import approved |

**Catalog correction checked 18 Nov 2026:** `Design-App/UI-UX/SOFT 3D/RIFERIMENTI_CLASSIFICATI_2026-11-12.md` explicitly states “JPG originali: non pubblicati”; `UI-UX/SOFT 3D/IMMAGINI/README.md` confirms no 12 Nov imported originals. Current directory listing instead contains `UIR-0051.jpg`, `UIR-0052.jpg`, `UIR-0076.jpg`; `UI-UX/NEUMORPHISM/IMMAGINI/` contains `UIR-0066/0068/0069.jpg`. Treat the older Anna priority table as a **conceptual shortlist with broken asset destinations**. There is no verified one-to-one replacement of these historical IDs. A separate image/source provenance review is required before any binary import. This does **not** invalidate the approved user aesthetic or the existing first-party Organic Journal code.

**Required source records**
- `Design-App/PER_APP/annas-diary.md`
- `Design-App/UI-UX/MATRICE_APP_STILI.md` and `UI-UX/REGISTRO_STILI.yaml`
- `Design-App/UI-UX/PRIORITA_VISUALI_PER_APP_2026-11-12.md`
- `Design-App/UI-UX/DRIBBBLE_COLLECTUI_APP_MAP_2026-11-18.md`
- `Design-App/UI-UX/DESIGN_QA_REVIEW_PROTOCOL_2026-11-17.md`
- `Design-App/docs/LICENSE_POLICY.md`
- `Design-App/AGENTS.md`.

**Selection rule:** user-curated Design-App references have priority over newly invented assistant styling **when coherent with the approved Anna identity, technically adaptable, safe and properly licensed**. Existing certified Core contracts and the Product Bible win on privacy/behavior. When a reference conflicts, record `ADAPT` or `REJECT` with reasoning instead of silently substituting it. Never vendor raw Uiverse/React assets or CSS into Flutter without license, runtime and dependency admission.

## 3. Source crosswalk and delta policy

Review at the pinned Anna SHA shows **existing implementations**, not a blank project:
- `lib/src/screens/home_inbox_search.dart`: shell, dedicated routes and Inbox entry.
- `lib/src/screens/more_screen.dart` + `explore_screen.dart`: canonical destinations, module guards and Settings links.
- `lib/src/screens/settings_hub.dart`, `appearance_colors.dart`, `personalization_screen.dart`: settings/search, five palette seeds, HSV 2D/Hue/HEX, draft-only apply, mode/presets/modules.
- `lib/src/search_connections_domain.dart`: one personal local search (agenda, diary, person, place, birthday, inbox, month), selected kinds, archived toggle, evidence/sort, canonical hit navigation.
- `lib/src/diary/diary_memories.dart` and `lib/src/screens/shared_space.dart`: real memories/shared ownership and existing controls.
- `lib/src/organic_pastel_design.dart`, editorial components and existing QA documents: a first-party visual starting point; preserve Classic and tokens.

**BEFORE any code PR:** obtain same-fixture current Flutter screenshots, map the N18 difference against `main`, and classify each as `ALREADY_IMPLEMENTED_SOURCE`, `VISUAL_DELTA`, `NEEDS_RUNTIME_EVIDENCE` or `NOT_IN_SCOPE`. Do not reimplement verified capabilities or claim that mock-up HTML is app code. Open UI PR #333 and any currently open surface owners must be checked for overlap at execution time. No simultaneous edits to the same UI file from separate branches.

## 4. Execution waves (one bounded PR per independently testable slice)

| Wave | PR scope / source ownership | Acceptance gate | Do not touch |
| --- | --- | --- | --- |
| **W0** | **This docs-only branch/PR:** pinned baseline, approvals, design priority and no-data-loss plan | markdown/links reviewed; source and behavior unaffected | Flutter code, APK/signing |
| **W1** | Native Flutter design foundation: canonical tokens, typography, paper surfaces, layout/motion/reduced-motion helpers, reversible Classic | focused widget/golden tests across light/dark/HSV; no new runtime dependency by default | preferences model, theme persistence |
| **W2** | Oggi + Calendar + Impegni delta (N18-01/02/03) | date selection, dense/empty days, long event labels, 320/390/600 dp, no duplicated events | planner writers, accounts, reminders |
| **W3** | Crea + grouped discoverability (N18-04), single existing capture owner | all existing actions visible and reachable, permission and cancellation, chosen-day routing, no second writer; compare old and new menu regression | capture persistence, voice/photo/sketch storage |
| **W4** | Diario/Ricordi (N18-05), full-ratio media, accessible text/memory navigation | authentic fixtures, empty history, long text, original media dimensions, photo view/back, no duplicate archive | original asset IDs, encryption, diary schema |
| **W5** | Insieme (N18-06) source-level display and label only | disabled module/guest path; owner/member, multiple spaces, offline status, 2-device sync **remains NOT_VERIFIED until tested** | invite validation, token expiry, credentials, member ACL, Supabase |
| **W6** | Altro/Esplora + Impostazioni/Personalizzazione (N18-07/08) | every existing route reachable, app-modules guarded, all five palettes+HSV+HEX+cancel/apply+Classic, settings/backup unaffected | billing, Vault, auth, backup writes |
| **W7** | Cerca/Inbox (N18-09) and feedback/state polish (N18-10) | search 1-character title-only, explanatory evidence and newest/oldest/A-Z; Inbox active+archived tags, pin, convert on successful canonical write; offline/loading/error/undo proven by actual source states | index duplication, archive/trash semantics, account scope |
| **W8** | Cross-screen integration & QA/rollout only | same-fixture before/after, localization/accessibility/perf, exact-head gates, branch merges, stable signed release candidate **only when source+device gates permit** | Play/Store release, destructive device restore |

**Risk/ordering rule:** W1 first; W2, W4 and W6 may be reviewed in parallel only with disjoint file ownership and independent branches; W3 and W7 must serialize around Inbox/Crea source; W5 isolated because shared permissions have elevated risk. Refuse silent main commits and broad unrelated cleanup. Keep PRs small and stop on confirmed regression.

## 5. Evidence and non-destructive gates

Before each PR: pin `main` SHA, check conflicting open PRs, inspect owned source, list changed files, generate before screenshot at a known fixture. No test evidence from previous SHAs is transferable.

**Source checks:** repository `Development checks` (Flutter analyze + tests + Web build), `AppLab Source Gate` and relevant screenshot workflows; verify **exact PR head SHA**, mergeability and blocking reviews. The source AppLab is **not** real phone/AppLab APK acceptance. Documentation-only PR uses the smallest complete applicable checks. CI FAIL or missing evidence means NO MERGE.

**Visual review:** repeat **same test fixture / locale / theme / scale** before and after at 320×640, 390×844 and tablet/wide; IT/EN/ES/FR/PT, light/dark/system, custom HSV, text scale including 200%, IME/keyboard, route Back, screen-reader focus, tap targets, no clipping, photo full aspect, low data and dense data. User's Chat mockup approval ≠ Flutter screenshot approval. Reduced motion must not break semantics.

**Data / access invariants:** stable IDs, existing data and migrations, personal/shared/Vault isolation, stored notes/media/voice/sketch/Vision Board, archive/Trash/recovery, notification times, account A→B→A, existing shared member and invitation history, backup/restore, login optional, consistent settings and ThemeMode. No schema/key/sync change in visual PRs. New app-upgrade evidence must prove in-place retention with an existing signed APK and non-destructive fixtures; physical personal data must not be reset.

**Runtime release boundary:** no PR-triggered signed APK. Follow `AGENTS.md` on current trusted-main signed ARM64 flow and increasing `versionCode` over **actual current main**, never rely on historical `>111` alone. Record commit, CI run, version, artifact hash and signing certificate identity. PWA, emulator, real devices and Play are separate gates. Do not claim physical acceptance without a real device review; keep privacy/account/shared sync acceptance open until proven.

## 6. Progress ledger

| Item | Status as of this PR |
| --- | --- |
| User interactive mock-up decisions | **10/10 APPROVED** (18 Nov 2026) |
| Product and Design-App source comparison | **TEXT/CODE REFERENCES READ** at pinned SHAs |
| User-curated visual assets viewed pixel-by-pixel | **NOT VERIFIED**; exact images and licensing to be inspected before style adoption |
| New Flutter feature implementation | **NOT STARTED BY THIS PLAN**; existing app implementation retained |
| Source checks on new code | **NOT RUN** (no new code in W0) |
| Actual post-redesign Flutter screenshots | **NOT AVAILABLE** |
| Android/PWA physical acceptance and data retention | **NOT VERIFIED** |
| APK/release | **NOT AUTHORIZED BY W0** |

**Next bounded action:** W1 only after W0 review/CI, with a separate PR and exact-head tests. This plan alone does not certify nor ship any screen.
