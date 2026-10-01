# Anna's Diary

Flutter app for personal planning, private diary and the shared **Noi ♡** space.

Current release line: **v0.89.0**.

Canonical product scope and security boundaries: `docs/PRODUCT_BIBLE.md`.

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


## v0.53.0 — Recurring Life Engine

- Replaces the old editor-only recurrence duplication with persistent recurring-series metadata carried by ordinary agenda items.
- Supports daily, weekly, monthly and yearly series with civil-calendar-safe month ends and leap-day handling.
- Existing data remains backward compatible: agenda items without recurrence metadata continue as one-off entries.
- Recurring items keep using the existing agenda persistence, private cloud sync, reminders, backup/export and Trash lifecycle instead of creating a parallel storage model.
- Editing or deleting a recurring occurrence can target only that occurrence, that occurrence and all following ones, or the whole series.
- Editing a single occurrence deliberately detaches it from the series, preserving predictable future-series behavior.
- Series creation is bounded to 60 occurrences per edit operation to keep reminder scheduling and local/cloud writes controlled.
- Dedicated regression tests cover serialization, restart persistence, calendar edge cases, scoped edits and Trash-backed scoped deletion.


## v0.54.0 — Voice Diary

- Adds native Android voice recording and playback without introducing an AI or transcription dependency.
- Voice clips are stored through the existing content-addressed `MediaAssetStore`, not in a parallel media database.
- The diary supports voice blocks with caption, duration, people links, Trash lifecycle and Memories integration.
- Quick Capture can save a voice note directly into today's diary.
- Web keeps the same data model and can import an audio file; integrated native playback/recording remains Android-specific.
- Private cloud sync materializes voice bytes only at the portable sync boundary and restores them back into local media storage.
- ZIP backup/restore includes voice media through the existing generic media manifest and integrity hashes.
- Android platform generation now declares microphone permission and configures a native MediaRecorder/MediaPlayer bridge.
- Dedicated tests cover serialization, local persistence, backup/restore, Trash recovery and Android platform contract.

## v0.55.0 — Personal Organization

- Extends existing organization primitives instead of creating a new content silo.
- Inbox entries now support tags and manual archive in addition to the existing pin behavior.
- Diary blocks now support pin, tags and manual archive while keeping their existing people/media relationships.
- The day diary hides manually archived blocks and sorts pinned memories first.
- Archive now surfaces manually archived Inbox entries and diary memories alongside the existing month-by-month historical archive.
- Tag normalization de-duplicates case-insensitively, trims whitespace and caps per-item tag count to keep payloads bounded.
- Organization metadata remains backward compatible with older Inbox and diary payloads.
- Dedicated tests cover tag normalization, persistence, archive state and backward compatibility.


## v0.56.0 — Android Home Widget

- Adds a lightweight native Android home-screen widget without introducing a new Flutter/plugin dependency.
- Reuses existing Day Hub, unified agenda, birthdays, pending tasks and Inbox data.
- Shows the next commitment, nearest birthday, pending task count and active Inbox count.
- Includes direct “+ Aggiungi” and “Oggi” actions that return into the existing Quick Capture and Today flows.
- Widget state is a projection of existing app data; it does not own a second database and cannot diverge as an independent source of truth.
- The Android platform generator creates the provider, manifest registration and widget resources deterministically for CI/release builds.

## v0.57.0 — Memories & Relationships 2.0

- People can store an anniversary / important relationship date with backward-compatible serialization.
- Relationship overview combines linked diary memories, birthday information and next anniversary.
- Adds first-memory / latest-memory timeline anchors.
- Adds deterministic “In questo giorno” memories for a person, excluding archived diary content.
- Existing person-to-diary links remain the canonical relationship graph; no duplicate relationship database is introduced.


## v0.58.0 — Diary 2.0

- Adds six deterministic, non-AI diary templates: Morning, Evening, Gratitude, Travel, Special Day and Reflection.
- Templates reuse ordinary editable diary notes instead of introducing a parallel document model.
- Template prompts support lightweight checklist-style reflection and can be combined immediately with existing photo, voice, sketch, tags and people links.
- Applying a template appends content without overwriting the existing day journal.
- Template-created content automatically inherits the existing journal persistence, private sync, backup/export, archive and Trash lifecycle.


