# Anna's Diary — Maxi-step 2: real signed APK emulator upgrade and recovery

**Factory baseline**: `riccardopinato/App-Factory-Core@c5adc147046beb7024629466d10eeb799c3c2619` / Master v27, Golden Index v29. **Only Chat, no Work.**

## Immutable source and scope

This is an ON-DEMAND, separately gated **real Android runtime** rehearsal using the **original previously signed APKs**, not synthetic fixture APKs and not new builds. Source and binary provenance of the files is fixed by [`ANDROID_SIGNED_PAIR_127_128_PINNED.json`](ANDROID_SIGNED_PAIR_127_128_PINNED.json):

| Original signed release | Flutter source build | Android ARM64 split versionCode | Real Actions |
| --- | ---: | ---: | --- |
| Original older | +127 | **2127** | [42123307290](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42123307290) |
| Original newer | +128 | **2128** | [42221409690](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42221409690) |

The exact binaries have the same release-signing certificate `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3`. The workflow rechecks historical GitHub run/source/artifact binding, ZIP+APK SHA-256, `aapt` and `apksigner verify` independently **before** any installation. The APK v2 signature is not forged or recreated. The workflow is PR-scoped in `.github/workflows/real-signed-apk-upgrade-emulator.yml`; no signing secrets, new APK, `versionCode` bump, Firebase credentials or Play track are involved.

## Exact real-app emulator journey and evidence levels

The test runs on a disposable Android API35 Google APIs x86_64 emulator with ARM64 native-library translation. The Python harness refuses a real phone or a preexisting installed package, before any installation. The guest/offline path never signs in, switches real accounts or loads personal backups.

1. Install original +127 ARM64 signed APK; verify package via Android PackageManager **2127**.
2. Complete normal guest onboarding using the existing `.maestro/journeys/onboarding.yaml` (the only place with `clearState: true`, on a completely new synthetic fixture).
3. Use real, unchanged Anna UI to create one **synthetic Inbox note**, text `X10_ANNA_127_128_EMULATOR_SYNTHETIC_ONLY`; observe it in Inbox.
4. Force-stop and **upgrade in-place** using original +128, `adb install -r`. No uninstall, `pm clear`, backup/restore or `-d`. Verify installed Android `versionCode=2128`.
5. Navigate to Inbox from freshly launched updated app, assert exactly the synthetic note remains visible.
6. Force-stop/relaunch and assert the same note remains visible.
7. Try ordinary `adb install -r` of the prior +127: require an actual `INSTALL_FAILED_VERSION_DOWNGRADE` result. Confirm still on +128 and same note preserved.
8. Reinstall the **same** stable-signed +128 as a **non-destructive same-version repair**; confirm the persisted note still visible. This proves recovery of a rejected update action, **not old-code rollback**.

One isolated Python receipt records immutable originals, runner Git SHA, emulated OS/ABI/ARM translation, outcome of each UI stage, and explicit hard false for phone, user data, actual release downgrade, Store, forward-fix and Golden. **Do not mark a step PASS if Maestro fails or the UI sentinel is missing.** Only the two JSON receipts may be uploaded, not original signed APK files, screenshot content, caches, databases or real data.

**Scope of actual runtime evidence if PASS:** `SIGNED_REAL_APP_EMULATOR_UPGRADE_AND_REPAIR_PASS` — one guest Inbox note under real +127/+128 binaries and emulator with ARM translation. This does not certify all app storage, Vault/Keystore, media, notifications, shared sync, account switching, OS/OEM policy, real device or physical release. ARM translation may affect runtime behavior: a future real ARM64 phone must be independently tested.

## Fail-closed recovery boundary

For a stable-signed **release** APK, a normal lower-version install is expected to be blocked by Android. This harness **never forces `adb install -d`**, never uninstalls the app to bypass refusal and never rotates signing cert. Same-version repair is not a rollback of application code. A genuine functional rollback should follow a new **forward-`versionCode` corrective release** tested and signed by the existing protected workflow, plus separately verified backups/data migration and human approval. No such new corrective APK is generated or authorized by this task.

Separate QA gates: **SOURCE + signed artifact pair → EMULATOR actual binary guest note → PHYSICAL spare device and data inventory → PLAY track (if authorized) → GOLDEN process**. Do not collapse these gates.

## Commands and maintenance

- CI: [`real-signed-apk-upgrade-emulator.yml`](../../.github/workflows/real-signed-apk-upgrade-emulator.yml)
- Orchestrator: [`tool/rehearse_real_apk_emulator_upgrade.py`](../../tool/rehearse_real_apk_emulator_upgrade.py)
- Real guest synthetic note: `.maestro/release-recovery/signed127-seed-synthetic-inbox.yaml`
- Post-upgrade assertions: `.maestro/release-recovery/signed128-check-synthetic-inbox.yaml`
- Fail-closed offline tests: `python3 -m unittest discover -s tool/tests -p test_real_apk_emulator_upgrade.py -v`
- Independent artifact verification already established in Maxi-step 1: [`ANDROID_SIGNED_PAIR_127_128_AUDIT.md`](ANDROID_SIGNED_PAIR_127_128_AUDIT.md)

**Acceptance:** exact-head GitHub CI real emulator runtime + independent review must be successful before merging this source into `main`. If GitHub Android image lacks ARM64 translation or the real UI cannot create/read the note, mark the runtime as **BLOCKED/FAIL**, not PASS based on source tests.
