# Agenda per Anna — Architecture

## Current structure — v0.47.0

Anna's Diary keeps `lib/main.dart` as the compatibility library boundary, but large responsibilities are now split by runtime domain:

- `src/store_signals.dart`: granular UI invalidation channels.
- `src/day_hub_domain.dart`: birthday model, annual occurrence/reminder logic and derived Day Hub snapshots.
- `src/people_domain.dart`: lightweight important-person model, birthday linkage, diary-memory references and relationship lifecycle cleanup.
- `src/store/backup_domain.dart`: ZIP/data serialization, backup validation and readable export.
- `src/agenda_store.dart`: persistence/account/cloud orchestration facade and domain mutation API.
- `src/screens/home_inbox_search.dart`: shell, Home/Daily Briefing, Inbox, Search and Archive.
- `src/screens/birthdays_screen.dart`: persistent birthday management using the existing planning/sync/lifecycle infrastructure.
- `src/screens/people_screen.dart`: important-person management and reusable diary people picker.
- `src/screens/backup_settings.dart`: backup and application settings.
- `src/screens/shared_space.dart`: Noi ♡ hub, shared space and shared media UI.
- `src/screens/cloud_account.dart`: account/cloud diagnostics and controls.
- `src/planner_views.dart`: Calendar, Today, Week, Month and Year.
- `src/diary/diary_components.dart`: shared diary media/components/editors.
- `src/diary/diary_memories.dart`: private memories search/timeline UI.
- `src/diary/diary_sketchbook.dart`: photo viewer, sketchbook editor and painter.

The `AgendaStore` public surface remains compatible. UI screens observe domain-specific `ValueListenable` revisions rather than the entire store where possible. This keeps existing persistence/sync semantics unchanged while narrowing rebuild propagation.

The PR production gate is:
`locked dependencies → analyze/tests → Web release → ARM64 release → AppLab emulator → Maestro → multi-screen screenshots/UI hierarchy → visual QA/regression → Logcat/crash/ANR`.

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


## v0.37.0 — Scale, Startup & Incremental Cloud Sync

- Private and shared `agenda_records` pulls use durable local cursors based on `client_updated_at`. Queries use an inclusive lower bound so rows sharing the last cursor timestamp are safely replayed; merge/application remains idempotent.
- First reconciliation, explicit full-sync recovery and missing local cursors still perform a complete pull. Subsequent pulls are incremental.
- Private remote results are persisted as account-scoped entity deltas and update the sync index directly, avoiding the previous full `_save()` + full entity hash scan.
- Shared space cache refresh starts from in-memory/disk baseline and applies changed records/tombstones. A targeted space refresh is used by the active shared screen.
- Realtime exposes typed record/interaction change envelopes. Unified shared agenda applies record changes directly, while the active shared screen applies comments, reactions and member-read changes directly to its cached maps.
- Physical DELETE events with incomplete old-row data fall back to the existing full interaction reconciliation.
- Startup cloud initialization performs private reconciliation first; shared queue flushes and shared remote refresh run in a short deferred task. Resume and periodic reconciliation remain full.


## v0.38.0 — Release, APK Size & Platform Hardening

- Generated Android source remains out of Git, but native configuration is no longer encoded as large inline workflow fragments. `tool/prepare_android_platform.py` is the single deterministic transformation applied by CI, size audit and production release.
- Flutter is pinned to 3.47.5 for platform generation. Missing template anchors fail immediately, turning upstream template drift into a visible CI failure.
- Development checks now compile a generated Android debug package, so native manifest/plugin/desugaring regressions are covered continuously instead of only during manual release.
- Production signing uses environment-backed Gradle values and a stable secret-decoded keystore. No release path falls back to debug/ephemeral signing.
- Direct sideload distribution is ARM64-first; universal and legacy ABI packages remain available separately. Play distribution uses AAB.
- Release binaries are obfuscated with split debug symbols preserved for symbolication.
- `tool/android_size_report.py` reports total compressed APK bytes, grouped compressed/uncompressed payload and the largest archive entries without requiring Android SDK analysis tools.
- A dedicated pull-request size audit builds the ARM64 release path with production-equivalent compiler flags but uploads only the text report, never an audit-signed APK.