## v0.59.0 — Search & Connections

- Home search is upgraded to one deterministic local search surface spanning private agenda, diary content, people, birthdays, Inbox and monthly pages.
- Multi-word queries use narrowing semantics: every typed token must be present, so results refine continuously while typing.
- Diary search includes captions/text, tags, linked people, sketch text, audio-note captions, dates and content type; archived content stays hidden unless explicitly enabled.
- Diary memories can explicitly link up to 12 other memories. Backlinks are derived from the existing journals rather than stored twice.
- Connections persist inside the ordinary DiaryBlock payload and therefore reuse private sync, backup/export and account isolation.
- Moving a linked memory to Trash preserves relationships for recovery; permanent purge removes dangling links from live and recoverable diary content.
- The previous monthly-page search remains available inside the expanded global search.


## v0.60.0 — Noi ♡ 2.0

- Shared spaces now expose their real participant list instead of treating collaboration as an implicit two-person flow.
- Existing multi-use 24-hour invites remain the invitation engine; no parallel collaboration model is introduced.
- Space owners can remove a non-owner member through an authenticated owner-only RPC.
- Member-management RPCs require an authenticated caller, verify space membership/ownership server-side, use locked search paths and expose only the public invoker wrappers to authenticated clients.
- Destructive collaboration semantics are explicit in the UI: owners “Elimina per tutti”, while members “Lascia solo per me”.
- Existing shared feed, agenda, memories, comments, reactions, unread state, offline queues and media maintenance remain the source of truth.

## v0.61.0 — Data Safety

- Adds a read-only local integrity audit over the existing storage and backup architecture.
- Detects referenced media that are missing or corrupt, local source-media files that are no longer referenced, and unreadable structured-storage sections.
- Reports pending cloud/shared changes and the current local safety-snapshot count without treating an unsynced queue as local corruption.
- Complete ZIP backups are validated immediately after creation before they are offered for saving.
- ZIP verification continues to reuse the existing manifest, SHA-256, declared-size, schema and media-index validation instead of adding a second backup format.
- The Backup & Data screen now exposes the integrity audit and a compact health report.
- No AI features are introduced.


## v0.62.0 — Non-AI Production Consolidation

- Final consolidation checkpoint for the current non-AI roadmap; no generative-AI dependency or product feature is introduced.
- Existing agenda, diary, Noi ♡, lifecycle, backup, sync, notification and media engines remain the implementation source of truth.
- Material interaction defaults explicitly preserve padded touch targets and standard visual density across themes.
- The application shell now uses reading-order focus traversal for predictable keyboard and accessibility navigation.
- Dedicated regression coverage locks the non-AI dependency boundary, release metadata and the required Development, Web, Android size-audit and AppLab contracts.
- Production readiness requirements are documented in `docs/PRODUCTION_READINESS_V062.md`.
- Web/PWA startup now migrates Web Push to a dedicated non-caching service worker, while Flutter's legacy cache worker is left only for framework migration. A safe `update-recovery.html` path clears obsolete Flutter caches without deleting diary/local application data, allowing clients stranded on old builds such as v0.39 to reach the current v0.62.
- v0.62 can merge only after Development checks, Web, Android size audit and AppLab Trusted Verify are all green.


## v0.62.1 — Generic Profile Default

- New profiles no longer prefill the personal display name with “Anna”.
- Settings shows the neutral placeholder “Inserisci il tuo nome” and removes the heart icon from the name field.
- Existing saved names remain unchanged and continue to sync/restore normally.
- Home falls back to neutral copy until a name is provided, avoiding empty personalized titles or greetings.
- No AI features or new persistence subsystem are introduced.


## v0.63.0 — Creative & Reminder Upgrade

- Sketchbook Creative Palette 2.0 expands the existing drawing palette from 6 to 16 curated colors without changing the saved sketch format.
- The palette is horizontally scrollable and keeps accessible labels/selection state while preserving the existing pen, highlighter, text and stroke-width tools.
- Android agenda reminders now expose quick actions: **Fatto**, **10 min**, **1 ora** and **Apri**.
- Snooze actions run through the existing local-notification engine without opening the UI and reschedule the same stable reminder identity instead of creating a second reminder subsystem.
- **Fatto** uses the existing AgendaStore completion path when the app is surfaced, so persistence, recurring reminder cancellation, sync and UI invalidation remain consistent.
- Quick actions are scoped to ordinary agenda reminders; birthday reminders keep their existing behavior.
- Android platform generation now registers the flutter_local_notifications action receiver deterministically.
- No AI dependency, new database or parallel reminder storage is introduced.


