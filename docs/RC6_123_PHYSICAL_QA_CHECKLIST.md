# Anna's Diary — RC 1.0.0-rc.6+123: physical acceptance contract

Created 4 November 2026. Source basis: four feature PRs #229, #230,
#232 and #231 merged to `main` through `bcab075b1843c5c1ca4a31be315e077b85b93d16`.

## Provenance / do not overclaim

- Confirmed Android identity: `com.riccardopinato.agenda_per_anna`,
  `1.0.0-rc.6+123`; **signed-apk SUCCESS** from
  `main@20b0d2c7375f4e33e0009e04e82c666cf07a3128`,
  [workflow #41871951662](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41871951662),
  artifact ID `13346141160`.
- The signed artifact contains `PHYSICAL_CERTIFICATION_MANIFEST.json`.
  Extract its APK SHA-256 and certificate SHA-256 from that exact artifact before
  claiming a device fingerprint/upgrade observation; a CI preflight alone is
  not sufficient.
- On 4 November 2026 the owner explicitly accepted the **P0 physical gate
  generally** for +123: `USER_ATTESTED_GENERAL_PASS`. This is a release
  acceptance decision, **not** an assertion that R0–R13 were individually
  performed or independently observed. Record any missing individual device,
  timing, backup, sync, Vault and Store evidence as `NOT VERIFIED`.
- Treat the existing Privacy V2 #215 and Google Calendar Direct #199 as
  independent blocked/draft scopes. Neither is activated by this release.

## Required physical checks

| ID | Action on Android (repeat Web where relevant) | Acceptance |
| --- | --- | --- |
| R0 | Install +123 directly above the currently stable-signed APK without uninstalling | Same package/certificate, monotonic versionCode, all existing agenda and diary data retained |
| R1 | Disable network; search exact names, short queries, one typo, two typos | Exact hits remain first; local fuzzy returns bounded suggestions without freezing |
| R2 | Use synthetic local datasets of 500 and 5000 authorized records; time search/scroll on the test device | Record median and worst-case latency, frame responsiveness, result count, and no memory spike; no invented latency threshold |
| R3 | Use private/shared/person/archive scopes and search for a Vault-only string | No source leaks, archived excluded unless explicitly requested, no Vault result in fallback |
| R4 | Create a task draft from a sentence with explicit date/time, then cancel; repeat with ambiguous date | No task is saved on cancel; uncertain dates are user-reviewed |
| R5 | Convert a diary list into a checklist, cancel, retry and save explicitly | Source note intact, no duplicate on cancel or stale account, canonical editor used |
| R6 | Enter photo descriptions including emoji/combining characters; close, reopen, backup/restore | TalkBack reads authored description; roundtrip preserved; >500 graphemes not persisted |
| R7 | Replace an already-described photo; provoke a failed save if safely reproducible | Old description cleared on replacement; failed save keeps unsaved draft for retry |
| R8 | Reorder Weekly Review and Realistic Day cards, restart, restore default, switch accounts | Card order persists for intended account and reset restores original order; no records deleted |
| R9 | Open 12-month memory frequency for sparse/empty and many recorded days | Correct calendar-day counts, no duplicate block inflation, no inference of emotions or real-life inactivity |
| R10 | Open Weekly Review with no tasks, completed, pending and overdue tasks | Valid denominator and percentage, no fabricated statistics or divide-by-zero |
| R11 | Toggle privacy masking and background/resume for memories and Oggi | Private image descriptions and counts never show through restricted previews |
| R12 | Exercise all target product locales IT/EN/ES/FR/PT plus large text/TalkBack | Labels readable, no clipped actionable controls, semantics usable |
| R13 | Restart offline, switch accounts, import/export backup, revisit notes/photos | Canonical data lifecycle/backup valid; private/shared data stays isolated |

## Evidence report (fill from actual device)

- Device model, Android version, package/version shown on device:
- Installed previous version, upgrade path, no-data-loss proof:
- APK SHA-256 and certificate SHA-256 from exact manifest:
- GitHub workflow run and source commit:
- Screenshots / TalkBack evidence / offline and account-switch scenarios:
- 500-record search median/worst latency (ms):
- 5000-record search median/worst latency (ms):
- R0–R13 individual results: PASS / FAIL / BLOCKED / NOT VERIFIED.
- Store / monetization / iOS PWA status: separate and not implicitly certified.

## Closure rule

Software source completion = exact-head PR gates + integrated-main QA.
Release candidate availability = successful stable-signing workflow and file
checksum bound to the integrated commit. Full physical certification requires
recorded proof for the intended scenarios; never convert CI or emulator success
into a physical pass.
