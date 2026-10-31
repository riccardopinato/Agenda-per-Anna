# Anna's Diary — v1.08 Motion & Visual Polish
## FINAL DESIGN CONTRACT — 20/20 APPROVED (31 October 2026)

**STATUS:** DESIGN APPROVED / IMPLEMENTATION NOT STARTED / NATIVE QA NOT VERIFIED.
**Product repository:** riccardopinato/Agenda-per-Anna.
**Source of approval:** explicit user choices M01–M20 in the interactive Chat design review on 30–31 October 2026.
**Decision register:** [V108_MOTION_VISUAL_DESIGN_DECISIONS.md](V108_MOTION_VISUAL_DESIGN_DECISIONS.md).
**Product boundaries:** [V105X_UI5_DF01_DF35_IMPLEMENTATION_CONTRACT.md](V105X_UI5_DF01_DF35_IMPLEMENTATION_CONTRACT.md); Product Bible and Roadmap take precedence for scope/data semantics.
**Factory:** App-Factory-Core@f8ec5a324823d79353a056f0d4c12d2979a18b4e (CURRENT v27, Golden Index v23), fixed for this design session. The referenced UI5 implementation retained its own historical verified baseline.
**Nature of document:** executable design specification and future acceptance plan, NOT permission to modify Flutter code or release APK.

## 1. Twenty approved motion decisions (binding)

| ID | Approved | Interaction and visual contract |
| --- | --- | --- |
| M01 | B | Global motion: soft, fluid, natural; gentle springs, non-distracting, never perpetual. |
| M02 | B+C | Main 4-tab shell: fade + slight directional slide. Hero/shared elements ONLY between semantically matching entities/cards and details, not every tab. |
| M03 | B | Raised central + Crea: press compression, gentle elastic release and one temporary rose glow. Continuous/pulsing glow FORBIDDEN. |
| M04 | C | Canonical UI5 Crea sheet actions open with a brief fan-out. Reuse original sheet, 5 principal actions + Altre opzioni; preserve effective initial date and canonical save paths. |
| M05 | C | Oggi selected-day content glides horizontally in date direction; fixed date strip and data-true day association. |
| M06 | C | Oggi summary cards enter with a small top-down stagger on relevant reveal, NOT the full sequence each normal M05 day swipe. |
| M07 | C | Calendar month/week changes: light zoom and animated grid reflow; correct dates, selection and agenda items remain authoritative. |
| M08 | C | Ricordi / Per te featured memories: editorial magazine transition recomposes individual memory photo + text without mixing memory identity or date labels. |
| M09 | C | Timeline accordion: smooth month expansion plus brief stagger of ONLY visible eligible memory cards; bounded total work. |
| M10 | C | On actual **successful** memory save: animated check, short rose halo and a few small sparkles. Never claim success before persistence, on failure, pending state or autosave. |
| M11 | B | Memory thumbnail photo expands via Hero/shared element into the matching detail; reverses on Back to the source, preserving scroll, focus and source identity. |
| M12 | C | Ricordi Per te / Timeline / Raccolte: short horizontal editorial slide as internal navigation, separate from M02 outer tabs. |
| M13 | C | Existing dedicated Ricordi global-search route: lens expands into query input, followed by short progressive entrance of initial page content. Preserve blank query / Tutti / guidance. |
| M14 | C | Ricordi Raccolte: existing album cover expands editorially into its album detail; newly visible first thumbnails appear with brief stagger. |
| M15 | C | When a new real search-result group arrives: very short top-to-bottom reveal of ONLY visible rows. No restart for each keystroke; preserve input/focus/filters. |
| M16 | C | Ricordi Then/Now: reveal aligned Ora photo horizontally over Prima, without modifying photo pair, comparison controls or storage. |
| M17 | C | Ricordi Map route: contextual map-surface expansion + ONE short entrance of actual geolocated pins. Never fake pins or interrupt map gestures. |
| M18 | C | On actual map pin selection: one brief scale emphasis + transient halo and coordinated memory-preview-card entrance. NO repeating pulse. |
| M19 | C | Per te Scelti per te / Vedi tutti: expand inline and briefly stagger ONLY newly revealed visible suggestions; never open Timeline or a new route. |
| M20 | C | Timeline year chip: short vertical editorial transition to newest **real nonempty month** of selected year; expand it and briefly highlight its heading. Avoid redoing all M09 stagger animations. |

