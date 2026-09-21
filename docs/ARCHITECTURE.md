# Agenda per Anna — Architecture

## v0.17.0

The application remains a single Dart library rooted at `lib/main.dart`, but the previous 10k-line monolith is split into focused `part` files to preserve private symbol visibility and runtime behavior while improving maintainability.

- `main.dart`: imports, library composition and bootstrap.
- `src/app_shell.dart`: app theme, onboarding and privacy gate.
- `src/domain_models.dart`: preferences, agenda, journal, shared-space and backup models.
- `src/agenda_store.dart`: local persistence, indexing, reminders, backup and cloud orchestration.
- `src/screens_core.dart`: shell, home, inbox, search, archive, settings, backup, shared space and account UI.
- `src/planner_views.dart`: calendar, daily timeline, week/month/year planning views.
- `src/widgets_editors.dart`: reusable tiles, editors, cards and presentation helpers.

This refactor intentionally changes no persistence keys, JSON schemas, sync record formats, navigation behavior, notification identifiers or user-visible features.

## v0.18.0 — Shared Space 2.0

- Shared-space changes are delivered through Supabase Realtime Postgres Changes.
- Shared edits use an account-scoped offline queue with per-entity coalescing.
- Stale concurrent writes are discarded deterministically in favor of the newest server revision.
- Cached shared entries retain server revision/audit metadata.
- Shared UI exposes realtime/offline/pending state, editor attribution and update badges.
- The private agenda remains separate from shared-space records.