## v0.64.0 — Capture & Writing

- Android exposes Anna's Diary as a native share target for **text/links** and **images**, using the existing Quick Capture, Inbox, diary and MediaAssetStore paths instead of a second import database.
- Shared text/link content can be routed to Inbox or to a normal note in today's diary.
- Shared images are copied into an app-private bounded temporary area, validated, consumed once, optimized through the existing diary image pipeline and stored as an ordinary photo memory.
- Incoming image payloads are capped at 30 MB and temporary tokens are canonical-path checked before reads/deletes.
- Diary notes keep the compact editor and add **Scrivi a schermo intero**, a distraction-reduced Focus Writing surface with live word/character count.
- Focus Writing returns ordinary note text to the existing DayJournal persistence flow; no proprietary document model or parallel note store is introduced.
- This release remains non-AI and offline-capable.


## v0.65.0 — Noi ♡ Permissions Lite

- Shared **Note / Photo / Sketch** memories now carry a deliberately small permission contract: **Tutti nello spazio** or **Solo io**.
- New creative memories keep the current collaborative default and record a stable edit owner; legacy shared memories remain collaborative and backward compatible.
- Read-only members can still open the memory, comment, react and see read receipts, but edit/replace/delete controls are removed.
- Permission changes reuse the existing SharedEntry payload, offline queue, Realtime refresh and deterministic merge path; there is no parallel ACL database.
- Supabase enforces locked-entry update/delete rules with a database trigger, so the restriction is not only a Flutter UI convention.
- Shared-photo insert/update/delete Storage policies also consult the entry permission contract; replacing a locked photo requires the edit owner.
- Media upload retry queues preserve permission metadata across offline/retry flows.
- Live Supabase migrations noi_permissions_lite_v065 and noi_permissions_media_v065 are applied to the production project.
- No generative AI or new collaboration role hierarchy is introduced.


## v0.66.0 — Smart Media Search

- Private diary photos gain **local on-device OCR** on Android using the bundled Google ML Kit Latin text recognizer; no server upload or generative model is required for recognition.
- Recognized text is stored only as derived metadata on the existing DiaryBlock photo. The original image remains the source of truth and the existing MediaAssetStore remains the only photo store.
- New photos are indexed automatically after ordinary journal persistence. Recent legacy photos are backfilled opportunistically after startup, and the Search screen can continue indexing additional photos.
- Empty OCR results are remembered as successfully scanned so photos without text are not processed repeatedly.
- Replacing a photo invalidates its old OCR metadata and automatically schedules fresh recognition.
- OCR metadata follows the existing journal payload through local persistence, private cloud sync, backup/restore, Trash recovery and account isolation.
- The existing deterministic multi-word search now includes OCR text, so a word visible only inside a photo can surface that diary memory.
- Web remains fully functional; OCR recognition itself is an Android enhancement, while OCR metadata already synced from Android remains searchable as ordinary journal metadata.
- OCR failures never block photo saving, viewing or diary usage.
- No semantic embeddings, remote OCR service, document scanner or generative AI is introduced.


## v0.67.0 — Lifecycle & Reference Integrity

- Restarts the active product line directly from the verified v0.66 baseline.
- Private cloud reconciliation treats deletion tombstones as authoritative over stale offline edits, while an explicit **Restore from Trash** remains a distinct recoverable user action.
- Shared **Noi ♡** deletion removes pending child interaction operations and cancels pending shared-media uploads for the deleted entry.
- Shared-media object deletions that fail transiently are retained in a durable retry queue instead of becoming silent orphans.
- Agenda reminder changes and deletions keep account-scoped PWA/Web Push reminders aligned even when the action originates from Android; failed remote reminder cleanup is retried after reconnect.
- Existing database-side cleanup of shared comments/reactions remains the source of truth and is not duplicated.
- No Life Core rewrite, monolithic Memory Engine or parallel lifecycle subsystem is introduced.
- Release metadata is aligned to v0.67.0+77.


