# v1.05-A0 — UX / Design Foundation

## Goal

Create one reusable visual foundation before changing Anna's Diary information
architecture. This step deliberately changes presentation primitives without
adding a new product domain, persistence owner, sync path or entitlement.

## Factory baseline

- App-Factory-Core: `4cc0b94467b94ab6fabe2c927fcc58afff49e39a`
- Master: v26.6
- Golden Index: v19

## REUSE-FIRST review

Patterns were reviewed before implementation in five relevant Flutter/open-source
products:

- StoryPad — simple diary-first Flutter product structure;
- Inkwell — mobile NavigationBar / desktop NavigationRail responsive pattern;
- Moodiary — mature diary theming, import/export and places/map direction;
- Daily You — privacy-first diary and migration/import emphasis;
- PlaneTxt — agenda/journal/quick-add and future wide-screen layout.

No donor source code is copied. GPL/AGPL projects are reference-only. Anna keeps
its own implementation and existing license boundaries.

## Implemented

### Canonical design tokens

`AnnaDesignTokens` now owns:

- spacing: 4 / 8 / 12 / 16 / 24 / 32;
- radius: 12 / 18 / 24 / 28;
- motion: 120 / 180 / 260 ms;
- content widths and the wide-layout breakpoint;
- a reduced-motion/accessibility check.

### Semantic visual domains

`AnnaVisualDomain` defines restrained accents for Today, Calendar, Memories,
People, Noi, Workout, Vault and Ecosystem. These are presentation tokens only:
they never own or copy domain data.

### Dark-mode surface correction

Accent/hero surfaces no longer blend toward white unconditionally. Light mode
blends toward the light surface and dark mode toward Material surface containers,
so dark mode remains genuinely dark rather than pastel-grey.

### Shared Material foundation

The app theme now centralizes:

- card radius/border/surface treatment;
- filled text fields and focus borders;
- bottom-sheet geometry;
- button geometry and minimum accessible height;
- chip shape;
- navigation-bar height and surface behavior.

`NavigationCard`, `SectionTitle` and `SimpleCard` consume the same tokens.

## Explicit non-goals

This step does **not** yet:

- change the main destinations;
- remove Home;
- merge Month and Week;
- redesign Unified Capture;
- restructure Settings;
- create Memory Map / Collections / Life Threads;
- change storage, sync, backup, cloud schemas or RevenueCat.

Those changes remain separately reviewable in the next roadmap steps.

## Acceptance

- `flutter analyze` and full tests green;
- Web release green;
- Android size audit green;
- AppLab trusted runtime green on the same exact head;
- existing accessibility and five-language behavior preserved;
- no visual regression is promoted to PASS without a real baseline.
