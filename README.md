# Anna's Diary

Flutter app for personal planning, private diary and the shared **Noi ♡** space.

Current release line: **v0.52.0**.

## Core areas

- Private agenda and planner: Today / Week / Month / Year.
- Day Hub 2.0: daily briefing, persistent birthdays and calendar ↔ diary context.
- People & Relationships: lightweight important-person profiles linked to birthdays and private diary memories.
- Private diary: Note, Photo and full vector Sketchbook.
- Noi ♡: shared agenda plus the same Note / Photo / Sketch diary tools.
- I nostri ricordi: shared memories grouped by memories, days, months, years and timeline.
- Offline-first private/shared queues with deterministic cloud reconciliation.
- Structured local state on Sembast with checksums, rollback records and account isolation.
- Media Engine 2.0 with binary assets separated from structured state.
- Supabase Auth, Database, Realtime and private Storage.
- Firebase Cloud Messaging for Android Noi ♡ push notifications.
- Local reminders with notification diagnostics and repair tools.
- Integrity-checked ZIP backup with separate binary media, legacy JSON import and account-scoped safety snapshots.

## Quality gates

GitHub Actions runs locked dependency resolution, platform generation/verification, Flutter analyze, the full test suite and a Web release build on pull requests and `main`. Pull requests keep Android coverage through the production-equivalent size audit plus AppLab; the Development ARM64 build is reserved for `main`/manual runs to avoid compiling the same PR three times.

Pull requests also run the AppLab Production Gate: release-mode ARM64 build, Android emulator install/launch, Maestro restart smoke, multi-screen visual journey, screenshot/UI hierarchy checks, visual regression, Logcat and crash/ANR scanning. Production distribution remains pinned to Flutter 3.47.5 and the persistent sideload/release signing contracts.

See `docs/ARCHITECTURE.md` and `supabase/README.md` for implementation details.

## v0.33.2 — Reliability & Cleanup

- Fail-safe startup when persistent local storage cannot be opened.
- No temporary-directory fallback for database or media.
- Transactional account switching.
- Atomic core-state backup restore with crash-safe full-sync recovery.
- Redundant Noi ♡ hub Realtime subscriptions removed.
- Permanent CI quality gate.
- Stable secret-backed Android release signing required.
- Runtime version metadata aligned across backup and push registration.


## v0.34.0 — Performance Core

- Hot-path agenda mutations persist as account-scoped per-entity deltas instead of rewriting an entire section JSON.
- Full-section writes remain backward-compatible and compact matching deltas atomically.
- Account switching compacts the active delta journal before archiving the profile.
- Backup restore clears stale deltas in the same transaction as the restored working set.
- Private/shared unified agenda lists, pending-task counts and month counts use invalidated caches instead of rebuilding and re-sorting the full agenda on every read.
- The top-level MaterialApp now listens only to shell/configuration revisions, so ordinary agenda, diary and sync notifications do not rebuild the entire app tree.


## v0.35.0 — Sketch & Media Performance

- Freehand strokes and lasso gestures use mutable in-progress buffers and freeze the point list only once when the gesture finishes.
- Pen/highlighter/eraser/lasso input is distance-sampled to reduce redundant points and repaint work without changing the saved sketch format.
- Selection dragging updates only selected elements through reusable working lists instead of rebuilding every stroke/text/image collection on every pointer event.
- Undo/redo uses lightweight structural snapshots with an adaptive history limit instead of deep-copying every stroke point up to 50 times per page.
- Duplicated sketch pages preserve embedded media asset references.
- Remote shared-photo disk cache is bounded to 160 entries / 200 MB with LRU-style pruning.
- Media garbage collection is debounced and runs after startup/diary edits instead of blocking the startup critical path.


## v0.36.0 — Backup & Cloud Media 3.0

- Complete backups now export as ZIP packages with `manifest.json`, `data.json` and separate binary media under `media/`.
- Backup data keeps local media references instead of embedding image Base64 in the JSON payload.
- Every media entry is integrity-checked through declared size and SHA-256; the data document has its own SHA-256 in the manifest.
- Restore accepts the new ZIP format and all previous JSON backups.
- Missing or corrupt referenced media prevents creation/restore of an apparently valid but incomplete full backup.
- Private cloud sync hashes and scans compact local journal payloads; Base64 media materialization occurs only when a journal is actually sent to the remote backend.
- The remote Supabase journal format remains backward-compatible in this release, avoiding a forced live storage migration or broken older clients.


