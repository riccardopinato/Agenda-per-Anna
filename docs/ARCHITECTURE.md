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


## v0.30.1 — Shared Diary Parity & Audit Hardening

- Noi ♡ exposes the same diary creation primitives as the private journal: Note, Photo and the full Sketchbook editor.
- Shared photos keep compressed local previews and use private Supabase Storage for originals, with offline retry and cancellation when an unsynced photo is deleted.
- Shared comments/reactions/read state remain account-scoped and offline-first.
- Deleted shared entries automatically clean their comments and reactions in the backend.
- Supabase Data API grants are least-privilege; anonymous table/RPC access is revoked.
- Shared agenda-record identity fields are immutable after insert; members can still edit payload/revision data.
- Android cloud/device backup is disabled for local diary data.
- CI is pinned to Flutter 3.47.5 and release signing can use protected GitHub Secrets, while preserving the existing sideload key as a compatibility fallback.
- The release workflow no longer uploads signing keys as artifacts.


## v0.31.0 — Shared Diary Parity 2.0

The private journal and Noi ♡ no longer maintain independent diary presentation code for the core Note / Photo / Sketch experience.

- `DiaryComposerSection` renders the common diary shell and the Note / Sketch / Photo actions.
- `DiaryContentCard` renders the same note, photo and sketch cards and action menus in both scopes.
- `showDiaryNoteEditor`, `showDiaryCaptionEditor` and `confirmDiaryContentDelete` are shared by private and shared flows.
- `DiarySketchbookScreen` remains the single full Sketchbook implementation for both scopes.
- `DiaryPhotoViewerShell` and `DiaryZoomableImage` provide the common immersive photo viewer.
- Noi ♡ adds collaboration-only UI (heart, comments, read receipts and sync state) as an optional footer/status layer on the common card.
- Shared entries persist `createdAt` in their JSON payload so same-day ordering follows creation order like the private diary and edits do not unexpectedly move old memories to the top.
- Legacy shared payloads fall back to their cloud revision when `createdAt` is absent.


## v0.32.0 — Data Safety & Local Storage

- Private agenda data, diary data, preferences, snapshots, account profiles, cloud-sync metadata and Noi ♡ offline caches/queues now use one structured local Sembast store instead of SharedPreferences as the primary persistence layer.
- Native builds persist the database in the application-support directory; the PWA uses the browser IndexedDB backend.
- First launch after upgrade performs a transparent, idempotent migration from the existing SharedPreferences keys. Legacy values are intentionally left untouched during this release as a rollback source, but all normal writes move to the structured store.
- Every stored state record carries a SHA-256 checksum and one previous committed value. If the newest payload is corrupt but its predecessor is valid, startup automatically recovers the predecessor instead of discarding the section.
- Storage-level corruption is exposed through the existing local-data warning path so damaged sections are not silently overwritten.
- Account switching keeps the existing per-account profile semantics while the working profile, private sync queue and shared-space queues are persisted through the same database.
- The external JSON backup format remains schema-compatible; backup/restore and local safety snapshots continue to work independently from the storage implementation.
- The v0.32 release gate runs analyzer, the full regression suite, the PWA build and the Android release packaging before distribution.


## v0.33.0 — Media Engine 2.0

- Standalone diary photos are no longer persisted as Base64 inside the primary journal JSON. Native builds use an application-support media directory; the PWA uses a dedicated IndexedDB media store.
- Media assets are content-addressed with SHA-256 IDs, deduplicated automatically and served through a bounded in-memory cache.
- Private journal records persist lightweight media references plus thumbnails. Legacy inline photos are migrated transparently on load.
- Images embedded in Sketchbook pages use the same asset store, including legacy migration, local previews and portable cloud/backup materialization.
- Private cloud sync and full JSON backup remain portable: media references are materialized back to Base64 only when a cloud/backup payload is built.
- Private and shared sync queues persist local media references rather than Base64 payloads; bytes are materialized only for the outgoing cloud request.
- Shared photo upload queues persist durable media asset references instead of large Base64 blobs, while accepting and migrating v0.32 queue entries.
- Shared photo thumbnails are localized into the media store for offline cards. Full remote photos are cached after first successful open for later offline viewing.
- Local snapshots remain lightweight and retain media references; garbage collection protects assets referenced by journals, snapshots, account profiles and pending queues.
- Media corruption is isolated from structured agenda state, and missing/corrupt assets fail as broken media without invalidating the journal database.


