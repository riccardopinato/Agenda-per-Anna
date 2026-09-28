# Anna's Diary — Roadmap

Source of truth for the active product sequence after v0.52. The roadmap follows the project Master Prompt: REUSE-FIRST, one stable version at a time, no next-version branch before the current version passes all required quality gates and is merged to `main`.

## Active sequence

| Version | Scope | Status | Core acceptance target |
| --- | --- | --- | --- |
| v0.53 | Recurring Life Engine | Completed | Persistent recurring agenda series; scoped edit/delete; reminders, sync, backup and Trash reuse |
| v0.54 | Voice Diary | Completed | Record, persist, play and lifecycle-manage diary audio without replacing the original recording |
| v0.55 | Organization | Completed | Personal organization layer that improves findability without turning the app into a work/Notion clone |
| v0.56 | Widget | Completed | Android home-screen glance + safe ultra-quick capture using existing app data |
| v0.57 | Memories / Relationships 2.0 | Completed | Richer person-linked memories, anniversaries and “on this day” navigation |
| v0.58 | Diary 2.0 | Completed | Reusable personal diary templates and richer daily-writing flows |
| v0.59 | Search / Connections | Completed | Unified local search, filters and explicit connections between personal content |
| v0.60 | Noi ♡ 2.0 | Completed | Stronger shared memories/agenda collaboration on the existing shared-space infrastructure |
| v0.61 | Data Safety | Completed | Restore drills, backup verification, orphan checks and long-term data portability hardening |
| v0.62 | Non-AI Production Consolidation | Completed | Accessibility, performance, regression and release-quality consolidation; no AI features |
| v0.62.1 | Generic Profile Default | Completed | Neutral first-run name field with preserved existing personalization |
| v0.63 | Creative & Reminder Upgrade | Completed | 16-color Sketchbook palette plus safe agenda notification actions using existing engines |
| v0.64 | Capture & Writing | Completed | Native Android share-to-diary/Inbox plus distraction-reduced diary writing |
| v0.65 | Noi ♡ Permissions Lite | Completed | Simple server-enforced edit/read-only control for shared creative memories |
| v0.66 | Smart Media Search | Completed | Local on-device OCR for diary photos integrated into deterministic search |
| v0.67 | Lifecycle & Reference Integrity | Completed | Tombstone-safe offline reconciliation, cross-device reminder cleanup and orphan-safe Noi ♡ lifecycle hardening |
| v0.68 | Memory Primitive Review | Completed | One derived diary-memory reference path reused by Ricordi, People and On This Day without a new memory store |
| v0.69 | Places Lite | Completed | Lightweight inline place references on diary memories, searchable without a separate Places database |
| v0.70 | Architecture Regression Gate | Completed | Cross-domain regression lock for memory/place compatibility, lifecycle, backup, account isolation and anti-duplication constraints |
| v0.71 | Shopping List | Completed | Lightweight private + Noi ♡ grocery list reusing existing local/cloud/shared lifecycle infrastructure |
| v0.72 | Multisport Workout | Completed | Dedicated Allenamento history + reusable plans for gym, running, cycling, swimming and other sports on existing private infrastructure |
| v0.73 | External Calendar Overlay | Completed | Read-only Android system-calendar projection with explicit opt-in and no canonical-store duplication |
| v0.74 | Lifecycle Integrity & Release Metadata Cleanup | In validation | Extend lifecycle regression coverage to post-v0.48 domains and remove release-version duplication from historical tests |

## Permanent constraints for this sequence

- No generative-AI or AI-dependent product features through v0.66.
- Anna's Diary remains primarily a personal diary / agenda; work and knowledge-management scope belongs to Notes-Ecosistema.
- Existing verified modules are reused before new infrastructure is introduced.
- User data remains offline-capable and account-isolated where applicable.
- Every new persisted entity or media type must integrate with lifecycle, backup/restore, sync rules and account erasure as applicable.
- README and this roadmap are updated in the same version that changes product behavior.
- Feature versions require code, analyze/tests, required builds, Android size/regression audit and documentation gates. AppLab runs cumulatively every two feature versions, plus the final v0.62 release checkpoint.

## Completed baseline

- v0.45 Lifecycle & Recovery Foundation
- v0.46 Day Hub 2.0
- v0.47 People & Relationships
- v0.48 Universal Delete & Lifecycle Audit
- v0.49 Account Erasure & Data Rights
- v0.50 Security & Production Hardening
- v0.51 CI Throughput & Gate Consolidation
- v0.52 AppLab Critical Journey Expansion