## v0.37.0 — Scale, Startup & Incremental Cloud Sync

- Private cloud pull stores an account-scoped cursor and fetches only records at or after the last applied `client_updated_at` after the first full reconciliation.
- Shared agenda uses a separate cursor per account/space and merges only changed/tombstoned records into the cached space instead of replacing every shared record list.
- Remote private changes persist through the v0.34 per-entity delta layer rather than forcing a full local-state serialization after each cloud pull.
- Realtime shared-entry events update the unified local cache directly; local pending edits newer than the remote revision remain protected.
- Realtime comments, reactions and read receipts are applied as interaction deltas. Full interaction queries remain as a conservative fallback when a DELETE payload is incomplete.
- Optimistic comment/heart mutations no longer immediately reload all interaction tables.
- Initial cloud bootstrap completes the private reconciliation first and defers shared uploads/pulls briefly, allowing push setup and the already-rendered UI to continue sooner.
- Full-sync recovery markers are cleared only after a successful reconciliation, and no SQL migration is required for the cursor model.


## v0.38.0 — Release, APK Size & Platform Hardening

- Android release generation is deterministic: the workflow creates only the pinned Flutter 3.47.5 Android template and applies app-specific native changes through a versioned Python script.
- Permanent CI now regenerates Android, applies the same native configuration and builds a debug APK in addition to analyze/tests/Web release, catching platform-template drift before a manual release.
- Production Android builds require the stable secret-backed keystore and no longer embed signing passwords into generated Gradle source.
- Release packaging uses obfuscation, split debug info and tree-shaken icons, with symbols retained as a dedicated artifact.
- Distribution artifacts are separated and version-named: preferred ARM64 APK, Play Store AAB, universal APK and legacy ABI APKs.
- SHA-256 checksums and compressed APK breakdown reports are generated for every production release.
- Pull requests affecting runtime/package inputs run an ARM64 production-equivalent size audit without publishing the audit APK.
- The dependency review found no safe direct dependency removal without removing active product functionality; size work therefore targets native ABI/package structure rather than speculative library deletion.


## v0.39.0 — Release Candidate & Final QA

- Adds an end-to-end release-candidate regression gate for private agenda, diary and inbox persistence across account switches.
- Verifies that full backup restore replaces granular state atomically and clears stale per-entity deltas.
- Verifies that invalid backup input cannot mutate the active or persisted working set.
- Locks the Android release contract in tests: production signing preparation, obfuscation, split debug symbols, ARM64 split APK, universal APK and Play Store AAB remain required.
- Keeps the development Android debug build and production-equivalent ARM64 size-audit paths under automated regression coverage.
- This release intentionally adds no major product features; it is a stabilization checkpoint before the next feature cycle.


## v0.39.1 — Media, Data Safety & Release Hardening

- Diary and shared photos now keep a high-quality optimized master; the old destructive 520 px / quality 48 fallback is removed.
- ZIP backup creation/import is bounded to avoid unbounded in-memory archive expansion; failed restores roll back media imported only for that attempt.
- Corrupt account-profile archives abort account switching instead of being silently replaced; unreadable shared queues are preserved and surfaced as storage warnings.
- Shared sync has explicit health state and a dedicated revision notifier, reducing full-agenda rebuilds for sync-only counter changes.
- Railway Web is pinned to Flutter 3.47.5 with the locked dependency graph, matching CI and Android builds.
- Lightweight ARM64 sideload releases use a persistent cached JKS signing key and explicit release signing.
- Added Android emulator smoke coverage for native storage/media and primary navigation.


## v0.40.0 — Architecture, Fluidity & AppLab Production Gate

