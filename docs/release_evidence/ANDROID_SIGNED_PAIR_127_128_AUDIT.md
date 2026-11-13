# Anna's Diary — Maxi-step 1: genuine signed Android APK pair identity

**Date:** 13 November 2026. **Factory:** `App-Factory-Core@c5adc147046beb7024629466d10eeb799c3c2619` / Master 27 / Golden Index 29. **Scope:** read-only original artifact provenance and APK identity, **not** a release, installation or rollback on a real phone.

## P0 finding — signed +128 binary versionCode does not equal Flutter buildNumber

**Independently observed in the actual APK by Android `aapt dump badging`:**
- +127: `source pubspec +127` / manifest `buildNumber=127` / **APK `versionCode=127`**.
- +128: `source pubspec +128` / manifest `buildNumber=128` / **APK `versionCode=2127`**.

The two historical source commits use **identical** `.github/workflows/sideload-arm64.yml`, `.github/workflows/auto-signed-arm64.yml` and `tool/prepare_android_platform.py` file identities; only source version changes. ZIP/APK bytes and manifest/source/run provenance match. The APK `AndroidManifest.xml` and compiled `lib/arm64-v8a/libapp.so` differ, so they are not the same APK copied twice.

**Do not silently interpret `2127` as `128`.** An ABI-specific version code offset is a possible explanation, but an exact causal mapping has **not** been independently established for these two historical runs; `2127 = 2000 + 127` is not a proven mapping from the +128 source. This discrepancy is explicitly pinned and must remain `BLOCKED_UNRESOLVED_BINARY_VERSIONCODE` for any in-place update/recovery admission.

The read-only CI may **PASS original byte/hash/source/signature authenticity while still reporting this BLOCKED version alignment**. A green audit CI must never be interpreted as a cleared release/physical gate. No user/device installation or downgrade is authorized by this historical evidence.

## Real immutable +127 and +128 evidence

| Evidence | +127 | +128 |
| --- | --- | --- |
| Source commit | `999bf8eb4c010d8fb7007179bb7f518fba5b71de` | `01151f379ebd9669c3936058aa089433a05a63ae` |
| Source `pubspec.yaml` | `1.0.0-rc.6+127` | `1.0.0-rc.6+128` |
| Stable signed run | [42123307290](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42123307290) | [42221409690](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42221409690) |
| Original artifact ID | `13459458898` | `13503582447` |
| Original GitHub artifact ZIP SHA-256 | `759638a3a9e42b5bd41185af6f64f4cf9916f81ab3cb1ee27d38e76a4a4206a5` | `000fedad87a37712bc52491202eb135c3002abf9b61d9b20cfaddf0326d00671` |
| Original inner APK SHA-256 | `063299c6fea06fdb187f91a470670efeee3145e06fcf962552a7f1c67db49435` | `d1fa6b9ba8df521a92114ad5da9bc6fbc6ab51bf971eeee660e0cf05331454cd` |
| APK bytes | `41798052` | `41798052` |
| GitHub job | `signed-apk / build: success` | `signed-apk / build: success` |
| Manifest signing cert SHA-256 | `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3` | `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3` |
| Package ID (manifest) | `com.riccardopinato.agenda_per_anna` | `com.riccardopinato.agenda_per_anna` |

These ZIPs and both original APKs were downloaded and their entire bytes hashed **independently** on 13 November 2026. Each SHA exactly matches its published run artifact and its inner physical-certification manifest. The APK Signing Scheme **v2 signing block certificate bytes were inspected directly in both APKs**; their SHA-256 matches the above cert. Merely extracting the public certificate does not independently cryptographically verify the signed whole APK, so the new CI must also run `apksigner verify`.

## Automated independent verifier

- **Frozen evidence coordinates:** [`ANDROID_SIGNED_PAIR_127_128_PINNED.json`](ANDROID_SIGNED_PAIR_127_128_PINNED.json).
- **Fail-closed source verifier:** [`tool/verify_historical_signed_apks.py`](../../tool/verify_historical_signed_apks.py).
- **Read-only GitHub CI:** [`historical-signed-apk-pair-audit.yml`](../../.github/workflows/historical-signed-apk-pair-audit.yml).
- Check exact run source SHA, original signed job PASS, artifact IDs/digests/sizes and corresponding historical `pubspec.yaml` build number.
- Hash complete original artifact ZIP and inner APK bytes. Verify embedded metadata and releaseReality manifest; no unmatched files or unbounded extracts.
- Inspect each actual APK using Android `aapt dump badging` for **package/versionCode/versionName** and `apksigner verify --verbose --print-certs` for valid **APK Signature Scheme v2** and same public certificate fingerprint.
- Emit a run/checkout-bound machine-readable `identity-result.json`; only this JSON is uploaded, **never actual signed APKs or personal information**.
- Negative tests reject stale runs/sources, skipped signer job, wrong ZIP bytes, mismatched manifest, missing cryptographic signer verification, and synthetic PR merge SHA substitution.

## Current +129 is NOT an existing signed Android release

`main@ffa3d98c21b6f04c8d5fe904e930cff003c6aa31` resolves `1.0.0-rc.6+129` and is verified at **SOURCE+CI**, not APK installed. [Auto-signed candidate run 43339886230](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43339886230): `release-preflight SUCCESS`, **`signed-apk SKIPPED`**, no artifact. Unchanged `versionCode` does not trigger signing by design; do not label this run a signed +129 release or silently increment a product version in a historical audit.

## Acceptance boundaries and exact next step

A successful CI from this PR can verify the **original +127/+128 bytes and signatures** but returns `SIGNATURE_AND_ORIGINAL_BYTES_VERIFIED_VERSIONCODE_DIVERGENCE` and `release_identity_gate=BLOCKED_UNRESOLVED_BINARY_VERSIONCODE` until the +128 binary version mismatch is explained. This is not a physical test or upgrade/downgrade. It does not prove installed-app identity, database migrations, cross-account state, Play Internal Testing, or safe reverse schema compatibility.

Android generally rejects lower-version installs under normal conditions. Even same-signer +127/+128 does not authorize forcing a downgrade over personal data. **Never uninstall, clear data, use `adb install -d` on a personal release, rotate signing keys, or publish a Store build as part of this audit.** A future recovery should use safe backups and, when technically appropriate, a forward-`versionCode` corrective release with the historical compatible behavior.

Next maxi-step: propose an isolated **real-app emulator** data-preservation and forward-fix recovery rehearsal with synthetic data only, retaining the complete separate physical/X10-032 gate. No automatic signing/build of +129, no mobile install, no cloud, no billing and no Golden admission.
