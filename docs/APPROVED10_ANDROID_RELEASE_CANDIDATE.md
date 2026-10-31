# Anna’s Diary — Approved 10/10 mock-up Android candidate

Status: **SIGNED APK BUILT — PHYSICAL DEVICE QA NOT VERIFIED**.

Historical signed candidate `rc.4+113` came from `4fbeb1c` and is outdated. The current `rc.6+115` stable-signing workflow succeeded on main `31b66ba96d66a3ca3984a3c19061c4f1bfc9f9c7`: [run #41248307448](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41248307448), artifact `annas-diary-light-arm64`. Artifact creation does not certify that signing matches the already-installed phone's certificate or that any physical scenario passed. See [APPROVED10_FULL_AUDIT_20261031.md](APPROVED10_FULL_AUDIT_20261031.md) for the earlier source audit.

Release identity: `1.0.0-rc.6+115`; package `com.riccardopinato.agenda_per_anna`.
Compared with previously installed `1.0.0-rc.2+111`, Android versionCode 115 is higher.
Version 115 has now been built by the stable-signing Android Actions workflow; the generated binary must still be validated on a real device.

## Release requirements

1. Include approved UI PRs #163–#170 plus audit repairs #172/#173/#174/#175/#176/#177 and the final localization PR #179 only after its exact-head gates pass and it is merged. Do not build from an incomplete or stale PR branch.
2. Verify the **new** exact main commit SHA after all corrections (not old `ac221eec`) and source gates: Development checks Flutter analyze/test/Web crypto, Deploy Web and AppLab Source Gate.
3. For this candidate, the **manual** `.github/workflows/sideload-arm64.yml` already succeeded on exact main SHA `31b66ba9`. For **future** build-number increments, `.github/workflows/auto-signed-arm64.yml` now invokes the same signing workflow automatically after successful trusted main CI. Retain `--release-signing` and the same four protected keystore secrets; never sign PR pushes.
4. Workflow fails closed on missing signing configuration. No keystore regeneration; no debug/unsigned replacement of an installed package. The generated artifact is `annas-diary-light-arm64` with `Anna-Diary-arm64-release.apk` and `PHYSICAL_CERTIFICATION_MANIFEST.json`.
5. Verify artifact name, source SHA, package ID, versionName/versionCode, Android target API and signing SHA-256 match existing stable identity. Save SHA-256 of APK.
6. On a real Android phone, **in-place update** the installed version with original data kept. Smoke test every navigation route, selected calendar date in +Crea, 5 languages, greeting rotation, private Vault unchanged, search (one character/title-only and A–Z/newest/oldest), and Inbox tags create/rename/filter/reopen.
7. On two *different* authenticated devices, verify reusable 24h shared-code QR join for both, different artwork does not change code/expiry, expiry and owner revoke, camera fallback and genuine QR decoding.
8. Observe reduced motion, offline/sync queues, backup/restore and no data loss. The phone report must identify pass/fail for each physical gate before release certification.

## Explicitly unverified
APK existence is verified by GitHub Actions run #41248307448. Matching signing identity against the existing installed version, sideload install, account migrations, QR readability/scanner camera, two-user invitation concurrency and physical Inbox taxonomy remain NOT VERIFIED without the relevant certificate/device evidence.

Private Vault presentation and cipher/key management have not been redesigned.
