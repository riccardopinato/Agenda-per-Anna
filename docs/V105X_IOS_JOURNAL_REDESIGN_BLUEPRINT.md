# Anna's Diary — iOS Journal visual redesign (v1.05.x only)

**Approved direction (28 Oct 2026):** Armonia iOS Journal, with editorial memories. Authoritative design choices from the user's explicit blueprint:
- Today **C** (Harmony); Calendar **C** (Harmony); Memories **B** (Contemporary Diary); More **C** (Harmony); Settings **A** (iOS Essential).
- UI typography **Manrope**; editorial/selected memory and diary headings **Lora**.
- Default reference palette **rose**, reference appearance **light**, but honor every saved palette, custom HSV seed, delicate/expressive intensity, dark/system setting.
- Mobile navigation **attached four-destination bar** (Today, Calendar, Memories, More), not a floating dock and no fifth tab.
- iOS-inspired hierarchy, spacing, grouped surfaces, motion, and clear affordances; remain a Flutter Material 3 application rather than claiming native iOS controls or native Liquid Glass.
- No v1.06. Work in Chat with protected PRs, exact-head checks and review.

## Dependency / integration gate

**PR #138 (custom HSV appearance) must be verified and integrated first.** At the time this plan was prepared, its head is `7d39ab26184382fc1f31e37c13f9234850a880ff`; Development/Web/Android audits PASS but **AppLab trusted runtime FAIL** at the **people** Maestro checkpoint (and Codex review pending). Do not treat a Flutter build PASS as the failed AppLab gate passing. Investigate/retest the underlying visual failure independently; do not weaken or bypass the checkpoint.

The first redesign PR is **logically dependent on #138** (branch `ux/v105x-ios-journal-ds1`). CI workflows trigger only for PRs targeting `main`; for exact-head validation, PR #139 may temporarily use `main` as its GitHub base, while its content still includes #138. **This is not merge permission**, and the #138 review/merge prerequisite remains in force. Return to the stacked parent or reconcile after the parent is merged, then rerun exact-head checks as required. It must never merge into main while #138 has blocking gates. After #138 passes and is merged, retarget to main and re-check its exact head. If #138 changes, synchronize, resolve and rerun all checks.

## Execution order

| Step | Screen(s) | Layout / design | Required acceptance |
| --- | --- | --- | --- |
| **UI3-D0: Design system foundation** | Shared theme and app shell | Centralized typography scale, `AnnaJournalPageHeader`, responsive content, domain-aware cards and section headings; 20dp gutters, 24dp rhythm, attached 76dp Material3 nav (four tabs), unchanged navigation state | Theme builds in light/dark and rose/custom HSV; selected indicator preserves delicate/expressive; 48dp targets; no changed storage, account or routes |
| **UI3-D0b: Font asset closure** | Shared typography | Bundle licensable **Manrope** and **Lora** font files locally in Flutter assets (no runtime font download). Map weights accurately, preserve multilingual glyphs and text-scale. The `fontFamily` tokens are *only scaffolding* until this happens | Fonts render OFFLINE on Android and Web, license notices included; no uncached network dependency. Keep phase IN PROGRESS until achieved |
| **UI3-D1: Today C** | Today / diary | Date strip, clear primary commitment hero, a compact activity+wellbeing pair, prominent *existing JournalEditor*, memories and optionally ritual, timeline collapsed later; existing Unified Capture sole write path | No duplicate CTA or phantom events; privacy masking, empty/offline/busy states, scroll/keyboard and deep-link preservation |
| **UI3-D2: Calendar C** | Month / Week | Large title, capsule mode switch, legible 7-column month, distinct today/selected and event indicators, useful date detail, month/year summaries. Mobile stack, dual pane on tablet/Web only when space permits | Selection, keyboard/touch, agenda overlays, recurrence, reminders and content filters unaffected |
| **UI3-D3: Memories B** | For You / Timeline | Editorial Lora accents, real-media-first hero, readable text-only fallbacks, collections/map/time grouping, searchable/filterable Timeline, no invented photos | Existing DiaryBlockReference/places/people privacy and memory projection owners retained; fast 10k-memory projection |
| **UI3-D4: More C & Settings A** | More / Settings | More quick actions, clear group categories; Settings iOS-like grouped rows, Appearance/colors entry from #138, account/backup/privacy and premium intact | All semantic IDs, conditional Noi navigation, alerts and direct routes preserved; no duplicate settings or preference owner |
| **UI3-D5: Final visual QA** | All | Baseline screenshots at 360/390/600/840/1180dp, light/dark, all palette seeds and custom HSV, scale 1.0/1.3/1.6; performance, reduced-motion and accessibility passes | Development/Web/Android/AppLab exact-head PASS, Codex clean, no physical/Play claims without actual evidence; docs and Product Bible aligned |

