# Android release runbook

Anna's Diary keeps generated platform folders out of source control. Android
release packaging is therefore reproducible from the pinned Flutter template
plus `tool/prepare_android_platform.py`.

## Production signing

The manual **Build Anna's Diary Android Release** workflow refuses to create a
release unless all four repository secrets are available:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

The keystore must be the same stable production key used for previous
installable releases. The workflow never creates or caches a fallback signing
key.

## Release artifacts

The workflow publishes separate artifacts so they cannot be confused:

- **annas-diary-arm64** — preferred APK for current Android phones.
- **annas-diary-play-aab** — Android App Bundle for Play Store distribution.
- **annas-diary-universal** — compatibility APK containing every supported ABI.
- **annas-diary-other-abis** — 32-bit ARM and x86_64 split APKs.
- **annas-diary-release-report** — SHA-256 checksums and APK size reports.
- **annas-diary-symbols** — Flutter obfuscation symbols; retain these for stack
  trace symbolication.

File names include both version name and build number.

## Platform generation contract

CI and release jobs pin Flutter **3.47.5** and generate Android from that exact
template. `tool/prepare_android_platform.py` then applies:

- `FlutterFragmentActivity` for local authentication;
- required Android permissions and notification receivers;
- `allowBackup=false` for private local diary data;
- core-library desugaring;
- Firebase Google Services when the checked-in config is present;
- launcher/notification assets using the Android-only `tool/flutter_launcher_icons_android.yaml` config;
- stable production signing only when `--release-signing` is requested.

The script is idempotent and intentionally fails when expected Flutter template
anchors disappear. A Flutter upgrade therefore fails CI instead of silently
shipping a partially configured native project.

## Size policy

Every pull request that changes application/runtime packaging runs an ARM64
release-size audit. The audit uses production-equivalent release flags
(obfuscation, tree-shaken icons and split debug info) but does **not** upload the
audit APK.

Production releases create both ARM64 and universal size reports. Prefer the
ARM64 APK for direct sideloading; the universal APK is expected to be
substantially larger because it carries native libraries for multiple ABIs.
