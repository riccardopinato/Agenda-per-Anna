# Anna's Diary v1.08 — Android signed sideload / physical acceptance

**Status:** RELEASE SOURCE PREPARED — APK NOT YET BUILT — PHYSICAL DEVICE NOT VERIFIED.
**Product scope:** merged Motion & Visual Polish implementation PR #161, 20 approved decisions M01–M20.
**Expected Android build identity:** `1.0.0-rc.3+112`, package `com.riccardopinato.agenda_per_anna`.
**Previous on-device build:** UI5 `1.0.0-rc.2+111`.
**Factory constraint:** source gate PASS != APK built != physical device verified != Play/Store ready.

## 1. Controlled build (manual-only)

1. Merge the bounded `+112` version-bump PR **only** after required exact-head Development checks, Web release and AppLab Source Gate pass, including any required reviews and branch protection.
2. On the merged `main` source, run GitHub Actions **Build lightweight ARM64 sideload APK** (`.github/workflows/sideload-arm64.yml`) manually with `workflow_dispatch`. Never build from a stale release branch or trigger an implicit APK build on PR/push.
3. Require the existing four signing secrets. Never regenerate a signing keystore or disclose its contents. If any secret is absent, stop; do not fall back to debug signing.
4. Download the workflow's `annas-diary-light-arm64` artifact and its `PHYSICAL_CERTIFICATION_MANIFEST.json`. Require the APK `Anna-Diary-arm64-release.apk`, buildNumber `112`, expected package, correct source SHA, artifact SHA-256 and signing certificate SHA-256.
5. Compare the new APK certificate fingerprint to the **actual installed UI5 +111** stable-signing certificate. A changed fingerprint is a BLOCKER for update-in-place. Use `apksigner verify --print-certs` and Android package metadata independently when available; do not assume the certificate is correct only because CI was green.
6. Record workflow run URL, source commit SHA, APK SHA-256, certificate SHA-256, exact APK filename and variant. Keep the same APK bytes during testing and distribution.

## 2. On-device matrix — user/device gate

**Preconditions:** Android phone with the stable-signed UI5 +111 already installed and representative local diary data; ensure an independent user-controlled safety backup exists before release testing. Do not clear app storage, uninstall, or perform destructive restore merely to complete QA. Exercise only real existing data; never seed fake memories into the personal account.

| ID | Scenario | Expected outcome | Evidence |
| --- | --- | --- | --- |
| V108-P01 | Install +112 APK **over** +111, without uninstall | Android accepts in-place update; package and signing unchanged; existing diary/agenda/media remain | NOT VERIFIED |
| V108-P02 | Relaunch, cold start, switch all four outer tabs | Oggi, Calendario, Ricordi, Altro remain interactive, correct, responsive | NOT VERIFIED |
| V108-P03 | Toggle reduced motion / screen reader while tab state is active | No tab/page disposal, lost Memories selection/expanded months, or Calendar view reset | NOT VERIFIED |
| V108-P04 | Crea central button and all original capture actions | Original five actions, Altre opzioni and Modelli stay usable; date-aware capture correct | NOT VERIFIED |
| V108-P05 | Save an actual test diary entry deliberately | Persisted entry is visible after app restart; success animation only after successful save | NOT VERIFIED |
| V108-P06 | Ricordi: Per te, Timeline, year chip, suggestions | Real dates/data preserved; inline expansions, target month and scroll/state correct | NOT VERIFIED |
| V108-P07 | Ricordi global search and filtered results, Back/reopen | Search starts fresh as designed; true results, filters and matching details; keyboard responsive | NOT VERIFIED |
| V108-P08 | Existing photo, album, Then/Now real paired photos | Hero/reveal only for matching content; original photo and identity preserved | NOT VERIFIED |
| V108-P09 | Ricordi map with real geolocated memories | Real pins only; gestures work; pin feedback opens matching existing memory | NOT VERIFIED |
| V108-P10 | Vault unlock/biometric, background/restart and app privacy | No regression in encryption/lock, private content isolation, screenshot security | NOT VERIFIED |
| V108-P11 | Offline/local-first and optional sync | Existing local content works offline; reconnection does not duplicate or lose items | NOT VERIFIED |
| V108-P12 | Motion/performance + accessibility on phone | No repeated excessive animations, substantial scroll jank, inaccessible targets or accidental taps | NOT VERIFIED |

**Separate qualification:** Notifications, two-device Noi ♡ sync, purchases/restore via Play and cross-device release compatibility need their own physical/distribution evidence and cannot be inferred from this v1.08 visual smoke.

## 3. Evidence to capture

- Device model / Android version / app build number
- Source SHA; exact artifact SHA-256 and signing certificate fingerprint
- Each scenario: PASS / FAIL / BLOCKED / NOT VERIFIED, observed behavior and reproduction steps
- Screenshots/video/logs when useful, without exposing private diary, Vault or account data
- Any issue requiring a change -> new source/compiled APK requires fresh exact-artifact verification

**Promotion policy:** only mark PHYSICAL DEVICE VERIFIED when the declared relevant scenarios have actual device evidence against this specific APK. A source-only AppLab PASS, Web build or emulator is never equivalent to this gate.