## v0.39.0 — Release Candidate & Final QA

- The release candidate adds a cross-feature regression gate rather than another persistence or sync architecture change.
- Account isolation is exercised as a complete private-data flow: agenda item, diary entry and inbox data survive an account round-trip without leaking into another account.
- Backup replacement is verified against the v0.34 entity-delta layer so restored aggregate state cannot be shadowed by stale granular mutations.
- Invalid backup input is verified to leave both in-memory and persisted state unchanged.
- Repository-level release assertions keep the v0.38 Android packaging contract explicit: deterministic release signing preparation, obfuscation, split symbols, split-per-ABI APKs, AAB output and Android debug CI coverage.
- Storage schemas, cloud record formats, Supabase migrations and media formats remain unchanged.


## v0.39.1 — Media, Data Safety & Release Hardening

This release keeps the v0.39 persistence/cloud model and hardens its boundaries rather than adding a new feature domain.

- **Media pipeline:** diary photos default to a 1600 px / quality 82 optimized master with a bounded 1280 px fallback; shared photos request a 1920 px / quality 84 master. Thumbnails remain separate low-cost assets.
- **Backup safety:** archive input, uncompressed expansion, individual entries and accumulated media have explicit memory-oriented ceilings. Media imported during restore is staged logically and deleted if model restore fails.
- **Account safety:** malformed account-profile archives are treated as blocking corruption during account switching, preventing accidental overwrite of profile metadata.
- **Queue diagnostics:** malformed shared pending queues remain on disk, are excluded from active processing and contribute to the existing storage-warning surface.
- **Sync health:** shared sync tracks attempts/errors separately from private Supabase state. Sync-only counters increment `syncRevision` instead of rebuilding every AgendaStore consumer.
- **Release parity:** Railway and GitHub CI use Flutter 3.47.5 and the lockfile. ARM64 sideload builds use an explicitly restored/generated cached JKS rather than relying on runner-local debug signing behavior.
- **Device gate:** an Android emulator integration smoke verifies native persistence/media plus the four primary navigation surfaces.

No Supabase schema migration is required for v0.39.1.


## v0.40.0 — Architecture, Fluidity & AppLab Production Gate

- Domain revisions isolate planner, diary, shared, settings and backup rebuilds.
- Shared-only mutations no longer invalidate private planner/journal/settings channels.
- Core and diary UI monoliths are physically split while remaining in the same Dart library, preserving private-symbol compatibility.
- Backup serialization/validation is separated from account/persistence restore orchestration.
- Persistence torture tests cover restart, offline-style pending edits, account switching, legacy migration and corrupt queue quarantine.
- AppLab verifies a release-mode ARM64 APK on Android and preserves per-screen visual baselines for Calendar, Week, Today and Memories.
- GitHub Pages is the canonical Web runtime and is produced from the same `main` revision as mobile releases.


## v0.45.0 — Lifecycle & Recovery Foundation

Lifecycle is implemented as a thin domain layer over the existing AgendaStore persistence/sync facade.

- `src/lifecycle_domain.dart` owns TrashEntry semantics, restore, permanent purge and cascade rules.
- `src/screens/trash_screen.dart` is the single user-facing Trash surface.
- Trash persists in the same structured LocalStateStore and account profile as the rest of the private working set.
- Trash records synchronize as ordinary private `agenda_records` entity type `trash`; no parallel backend is introduced.
- Portable cloud/backup serialization materializes diary media only at the transport boundary and re-localizes it through MediaAssetStore on receipt.
- Media garbage collection treats live Trash references as reachable and only reclaims them after permanent purge and after recovery snapshots no longer reference them.
- Noi ♡ keeps explicit collaborative delete/leave semantics and its existing tombstone/media cleanup pipeline.


## v0.46.0 — Day Hub 2.0