- Added domain-specific revision channels for agenda, journal, planning, shared space, inbox, settings, backup and account state.
- Main planner screens listen only to the domains they render, reducing unrelated rebuilds while preserving the existing AgendaStore API.
- Split the previous `screens_core.dart` monolith into home/search, backup/settings, shared-space and cloud-account modules.
- Split the previous `diary_media.dart` monolith into diary components, memories and sketchbook/viewer modules.
- Extracted ZIP serialization, manifest validation and readable export logic into a dedicated backup domain while AgendaStore remains the compatibility/orchestration facade.
- Added persistence torture coverage for process-style restart, account isolation with pending edits, legacy upgrade and corrupt shared queues.
- Pull requests now build an ARM64 release APK instead of relying only on debug packaging.
- Added AppLab as a first-class PR gate with restart persistence smoke and Calendar / Week / Today / Memories visual checkpoints.
- GitHub Pages is the canonical Web deployment: https://riccardopinato.github.io/Agenda-per-Anna/


## v0.41.0 — Universal Identity & Persistent Noi ♡

- Google-first universal identity is shared by private agenda, sync and Noi ♡.
- Shared-space invite codes persist server-side for 24 hours and survive navigation/restart.
- Android OAuth deep-link handling and always-synced shared-space bootstrap are production-gated.

## v0.42.0 — Private Vault

- Local-only encrypted vault with password-derived protection and Android Keystore wrapping.
- Biometric unlock, automatic relock and FLAG_SECURE protect sensitive local entries.
- Vault contents are excluded from ordinary cloud sync, search and normal backup flows.

## v0.42.1 — Full Day Timeline

- La mia giornata covers the complete 00:00–24:00 civil day.
- Timeline, current-time indicator, taps and events use chronological top-to-bottom mapping.

## v0.43.0 — Notification Reliability

- Android notification health now checks app permission, individual channels, exact alarms and scheduled delivery.
- FCM self-test verifies token registration and backend delivery results.
- Push delivery telemetry records delivered, failed, missing-device and invalid-token outcomes.
- Realtime remains a delayed fallback instead of assuming a registered token means successful delivery.

## v0.44.0 — Cross-Platform Notifications & Release Hardening

- Noi ♡ supports standards-based Web Push for the installed iPhone/iPad PWA and compatible desktop browsers.
- Web Push subscriptions are account-scoped in Supabase and use server-generated VAPID credentials that never enter the repository.
- Notification taps reopen the correct shared space through the PWA service worker.
- GitHub Pages deploys public Privacy Policy and Terms of Service for Google OAuth branding.
- Direct ARM64 sideload builds use the protected stable release signing secrets rather than a generated cached key.


## v0.45.0 — Lifecycle & Recovery Foundation

- Private agenda items, diary blocks/pages, month/week planning pages, habits and Inbox entries use one account-scoped Trash lifecycle.
- Trash records ride the existing private sync engine instead of creating a parallel database or cloud channel.
- Restoring an agenda item reinstates its reminders through the existing notification scheduler.
- Deleting a habit preserves and restores its historical completion links.
- Diary media referenced by Trash stay protected from garbage collection; permanent deletion schedules normal MediaAssetStore cleanup.
- Permanent purge creates a local safety snapshot before removing recoverable content.
- Shared Noi ♡ deletion keeps its existing collaboration semantics and server tombstones rather than copying shared data into the private Trash.


## v0.46.0 — Day Hub 2.0

- Home's existing focus card becomes the Daily Briefing instead of adding a parallel dashboard: today's appointments/tasks, next commitment, Inbox, diary state and next birthday share one compact surface.
- Birthdays are first-class private entities with optional birth year, notes and annual reminder lead time; they persist locally, sync through the existing private-record pipeline, survive account switching and are included in JSON/ZIP/readable exports.
- Birthday reminders reuse the existing Android local-notification and PWA Web Push reminder infrastructure and are reconciled on bootstrap/resume.
- Birthdays use the v0.45 Trash/restore/purge lifecycle from day one instead of introducing a separate delete path.
- Calendar selected-day context exposes diary state and birthdays with a direct “Apri giornata” action.
- La mia giornata shows birthdays alongside the same unified agenda and diary data rather than copying them into AgendaItem records.
- Quick Capture exposes the birthday flow without adding a second capture system.


## v0.47.0 — People & Relationships

