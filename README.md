# Anna's Diary

Flutter app for personal planning, private diary and the shared **Noi ♡** space.

Current release line: **v0.44.0**.

## Core areas

- Private agenda and planner: Today / Week / Month / Year.
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

GitHub Actions runs locked dependency resolution, Android platform generation/verification, Flutter analyze, the full test suite, a Web release build and an ARM64 release build on every pull request and every push to `main`.

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