## v0.68.0 — Memory Primitive Review

- Consolidates private diary memory projections on the existing `DiaryBlockReference` instead of creating a new Memory database or engine.
- Ricordi, People relationship memories and “In questo giorno” now derive from the same reference path and ordering rules.
- No new persistence key, cloud table, sync queue or lifecycle type is introduced.
- Existing DiaryBlock, DayJournal, People, Connections, Search, Trash and backup formats remain authoritative.
- This is deliberately a consolidation release: it removes duplicate in-memory representations without changing the user’s stored diary data.


## v0.69.0 — Places Lite

- Diary memories can carry lightweight inline place references without creating a Places database or management module.
- A place stores a human-readable name plus optional latitude/longitude directly inside the existing DiaryBlock payload.
- The diary card menu exposes **Luoghi** alongside people, tags and related memories; linked places appear as compact chips.
- Previously used place names are offered as lightweight suggestions.
- Deterministic global search indexes place names and exposes a derived **Luoghi** result type; opening a place result returns to the day that contains the latest matching memory.
- Ricordi search also matches linked place names.
- Legacy DiaryBlock payloads without places remain fully compatible.
- Places automatically inherit existing journal persistence, cloud sync, backup/restore, Trash and account isolation because no parallel store is introduced.


## v0.70.0 — Architecture Regression Gate

- Closes the v0.68–v0.70 consolidation cycle without adding another product domain.
- Memory surfaces remain derived from the existing DiaryBlock/DayJournal source of truth through one DiaryBlockReference projection.
- Places Lite remains inline DiaryBlock metadata; it introduces no standalone store, cloud table, sync queue or lifecycle entity.
- Regression coverage verifies legacy compatibility, persistence/restart, backup/restore, Trash/restore, account isolation and deterministic search for place-linked memories.
- Architecture assertions prevent reintroduction of duplicate memory-record classes and parallel Places/Memory persistence keys.
- Existing lifecycle, private sync, media, backup, search and account-profile infrastructure remains authoritative.


## v0.71.0 — Shopping List

- Adds a low-friction personal shopping list without turning Anna's Diary into a task manager.
- Private shopping items support name, optional quantity, deterministic local category suggestion, bought state, manual ordering and frequently purchased shortcuts.
- Private items reuse the existing entity-delta persistence, account profiles, cloud reconciliation, JSON/ZIP backup and Trash lifecycle.
- Deleting a private shopping item moves it to the existing Cestino and restores it losslessly.
- **Noi ♡** exposes a dedicated shared shopping list by reusing the existing generic `SharedEntry` payload, offline pending queue, Realtime refresh and tombstone conflict rules.
- Shared shopping stays outside the agenda/feed so grocery changes do not pollute the couple timeline.
- No shopping backend table, new collaboration engine, AI service or external API is introduced.


## v0.75.0 — Day / Life Consolidation

- `La mia giornata` becomes the central daily surface instead of treating agenda, diary and life records as separate products.
- `DayHubSnapshot` now projects agenda entries, birthdays, workouts and non-archived diary blocks into one chronological `DayLifeEntry` stream.
- Home and the detailed day view reuse the same day overview projection; Home remains reachable for memories, people, Noi ♡, data and utility modules while new profiles open directly on Oggi.
- The detailed day view replaces multiple parallel mini-sections with one `Momenti del giorno` stream plus an optional expandable hourly timeline.
- Quick Capture is available directly from the day surface.
- Workout sessions recorded for a date participate in the same daily context without being duplicated into the agenda store.
- New profiles default to the `Oggi / La mia giornata` start surface while preserving existing users' stored preference.


## v0.76.0 — Unified Capture

- `Cattura` is now one shared entry surface for text, voice, photo, Inbox, tasks and appointments instead of several partially duplicated write flows.
- Text, voice and photo captures are persisted as ordinary `DiaryBlock` records in the existing `DayJournal`; quick notes continue to use the existing `InboxEntry` model.
- Voice capture reuses the existing native/Web voice path and `MediaAssetStore`; photo capture reuses the existing optimized image, thumbnail and OCR-compatible media path.
- Share-target text and images now reuse the same capture persistence helpers instead of maintaining separate diary-save logic.
- Capturing from `La mia giornata` respects the day currently being viewed, including past/future days, while preserving the current time as the moment ordering time inside that day.
- No capture database, parallel media store, AI layer or new cloud schema is introduced.

