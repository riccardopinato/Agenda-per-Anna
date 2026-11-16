# Anna's Diary — audit residual register after +134 / post-UI roadmap

Updated 16 November 2026. This file is **append-only in spirit**: preserve origin/evidence for each item and record the later closure proof. Do not equate a merged PR, CI, artifact, owner visual opinion or physical test.

## Release/source identity

- Factory: `App-Factory-Core@c5adc147046beb7024629466d10eeb799c3c2619`, Master v27, Golden Index v29.
- Last signed APK **unchanged**: `1.0.0-rc.6+134` from release source `afbbb3ec5b46d1744d2f681668742fdef7723ea1`, [signed run #43777799161](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43777799161), artifact `14186833210`. The owner states that the APK works. Do not reopen download/signing without new failure evidence.
- UI source polish: [PR #328](https://github.com/riccardopinato/Agenda-per-Anna/pull/328) **MERGED** at `main@2934ea9573edc68edbfc24210fbf8296ac67af49`, same `+134` metadata, no new signed APK; pending **owner visual acceptance**. Residual tracking: [issue #329](https://github.com/riccardopinato/Agenda-per-Anna/issues/329). [UI quality follow-up #327](https://github.com/riccardopinato/Agenda-per-Anna/issues/327).
- Current Web is based on main; source-only changes after +134 **do not retroactively alter the signed APK**.

## Items resolved at source or confirmed by owner

| ID | Audit point | Resolution level | Evidence and caveat |
| --- | --- | --- | --- |
| AUD-001 | Earlier download problem | **OWNER ATTESTED WORKING** / no further task | 16 Nov: "apk funziona quindi lascia stare"; not an independent download/installation audit |
| AUD-003 | Memories populated carousel can render a 304–328dp empty hole while the hero fades in | **SOURCE FIX + FLUTTER SCREENSHOT PASS** | PR #328: display the authentic hero immediately in Journal, preserve Classic animation; [real screenshot #43785771246](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43785771246), manual device QA pending |
| AUD-005a | M3-looking Year ChoiceChip / Calendar create CTA / flat surfaces in the specified Journal routes | **SOURCE FIX + CI/SCREENSHOT PASS** | PR #328: original year pill, Organic action, paper texture; Material host and Classic deliberately remain |
| AUD-006 | Top-level docs identify +123/+129/+130 as if current | **DOCUMENTATION RECONCILED IN PR** | README/Product Bible/ROADMAP header identifies +134, old records retained with historical labels; verify after merge |
| AUD-007a | Full source scan missing | **SOURCE AUDIT PASS** | [source scanner run #43786278027](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43786278027): 332 Dart files, 0 skipped, report artifact; zero high-confidence legacy signatures |

## Persisting findings: do not close without the named evidence

| ID | Priority | Status / reason | Next acceptance gate |
| --- | --- | --- | --- |
| AUD-002 | P1 | **OWNER VISUAL ACCEPTANCE PENDING**. Calendar/Impegni/Ricordi/More/Settings closer to Home in screenshot evidence, but owner has not evaluated final iteration | Compare rendered Home ↔ all updated screens on real device; accept or report targeted visual adjustments |
| AUD-004 | P1 | **NOT VERIFIED**: APK +134 data retention, update-in-place and 31-scenario physical gate; owner's "APK works" covers basic operation only | Backup verified, installed version/signature recorded, diary/media/Trash restore, account A→B→A, offline-reconnect and unchanged Vault state on controlled device; preserve user data |
| AUD-005b | P2 | **INTENTIONALLY NOT GLOBAL-MIGRATED**: material framework/theming, un-migrated secondary M3 controls remain outside the target editorial scope | Targeted per-screen UX findings then bounded UI-only PR; never switch global `useMaterial3` off blindly, retain Classic and protected areas |
| AUD-007b | P2 | **REVIEW CANDIDATES, NOT CONFIRMED BUGS**: 257 scanner matches; legacy_preferences=57, native_dart_io=134 (primarily test/platform boundaries), eager_listview=65, async_void_handler=1 (notification callback) | Triage specific production-path file/line against real behavior, measured cost or outdated API, then add regression test; no blanket mechanical refactor |
| AUD-008 | P1 | **NOT VERIFIED**: Noi ♡ two-device sync, shared membership/revocation and stale write / conflict after app upgrade | Two separate authorized devices/accounts, offline edits, conflict and rejoin matrix; backend receipt and both clients' materialized final state |
| AUD-009 | P1 | **NOT VERIFIED**: Native reminders/push/Google external-calendar bridge end to end | Permissions denied/granted, reboot, timezone/DST, notification delivered and opened with correct routing on real device |
| AUD-010 | P1 | **NOT VERIFIED / SPECIFIC PRIVACY GATE**: PIN/biometric, Vault app switching and private content isolation after update; Vault intentionally excluded from visual changes | Protected real-device matrix, lock/restart/screenshot/search/backup boundaries; no changes to Vault in this UI scope |
| AUD-011 | P2 | **NOT MEASURED**: Android jank, frame p95, scroll, cold start, RAM/battery, large history/backup | 1–2 device models, release-profile instrumentation, repeatable fixtures and before/after baseline; no invented speedup |
| AUD-012 | P2 | **PARTIAL TEST COVERAGE**: dark/HSV combinations, all five languages, 200% font, 320/390/600, keyboard/IME/accessibility on all secondary journeys | Real Flutter viewport screenshots + TalkBack/keyboard + large text tests; retain 5-language localized copy |
| AUD-013 | P2 | **NOT VERIFIED**: Web/PWA actual install and on-device cache rollout/offline data sync; Pages source deployment PASS is narrower | PWA refresh, offline start, update cache, full capture/save/reload with user consent on two browsers |
| AUD-014 | P3 | **OUTSIDE SCOPE**: Play AAB, Store declaration/eligibility, paid RevenueCat entitlement and purchase restoration; sideload build explicitly `ANNA_PREMIUM_PREVIEW=true` | Independent authorized Store/QA lane, product billing admission, Play Internal Testing and provider receipt verification |
| AUD-015 | P3 | **ISOLATED DRAFT — DO NOT MERGE**: Privacy V2 PR #215 and Google Calendar Direct OAuth PR #199 | Separate security/OAuth admission, reviewed provider contracts, staging tests and explicit release gate |
| AUD-016 | P3 | **NOT GOLDEN-CERTIFIED**: App Factory visual/system/release patterns require cross-app independent evidence | Registry/Golden promotion only after verifiable consumer-specific runtime QA; catalog sync separate from this UI PR |

## Follow-up procedure

1. Close **source** work only with actual merged-main SHA and its required CI/Pages checks.
2. Close **visual** work only with owner review of new real Flutter screenshots / app, not just snapshots existing as ZIPs.
3. Close **physical** work only with a scoped test record linked to the exact APK artifact SHA, installed version, device and scenario; never perform destructive restore on personal phone.
4. Close **provider/Store** work only after independent verified provider receipts, not Premium preview.
5. On next roadmap cycle review this ledger first, remove already-closed items from active counts, preserve the record and record the receipt.

**Scope exclusions:** user says working APK, so do not create another signed APK or change versionCode on behalf of this audit; no data, Vault, account, sync, Store or Play mutation.
