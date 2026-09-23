# Anna's Diary

Flutter app for personal planning, private diary and the shared **Noi ♡** space.

Current release line: **v0.36.0**.

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
- Portable JSON backup and account-scoped safety snapshots.

## Quality gates

GitHub Actions runs locked dependency resolution, Flutter analyze, the full test suite and a Web release build on every pull request and every push to `main`.

Release Android builds remain manual and use Flutter 3.47.5 for reproducibility. Release APK signing requires the stable keystore credentials in GitHub Secrets; the workflow deliberately refuses ephemeral or cache-backed signing keys.

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