## v0.89.0 — Cycle Premium Engine

- Adds a centralized Premium entitlement contract for cycle capabilities without coupling the UI to a billing SDK.
- Premium cycle features are enabled in preview mode until the app-wide purchase provider is configured.
- Adds deterministic trends: recorded-cycle range, estimated next-period window, recurring symptom patterns and advanced observation counts.
- Adds optional private tracking for basal temperature, cervical mucus, sexual activity and ovulation-test results.
- Adds up to 12 custom symptom labels while preserving historical labels already stored in encrypted day logs.
- Adds an explicit private text report copied only on user request; no automatic export or cloud upload is introduced.
- Existing v0.88 cycle payloads remain readable and the FREE calendar/log/history/prediction core remains intact.
- Release metadata is aligned to v0.89.0+99.

## v0.88.0 — Private Cycle Tracker

- Adds **Il mio ciclo / My cycle** as a dedicated mini-app inside the unlocked Private Vault.
- Menstrual day logs, symptoms, mood, pain, energy and notes are serialized only inside the existing AES-GCM encrypted Vault payload.
- The cycle domain is excluded from ordinary cloud sync, global search and standard backup by construction.
- Includes private dashboard, monthly calendar, history, deterministic cycle/fertility estimates and discreet period reminders.
- Predictions are explicitly estimates and are not presented as contraception, diagnosis or medical advice.
- The cycle UI immediately hides sensitive content if the Vault auto-locks or the app leaves the protected state.
- Localization covers English, Italian, Spanish, French and Portuguese.
- Release metadata is aligned to v0.88.0+98.

## v0.87.0 — Private Vault Web Unlock Hotfix

- Web Vault password derivation now uses browser-native asynchronous Web Crypto PBKDF2-HMAC-SHA256 instead of running the 600,000-iteration derivation synchronously on the Flutter Web UI event loop.
- The cryptographic contract is unchanged: existing salts, iteration counts, 256-bit derived keys and AES-GCM envelopes remain compatible; no Vault migration or password reset is introduced.
- Android/native keeps the existing PBKDF2 semantics together with Android Keystore wrapping and FLAG_SECURE protection.
- The locked Vault UI now paints an explicit unlock-progress state, rejects duplicate unlock submissions and always exits the busy state on success, wrong password or unexpected failure.
- A dedicated Chrome regression test verifies browser PBKDF2-SHA256 against a known compatibility vector.
- Release metadata is aligned to v0.87.0+97.

## v0.86.0 — Security & Governance Hardening

- Makes the Noi ♡ shared-password key a **first-writer-wins atomic owner claim** on the backend, preventing concurrent owner devices from silently creating different accepted E2EE keys.
- Shared credential update/delete operations use server-side **compare-and-swap revisions** with row locking. A stale device receives an explicit conflict instead of overwriting a newer password.
- Shared credential modification timestamps are committed by the backend rather than trusted from the device clock.
- Pairing envelopes are created through an owner-only dedicated RPC and consumed through an atomic one-shot RPC; the Data API and legacy generic merge RPC are blocked from mutating all protected shared-password records.
- Shared-password backend guards reject plaintext credential fields and enforce valid AES-256-GCM envelope/tombstone shapes.
- Password-specific reads now query only key metadata, pairing envelopes or shared credentials instead of downloading every shared-space record.
- Authoritative membership reconciliation purges removed-space password keys and encrypted mirrors immediately when the Vault is already unlocked; offline devices still purge on the next successful reconnect/reconcile.
- Adds an explicit **encrypted recovery package** for the Noi ♡ password-space key. Recovery uses a separate password, PBKDF2-HMAC-SHA256 at 600,000 iterations and AES-GCM; raw keys remain excluded from ordinary backup.
- New Private Vault setups use PBKDF2-HMAC-SHA256 at **600,000 iterations** and require at least 12 characters. Existing 180,000-iteration Vaults remain compatible and upgrade their password wrap after a successful password unlock.
- Temporary plaintext/key buffers are zeroed more consistently across Vault/shared-password crypto operations.
- The Vault auto-locks after five minutes without user interaction; leaving the Password Noi ♡ surface also locks the Vault immediately.
- Web Vault and shared-password screens disclose the reduced browser security boundary where Android Keystore and FLAG_SECURE are unavailable.
- Vault/shared-password security UI is consolidated onto the existing en/it/es/fr/pt localization path.
- Adds the canonical Product Bible and realigns roadmap, architecture, security and release-readiness documentation under the SHOS governance model.
- Release metadata is aligned to v0.86.0+96.