- Adds a deliberately lightweight “Persone importanti” area: name, relationship, private note, favorite status and optional link to an existing birthday, without turning Anna's Diary into a contacts/CRM app.
- Private diary Note / Photo / Sketch blocks can link one or more saved people; the existing memories gallery can then open a person-filtered timeline without duplicating diary content.
- People are first-class private entities using the existing per-entity persistence, cloud sync, account isolation and backup/export pipeline.
- Person deletion uses the v0.45 Trash contract. Memory links are preserved while the person is recoverable and are removed only on permanent purge; permanent birthday purge safely clears person links.
- Home and Quick Capture expose the feature, while AppLab adds a dedicated People visual checkpoint.


## v0.48.0 — Universal Delete & Lifecycle Audit

- Trash preserves historical versions of the same logical content instead of collapsing them by date/key.
- Restore is conflict-safe: an older Trash version can never overwrite a live item, diary block, day, week, month, habit, birthday, person or Inbox entry with the same identity.
- Permanent habit purge removes stale completion IDs from both active journals and journals already in Trash.
- Purging an old historical person/birthday/habit version no longer breaks links when the same logical entity is live again.
- The lifecycle matrix is documented in `docs/LIFECYCLE_AUDIT.md`, including private Trash, shared collaboration semantics, Vault permanent deletion and embedded-page ownership.
- Regression coverage locks version-safe Trash, restore conflicts and cascade cleanup.


## v0.49.0 — Account Erasure & Data Rights

- Account settings now expose a permanent **Elimina account e dati** flow with typed `ELIMINA` confirmation.
- A dedicated authenticated Supabase Edge Function performs server-side Auth deletion using privileged credentials that never enter the Flutter client.
- Before Auth deletion, shared media owned by the deleting user is removed; media folders of shared spaces owned by that user are removed with the spaces.
- Database foreign-key cascades remove private records, memberships, comments, reactions, push registrations, web reminders and owned shared spaces; `updated_by` references use `SET NULL` where history may remain.
- After remote deletion, the device removes the erased account profile, granular deltas, sync cursors, shared caches/queues and account-scoped backup state, then restores the guest working set.
- Local notifications are cleared before the account working set is removed; guest reminders are reconciled afterwards.
- The encrypted local Private Vault remains device-local and separate from cloud account erasure, as explicitly disclosed in the confirmation UI.


## v0.50.0 — Security & Production Hardening

- Privileged account-erasure media cleanup now accepts shared media paths only under the source record's own `space_id/` prefix; mutable JSON can no longer nominate an arbitrary Storage path for service-role deletion.
- The live `delete-account` Edge Function is deployed as version 2 with JWT verification still mandatory.
- Anonymous table privileges are removed from `web_push_reminders` and `web_push_subscriptions`; authenticated RLS policies and backend service-role delivery remain unchanged.
- Production RLS, shared-space SECURITY DEFINER functions and Supabase security advisors were audited against the live project.
- `pg_net` is deliberately left on its supported non-relocatable configuration because its operational API already lives in `net` and forced recreation would endanger scheduled Web Push delivery.
- `docs/SECURITY_BASELINE.md` records the security model, accepted platform warnings and release-gate requirements.
- Regression tests lock the Storage path scope, JWT account-erasure contract and anonymous Web Push privilege removal.


## v0.51.0 — CI Throughput & Gate Consolidation

- Pull requests no longer run the duplicate Android ARM64 build inside Development checks.
- PR Android coverage remains intact through the independent production-equivalent size audit and AppLab release APK/runtime gate.
- Development checks still build Android ARM64 on `main` pushes and manual workflow runs.
- The size-audit workflow now also reacts to changes in Development/AppLab workflow definitions, so CI-gate edits cannot bypass production-equivalent Android coverage.
- Regression tests lock this split-gate contract so future cleanup cannot accidentally remove Android PR validation.


## v0.52.0 — AppLab Critical Journey Expansion

- AppLab visual coverage expands from Calendar / Week / Today / Memories / People to include Home, Noi ♡, Account and Cestino.
- New Maestro flows are state-aware and chained deliberately to avoid false failures caused by starting from the wrong navigation depth.
- Home verifies the Daily Briefing surface; Noi ♡ verifies the shared-space hub; Account verifies cloud/account controls; Cestino verifies the lifecycle recovery surface.
- Release tests lock the complete nine-checkpoint AppLab journey.
