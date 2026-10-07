# Anna's Diary — v1.00-D Security / Native Physical Certification

Status: **IN PROGRESS — physical evidence required**

This step follows the Master Prompt v21 evidence ladder. AppLab, CI and backend
verification are preflight evidence; they do not substitute a real device for
file providers, Android Keystore/biometrics, notification delivery or the
two-device shared-password lifecycle.

## Live backend evidence — 2026-10-07

Supabase production project:

- project: `agenda-per-anna`
- project ref: `pxsxlorntswypdbeerzw`
- region: `eu-central-1`
- state observed: `ACTIVE_HEALTHY`

Production migration history contains:

- `20261001075952 shared_password_hardening_v086`

This closes the previous P0 uncertainty about whether
`027_shared_password_hardening_v086.sql` had actually reached the live
project.

The repository contract
`supabase/tests/027_shared_password_hardening_contract.sql` was executed
against the live project. It uses two existing authenticated identities inside
one SQL transaction and ends with `ROLLBACK`. It completed without an
exception, covering atomic key claim, owner-only key-envelope creation,
one-shot envelope consumption, revision-safe credential create/update/delete,
stale update/delete rejection, generic-merge bypass rejection and removed
member rejection. No contract-test rows are retained.

This is **LIVE BACKEND CONTRACT VERIFIED**, not a physical two-device client
certification.

## Supabase advisor triage

Security advisor results after the live contract check:

- `extension_in_public / pg_net`: accepted platform warning already documented
  in `docs/SECURITY_BASELINE.md`. Anna's Web Push scheduler uses
  `net.http_post`; the installed extension is non-relocatable and must not be
  force-moved/dropped just to clear the advisor.
- `auth_leaked_password_protection`: **OPEN EXTERNAL CONFIGURATION WARNING**.
  The current connector cannot change the Auth dashboard setting. It must be
  enabled/verified before Store Ready is claimed.

Performance advisor results contained only `unused_index` INFO findings.
No index is removed from a release candidate merely because production usage
counters are currently low.

## Trusted-runtime preflight

v1.00-D extends the AppLab visual journey with a Backup/Data checkpoint that
verifies the application-side presence of:

- complete ZIP backup;
- restore-from-file entry point;
- Open Life Export;
- local integrity audit.

The trusted emulator intentionally does not certify Android's real document
provider/file picker.

## Stable physical-candidate identity

The existing protected stable-signing workflow remains the source for direct
Android physical-test APKs. `sideload-arm64.yml` now ships the signed APK
together with `PHYSICAL_CERTIFICATION_MANIFEST.json`, recording:

- repository and exact commit;
- app version/build;
- release variant/channel;
- workflow run id;
- APK SHA-256;
- signing certificate SHA-256.

Physical results must point back to that manifest. Rebuilding after the
physical test produces a new artifact and requires new identity evidence.

## Mandatory physical matrix

All rows must be PASS on the exact recorded artifact before v1.00-D can be
marked PHYSICAL DEVICE VERIFIED.

| ID | Scenario | Minimum evidence |
|---|---|---|
| DS-01 | Create a real ZIP backup through Android document provider, close/reopen app, restore that exact file | device/OS, provider, observed restored diary/media, PASS |
| DS-02 | Restore a corrupted backup | explicit rejection, existing data unchanged, PASS |
| DS-03 | Restore a backup with missing referenced media/reference mismatch | explicit fail-closed behavior, no partial data, PASS |
| DS-04 | Interrupt/kill a restore during file/media work, then relaunch | no partial visible state, staging recovered/cleaned, PASS |
| DS-05 | Purge one entity while the same media remains referenced elsewhere/Trash | surviving reference still opens media, PASS |
| DS-06 | Open Life Export through a real provider, then inspect ZIP outside Anna's Diary | README/data/media available, PASS |
| VAULT-01 | Create/unlock Private Vault using password on real Android | decrypted content available only while unlocked, PASS |
| VAULT-02 | Enable biometric unlock, relock/restart, unlock biometrically | Android Keystore/biometric path works, PASS |
| VAULT-03 | Disable/re-enable biometric or invalidate biometric credential | safe fallback to password; no Vault loss, PASS |
| VAULT-04 | Attempt screenshot/recents capture on sensitive Vault surface | FLAG_SECURE boundary behaves as expected, PASS |
| NOI-01 | Device/account A generates Password Noi ♡ pairing envelope; device/account B consumes it once | same key/fingerprint, second consume rejected, PASS |
| NOI-02 | B creates credential, A receives/decrypts it; both edit from stale revision | one accepted revision, stale writer receives conflict, PASS |
| NOI-03 | Valid delete propagates; A removes B from space; B reconnects | removed device cannot mutate and stale local secret/key mirror is purged, PASS |
| NATIVE-01 | Android share target sends text and a photo into Capture | correct explicit destination, content preserved, PASS |
| NATIVE-02 | Long-press launcher icon opens Capture and Today shortcuts | both shortcuts route correctly, PASS |
| NATIVE-03 | Real notification delivery/tap on device | delivery and destination callback work, PASS |

## Completion rule

Until the matrix above is backed by real-device observations, the maximum
supported evidence for this step is **TRUSTED RUNTIME VERIFIED + LIVE BACKEND
CONTRACT VERIFIED**. The step remains **BLOCKED ON PHYSICAL EVIDENCE** and
v1.00-E must not be claimed complete.
