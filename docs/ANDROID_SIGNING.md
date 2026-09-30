# Android stable release signing

Anna's Diary uses one persistent Android signing identity for installable release APKs and Play Store AABs.

## One-time Windows bootstrap

Prerequisites:
- JDK with keytool
- GitHub CLI (gh) authenticated with access to riccardopinato/Agenda-per-Anna

From the repository root run:

    powershell -ExecutionPolicy Bypass -File .\tool\setup_release_signing_windows.ps1

The script creates one RSA-4096 JKS locally, generates random store/key passwords, writes the recovery bundle only under %USERPROFILE%\.annas-diary-signing, registers the four required GitHub Actions Secrets, runs Android signing doctor, and triggers the lightweight ARM64 sideload build.

The secret values are never committed to the repository.

## Required repository secrets

- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

## Recovery rule

The folder %USERPROFILE%\.annas-diary-signing is release-critical. Keep at least two secure backups, including one offline copy.

Do not create a new keystore for ordinary releases. A different signing key changes the Android application signing identity and can prevent in-place updates of previously installed APKs.

## Verification

Run Android signing doctor manually whenever signing configuration is changed. It validates secret presence, Base64 decoding, keystore password and alias without printing secret values.