Day Hub 2.0 deliberately extends existing domains instead of creating a parallel daily-dashboard subsystem.

- `BirthdayEntry` is a small private entity stored under `birthdays_v1` and synchronized as `entity_type=birthday` through the existing per-entity cloud queue.
- Account profile capture/restore, entity deltas, full backup/restore and readable export all include birthdays.
- Birthday deletion is delegated to the shared v0.45 lifecycle domain and therefore inherits Trash, restore, permanent purge and safety snapshots.
- Annual birthday reminders schedule only the next relevant occurrence and are reconciled whenever the app starts/resumes; Android uses `NotificationService`, while Web/PWA uses the existing `web_push_reminders` backend.
- `DayHubSnapshot` is a derived projection over UnifiedAgenda + birthday occurrences + DayJournal. It owns no duplicate persistence.
- Home reuses the existing `_HomeFocusCard` as the Daily Briefing. Calendar and Planner consume the same projection/context rather than maintaining independent daily data.


## v0.47.0 — People & Relationships

People are intentionally modeled as a small personal-context entity rather than a contact book.

- `PersonEntry` is stored under `people_v1` and synchronized as `entity_type=person` through the same private incremental cloud pipeline used by agenda, journals and birthdays.
- A person may reference an existing `BirthdayEntry` by ID. The birthday remains the single source of truth for annual dates and reminders.
- `DiaryBlock.personIds` stores relationship links directly on existing Note / Photo / Sketch memories; no parallel memories table is introduced.
- Person-filtered memories are a derived projection over the existing journal store, preserving one canonical copy of each diary block and its media.
- Moving a person to Trash preserves diary links so restore is lossless. Permanent purge removes the orphan person IDs from affected journal blocks and persists those journal deltas. Permanent birthday purge clears only the related `birthdayId` links.
- People participate in account profiles, JSON/ZIP backup, readable export and private cloud reconciliation. No phone number, email address or external contacts permission is required.


## v0.48.0 — Universal Delete & Lifecycle Audit

The lifecycle layer remains a thin extension over AgendaStore and the existing account-scoped persistence/sync pipeline.

- Trash records are versioned by their own UUID; `originalKey` is descriptive identity and is no longer used to collapse historical deleted versions.
- `trashRestoreConflictReason` guards restore before mutation so recovery cannot overwrite a live entity with the same identity.
- Deterministic singleton pages (day/week/month) can retain multiple deleted versions safely: move the active version to Trash, then restore the desired historical version.
- Habit permanent purge scrubs `completedHabitIds` from live journals and trashed journal payloads, matching the existing person/birthday orphan-link cleanup model.
- Cascades execute only when the logical person/birthday/habit is no longer live or recoverable; purging an obsolete historical Trash record cannot damage links to a current live entity.
- Media reachability remains unchanged: recoverable diary media stay protected while referenced by Trash and normal MediaAssetStore maintenance runs after permanent purge.
- `docs/LIFECYCLE_AUDIT.md` is the explicit entity-by-entity lifecycle contract and records intentional exceptions for shared data, embedded page rows, Vault data and backup artifacts.


## v0.49.0 — Account Erasure & Data Rights

- Cloud account deletion is executed only by `supabase/functions/delete-account/index.ts`; the client never receives or embeds service-role/secret credentials.
- The function requires a valid user JWT plus an explicit `DELETE_MY_ACCOUNT` request body marker, verifies the user with Auth, removes shared-media paths affected by the user's ownership, then calls the Admin Auth delete-user API.
- Existing database foreign keys provide the authoritative cleanup boundary for account-owned private data and collaboration membership/content. Shared-space ownership cascades the owned space; historical updater references that may remain use `SET NULL`.
- `AgendaStore.eraseLocalCloudAccount` atomically removes the local account profile and all known account-scoped delta/cursor/cache/queue keys before reloading the guest profile.
- Local scheduled notifications are cleared before erasure and guest reminders are re-reconciled after the guest working set is restored.
- Vault data intentionally remains outside account erasure because it is device-local encrypted data, not cloud account data.
