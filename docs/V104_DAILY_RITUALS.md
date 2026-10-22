# Anna's Diary — v1.04 Daily Rituals & Life Flow

Status: **IMPLEMENTED CANDIDATE — EXACT-HEAD 4/4 MERGE GATE REQUIRED**

Factory baseline:
- App-Factory-Core `47c47f49a7b46812e3bd6f1231c3524f2b52b826`
- Master v26.6
- Golden Index v18

## Product goal

Add optional morning and evening ritual moments to **Planner → Today** without
turning Anna's Diary into a habit tracker, streak product or parallel journaling
system.

## Ownership and reuse

v1.04 introduces no new database, repository, sync queue or canonical ritual
entity.

- enablement, reminder preference and local times live in `AgendaPreferences`;
- starting a ritual materializes one ordinary editable `DiaryBlock` through
  the existing diary-template write path;
- the stable tags `ritual:morning` / `ritual:evening` provide deterministic
  same-day idempotency without creating a ritual store;
- local alerts reuse `NotificationService.scheduleDaily`;
- notification taps route to the existing Planner Today surface;
- preferences continue through the existing backup/restore path.

## UX contract

- Morning and evening rituals are disabled by default.
- Each ritual can be enabled independently from Settings.
- Suggested local times default to 08:00 and 20:30 and remain editable.
- Reminder permission is requested only when the user explicitly enables ritual
  reminders.
- If both rituals are disabled, ritual reminders are disabled too.
- The ritual card appears only for the current day in Planner, never on
  historical/future days.
- Starting a ritual twice on the same day returns the same canonical diary
  block and creates no duplicate.
- The UI says **Started / Iniziato**, not “Completed”, because v1.04 does not
  invent a completion metric.
- All new copy resolves through the existing en/it/es/fr/pt localization
  catalog.

## Privacy and lifecycle

Ritual content is ordinary private diary content. Existing diary lifecycle,
backup, account isolation, media handling, search and privacy rules remain
authoritative. No AI, scoring, psychological inference or autonomous narrative
is introduced.

## Acceptance gate

Before merge to `main` the exact candidate head must pass:

1. Development checks;
2. Deploy Anna's Diary Web;
3. Android size audit;
4. AppLab Production Gate.

Physical/store/cross-app evidence is not required to prove this local product
feature and is not promoted by v1.04.