## v0.53 acceptance criteria

- A recurring series is represented persistently and survives app restart.
- Daily, weekly, monthly and yearly recurrences use civil-calendar behavior.
- Editing supports single occurrence, current-and-future and whole-series scopes.
- Deleting supports the same scopes and retains the established Trash/recovery semantics.
- Legacy one-off agenda items remain readable and unchanged.
- Existing local/cloud reminder paths remain the scheduling implementation.
- Existing private sync, backup/export and account isolation automatically include recurrence metadata through the ordinary AgendaItem payload.
- No parallel recurrence database/table is introduced.


## v0.54-v0.55 paired gate

Per the active development cadence, AppLab runs once every two feature versions. v0.54 and v0.55 therefore share one cumulative runtime gate on the final v0.55 APK. Development checks, unit tests, web release build and Android size audit still apply to the combined branch before merge.

### v0.54 acceptance criteria

- Android can record and play a diary voice clip through the native bridge.
- Voice blocks persist through the ordinary DayJournal model and MediaAssetStore.
- Quick Capture can create a voice diary entry.
- Voice media participates in private sync portability, ZIP backup/restore and Trash recovery.
- No AI, speech-to-text or generated content is introduced.

### v0.55 acceptance criteria

- Inbox entries support pin, tags and manual archive.
- Diary blocks support pin, tags and manual archive.
- Archived personal content remains recoverable without using Trash.
- Archive surfaces manually archived content together with historical month navigation.
- Older payloads without organization metadata remain readable.


## v0.56 acceptance criteria

- Android home widget is generated by the existing pinned-platform build pipeline.
- Widget data is derived from the existing agenda/day-hub/birthday/inbox models.
- Widget actions reuse Quick Capture and Today instead of creating alternate write paths.
- No new persistent store or third-party widget dependency is introduced.

## v0.57 acceptance criteria

- Person anniversary data is backward compatible and account-scoped through the existing people payload.
- Relationship overview derives from existing people, birthday and diary links.
- “In questo giorno” is deterministic, historical-only and excludes archived diary blocks.
- Existing memory/person lifecycle behavior remains unchanged.


## Active AppLab cadence

- v0.54 + v0.55 → completed on v0.55
- v0.56 + v0.57 → AppLab on v0.57
- v0.58 + v0.59 → AppLab on v0.59
- v0.60 + v0.61 → AppLab on v0.61
- v0.62 → final AppLab release validation


## v0.58 acceptance criteria

- Diary templates remain deterministic and introduce no AI dependency.
- Applying a template never replaces existing day content.
- Template output remains ordinary editable DiaryBlock content.
- Morning, evening, gratitude, travel, special-day and reflection flows are available.
- Existing photo, voice, sketch, tag and person-link tools remain composable with template output.
- No parallel persistence, backup or sync path is introduced.


## v0.59 acceptance criteria

- Search remains local and deterministic.
- Multi-word queries narrow results continuously across agenda, diary, people, birthdays, Inbox and monthly pages.
- Diary search includes tags, person links, sketch text and voice captions; archived content is opt-in.
- Diary memories support explicit related-memory links with derived backlinks.
- Connection metadata is backward compatible and persists through the ordinary journal payload.
- Trash preserves recoverable links; permanent purge removes dangling references.
- The v0.58 + v0.59 pair closes only after Development, Web, Android size audit and AppLab Trusted Verify pass.


## v0.60 acceptance criteria

- Existing shared-space infrastructure remains the collaboration source of truth.
- A signed-in space member can view the people participating in the space.
- Only the owner can remove another non-owner member; the owner cannot remove themselves.
- Existing persistent 24-hour multi-use invites remain unchanged and support groups larger than two.
- Leaving a space affects only the current member; deleting an owned space remains a destructive action for everyone.
- Shared feed, agenda, memories, interactions, unread state and offline queues keep their existing ownership/sync semantics.
- Member-management RPCs are authenticated, server-authorized and locked to explicit function privileges.
- No AI features are introduced.

## v0.61 acceptance criteria

- Local data safety can be audited without mutating user content.
- Referenced media missing from storage are detected.
- Corrupt content-addressed local media are detected.
- Unreferenced local source media are reported separately from the bounded remote-media cache.
- Existing unreadable-storage warnings and pending cloud/shared mutations are visible in the report.
- A newly generated complete ZIP backup is fully validated before file delivery.
- Existing restore rollback, safety snapshots, backup compatibility and media integrity checks remain the implementation path.
- v0.60 + v0.61 close only after Development, Web, Android size audit and AppLab Trusted Verify all pass.