## v0.85.0 — Noi ♡ Shared Passwords

- Adds a dedicated **Password Noi ♡** surface while keeping the v0.84 Private Vault as the local security boundary.
- Noi ♡ is the authoritative source for shared credentials; the Private Vault keeps an encrypted local mirror tagged with the originating space and credential ID.
- Editing or deleting a Noi ♡ mirror from the Private Vault routes the operation back through the shared authoritative record, preventing divergent local copies.
- Shared credential records reuse the existing `agenda_records` shared channel with entity type `shared_credential`; no password-specific cloud table or migration is introduced.
- Credential content is encrypted client-side with **AES-256-GCM** and AAD bound to the Noi ♡ space and credential ID. The backend receives ciphertext, nonce, version metadata and timestamps, but not service name, username, email, password or notes in plaintext.
- Each Noi ♡ space uses a random 256-bit password key stored only inside the existing encrypted Private Vault payload. A public SHA-256 fingerprint detects key mismatches and prevents silent multi-device split-brain.
- Additional devices receive the E2EE space key through a one-time 128-bit pairing code. The code derives a wrapping key with PBKDF2-HMAC-SHA256 (180,000 iterations), expires after 15 minutes and its envelope is tombstoned after successful import.
- Shared-password changes and tombstones are applied through the existing global Noi ♡ Realtime subscription; unlocking the Private Vault also performs an authoritative membership/password reconciliation for changes received while the Vault was locked.
- Leaving or deleting a Noi ♡ space removes its local shared-password key and mirrors. If a member is removed while a device is offline, the local copy is purged on the next authoritative membership reconciliation after that device reconnects and unlocks the Vault.
- Shared credentials remain hidden by default, use secure-screen protection, and keep conditional clipboard cleanup. Pairing codes are also cleared from the clipboard on a best-effort timer.
- Personal Private Vault credentials remain private and are never promoted to Noi ♡ automatically.
- Private and Noi ♡ credential detail views show a locale-aware **last updated** footer sourced from each record's existing `updatedAt`; shared mirrors preserve the authoritative Noi ♡ modification timestamp rather than the local sync time.
- No new ordinary backup path, global-search index, credential sync queue, database table or persistence key is introduced.
- Release metadata is aligned to v0.85.0+95.

## v0.84.0 — Password Vault

- Extends the existing encrypted **Cassaforte privata** instead of creating a parallel password database or sync path.
- Adds a dedicated **Password** section alongside existing private notes.
- Each credential stores: service name, username, email, password and optional notes.
- Credential records reuse the existing AES-GCM Vault payload, password-derived key wrapping, optional biometric unlock and secure-screen protection.
- Existing Vault notes remain backward compatible: payloads without an entry type continue to decode as private notes.
- Passwords are hidden by default in both editor and detail views; reveal is explicit.
- Username, email, password and notes can be copied from the detail view. Clipboard cleanup runs after 30 seconds and clears only when the clipboard still contains the copied Vault value.
- Credential list rows never render the password.
- Credential deletion is explicit and permanent; credentials do not enter the ordinary Trash lifecycle.
- Password Vault stays device-local and remains excluded from ordinary cloud sync, Noi ♡, global search and standard backup.
- No new persistence key, database, cloud table or credential sync queue is introduced.
- Privacy Center now explicitly identifies personal credentials as content protected by the local encrypted Vault.
- Release metadata is aligned to v0.84.0+94.

## v0.83.0 — Life & Recovery Localization

