# Anna's Diary — v1.00-D2 Vault AppLab Deep Journey

Status: **IMPLEMENTED — release gates required**

## Purpose

The previous AppLab Vault coverage could pass after merely reaching either the
first-time setup surface or the locked surface. That proved navigation but did
not prove password KDF execution, encrypted payload persistence or wrong-password
behavior.

D2 replaces that shallow condition with a mandatory functional flow called from
`.maestro/applab-smoke.yaml`.

## Required trusted-runtime journey

The AppLab build starts with `clearState: true`. The Vault flow therefore
requires this exact sequence:

1. enter Private Vault and require the first-time setup surface;
2. configure a deterministic QA-only password;
3. create the sentinel note `D2_APPLAB_PERSISTENCE` with a deterministic body;
4. explicitly lock the Vault;
5. submit a deterministic wrong password;
6. require the localized incorrect-password error and require the locked surface
   to remain visible;
7. clear the failed value and unlock with the correct password;
8. require both sentinel title and body;
9. stop the app process and launch it again without clearing state;
10. navigate back to Private Vault and require the locked surface;
11. unlock with the same password;
12. require the same sentinel title and body again.

This means a PASS now exercises setup, 600k password derivation, AES-GCM payload
write/read, explicit relock, wrong-password failure, correct unlock and
cross-process encrypted persistence.

## FLAG_SECURE boundary

Private Vault deliberately stays out of `applab-journey.json` screenshot and
visual-regression checkpoints. Android `FLAG_SECURE` is expected to suppress
screenshots.

D2 therefore uses Maestro UI-hierarchy/state assertions and exact sentinel
content rather than requiring a screenshot of sensitive content.

## Evidence ceiling

A green D2 AppLab result is **TRUSTED RUNTIME** evidence. It **does not certify**
physical Android Keystore behavior, biometric enrollment/invalidation,
OEM-specific ANR behavior, or the two-device Noi ♡ lifecycle.

Those remain physical v1.00-D certification scenarios and cannot be promoted to
PASS from D2 automation alone.
