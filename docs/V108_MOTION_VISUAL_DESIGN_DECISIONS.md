# Anna's Diary — v1.08 Motion & Visual Polish
## Design approval register — all choices M01–M20

**Status:** 20/20 USER APPROVED — DESIGN CLOSED — NOT IMPLEMENTED.
**Recorded:** 30–31 October 2026.
**Product baseline:** post-UI5, `main@db40f53c4d1287ba14eb67d4b6987738d6e4281d` before this documentation commit.
**Factory source:** `App-Factory-Core/CURRENT.yaml` read 30 October 2026;
`App-Factory-Core@f8ec5a324823d79353a056f0d4c12d2979a18b4e`,
Master v27, Golden Index v23.
**Next:** see [final implementation-ready DESIGN contract](V108_MOTION_VISUAL_POLISH_FINAL_DESIGN_CONTRACT.md). The 20 decisions are approved as design only. Actual Flutter changes still require a separate, explicit authorization; the previously approved sequence resumes v1.07 Daily-use UX planning after this design round.

### Block 01 — canonical user decisions

| ID | Choice | Approved behavior |
| --- | --- | --- |
| M01 | **B — Morbido e fluido** | Global motion direction: soft, natural, elegant; avoid showy perpetual animations. |
| M02 | **B + C — navigation + relevant shared elements** | Four-tab navigation uses fade plus slight directional slide; Hero/shared-element continuity ONLY for meaningful matched content routes (e.g., diary photo to matching detail), not arbitrary tab elements. |
| M03 | **B — Crea press feedback** | Delicate elastic compression; transient pink halo slightly stronger on release; NO continual pulsing glow. |
| M04 | **C — Crea fan opening** | Fan-style entrance for actions, while preserving the canonical UI5 Unified Capture bottom sheet, five primary actions, other options and date semantics; no new persistence/write path. |
| M05 | **C — Oggi day change** | Directional horizontal movement of daily content when moving between dates. |
| M06 | **C — Oggi summaries** | Brief staggered top-to-bottom appearance of summary cards. Coordinate with M05: avoid layering full stagger on each normal day swipe. |
| M07 | **C — Calendar grid** | Light zoom and animated transformation/recomposition of month/week grid, preserving day and agenda correctness. |
| M08 | **C — Per te magazine effect** | Between individual featured memories, photograph and accompanying text move and recompose with an editorial/magazine feel, while retaining actual memory identity. |
| M09 | **C — Timeline accordion stagger** | Expand month with brief delicate stagger of visible memories only; no unbounded item animations; reduced-motion safe. |
| M10 | **C — save success confirmation** | Animated check mark, temporary rose glow and tiny sparkles **only after actual successful persistence**; no false success during pending/failure. |

### Design implementation boundaries (not authorization to code)

- Existing UI5 routes, central Crea, 5 visible capture actions and expanded other options stay unchanged.
- Reuse design tokens, Manrope/Lora, rose palette and HSV user-selected colors; avoid hard-coded light-theme-only motion effects.
- User's reduced-motion / OS accessibility preferences take precedence; all decorative motion can fall back to instantaneous or understated feedback.
- Animate visually relevant elements rather than rebuilding canonical models, images, data stores or sync.
- Preserve touch targets, focus order, Back/navigation semantics, scroll position, accessibility labels and state restoration.
- Keep transitions performant: avoid full-list animation for extensive Timeline history, unnecessary image decodes and jank.
- Do not change data, privacy, backup, sync, billing, account identity or signing as side effects of motion.
- v1.08 **design selection only** until user explicitly authorizes implementation.
- No APK is built to record a design decision. Any future signed APK must use strictly greater Android versionCode than 111.

### Block 02 — canonical user decisions (M11–M20)

**M11 USER APPROVED — B (31 October 2026):** opening an individual memory from its preview uses a **Hero/shared-element expansion of the same photograph** into the memory-detail screen; on back navigation this reverses smoothly, returning to the original preview/card. Match stable memory/photo identity (not arbitrary images), maintain focus, scroll restoration, data truth, and reduced-motion fallback. Preserve UI5 memory routes and existing interaction semantics. Design approved, NOT implemented.

