# Anna's Diary — v1.08 Motion & Visual Polish
## Interactive design decisions — Block 01 (choices 01–10)

**Status:** 10/10 USER APPROVED — DESIGN ONLY — NOT IMPLEMENTED.
**Recorded:** 30 October 2026.
**Product baseline:** post-UI5, `main@db40f53c4d1287ba14eb67d4b6987738d6e4281d` before this documentation commit.
**Factory source:** `App-Factory-Core/CURRENT.yaml` read 30 October 2026;
`App-Factory-Core@f8ec5a324823d79353a056f0d4c12d2979a18b4e`,
Master v27, Golden Index v23.
**Next:** choice 11/20, one visual/animated comparison with three options
and explicit clickable user selection at a time.

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

### Planned block 02 — design review (11–20)

Proceed one item at a time with a visual/animated mockup and user-clickable A/B/C
selection. **M11 USER APPROVED — B (31 October 2026):** opening an individual memory from its preview uses a **Hero/shared-element expansion of the same photograph** into the memory-detail screen; on back navigation this reverses smoothly, returning to the original preview/card. Match stable memory/photo identity (not arbitrary images), maintain focus, scroll restoration, data truth, and reduced-motion fallback. Preserve UI5 memory routes and existing interaction semantics. Design approved, NOT implemented.

**M12 USER APPROVED — C (31 October 2026):** brief, fluid **horizontal editorial slide** between Ricordi sub-sections **Per te**, **Timeline**, **Raccolte**, maintaining the UI5 tabs and their order and contents. Sub-tab movement is separate from global tab navigation M02, preserves selected sub-tab, history/scroll and search, and respects reduced-motion settings. Design only, NOT implemented.

**M13 USER APPROVED — C (31 October 2026):** the search icon/lens visually expands into the query input, then the dedicated Ricordi search page content enters progressively with brief, accessible motion. Preserve the UI5 dedicated search/results route, initial blank query, the `Tutti` filter default, subtle guidance, existing search data truth and Back behavior; never force users into Timeline or invent recent results. Reduced-motion disables decorative expansion. **DESIGN ONLY — NOT IMPLEMENTED.**

**M14 USER APPROVED — C (31 October 2026):** opening an existing **Ricordi → Raccolte** album uses an editorial album-opening transition: collection cover expands toward the album detail and a small number of visible thumbnails enter progressively. Keep motion **brief, accessible and limited to visible items**; preserve actual collection identity, content, route, back-navigation/scroll position and canonical data owner. Reduced-motion disables decoration. **DESIGN ONLY — NOT IMPLEMENTED.**

**M15 USER APPROVED — C (31 October 2026):** results in the dedicated Ricordi global-search route enter with a **brief top-to-bottom stagger**, limited to visible rows when a real result group arrives. Do NOT restart the cascade on every keystroke; preserve live query input, focus, filters (`Tutti` default), empty/no-match/error states, real search results and stable item identity. Reduced-motion disables stagger. **DESIGN ONLY — NOT IMPLEMENTED.**

**M16 — PENDING USER SELECTION:** visual motion in the existing Ricordi **Then/Now** comparison when changing the active photograph, with A immediate photo change, B gentle photo crossfade, C directional reveal/wipe. This is a motion-only mockup, not a redefinition of the feature or its persisted data. Preserve the real Then/Now controls and photo identity; reduced-motion fallbacks.

**M16–M20 — PENDING:** show one interactive comparison at a time, and await a specific user choice. Never prefill their decision letters.

### Sequencing

v1.05.x software line closed, UI5 physical quick smoke user-reported PASS.
v1.06 external integrations postponed until PC access.
Current session: v1.08 design exploration in batches of 10, **then** return
to v1.07 daily-use UX. Design completion is not feature/runtime certification.
