# Anna's Diary — rc.6+121 physical QA and release evidence

Source lane: private direct-sideload ARM64, **not Play Store**.
Product version: `1.0.0-rc.6+121` (versionCode 121); predecessor `rc.6+120`.
Scope: widget account/privacy hardening (#216), optional assisted planning CAP-0102 (#217), personal future letters CAP-0142 (#218), and existing Quick Wins + backup/restore paths. Privacy V2 #215 and direct Google Calendar #199 are excluded.

## Release gate and identity

1. Merge this version bump ONLY after Development checks and source gate pass for its exact PR head, with no blocking review; verify main push CI.
2. The existing `auto-signed-arm64.yml` workflow starts only after **successful main push** Development checks and only if `pubspec.yaml` versionCode increased against parent main commit; inspect both `release-preflight` and **`signed-apk`** jobs. An overall green workflow with a skipped signed-apk job does not constitute a new build.
3. From the `sideload-arm64.yml` artifacts retain `Anna-Diary-arm64-release.apk` and `PHYSICAL_CERTIFICATION_MANIFEST.json`; assert manifest source SHA, version, SHA-256, stable package ID, workflow run ID and signing certificate SHA-256. Compare signing certificate fingerprint with the actually installed predecessor before in-place update. A private keystore/password is never committed.
4. Built artifact validation `ARTIFACT_BUILT` does not claim device / provider / Play success.
5. Download and sideload the artifact **without uninstalling** the existing app if certificate/package match. Keep a separate backup before testing restore. Never overwrite live data by experimenting with restore in an unprotected profile.

## Device manual test matrix — PENDING

| ID | Case | Expected | Status |
|---|---|---|---|
| QA-01 | Launch and in-place upgrade from signed +120 to signed +121 | Package/signature unchanged, personal journals/photos/tasks remain | NOT_RUN |
| QA-02 | Home widget, normal appointment, hideHomeDetails OFF then ON | ON masks title and birthday; no stale text on launcher | NOT_RUN |
| QA-03 | Private/shared/sensitive item, account switch guest -> user -> guest, erase | No cross-account preview, widget remains interactive | NOT_RUN |
| QA-04 | Launcher during app background/termination and widget refresh | No previous-account title reappears; date/locale remain correct | NOT_RUN |
| QA-05 | Overdue personal task: postpone, Undo, concurrent edit, new alternative action | Existing actions intact; suggestions never write without confirmation | NOT_RUN |
| QA-06 | Replan with full-day busy event; external calendar unavailable; account switch while dialog open | Show partial/scope notices; no overwrite or move on stale context | NOT_RUN |
| QA-07 | Inbox -> appointment, appointment -> memory, Trash -> restore | Existing records and links survive and no duplicate creates | NOT_RUN |
| QA-08 | Create a personal future letter, future date, read early, restart, Trash / restore | Single canonical diary entry, no accidental exposure claims | NOT_RUN |
| QA-09 | Local notifications: Done, Snooze 10/60 with app background/killed; OS permissions denied | No incorrect completion, no stranded/persistent stale notification | NOT_RUN |
| QA-10 | Export backup ZIP then inspect and restore to disposable QA profile | No lost media/notes, failure rollback safe, user confirmation | NOT_RUN |
| QA-11 | Cross-device Noi space with delayed network/disconnect/reconnect | No silent loss or overwrite of private/shared content | NOT_RUN |
| QA-12 | UI normal/large font, compact screen, five languages, light/dark | No clipping or unreadable controls, visual baseline review | NOT_RUN |

## Regression evidence

Automated suites include `test/v056_home_widget_test.dart`, `test/v107_quick_wins_test.dart`, `test/v107_a1_event_to_memory_test.dart`, `test/v100_data_safety_v21_test.dart`, `test/v048_universal_lifecycle_audit_test.dart`, `test/v063_creative_reminders_test.dart`, and `test/v105b0_memories_3_core_test.dart`. Claim a test PASS only when its exact source commit workflow is successful. These do not certify physical behavior.

No release readiness label `DEVICE_VERIFIED` or `STORE_READY` until evidence is attached to a concrete APK hash, device/OS, steps and expected/actual outcomes.
