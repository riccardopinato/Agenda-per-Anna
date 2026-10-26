# v1.05-A3 — Today Consolidation

## Goal

Make **Today** the single daily hub after A2 promoted the canonical navigation
to **Today · Calendar · Memories · More**.

A3 is a consolidation and bounded cleanup step. It does not introduce a new
data domain, store, sync path or entitlement.

## Factory baseline

- App-Factory-Core: `a923e0e766d83e8dfb92356c05752bd566eaed9e`
- Master: v26.6
- Golden Index: v21
- Relevant process updates: Roadmap Fast + Continuous Maintenance v1,
  Event-Driven Reconciliation v1, Immutable Build/Test Artifact v1,
  Code Hygiene v1.1, App Shell/Responsive/Visual QA and AppLab QA.

## Today hierarchy

Today keeps the existing canonical day projection and adds only value that was
unique to the retired Home dashboard:

1. date opening + optional Daily Ritual;
2. content filter;
3. compact **Today focus** with the next upcoming item plus global open-task /
   Inbox attention;
4. up to three **Pinned** agenda items when relevant;
5. canonical Day/Life overview;
6. compact **wellbeing** summary for the actual current day;
7. On This Day recall;
8. canonical life stream;
9. progressive-disclosure hourly timeline;
10. diary editor.

The focus card deliberately does not duplicate today's appointment/task/journal
metrics already owned by the Day/Life overview.

## Redistribution retained from A2

- sync and storage warnings remain in **More**;
- Month/Week and month/year navigation remain under **Calendar**;
- Search, Inbox, Explore, Personalization, Archive, Backup, Account and Settings
  remain under **More**;
- Memories remains a first-class primary destination;
- Home Widget synchronization remains owned by Today.

## Bounded code hygiene

Removed as superseded by A2/A3:

- unreachable `HomeScreen`;
- `_HomeFocusCard`;
- old Home-only `_TodayWellbeingCard` implementation;
- `PrivateVaultHomeCard`, which had no consumer after Home retirement;
- legacy `home_more_menu` / `home-more-menu` contracts.

Retained intentionally:

- `_SyncAttentionCard`: still active in More;
- all canonical persistence, migration, Vault, backup, sync and module preference
  contracts;
- historical localization keys needed by older documentation/tests or other
  compatible presentation paths.

## Runtime / QA contract

- Today exposes `today-focus-card` through platform semantics;
- AppLab's Today journey must locate and assert that consolidated focus surface;
- exact-head Development, Web, Android size and AppLab gates are required;
- the APK handed to the user must come from an immutable artifact bound to the
  exact source SHA that passed the applicable runtime gate.

## Non-goals

A3 does not redesign Unified Capture, recategorize Settings, redesign Memories
3.0, add Map Memories, change billing, change cloud ownership or claim physical
device/store certification.