**M12 USER APPROVED — C (31 October 2026):** brief, fluid **horizontal editorial slide** between Ricordi sub-sections **Per te**, **Timeline**, **Raccolte**, maintaining the UI5 tabs and their order and contents. Sub-tab movement is separate from global tab navigation M02, preserves selected sub-tab, history/scroll and search, and respects reduced-motion settings. Design only, NOT implemented.

**M13 USER APPROVED — C (31 October 2026):** the search icon/lens visually expands into the query input, then the dedicated Ricordi search page content enters progressively with brief, accessible motion. Preserve the UI5 dedicated search/results route, initial blank query, the `Tutti` filter default, subtle guidance, existing search data truth and Back behavior; never force users into Timeline or invent recent results. Reduced-motion disables decorative expansion. **DESIGN ONLY — NOT IMPLEMENTED.**

**M14 USER APPROVED — C (31 October 2026):** opening an existing **Ricordi → Raccolte** album uses an editorial album-opening transition: collection cover expands toward the album detail and a small number of visible thumbnails enter progressively. Keep motion **brief, accessible and limited to visible items**; preserve actual collection identity, content, route, back-navigation/scroll position and canonical data owner. Reduced-motion disables decoration. **DESIGN ONLY — NOT IMPLEMENTED.**

**M15 USER APPROVED — C (31 October 2026):** results in the dedicated Ricordi global-search route enter with a **brief top-to-bottom stagger**, limited to visible rows when a real result group arrives. Do NOT restart the cascade on every keystroke; preserve live query input, focus, filters (`Tutti` default), empty/no-match/error states, real search results and stable item identity. Reduced-motion disables stagger. **DESIGN ONLY — NOT IMPLEMENTED.**

**M16 USER APPROVED — C (31 October 2026):** Ricordi Then/Now photo comparison reveals the **Ora** photograph horizontally over the **Prima** photograph, with short aligned transition, preserving the photo pair/compare controls, photo identity and data. With reduced motion, use immediate update. **DESIGN ONLY — NOT IMPLEMENTED.**

**M17 USER APPROVED — C (31 October 2026):** existing Ricordi Map opens via a **brief contextual expansion** of the map surface from the map entry context, with a one-time progressive entrance of the real geolocated memory pins. The effect must not fake locations, delay map availability, reorder or duplicate the UI5 Ricordi sub-tabs, or disrupt map gestures, accessibility, and back-navigation. No perpetual pin pulses; reduced-motion shows the map and pins immediately. **DESIGN ONLY — NOT IMPLEMENTED.**

**M18 USER APPROVED — C (31 October 2026):** tapping an existing real Ricordi Map pin produces **one brief pin scale emphasis, a temporary halo and coordinated entrance of the selected memory preview card**. No continuous pulsing or repeated decoration; keep map gestures, stable memory and location identity, performance, accessibility, and reduced-motion fallback. The preview is shown only for actual selected items. **DESIGN ONLY — NOT IMPLEMENTED.**

**M19 USER APPROVED — C (31 October 2026):** in Ricordi → Per te, `Vedi tutti` expands the existing `Scelti per te` section **in place** with a smooth, brief bounded expansion and short stagger for **only the newly revealed visible cards**. `Vedi tutti` must be shown only when additional real eligible suggestions exist; preserve canonical suggestions, scroll/focus, Back and accessibility, and never navigate to another page or Timeline. Respect reduced-motion and performance. **DESIGN ONLY — NOT IMPLEMENTED.**

**M20 USER APPROVED — C (31 October 2026):** Ricordi → Timeline year selection uses a **short vertical editorial transition** to the latest **actually populated month** of the selected year, **expands** that month and temporarily emphasizes its heading. Preserve UI5 year-chip selection, actual month counts, expanded groups and in-session history. Never show phantom months or trigger a second expensive M09 item cascade on each year change. Respect reduced-motion and accessibility. **DESIGN ONLY — NOT IMPLEMENTED.**

**M01–M20 CLOSED as design decisions.** All 20 are documented in the final contract. No code, build, APK, runtime or visual certification is implied.

### Sequencing

v1.05.x software line closed, UI5 physical quick smoke user-reported PASS.
v1.06 external integrations postponed until PC access.
v1.08 design selection is now **COMPLETE (20/20)**. The approved sequencing returns to **v1.07 Daily-use UX** planning; v1.08 Flutter implementation is **NOT AUTHORIZED** by design approval alone. Design completion is not feature/runtime certification.
