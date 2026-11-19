# Anna's Diary — signed ARM64 rc.6+140: artifact receipt (19/11/2026)
**Recorded level: `ARTIFACT_BUILT / SOURCE_IDENTITY_VERIFIED / PHYSICAL_NOT_VERIFIED / STORE_NOT_VERIFIED`.** This receipt documents the **exact artifact that exists**, not an app installed on a phone.

## GitHub provenance
- Release source: `main@2395ca6f78ff35a9d65f59f6809b4be7d11fcee6` (PR [#370](https://github.com/riccardopinato/Agenda-per-Anna/pull/370) merged; source includes M1 [#367](https://github.com/riccardopinato/Agenda-per-Anna/pull/367), M2 [#368](https://github.com/riccardopinato/Agenda-per-Anna/pull/368), M3 [#369](https://github.com/riccardopinato/Agenda-per-Anna/pull/369)).
- [main Development checks #44432560423](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44432560423): **SUCCESS** on this SHA. [Auto signed ARM64 #44433294681](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44433294681): `release-preflight=SUCCESS`; **`signed-apk / build=SUCCESS`**, not skipped. Companion [Android native compile #44432560445](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44432560445) is separate source/native evidence, not device QA.
- Actual [Actions artifact ID 14487751762](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44433294681/artifacts/14487751762), name `annas-diary-light-arm64`, contains `Anna-Diary-arm64-release.apk` + `PHYSICAL_CERTIFICATION_MANIFEST.json` from same job.
- Prior signed +139 from [run #44097602073](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44097602073), source `e973cac9711de6cf1665ba289b72e933914c04a5`; package/signer comparison based on **actual prior APK**, not only its manifest.

## Bytes validated outside GitHub
| Field | Real value or evidence |
|---|---|
| Flutter identity | `1.0.0-rc.6+140` |
| Actual APK Android versionName | `1.0.0-rc.6` |
| Actual APK Android versionCode | `2140` (ABI split ARM64; previous +139 APK = `2139`) |
| Actual manifest package | `com.riccardopinato.agenda_per_anna` |
| Actual APK targetSdkVersion | `36` |
| Actual APK minSdkVersion | `24` |
| APK byte size | `42388776` bytes |
| **Actual extracted APK SHA-256** | `196a3310fd3043745e5a7b5fc7eec68d2b3a386e2e37683b77e492cb5f86a237` |
| **Downloaded artifact ZIP SHA-256** | `64e755390185f4685853010de1e07b3b22f6afd496f9e01009bb8ba553d3977d` |
| Manifest `artifactSha256` vs actual APK bytes | **MATCH** |
| Manifest `sourceSha` vs main release commit | **MATCH** |
| Embedded Android APK Signing Block | v2 ID `0x7109871a` present in original APK bytes |
| Actual embedded v2 signer X.509 DER cert SHA-256 | `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3` |
| Prior +139 embedded v2 signer certificate hash | `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3` — **SAME CERT** |
| Cert hash asserted in CI-created physical manifest | Same — **MATCH** |
| Full independent `apksigner verify` on APK | **NOT_RUN locally**; signed CI job PASS, standalone signature cryptographic verification still recommended as pre-install validation |
| Installed APK fingerprint/versionCode on user's phone | **NOT_VERIFIED** |
| Update-in-place, backup restore, 31 real-device cases | **NOT_PERFORMED** |
| Play AAB/Internal Testing/RevenueCat purchases | **NOT_VERIFIED** |

### Verification method and limits
Downloaded the authentic GitHub Actions artifact ZIP; extracted the APK; computed SHA-256 of archive and exact APK bytes; parsed binary `AndroidManifest.xml` for versionCode, package, minSdk/targetSdk; located APK Signing Block 42 and its v2 signer certificate, parsed DER as X.509 and computed SHA-256 with the same operation on actual +139 APK. The independent cert comparison **establishes same embedded signer certificate in these two files**, not that the currently installed app has the same signer, not full cryptographic `apksigner verify`, and not device upgrade success.

The original manifests list `validationLevel=ARTIFACT_BUILT` and `physicalVerification.status=PENDING`. **Never** upgrade that status to a physical pass based on this source/artifact receipt.

## Safe next gate
Read [M4 candidate](ANDROID_RC6_140_M4_CANDIDATE_20261119.md) and [31-case physical acceptance](ANDROID_MAXISTEP3_PHYSICAL_DATA_GATE_20261113.md). Prior to installation, run read-only APK/device identity preflight with current package/version and full `apksigner verify`, confirm independent tested backup **off-device**, and prefer a dedicated ARM64 spare with synthetic A/B profiles. **STOP** if the app's installed cert differs, backup restoration has not been verified, package/version downgrade is detected, or any user/private data would be overwritten. No `pm clear`, uninstall, downgrade, new keystore, real Vault/user data in cloud runners, or Play upload.

**DoD A20-19:** artifact signing/provenance subgate **PASS**; physical update-in-place/data preservation **BLOCKED ON REAL DEVICE AND VERIFIED BACKUP**.