**Conflict precedence inside v1.08:** genuine user data & UI5 actions > accessibility/reduced motion > navigation consistency > decorative movement. Motion may shorten or disappear; original behavior may not change.

## 2. Scope / product truth

1. Retain four main destinations Oggi, Calendario, Ricordi and Altro; central + Crea is an action, NOT a fifth tab.
2. Retain the original Unified Capture, its five actions Scrivi un momento / Foto / Attività / Nota vocale / Sketch, extended Altre opzioni and Modelli, calendar-selected-day vs TODAY date rule, original date picker and canonical content writers.
3. Preserve Ricordi / Per te anniversary and fallback rules, individual hero memories, real dates, year chips and up-to-three initial suggestions. Show Vedi tutti only if more eligible real suggestions exist, and expand within the same page.
4. Preserve Timeline months, counts, nonempty-year targeting, expanded state and session scroll, without phantom months or a second UI-history persistence store.
5. Preserve global search as a **dedicated dismissible route** with blank initial query, filter Tutti, and the five existing visible type filters Tutti/Note/Foto/Sketch/Audio; live canonical results, assigned-memory-date descending ordering, true empty/no-match states, exact content opening, restoration on Back and fresh state when search route is closed/reopened.
6. Preserve existing Map / Then-Now / Raccolte / people functions; animations must target their actual components and entries, not placeholder data or an invented navigation graph.
7. No changes to storage schema, migrations, sync, backup/restore, Noi, privacy, archive/Trash, login, RevenueCat, permissions or release signing. No new owner/store/router. Reuse existing design system and domain services.
8. Use light/dark/system, HSV personalized accent and rose reference coherently. Manrope body + Lora editorial headings. Motion decoration must not assume a hardcoded pink theme on user-customized colors.

## 3. Motion system — future implementation targets (engineering proposals, not additional user choices)

**Shared primitives:** one animation/token layer for motion durations/curves/soft-spring/reduced-motion; lifecycle-safe route/element identity; existing Flutter animation APIs before adding any dependencies.

**Timing guidance (proposed, to tune on real devices):**
- Button/tap feedback approximately 120–220 ms.
- Crossfade, small reveals and pin feedback approximately 180–350 ms.
- Hero/card/album/map transitions approximately 250–500 ms; larger editorial effects may need context-specific tuning.
- Delays between visible staggered rows approximately 35–80 ms, with total entrance bounded; NEVER attach expensive animations to entire list history.
- All durations and curve selections are tentative engineering parameters, subject to accessibility, performance and physical-device evidence; only interaction semantics in section 1 are user-approved.

**Overlap and interruption:**
- Navigation/back and keyboard input remain responsive during movement.
- Rapid taps or gesture cancellation must not duplicate destinations, leave ghost cards, desynchronize selected days/years, lose focus, or lock content behind a transition.
- M05 dominates ordinary Oggi day swipe rather than retriggering M06 entire page.
- M09 is not replayed in full after M20 year jump.
- M11 is a shared photograph transition; M14 is an album opening, neither replaces native route semantics or the real data-backed detail.
- No recurring loops, perpetual halos, confetti storms or pulsating map pins.

**Accessibility:**
- Respect OS reduce-motion and in-app accessibility where exposed; replace complex movement with immediate semantic state changes or understated crossfade.
- Semantics/TalkBack and screen-reader focus, tappable target size, touch navigation, Back button, font scaling, insets/safe areas, scrolling, keyboard/IME and RTL/direction-sensitive needs must be verified.
- Decorative effects cannot be required to understand or complete an action.

## 4. Acceptance scenarios (future implementation QA)

