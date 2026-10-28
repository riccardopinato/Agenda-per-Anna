# Anna's Diary — v1.05.x post-maintenance pastel UI polish

Status: **IN PROGRESS — protected PR; exact-head gates and review required**.

Base app: v1.05.x maintenance Completed, integrated main `ab3bef172af68c7c0941f80f25cdc89449d0cd1b`.
Factory baseline: App-Factory-Core `7b84e33df715cf2a48bda7c7495d0690819bff0f` (Master v26.6 / Golden Index v23).
No v1.06 development, schema changes or release certification are implied.

## Bounded first slice — Today, More, Settings

- **Today:** one primary, labelled Capture FAB; remove competing AppBar add shortcut, keeping the existing canonical unified item composer available from Capture. Diary writing appears ahead of the derived life stream and secondary hourly timeline. Desktop/Web reading area has a comfortable capped width.
- **More:** keep Search, Inbox, Explore, Personalization, Noi, Archive, Backup, Cloud and Settings entry points and their semantic IDs. Present clear grouped headers with light/dark-responsive pastel icon surfaces; cap content width on wide displays.
- **Settings:** retain existing Personalization, advanced preferences/privacy, Premium, account/sync, backup/restore routes and IDs. Apply the same section pattern and width constraint.
- **Design system:** reuse existing `AnnaVisualDomain` semantic accents and spacing/radius tokens; new `AnnaPastelIcon` and `AnnaPastelSectionHeader` remain presentation-only. Icon glyphs use `onSurface` for readable contrast across themes.
- **No new persistence or duplicated writes:** no change to AgendaStore, DayJournal, sync, backup, user preferences, identity, entitlement or encryption. No app-version bump or new APK in this UI-only review.

## Regression policy

1. Check diary-before-life-stream order and canonical Capture reachability.
2. Keep all More/Settings semantic IDs and navigation destinations.
3. Check light/dark and min 48dp icon footprint in widget tests.
4. Run all Development checks, Web build, Android size audit and AppLab Production Gate against the same final PR head.
5. Require review free of blocking findings and normal branch protection before merge.
6. Validate visual checkpoints (Today, More, Settings) in AppLab. Physical-device, Web user-browser inspection and Play distribution remain **NOT VERIFIED** until direct evidence is obtained.

## Bounded hygiene

No former routes removed: advanced preferences, Personalization, Cloud, Backup and canonical Capture remain reachable. The redundant AppBar add affordance is removed; the underlying composer is retained for its other callers. No dependency, asset, localization or storage migration is introduced.

## Evidence

Pending final exact-head runs and review. Do not mark Completed while pending.