- Extends the existing `AnnaStrings` localization path across the main secondary private-life surfaces: Important People, Birthdays, Workouts, Shopping List and Trash.
- People and relationship views localize editor chrome, relationship summaries, memory actions and all visible dates while preserving the existing Person/DiaryBlock relationship model.
- Birthday creation, reminders, list states and actions now follow the selected language and locale-aware date formatting.
- Workout history, plans and editors localize their UI vocabulary and render sport labels through locale-aware presentation helpers without changing persisted enum values.
- Shopping List localizes private/shared list chrome, editors, filters, empty states and shopping category labels while keeping the canonical shopping models language-neutral.
- Trash/recovery localizes destructive confirmations, restore feedback and deleted-at timestamps without changing the v0.45 lifecycle semantics.
- No localization database, remote translation service, new sync channel or localized persistence values are introduced.
- Release metadata is aligned to v0.83.0+93.

## v0.82.0 — Localization Coverage

- Extends the v0.81 localization foundation across the highest-frequency daily flows: Calendar/Today, Unified Capture, Inbox and Open Life Archive.
- These surfaces reuse the same `AnnaStrings`, resolved locale and existing AppLanguage preference introduced in v0.81.
- Calendar, planner and archive date formatting now follows the selected/resolved app locale rather than hardcoded Italian formatting.
- Unified Capture localizes its sheet, quick Inbox editor, photo-source chooser and success feedback.
- Inbox localizes empty state, capture action, menus and timestamps.
- Open Life Archive localizes title, search, filters, restore actions, month exploration and aggregate counts.
- AppLab/Maestro selectors accept the localized labels for these flows across en/it/es/fr/pt.
- Feature-specific lower-frequency strings not migrated in this step remain on the same incremental localization roadmap.
- No second localization framework, translation backend, database or language sync channel is introduced.
- Release metadata is aligned to v0.82.0+92.


## v0.81.0 — Localization Foundation

- Adds the localization foundation for English, Italian, Spanish, French and Portuguese.
- Language can follow the device or be selected manually from Settings.
- Unsupported device locales fall back to English.
- The selected language is stored in the existing AgendaPreferences payload and therefore reuses the established account/local-first preference lifecycle.
- Material/Cupertino system strings, primary bottom navigation, Home chrome and the main Settings chrome now react to the selected locale.
- Date formatting for the localized Home header follows the resolved app locale.
- Existing Maestro journeys accept localized navigation labels so runtime validation remains stable across device locales.
- This release is intentionally a foundation: legacy feature-specific strings not yet migrated remain unchanged until subsequent coverage steps.
- No localization database, remote translation service, new sync queue or parallel preference store is introduced.
- Release metadata is aligned to v0.81.0+91.


## v0.80.0 — Notes Bridge Lite

- Adds an explicit one-way **Copia per Notes** action to private diary content and Inbox entries.
- The bridge produces portable plain text with source, date, tags and existing people/place metadata when available.
- Diary notes copy their text directly; photo/audio entries copy their captions plus a clear notice that the original media remains in Anna's Diary.
- Sketches export only their textual elements; strokes and embedded images remain in the diary.
- Transfer uses the system clipboard and requires an explicit user action. There is no background sync, direct Notes account access or cross-app database.
- Anna's Diary and Notes-Ecosistema remain separate products and separate sources of truth.
- No new persistence key, cloud table, sync queue, HTTP dependency or binary-media transfer is introduced.
- Release metadata is aligned to v0.80.0+90.


## v0.79.0 — Privacy Architecture Finalization

- Consolidates the existing privacy controls into a single **Privacy Center** inside Settings.
- App lock, PIN, biometric unlock, auto-lock and Home-detail hiding keep using the existing AppPreferences and PrivacyGate paths.
- Privacy Center links directly to the existing encrypted Private Vault, verified backup/data-safety tools and cloud account/data-rights controls.
- The UI explicitly distinguishes ordinary local-first agenda data from the device-local encrypted Vault and from optional cloud account data.
- Account deletion remains the existing authenticated cloud-erasure flow; Vault deletion/lifecycle stays separate and local.
- No new privacy database, key store, sync engine, cloud table or parallel security state is introduced.
- Release metadata is aligned to v0.79.0+89.


## v0.78.0 — Open Life Archive