| Area | Acceptance scenario |
| --- | --- |
| App shell | All four tabs work; previous screen retained correctly; Hero only for matching content. No UI5 regression in nested navigation. |
| Crea & save | 5 primary actions, other options and date routing unchanged. Success animation shown only AFTER confirmed canonical save. Failure/error produces no success visuals. |
| Oggi | Fast day switching keeps selected day aligned with data; no duplicate cards or continuous global stagger; return-to-today works. |
| Calendario | Month/week boundaries, locale/week numbers where present, leap day and event selection remain correct during animated reflow. |
| Per te | Every authentic memory retains its photo/date/identity. Suggestions expand in place only when additional eligible content exists. |
| Timeline | Nonempty initial month; target year goes to latest actual nonempty month; month expands once; scroll and Back/session state preserved. Empty year behavior remains data-true. |
| Search | Blank query guide; five real type chips; fast typing does not repeatedly animate or lose input; no matches and filter reset correct; closing/reopening starts clean; Back restores query and scroll from detail. |
| Albums & details | Shared photo/album cover corresponds to same memory/collection; rapid open/close/back does not show wrong images or leak media. |
| Map & Then/Now | Geolocated pins only, map drag/zoom intact, selected preview matches pin; no repeated halo. Before/After photos aligned and associated with actual pair. |
| Motion-disabled | Everything remains usable with accessibility reduce-motion; no decorative cascade/zoom/wipe; state and feedback still accurate. |
| Device/performance | Verify smoothness, bounded list work, image decode pressure, battery, web fallback and Android hardware at small/large screens. No overflow or frozen touch input. |
| Data and upgrades | In-place update does not wipe local content; preserve historical stores, import compatibility and original signing/package identity. |

**Evidence levels:** Flutter analyze/tests/Web and exact-head AppLab Source Gate validate source contracts; they do NOT certify Android native visuals or haptics. Native integration, physical-device and update-install checks require separate explicit evidence. Test outcomes remain NOT VERIFIED until performed after implementation.

## 5. Proposed implementation work packages — NOT AUTHORIZED

Work-package order minimizes coupling and permits independent verification; it is a proposal for a later separately approved v1.08 execution:

1. **MOTION-FOUNDATION:** motion tokens, per-target reduced motion, route/cancelation safety, theme and accessibility hooks; no new duplicate owner/service.
2. **SHELL + CAPTURE:** M01–M04 and M10. Preserve UI5 four-tab shell, canonical Crea route/date and success truth.
3. **DAILY + CALENDAR:** M05–M07. Ensure Oggi day-swipe and summary stagger do not conflict with Calendar grid transitions.
4. **RICORDI BASIC:** M08–M09, M11–M12, M14, M19–M20. Real-data Hero identities, month logic, editorial album/per-te content.
5. **SEARCH + MAP + COMPARISON:** M13, M15–M18. Search input/keyboard and map gestures, Then/Now photo alignment and bounded pin/rows.
6. **INTEGRATED QA:** regression tests, accessibility, localization, visual comparison, frame-time/jank and image-memory checks, source gates on final SHA, manual native/physical review when separately authorized.

Possible subpackages are bounded PRs (shared foundation first). A source-only CI PASS is not an APK PASS. Keep any future APK build manual-only; if a new sideload APK is authorized it must have Android versionCode **>111**, stable package `com.riccardopinato.agenda_per_anna` and matching compatible signing, with artifact provenance.

## 6. Next-step sequencing and authority

- **NOW:** design decisions M01–M20 complete; this contract and decision register are documentation only.
- **NEXT PER EXISTING ROADMAP:** resume **v1.07 Daily-use UX** planning/authorized scope; no automatic reordering into v1.08 implementation.
- **LATER, ONLY AFTER EXPLICIT USER AUTHORIZATION:** execute v1.08 Flutter implementation from the approved contract and proposed work packages; report actual code/gates, not mockup status.
- **DEFERRED:** v1.06 external integrations until PC/device access.
- Do not mistake an HTML/CSS animated design comparison for implemented Flutter/native capability.

**Definition of done for current design-only milestone:** 20/20 decisions captured consistently, final contract linked by Roadmap, documentation-only PR passes required exact-head gates, merge safely if authorized gates permit. Neither the application implementation nor runtime certification belongs to this milestone.
