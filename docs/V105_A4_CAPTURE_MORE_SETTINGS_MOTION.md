# v1.05-A4 — Capture / More / Settings / Motion Polish

## Goal

Finish the bounded UX foundation before Memories & Recall 3.0 by reducing
visible complexity in three high-frequency surfaces without adding a new data
owner, router, persistence path, sync engine or entitlement.

## Factory baseline

- App-Factory-Core: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Master: v26.6
- Golden Index: v22
- Factory Mode: `ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

## Unified Capture

The canonical `showUnifiedCapture` path remains the only Capture surface.

Primary actions are now visible first:

- write moment;
- photo;
- task;
- voice.

Inbox, appointment, birthday and person remain available behind explicit
progressive disclosure. Their existing write/navigation paths are unchanged.

No capture database, router or persistence owner was added.

## More

More now presents three explicit groups:

- Quick access;
- Your space;
- Data and app.

The duplicate Search icon in the AppBar was removed because Search remains a
first-class row immediately below it. Existing semantic route identifiers remain
stable for AppLab and navigation regression.

## Settings

More now opens a lightweight `SettingsHubScreen` first.

The hub routes to the existing canonical owners:

- Personalization;
- existing Preferences / Privacy settings;
- Premium;
- Account and sync;
- Backup and restore.

The historical full Settings surface is retained as the canonical advanced
preferences/privacy implementation rather than duplicated into new stores or
parallel services.

## Motion and feedback

`AnnaFeedback` centralizes subtle mobile haptics for selection/success.
Web receives no haptic call.

Capture expansion uses the existing `AnnaDesignTokens.motionStandard` and
honors `AnnaDesignTokens.animationsEnabled`, so reduced-motion/accessibility
settings disable the transition duration.

## Code hygiene

Removed/superseded presentation:

- duplicate More AppBar Search affordance;
- eight simultaneously visible Capture choices.

Retained intentionally:

- all eight canonical Capture actions;
- existing SettingsScreen implementation and services;
- More semantic route IDs;
- existing persistence, migration, sync, backup, Vault and entitlement owners.

The old Factory v21 baseline text in historical evidence remains historical.
Current execution documentation is aligned to v22 separately; no historical
PASS evidence is rewritten.

## Validation

Required exact-head gates:

- Development checks;
- Deploy Anna's Diary Web;
- Android size audit;
- AppLab Production Gate.

Physical-device and Google Play / RevenueCat real-purchase evidence remain
separate fail-closed lanes and are not claimed by this step.
