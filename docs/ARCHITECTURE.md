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


## v0.19.0 — Unified Agenda & Fluid UX

- Private agenda records and Shared Space records stay physically separate and account-scoped, but are projected through a unified presentation layer.
- Home, Calendar, Day, Week and Month views can show Tutto / Privato / Noi ♡ without copying shared records into private storage.
- Shared calendar entries are indexed by civil day to keep TableCalendar and planner navigation fast.
- New agenda items choose visibility explicitly; Privato remains the default path and Shared Space is opt-in.
- Existing entries can move Privato → Noi ♡ or Noi ♡ → Privato through explicit actions.
- Shared changes update the unified offline cache immediately and reconcile through the existing deterministic queue/realtime pipeline.
- Empty or removed remote shared data never falls back to stale cache after a successful remote fetch.


## v0.20.0 — Release Readiness & Daily Reliability

- Account recovery is complete: password reset email, recovery callback handling and in-app new-password gate.
- Cloud errors shown to users are translated into clear messages while technical details remain internal.
- Private sync and Shared Space sync are reconciled through one reliability path on login, resume, manual sync and periodic refresh.
- Home exposes a compact sync-health card with synced/offline/pending states and a combined private + shared pending count.
- Shared pending work is counted per active account and kept isolated across account switches.
- A local safety snapshot is created before account sign-out; restore already creates its own pre-restore snapshot.
- Backup metadata now reports the current release line while keeping schema compatibility unchanged.
- Production PWA shell, manifest and service-worker caching are hardened so Railway deploys do not strand users on stale bundles.
- Onboarding now explains that Privato is the default and Noi ♡ is always explicit opt-in.
- Reliability regression coverage includes pending queue accounting, account scope isolation and backup release metadata.