## v0.62 acceptance criteria

- No generative-AI or AI-dependent dependency or product feature is introduced.
- Existing persistence, sync, backup/restore, lifecycle, notifications and media infrastructure is reused without a parallel subsystem.
- Material controls retain accessible padded touch targets and standard visual density.
- Keyboard/accessibility focus follows reading order at the application-shell boundary.
- Installed Web/PWA clients migrate Web Push to a dedicated non-caching worker. A recovery route clears only obsolete Flutter caches, preserves application storage, and lets clients stranded on historical builds reach v0.62.
- Release metadata is aligned to v0.62.0.
- Full regression coverage remains green.
- Web release validation remains green.
- Android production-equivalent ARM64 size audit remains green.
- Final AppLab Production Gate and Trusted Verify remain green.
- README, roadmap and production-readiness documentation match the shipped state.
- Merge to `main` occurs only after every required gate above is green.


## v0.62.1 acceptance criteria

- A new profile starts with an empty display name instead of “Anna”.
- The Settings name field has no heart prefix icon and shows “Inserisci il tuo nome” as its placeholder.
- Saving an empty field never restores “Anna” automatically.
- Existing explicitly saved names remain unchanged through persistence, sync, backup and restore.
- Home renders neutral title/greeting copy while the display name is empty.
- Release metadata is aligned to v0.62.1+72.
- Development checks, Web release validation, Android size audit and AppLab remain green before merge.


## v0.63 acceptance criteria

- Creative Palette 2.0 is approved from the central ideas backlog and extends the existing Sketchbook rather than creating a parallel drawing editor.
- The Sketchbook exposes 16 curated colors with horizontally scrollable, accessible controls.
- Existing sketches remain fully compatible because stored stroke/text color values and sketch serialization are unchanged.
- Reminder Actions 2.0 is approved from the central ideas backlog and reuses NotificationService plus AgendaStore.
- Android agenda reminders expose **Fatto**, **10 min**, **1 ora** and **Apri**.
- **10 min** and **1 ora** can run without opening the app, reuse the same stable reminder identity and keep the existing notification channel.
- **Fatto** resolves the agenda item through its existing stable ID and uses the ordinary completion/persistence path; it must never toggle an already completed item back to pending.
- Birthday reminders do not receive agenda-only completion actions.
- Android platform generation includes the plugin ActionBroadcastReceiver required by notification actions.
- No new database, duplicate reminder store or AI dependency is introduced.
- Release metadata is aligned to v0.63.0+73.
- Development checks, Web release validation, Android size audit and AppLab Trusted Verify must all be green before merge.


## v0.64 acceptance criteria