## v0.33.1 — Media cache hardening

- Native media replacement now always commits the new bytes atomically, including named shared-media cache entries whose new payload happens to have the same byte length as the previous file.
- This prevents stale shared photos from reappearing after an app restart when a remote asset is updated in place.
- Regression coverage verifies equal-size replacement semantics at the native file backend boundary.


## v0.33.2 — Reliability & Cleanup

- Runtime release metadata is centralized and shared by backup exports and push-device registration.
- Native state and media backends require the persistent application-support directory; they no longer fall back to system temporary storage.
- Startup fails closed with an explicit local-storage error screen instead of presenting an empty working set when persistent state cannot be opened.
- Account switching archives the current profile, installs the target working set and updates the active account in one Sembast transaction.
- Backup restore commits all core structured sections atomically, rolls back the in-memory working set on storage failure, and uses a durable full-sync marker so an interrupted post-restore cloud reconciliation is retried safely.
- The Noi ♡ hub no longer creates duplicate Realtime subscriptions with no-op callbacks; the unified store and active shared-space screen remain responsible for live updates.
- Permanent CI now validates locked dependencies, analyze, tests and a Web release build on pull requests and main.
- Manual Android release builds require stable secret-backed signing credentials and refuse cache-generated or ephemeral fallback keys.


## v0.34.0 — Performance Core

- Structured persistence keeps the v0.32 aggregate sections as a compact compatibility baseline while normal item, journal, month, week, habit and inbox edits are appended as account-scoped per-entity deltas.
- Reload overlays deltas on the aggregate baseline. Account switching compacts the current scope before archiving it; backup restore replaces the baseline and removes stale deltas atomically.
- Granular mutations update the cloud sync index and queue directly, avoiding a complete entity scan and avoiding portable-media materialization for unrelated journals.
- Full-section saves are batched into one Sembast transaction and compact deltas for the sections they replace.
- Unified agenda results cache the sorted combined list, pending task total and month totals. Private or shared mutations invalidate the cache explicitly.
- The application shell has its own revision notifier. Theme, onboarding, privacy and account-scope changes rebuild the shell; ordinary agenda content changes remain below MaterialApp.


## v0.35.0 — Sketch & Media Performance

- Sketch gestures keep a mutable transient point buffer. The persistent DiarySketchStroke remains immutable-by-convention and receives a frozen point list only at gesture end.
- Pointer sampling uses a small pixel-distance threshold, reducing redundant freehand/lasso points and eliminating the previous O(n²) list-copy pattern.
- Selection dragging reuses mutable working collections and replaces only selected objects while the gesture is active.
- Undo/redo snapshots reuse immutable stroke/text/image objects and copy only collection structure; history depth adapts to sketch point complexity.
- Media cache backends expose access recency and byte size. Native files use file modification time; Web records persist access metadata alongside the existing Base64 payload.
- Remote media cache eviction is LRU-style with count and byte budgets. In-memory cache entries are protected from immediate disk eviction.
- Full media GC is scheduled after the first frame path and debounced after diary writes, rather than awaited by AgendaStore.load().


## v0.36.0 — Backup & Cloud Media 3.0

- Portable full backup uses a ZIP bundle. `data.json` contains the normal local structured representation, while media assets are stored separately as `media/<assetId>.bin`.
- `manifest.json` declares bundle version, release version, export timestamp, data SHA-256, media count and per-media size/SHA-256.
- ZIP decoding is bounded by entry count and total uncompressed bytes and never extracts archive paths directly to disk.
- Legacy single-file JSON backup remains importable and `createBackupJson()` remains available for compatibility/tests.
- ZIP restore validates the complete bundle before mutating working state, writes media into MediaAssetStore, then uses the existing transactional restore path.
- Cloud sync indexing now hashes journal `toLocalJson()` rather than materializing media. The legacy-compatible remote Base64 representation is produced only for pending journal operations at the upload boundary.
