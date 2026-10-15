# Anna's Diary — v1.01 Personalization & Simplicity

Status: **IN PROGRESS**

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

## Planned sequence

- **v1.01-A** Module Preferences — completed and merged after 4/4 gates.
- **v1.01-B** Personalized Onboarding — completed and merged after 4/4 gates.
- **v1.01-C** Dynamic Explore & Personalization — implemented; merge remains gate-controlled.
- **v1.01-D** Adaptive Home & Quiet UX — quiet sync, reduced chrome, contextual cards.
- **v1.01-E** Polish, Accessibility & Regression — five-language QA and trusted runtime.

## Rollback strategy

The entire release is reversible.

If v1.01 presentation changes are reverted:
- domain data remain untouched;
- old clients ignore the new preference fields;
- current clients without those fields default to Complete;
- restoring Complete re-exposes every optional destination.

A rollback therefore changes presentation preferences, not canonical user data.
