# Anna's Diary — Editorial Hybrid real-data signed physical candidate +126

- Date: 2026-11-05.
- Basis: main@f73d20b358f6880f21285939f75d3627c73b572c, after merged DS1 PR #255 and real-data DS2 PR #256.
- Flutter version: 1.0.0-rc.6+126. Android versionCode=126 (>125); package remains com.riccardopinato.agenda_per_anna.
- Scope: release identity ONLY; the user specifically requested a direct-install signed APK for comparing Editorial Hybrid with original Home.
- Signing policy: protected existing Android keystore, never generate a replacement; auto-signed-arm64 triggered only after successful main Development checks from push, strictly monotonic code, then sideload-arm64 signs the tested SHA.
- Artifact: annas-diary-light-arm64 / Anna-Diary-arm64-release.apk and PHYSICAL_CERTIFICATION_MANIFEST.json.
- Release workflow must PASS and APK package/version/signature/checksum evidence must be inspected. A successful source PR does not imply an APK exists.
- Device steps: install over the current stable-signed Anna app WITHOUT uninstalling or clearing data; open Altro > Impostazioni > Personalizzazione > Home Editorial Hybrid; enable, test real diary and selected-day content, disable and confirm Classic returns; verify + Crea and Calendar.
- Actual Android device update, backups/vault/media retention, Google identity, notification flows, device-only visual fidelity, dark/custom palette, gesture insets, small phone and physical QA remain **NOT VERIFIED** until user reports execution.
- This is a sideload QA candidate, not automatic Google Play publication.
