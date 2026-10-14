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

Fresh profiles keep the existing welcome explanation, then choose one of three
clear starting presets before entering the app:

- **Essential** — core Today/Calendar/Diary/Capture surfaces only;
- **My Life** — Essential plus Memories, People and Habits; recommended default;
- **Complete** — every optional module visible.

The choice is persisted through the v1.01-A preference contract. Existing
profiles never see this migration screen again because their onboarding state
is already complete and their missing v1.01 fields resolve to Complete.

The onboarding explicitly tells users that the choice is reversible and never
deletes content.

## Planned sequence

- **v1.01-A** Module Preferences — persistence contract and compatibility.
- **v1.01-B** Personalized Onboarding — preset choice for fresh profiles.
- **v1.01-C** Dynamic Explore & Personalization — module visibility and user controls.
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
