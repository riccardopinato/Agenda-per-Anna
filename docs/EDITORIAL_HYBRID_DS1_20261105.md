# Anna's Diary — Editorial Hybrid DS1 (5 November 2026)

**Authority:** user approval of the Editorial Hybrid visual direction, after side-by-side B/C interactive Android previews and user acceptance of the docked bottom bar. **Scope:** Step 1 only — reusable visual design system. The production Home and its navigation remain unchanged during this step.

**Factory:** App-Factory-Core@42ad47a9ebacc55ae901ea55a01a6855e320377d; CURRENT Master v27, Golden Index v28.
**Experimental donor:** PR #254, design_lab/editorial/lib/main.dart at afb2b34d1212ad29275daa3b80984ead0ee76177; draft and NOT merged into production.

## Reused canonical components

- ThemeData/ColorScheme from AgendaApp, including stored rose/lilac/sage/peach/sky/custom HSV seed, theme mode and color intensity. **No second palette preference, no color hardcoding.**
- AnnaJournalTypography (Manrope UI, Lora editorial headers), locally packaged SIL OFL fonts; no new font assets or dependencies.
- AnnaDesignTokens, AnnaJournalPageHeader, AnnaJournalCard and AnnaResponsiveShellPolicy are retained and NOT replaced until a feature-screen migration requests that delta.

## New bounded components

File: lib/src/editorial_hybrid_design.dart, part of existing lib/main.dart.

| Component | Purpose |
| --- | --- |
| AnnaEditorialTokens | Rhythm, editorial type scale, radius and minimum 48dp touch target referencing current tokens |
| AnnaEditorialColors | ColorScheme-derived canvas, card, quiet/featured surfaces, accents, outlines and readable text |
| AnnaEditorialPageLayout | Non-scrolling max-width reading area; caller retains scroll/keyboard behavior |
| AnnaEditorialHeader | Lora editorial heading and caller-provided, localized, data-true subheading; optional trailing action |
| AnnaEditorialSurface | Responsive, optional clickable editorial card with quiet/featured variants |
| AnnaEditorialPrimaryAction | Pill CTA using active theme palette and at least 48dp target |
| AnnaEditorialQuickAction / AnnaEditorialActionPair | Modular card duo, stacking on narrow screens without fixed text heights |
| AnnaEditorialSectionHeading | Lightweight editorial section heading |
| AnnaEditorialDockSurface | Full-bleed attached presentation-only bottom bar, SafeArea-aware; **no nav action ownership** |

## Invariants

- No change to AgendaApp theme selection, main shell, existing four tabs, +Crea canonical writer/animation, calendar, search, Vault or shared spaces.
- No fake diary data, no new account/store/router, no new persistence, no migration, no package/version increment, no APK or Play release.
- Existing localized content and user preference colors remain authoritative; this layer only styles widgets supplied in a later approved screen migration.
- Preserve accessibility, 48dp action targets, text-scale, OS reduced-motion constraints and future physical safe-area validation.
- Avoid merging the standalone Design Lab into main. Its data and navigation do not belong in production.
- **Step 2:** enable a real-data Editorial Hybrid Home behind an explicit local appearance preference; migrate by composition using the canonical Today store and capture routes (not simulated preview data). Only after explicit UI validation extend to other screens.

## Evidence
Dedicated widget tests cover theme dependence across different color seeds and brightness, accessible CTA, narrow-screen large-text card flow, and full-bleed dock geometry. Exact-head Flutter analyze/test/Web + AppLab Source Gate required before merge. Actual app UI has not switched to Editorial Hybrid, and physical screenshot matrix remains NOT VERIFIED.