D0 to D5 are independent, reviewable **v1.05.x UX/UI phases**. They do not consume the planned v1.06 ecosystem-expansion scope.

## Detailed design contract

### Shared
- Semantic `ColorScheme.fromSeed` remains the sole global color owner; use `Theme.of(context).colorScheme` rather than hardcoded brand foreground/background colors.
- `AnnaJournalTheme.apply` decorates the existing theme *after* the saved palette/HSV/intensity is computed. It must preserve the base `NavigationBarThemeData.indicatorColor`, including Expressive.
- Navigation remains in `Scaffold.bottomNavigationBar`, not in an unconstrained overlay; do not change `IndexedStack`, NavigationRail threshold >=840dp, extended rail >=1180dp, keys, semantics or deep links.
- Typographic roles: UI 400/500/600/700; title approximately 30–34sp, sections 18–20sp, body 14–16sp; editorial Lora only in diary/featured memories, not in small controls.
- Themes: light/dark/system, rose/lilac/sage/peach/sky/custom, delicate/expressive. Do not increase font download/runtime dependency.
- Cards: radius 20–24dp, hero 28dp, section gap ~24dp; 48dp+ interactive targets; no aggressive blur required. Avoid hardcoded fixed heights for variable text.
- Strings: use existing en/it/es/fr/pt catalog, never new non-localized fixed labels in app code.

### Today C
- **Top:** date and large title; 4-5 day quick strip.
- **Focus:** hero displaying a meaningful, privacy-safe derived item when present; fallback invitation when empty.
- **Middle:** compact activities/wellbeing; diary editor with multiple content types, not a second persistence store.
- **Bottom:** memory recall, opt-in rituals, optional expanded timeline, with content-derived visibility.

### Calendar C
- Segmented Month/Week, month grid, selected-date summary, direct entry to Day/Diary and existing Month/Year summaries; a distinct focus treatment for today's date.
- Show dots/icons with a non-color signal for accessible event types.

### Memories B
- A large but bounded featured-media card using actual photo content; fallback editorial text/voice/sketch treatment when media absent.
- Preserve For You/Timeline choice, filters, search, map, collections and linked memory reference model. No new memory DB.

### More C
- Search and Inbox are quick actions; Explore nearby. Personalization/Noi (conditional) grouped under personal space; Archive, Cloud, Backup, Settings grouped under data/app.
- Preserve sync-attention and privacy alerts.

### Settings A
- Group rows with icons and sections rather than nested menus. Appearance & colors from PR #138 displayed once as a primary personalized entry; maintain existing SettingsHub and SettingsScreen flows and legacy semantic IDs.

## Evidence, stop conditions, and risk

- UI3-D0 status: **IN PROGRESS on stacked branch**, not integrated or signed. It currently includes shared layout primitives, typographic semantic tokens and theme composition. Official Manrope and Lora variable TTF files and SIL OFL notices are bundled in `assets/fonts/`, with variable weights mapped in `pubspec.yaml`. Offline Android/Web execution and multi-locale glyph QA are NOT VERIFIED pending exact-head CI; visual physical-device certification is NOT VERIFIED.
- The existing user-created data, profile prefs, local storage, backup, Cloud account/sync, private Vault and paid entitlements must not be touched in the redesign branch.
- Stop any merge on failing required checks, unresolved reviews, or base-head drift; never bypass the #138 AppLab failure or branch protection.
