# Privacy V2 #215 — disclosure-path matrix, source QA only

**Status:** BLOCKED / OPEN / DRAFT — DO NOT MERGE / DO NOT SIGN / DO NOT PUBLISH.
**App baseline reconciled:** `main@cb477cbecc85c1b1c415c60fd69bbd128fb82904` (`rc.6+121`).
**Factory baseline:** `App-Factory-Core@b73013a8c676fa5eb2be64a52cf753c5bdd1460a` (Master 27, Golden Index 28).
**Contract:** `isSensitive` is a UI concealment marker, **NOT encryption, E2EE, OS concealment everywhere or server isolation**. User authorization permits source/CI work only, not a merge or APK from this branch.

## Source route coverage and obligations

| Surface or attack path | Evidence in Draft #215 | Current assessment | Required remaining proof |
|---|---|---|---|
| Calendar list, day timeline, hourly projection | `planner_views.dart`, `unified_agenda.dart`, `widgets_editors.dart` | Source masking / omission in unguarded slots | Widget, semantic labels, tap/long-press on a real Android build |
| Local marked agenda editor | `widgets_editors.dart`, `discreet_privacy.dart` | PIN challenge and account-at-challenge guard | Biometric cancellation, app pause/resume, navigation and lock |
| Shared feed, note, sketch and photo cards | `screens/shared_space.dart` | Card masks before title/thumbnail; explicit challenge to open | Two signed-in devices, deep links, offline cache, screen reader |
| Shared Memory cover/search/Then & Now | `shared_memories.dart` | Sensitive entries excluded; no separate reveal UI | Ensure no hidden sensitive cover, search hit or recap persists |
| Android launcher widget | `home_widget_bridge.dart`, `agenda_store.dart`, `tool/prepare_android_platform.py` | Merged +121 scope clear and redaction plus Home discreta marker | Real launcher: sensitive values, account switch and old cached previews |
| Android Calendar B3 | `android_calendar_sync.dart` | New sensitive appointments excluded | Historical exported events **not revoked**; user-controlled inventory |
| Local and Web push reminder creation | `agenda_store.dart` | Flagged title replaced by generic placeholder for **new** reminders | Previously delivered notification history and snooze/background callbacks |
| Cestino, restore/purge | `screens/trash_screen.dart`, `discreet_privacy.dart` | Sensitive titles hidden; destructive actions gated | Cestino batch, screen reader labels, restore, wrong PIN |
| Backup ZIP, open ZIP and TXT exports | `screens/backup_settings.dart`, `discreet_privacy.dart` | Active + trashed sensitive local items require PIN/explicit warning | File remains plaintext; inspect actual export contents and safety of OS share |
| Shared deferred photo media queue | `domain_models.dart`, `agenda_store.dart`, `screens/shared_space.dart` | **Source patched:** sensitivity roundtrip through JSON/localization/remote entry; existing sensitive photo replace remains fail-closed | Legacy queue created before marker, concurrent sensitivity edits, network retry on TWO devices; **DO NOT ENABLE replacement yet** |
| Local PIN verification | `agenda_store.dart`, `discreet_privacy.dart` | **Source mitigation:** 5 failures -> 60s in-memory deny, fixed-length comparison | Session restart bypasses lock; Keystore-bound verifier not implemented, full biometric tests missing |
| App screenshots, Android Recents and overlapping Vault window | `app_shell.dart`, `vault_service.dart` | Source lease ownership, serialized native secure screen | Android physical FLAG_SECURE tests; Web/PWA cannot promise OS screenshot protection |
| Year Review, archive and other derived projections | `life_archive_domain.dart` | Sensitive appointments omitted from summary | Probe search/recap/index/accessibility and offline restored caches |
| Personal future letters (new in +121) | `diary/diary_memories.dart`, `screens/more_screen.dart` | Stored as normal tagged DayJournal text; **not a protected time-locked secret** | Do not imply PIN protection of future letters without a separately reviewed classification scheme |

## Deferred photo queue risk — explicit contract

- `SharedMediaPendingUpload.isSensitive` is serialized and rehydrated; missing legacy values map to `false`.
- New local previews, queue-localization copies and remote `SharedEntry` preserve the marker instead of losing it.
- **Residual blocker:** queued legacy records with missing markers or sensitivity changes from another device while offline are not safe to assume nonsensitive; a follow-up adversarial reconciliation policy and two-device test are required before relaxing fail-closed replacement.
- Source tests prove shape/serialization only, NOT cloud/provider consistency, permissions or delivered media confidentiality.

## External state and informed consent

Do **not** silently delete or rename prior Android/Google Calendar publications, downloaded/exported archives or already delivered notifications. The next user-assisted physical test should inventory and explicitly decide any cleanup at the destination, then verify that **future** sensitive publishing uses generic or excluded values. No automatic removal was executed.

## Exact-head automated gates (record after running)

- Flutter `analyze`, full `test`, Web Vault crypto tests and Web release compile via Development checks: **PENDING current head**.
- AppLab source gate: **PENDING current head**.
- Native Android debug compile: **PENDING current head**. Passing debug compile does not prove screenshot/notification delivery or signed APK.
- Specific tests: `test/privacy_discreet_home_test.dart`, `test/v056_home_widget_test.dart`, `test/v084_password_vault_test.dart`, `test/v065_noi_permissions_test.dart`, plus backup/restore and account-switch regressions.
- Source SHA and CI run IDs must be recorded in final PR comment; do not write PASS into this document without evidence.

## Manual gates — all NOT RUN

1. Android physical screenshot/Recents, PIN lock, biometrics, overlap with Vault, background/resume, focus and permissions.
2. App +121 data continuity on a **separate privacy QA build**, not the released +121 artifact.
3. TWO-device shared photos, offline/retry/marker conflicts, account switch and revocation.
4. Historical Calendar Provider / Google items and delivered notification history review with explicit owner consent.
5. Native widget stale cache, push quick actions, OS share sheet/backup ZIP and accessibility semantics.
6. Web/PWA: browser previews and screenshot constraints documented without false secure-window claims.

**Hard gate:** PR #215 must remain Draft and unmerged until owner explicitly resumes physical privacy QA and authorizes integration after the unresolved HIGH security findings have evidence.