- Replaces the narrow archive list with **Archivio della vita**, a unified historical view over existing diary, agenda, workout and archived Inbox data.
- Search is local, deterministic and multi-word across titles, notes, tags, people, places, sports and dates.
- Type filters let the same history be explored as Diario, Agenda, Allenamenti or Inbox without a secondary index.
- Historical entries remain owned by their original domains; opening a result returns to the existing day, workout or Inbox flow.
- Manually archived diary/Inbox items keep their existing restore semantics.
- Month browsing remains available and now includes workout activity in the historical context.
- Future agenda entries are excluded from the historical archive.
- No archive database, cloud table, sync queue, lifecycle type or duplicated copy of user data is introduced.
- Release metadata is aligned to v0.78.0+88.


## v0.77.0 — Memory Recall 2.0

- Adds a deterministic **Riscopri** view inside I miei ricordi without creating a persistent Memory Engine.
- “In questo giorno” reuses the canonical `DiaryBlockReference` path and now surfaces directly inside `La mia giornata` when historical matches exist.
- Riscopri groups same-month memories from previous years and derives one year highlight, preferring a photo when available.
- Recurring people and places are derived from existing person/place links and remain navigable through the current Ricordi/search flows.
- Search/type filters can feed the same recall projection, so filtered memory exploration does not require another index.
- Archived memories stay out of recall resurfacing.
- No new storage key, database/table, cloud queue, lifecycle entity, AI model or embedding index is introduced.
- Release metadata is aligned to v0.77.0+87.


## v0.74.0 — Lifecycle Integrity & Release Metadata Cleanup

- Revalidates the existing universal Trash contract against the newer Shopping and Workout domains instead of introducing a second lifecycle engine.
- Complete backup/restore coverage now explicitly proves that trashed shopping items, workout sessions and workout plans remain recoverable.
- Workout-plan purge is regression-tested so historical sessions keep their copied plan snapshot even when the originating plan is deleted, recreated or permanently purged.
- Noi ♡ shopping deletion remains intentionally separate from private Trash and continues to use the existing shared tombstone/offline-queue path.
- Release coordinates are owned by one canonical metadata gate; historical feature tests no longer hardcode the current app version/build number.
- Runtime version and build number are centralized in `lib/app_version.dart` and must exactly match `pubspec.yaml`.

## v0.73.0 — External Calendar Overlay

- Android can show events from calendars already configured on the device through the system Calendar Provider.
- Access is explicitly opt-in and read-only; Anna's Diary requests `READ_CALENDAR` but never writes to the external calendar.
- Users can enable/disable the overlay and choose which visible device calendars are shown.
- External events appear in Home/Today, Calendar, Day Hub and Week surfaces without entering the canonical private/shared agenda store.
- External events never become Diary, Memory, Noi ♡, backup payloads or cloud-sync entities automatically.
- Calendar selection and overlay state remain local to the device. Web/PWA surfaces explain that direct device-calendar access is not available in this release.
- Android platform generation, manifest permission and MethodChannel bridging remain versioned in `tool/prepare_android_platform.py`, so CI-generated Android builds preserve the feature.

## v0.72.0 — Multisport Workout

- Adds one dedicated **Allenamento** section that stores both completed sessions and reusable plans without mixing workout history into the diary.
- Sessions are sport-agnostic: gym, running, cycling, swimming, walking, hiking, yoga/mobility, team sports and custom/other activities share the same lightweight model.
- Endurance sessions can record distance, duration and optional elevation; running/walking/hiking derive pace, while cycling/swimming and other distance sports can derive average speed.
- Intensity (RPE 1–10) and free notes are optional, so an entry can be as simple as “15 km corsa · 1:05:20” or “50 km bici · 1:45:00”.
- Reusable workout plans support structured rows such as `Panca 4x8 @ 60kg` as well as free-text blocks.
- TXT/CSV plan import reuses the existing file picker and parses locally; no AI, OCR service or new upload backend is introduced.
- Starting a session from a plan copies the plan/exercise snapshot into the historical session so later plan edits cannot rewrite past training history.
- Sessions and plans reuse existing account profiles, granular private sync, backup/restore and Trash lifecycle through `workout_session` and `workout_plan` entities.
- No workout-specific backend table or parallel cloud engine is introduced.
