# Anna's Diary — Editorial Hybrid DS5 Calendario, bundled signed +128

**User-approved scope:** Calendar C — Armonia iOS Journal; bundle with already merged Step 4 Ricordi and compact first-person diary card.  
**Central App Factory:** App-Factory-Core@3481a8190a5db5965bb22f84832094268d05be98 (Master v27, Index v28).  
**Base app:** Agenda-per-Anna@ac935ae4bc8a4f39cad6b74590147ceeac79698c (DS4 merged).  
**Release candidate:** 1.0.0-rc.6+128, package com.riccardopinato.agenda_per_anna, unchanged stable Android signing certificate.

## Design-only implementation

- The same local `AnnaEditorialTodayMode.enabled` toggles Editorial Hybrid vs original Classic. `CalendarHubScreen` has the palette/HSV-aware headline, Mese/Settimana selector, single-line five-language tagline, and original `Il mio mese`/`Il mio anno` actions in a shared editorial surface.
- `CalendarScreen` retains one canonical `TableCalendar<UnifiedAgendaEntry>`, date selection, month paging, real markers and external calendar loaded range. Editorial uses Lora header, themed calendar grid and a matching card for the existing collapsed 07:00–22:00 hourly timeline.
- The timeline remains **initially collapsed**, below the calendar and above the selected-day agenda. Hour buttons open only the original `openItemEditor` with the selected civil date and prefilled appointment time; original Save remains the only persistence owner. Real events retain time sorting, privacy labels and original opening routes.
- `WeekScreen` reuses actual week data, navigation, notes and tasks. The new Editorial weekly overview displays only existing counts; Classic retains `_WeekHero`. Calendar filters, day context, free slots, year/month notebooks, shared/external events and all actions remain available.
- `lib/src/editorial_calendar.dart` is visual-only and uses the existing ColorScheme, Lora/Manrope and design tokens. No new dependencies, DB, sync, media records, Vault changes or Play release.

## Gates

Exact-head PR and main Flutter analyze/full tests/Chrome Vault/Web, AppLab Source Gate and review, then existing auto signed ARM64 workflow and stable-key verification. The +128 artifact must have matching package and signing fingerprint and versionCode 128; verify SHA256 and certification manifest.

**NOT VERIFIED until physical phone test:** update-in-place from +127 without record loss, Calendar day-selection and creation, narrow screens, theme/HSV, large text, Android insets, Ricordi media viewer and full source-to-device visual fidelity.
