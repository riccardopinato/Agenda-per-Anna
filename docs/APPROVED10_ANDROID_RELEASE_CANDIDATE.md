# Anna’s Diary — Approved 10/10 mock-up Android candidate

Status: **SOURCE PREPARATION — APK NOT BUILT — PHYSICAL DEVICE QA NOT VERIFIED**.

Release identity: `1.0.0-rc.4+113`; package `com.riccardopinato.agenda_per_anna`.
Compared with previously installed `1.0.0-rc.2+111`, Android versionCode 113 is higher.
Version 113 is **reserved** here; no file should be called an APK until Android Actions produces it with the stable certificate.

## Release requirements

1. Merge source from the fully green, reviewed approved-navigation PR on top of merged #163, #164, #166 and #167.
2. Verify exact main commit SHA and source gates: Development checks Flutter analyze/test/Web crypto, Deploy Web and AppLab Source Gate.
3. Run **manual** GitHub Actions `.github/workflows/sideload-arm64.yml` from current `main` (never PR push), retaining `--release-signing` and the same four protected keystore secrets from earlier signed releases.
4. Workflow fails closed on missing signing configuration. No keystore regeneration; no debug/unsigned replacement of an installed package. The generated artifact is `annas-diary-light-arm64` with `Anna-Diary-arm64-release.apk` and `PHYSICAL_CERTIFICATION_MANIFEST.json`.
5. Verify artifact name, source SHA, package ID, versionName/versionCode, Android target API and signing SHA-256 match existing stable identity. Save SHA-256 of APK.
6. On a real Android phone, **in-place update** the installed version with original data kept. Smoke test every navigation route, selected calendar date in +Crea, 5 languages, greeting rotation, private Vault unchanged, search (one character/title-only and A–Z/newest/oldest), and Inbox tags create/rename/filter/reopen.
7. On two *different* authenticated devices, verify reusable 24h shared-code QR join for both, different artwork does not change code/expiry, expiry and owner revoke, camera fallback and genuine QR decoding.
8. Observe reduced motion, offline/sync queues, backup/restore and no data loss. The phone report must identify pass/fail for each physical gate before release certification.

## Explicitly unverified
Native APK existence, signing identity, sideload install, account migrations, QR readability/scanner camera, two-user invitation concurrency and physical Inbox taxonomy are NOT verified by source checks alone.

Private Vault presentation and cipher/key management have not been redesigned.