- The central-backlog ideas **Share to Anna's Diary** and **Focus Writing Mode** are approved for this release.
- Android accepts ACTION_SEND text/plain and image/* without introducing a third-party share-intent dependency.
- Shared text/links reuse Inbox or ordinary diary Note persistence.
- Shared photos reuse MediaAssetStore, the current image optimization/thumbnail pipeline and ordinary diary Photo blocks.
- Temporary shared-image files are app-private, size-bounded, path-validated and consumed/deleted rather than becoming a second media store.
- Focus Writing is a presentation/editor mode only; saved output remains an ordinary DiaryBlock note.
- Existing compact note editing remains available.
- Release metadata is aligned to v0.64.0+74.
- Development, Web, Android size audit and AppLab Trusted Verify must all pass before merge.

## v0.65 planned scope — approved

- Implement **Noi ♡ Permissions Lite** on the existing shared-space infrastructure.
- Keep permissions deliberately simple: collaborative editing or read-only for other members.
- Enforce authorization server-side as well as in the Flutter UI.
- Reuse current shared entries, membership, offline queue, interactions and sync semantics.
- Do not introduce enterprise-style ACL roles.

## v0.66 planned scope — approved

- Implement **Smart Media Search** with local/on-device OCR for private diary photos.
- OCR text is derived metadata; the original photo remains the source of truth.
- Reuse the existing photo model, MediaAssetStore and deterministic global search.
- OCR failure must never block saving/viewing the photo.
- No generative AI, semantic embeddings or document-scanner workspace are part of this release.


## v0.65 acceptance criteria

- The approved **Noi ♡ Permissions Lite** idea extends the existing shared-space engine instead of creating team/workspace ACL infrastructure.
- New shared Note / Photo / Sketch entries keep collaborative editing by default and store a stable edit owner.
- The edit owner can choose **Tutti nello spazio** or **Solo io**.
- A member without edit permission can still view the memory, comment, react and participate in read receipts.
- Read-only users do not receive edit, caption-replace or delete controls for the protected creative memory.
- Legacy payloads without permission fields remain collaborative.
- Permission metadata survives shared cache, offline queue, media upload retry and remote round-trip.
- PostgreSQL blocks unauthorized update/delete of restricted shared entries even if a client bypasses Flutter.
- Shared-media Storage update/delete policies enforce the same restriction for photo objects.
- No enterprise role matrix, new ACL table or parallel sync engine is introduced.
- Production Supabase contains both v0.65 permission migrations.
- Release metadata is aligned to v0.65.0+75.
- Development, Web, Android size audit and AppLab Trusted Verify must all pass before merge.


## v0.66 acceptance criteria

- The approved **Smart Media Search** idea extends private diary photos and the existing deterministic search; it does not create a document workspace.
- Android OCR runs locally/on-device through a bundled text-recognition model and sends no photo to a remote OCR service.
- The original photo remains authoritative; OCR is derived metadata on the existing DiaryBlock.
- Legacy photos without OCR metadata remain readable and are progressively backfilled without blocking startup.
- New photos schedule OCR after the normal journal save path.
- A successful scan with no recognized text is recorded so the same photo is not repeatedly processed.
- Replacing a photo clears stale OCR metadata and schedules recognition for the replacement.
- OCR failure never prevents saving, opening, backing up or syncing a photo.
- OCR text participates in the existing token-based multi-word diary search and remains compatible with tags, people, captions and sketch text.
- Existing journal persistence automatically carries OCR metadata through backup/restore, Trash, cloud sync and account isolation.
- Web continues to function without the native OCR bridge and can search OCR metadata previously produced on Android.
- No generative AI, semantic embeddings, remote OCR, PDF scanner or new media database is introduced.
- Release metadata is aligned to v0.66.0+76.
- Development, Web, Android size audit and AppLab Trusted Verify must all pass before merge.


## v0.67 acceptance criteria

- v0.66 is the frozen functional baseline for this development line; later abandoned v0.67/v0.68 work on the old `main` is not part of this release.
- Private remote tombstones defeat ordinary stale offline edits and cannot be silently resurrected on reconnect.
- An explicit Trash restore remains a supported user intent and can revive the entity without being mistaken for a stale edit.
- A local private delete remains authoritative over an ordinary remote edit and advances its tombstone revision when required by last-write-wins reconciliation.
- Shared synchronization pulls authoritative remote tombstones before flushing pending entity writes.
- Deleting a Noi ♡ shared entry removes queued child interactions and cancels pending media uploads tied to that entry.
- Existing server-side cascade cleanup for shared comments/reactions remains authoritative.
- Failed exact shared-media deletions and failed account-scoped PWA reminder deletions persist as retryable cleanup work.
- Deleting or completing an agenda item from Android also reconciles the corresponding account-scoped Web/PWA reminder state.
- Account erasure removes the new lifecycle retry/restore-intent state together with the existing account-scoped data.
- No parallel lifecycle engine, Life Core rewrite or monolithic Memory Engine is introduced.
- Release metadata is aligned to v0.67.0+77.
- Analyze, full tests, Web release, production-equivalent ARM64 build/size audit and AppLab must be green before this line is promoted.


## v0.68 acceptance criteria

- The existing DiaryBlock/DayJournal data model remains the source of truth for private memories.
- `DiaryBlockReference` is the single derived in-memory primitive for diary-memory projections.
- People-linked memories delegate to the same derived reference path instead of maintaining a parallel scan/model.
- “In questo giorno” delegates to the same derived reference path and keeps its historical-only, non-archived behavior.
- The Ricordi screen consumes the same derived references instead of maintaining its own local memory-record class.
- No MemoryEngine database, Life Core entity, new storage key, cloud table, sync queue or lifecycle type is introduced.
- Release metadata is aligned to v0.68.0+78.


## v0.69 acceptance criteria

- Places are lightweight references attached to the existing DiaryBlock payload; there is no separate Places database/table/store.
- Each linked place has a name and may optionally preserve latitude/longitude.
- Legacy DiaryBlock JSON without place metadata remains readable with an empty place list.
- The private diary editor can add, remove and reuse place references without creating a profile-management flow.
- Place chips coexist with tags, people and memory connections on the existing diary card.
- Global deterministic search includes place names and exposes a derived Luoghi filter/result type.
- Ricordi text filtering includes place names.
- Journal persistence automatically carries places through private sync, backup/restore, Trash and account isolation.
- Release metadata is aligned to v0.69.0+79.


## v0.70 acceptance criteria

- v0.68 and v0.69 remain additive/consolidating changes over the existing DiaryBlock/DayJournal architecture, not a Life Core rewrite.
- Legacy DiaryBlock payloads without Places Lite metadata remain readable.
- Place references survive ordinary local persistence and process-style reload.
- Place references survive JSON backup/restore through the existing backup pipeline.
- Moving a place-linked diary block to Trash and restoring it preserves the place reference and optional coordinates.
- Place metadata remains isolated across account profiles through the existing account-switching mechanism.
- Deterministic diary/place search resolves place-linked memories without a secondary search database.
- Ricordi, People and On This Day share DiaryBlockReference; duplicate memory record classes stay removed.
- No `places_v1`, `_placesKey`, MemoryEngine persistence key, Life Core store or new Places backend table is introduced.
- Existing lifecycle, sync, backup/media and account-erasure paths remain the source of truth.
- Release metadata is aligned to v0.70.0+80.
- Analyze, full tests, Web release, Android size audit and AppLab Trusted Verify must be green before promotion to main.


## v0.71 acceptance criteria

- The private shopping list stores only lightweight item data: name, optional quantity, category, order and bought/frequency metadata.
- Category suggestion is deterministic and local; no AI/API is required.
- Private shopping items use the existing granular entity-delta persistence and private cloud reconciliation rather than a second sync engine.
- Shopping remains account-isolated and is included in existing backup/restore and readable export.
- Private delete uses the existing Trash → restore → permanent purge lifecycle.
- Frequently purchased shortcuts are derived from purchase metadata on the same ShoppingItem, not stored in another favorites database.
- Noi ♡ shopping items reuse `SharedEntryType.shopping`, the existing shared cache/pending queue/Realtime path and server tombstones.
- Shared shopping does not appear as agenda/feed content and introduces no new Supabase table.
- The same Shopping List screen supports private and shared modes to avoid duplicated UX logic.
- Release metadata is aligned to v0.71.0+81.
- Analyze, full tests, Web release, Android size audit and AppLab Trusted Verify must be green before promotion to main.


## v0.74 acceptance criteria

- The existing v0.48 universal lifecycle engine remains the only private Trash implementation.
- Shopping items, workout sessions and workout plans survive complete backup/restore while in Trash and restore losslessly.
- Permanently purging an obsolete workout-plan version cannot mutate an existing historical WorkoutSession snapshot or a recreated live plan with the same ID.
- Noi ♡ shopping deletion remains on the shared tombstone/offline-operation path and never creates a private Trash copy.
- External calendar events remain excluded from Trash because they are an ephemeral read-only projection, not canonical Anna's Diary content.
- Current release coordinates are defined once in runtime metadata and checked once by the canonical release metadata test.
- Historical feature tests must not hardcode the current release version/build number.
- Release metadata is aligned to v0.74.0+84.
- Development checks, Web release, Android size audit and AppLab Trusted Verify must all pass before merge.

## v0.72 acceptance criteria

- Allenamento is a dedicated user-facing section with **Sessioni** and **Schede** views.
- A completed session is independent from gym-specific concepts and can represent running, cycling, swimming, walking, hiking, gym, yoga/mobility, team sports or another activity.
- Session fields are optional where appropriate: distance, duration, elevation, RPE and notes never prevent logging a sport that does not use them.
- Running/walking/hiking derive pace when distance and duration exist; other distance activities derive average speed.
- A workout plan is reusable and may contain structured exercise rows or free-text training blocks.
- TXT/CSV plan import is local, bounded and uses the existing file-picker dependency.
- Starting from a plan copies a snapshot of its exercises into the new session; subsequent plan edits/deletion do not rewrite workout history.
- Workout sessions/plans are account-scoped, offline-first and use the existing private entity-delta/cloud reconciliation path.
- Existing JSON/ZIP backup, readable export and Trash → restore → purge lifecycle include both sessions and plans.
- No workout-specific Supabase table, AI parser, remote plan service or second sync engine is introduced.
- Release metadata is aligned to v0.72.0+82.
- Analyze, full tests, Web release, Android size audit and AppLab Trusted Verify must be green before promotion to main.
