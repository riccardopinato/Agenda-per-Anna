# Anna's Diary — v1.01 Personalization & Simplicity

Status: **COMPLETED — A→E merged with exact-head 4/4 gates**

## Product goal

Make the existing product feel smaller, calmer and personal without removing
capabilities or creating new data owners.

The release is intentionally additive at the presentation layer and
conservative at persistence boundaries.

## Non-negotiable rules

- Hiding a module never deletes or migrates its data.
- Existing profiles must retain the current complete experience by default.
- Module visibility is persisted only through the existing
  `AgendaPreferences` path.
- Backup/restore and account preference lifecycle continue to reuse the current
  canonical preference payload.
- No second preferences store, router, database or sync queue is introduced.
- Every user can restore the complete experience at any time.
- v1.01 does not add new feature domains.

## v1.01-A — Module Preferences

Introduces the reversible personalization contract only. No major UI is changed.

Optional presentation modules:
- Memories;
- People;
- Habits;
- Noi ♡ / shared space;
- Shopping;
- Workout;
- Cycle Tracker;
- Private Vault;
- Life Ecosystem.

Core surfaces remain outside module hiding:
- Today / planning;
- Calendar;
- private Diary;
- Unified Capture;
- Search;
- account/data safety.

### Presets

- **Essential**: core surfaces only.
- **My Life**: Memories + People + Habits.
- **Complete**: all optional modules enabled.
- **Custom**: any manual combination.

Legacy payloads without personalization fields resolve to **Complete**, so
updating the app does not suddenly hide existing destinations.

Manual module toggles switch the preference state to **Custom**.

## v1.01-B — Personalized Onboarding

Fresh profiles now receive a concise two-step first-run flow:

- choose **Essential**, **My Life** or **Complete**; **My Life** is the recommended
  starting point, while **Custom** stays out of first-run and belongs to the later
  personalization controls;
- optionally open the existing **Unified Capture** for the first useful action,
  or enter the agenda without creating anything.

The preset and `onboardingDone` flag are persisted together through the existing
`AgendaPreferences` path only when onboarding completes. A partially completed
first run therefore cannot leave half-applied personalization behind.

Existing profiles do not re-enter onboarding because their existing
`onboardingDone` state remains authoritative and legacy v1.01 fields still
resolve to **Complete**.

The flow is local-first, does not require account creation, uses the existing
five-language catalog, and exposes stable semantics for AppLab/Maestro. Hiding a
module remains presentation-only and never deletes domain data.

## v1.01-C — Dynamic Explore & Personalization

The v1.01-A preference contract now drives presentation:

- Explore renders only enabled optional destinations and always exposes a
  Personalize entry point;
- Settings exposes one Personalize surface for Essential / My Life / Complete
  presets and manual per-module switches;
- manual switches resolve to Custom through the existing
  `AgendaPreferences.withModuleEnabled` path;
- Home hides optional Noi ♡ and Private Vault entry points when disabled,
  suppresses People birthday preview when People is disabled, and removes the
  habits summary when Habits is disabled;
- the day editor hides habit controls when Habits is disabled;
- Cycle Tracker is hidden inside Private Vault when its module is disabled;
- Cycle Tracker → Private Vault dependency and Vault-off → Cycle-off behavior
  remain owned by the v1.01-A preference contract;
- Search, Archive, data safety and canonical storage remain intact, so hidden
  data is recoverable and never deleted.

No second preferences store, router, database or sync queue is introduced.

## v1.01-D — Adaptive Home & Quiet UX

Home now adapts presentation without changing any canonical owner:

- Search remains a direct high-frequency action;
- Inbox is direct only when there is active content requiring attention and is
  always reachable through the stable **More** menu;
- Noi ♡ becomes a direct Home action only when the module is enabled and unread
  shared activity exists; otherwise it remains available from More when enabled;
- Archive, Backup, Account & sync, Settings, Explore and Personalize are grouped
  under the stable `home_more_menu` secondary-navigation control;
- the Private Vault card follows its module preference;
- birthday preview is omitted when People is hidden;
- Habits and Memories metrics disappear independently from the wellbeing card
  while core mood/gratitude presentation remains available;
- Home shows Explore only when at least one Explore destination is enabled;
  otherwise it points directly to Personalize;
- intentional device-only use and a healthy fully-synced cloud state are silent;
- sync errors, pending changes, shared-sync failures and lost authenticated
  sessions remain visible and actionable.

Contextual references from Search, Archive or historical records may still open
hidden-module content. Module hiding remains a discovery/presentation choice and
never deletes, migrates or orphans data.

No new router, persistence store, database, sync queue or recommendation engine
is introduced.

## v1.01-E — Polish, Accessibility & Regression

The final v1.01 step hardens the presentation layer without changing product
ownership or adding feature scope:

- onboarding titles and Personalize section titles expose explicit heading
  semantics;
- onboarding preset cards expose one stable, non-duplicated semantic node with
  selection state, action and localized descriptive label;
- the recommended badge can wrap below the preset title instead of forcing a
  rigid row, reducing overflow risk on narrow screens and with larger text;
- preset chips and module switches in Personalize expose stable semantic IDs,
  explicit state and accessibility actions without duplicating descendant
  semantics;
- the Home More control exposes an explicit localized accessibility label;
- the v1.01 regression suite renders fresh onboarding at a narrow viewport in
  English, Italian, Spanish, French and Portuguese and rejects any rendering
  exception;
- every v1.01 presentation localization row is required to contain non-empty
  en/it/es/fr/pt values;
- AppLab adds a trusted personalization checkpoint that enters through More,
  applies Essential, performs one manual Custom change, restores Complete and
  returns to Home;
- all E changes remain presentation-only and continue to reuse
  `AgendaPreferences`, existing stores, existing navigation and the canonical
  Unified Capture path.

The final merge remains fail-closed on Development checks, Web deploy, Android
size audit and AppLab Production Gate passing on the same exact PR head.

## Planned sequence

- **v1.01-A** Module Preferences — completed and merged after 4/4 gates.
- **v1.01-B** Personalized Onboarding — completed and merged after 4/4 gates.
- **v1.01-C** Dynamic Explore & Personalization — completed and merged after 4/4 gates.
- **v1.01-D** Adaptive Home & Quiet UX — completed and merged after 4/4 gates.
- **v1.01-E** Polish, Accessibility & Regression — completed and merged after 4/4 exact-head gates.
- **v1.01-F** Release Truth & Factory Alignment — completed documentation/evidence closure under App Factory v26.6.

## Rollback strategy

The entire release is reversible.

If v1.01 presentation changes are reverted:
- domain data remain untouched;
- old clients ignore the new preference fields;
- current clients without those fields default to Complete;
- restoring Complete re-exposes every optional destination.

A rollback therefore changes presentation preferences, not canonical user data.
