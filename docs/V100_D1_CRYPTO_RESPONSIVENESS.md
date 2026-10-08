# Anna's Diary — v1.00-D1 Crypto Responsiveness

Status: **IMPLEMENTED — release gates required**

## Problem isolated

The v1.00-D audit found that native Vault PBKDF2-SHA256 derivation was declared asynchronous at the API boundary but still executed PointyCastle's CPU-heavy derivation synchronously on the Flutter isolate. At 600,000 iterations this could starve input/frame processing and is consistent with the observed real-device “Anna's Diary non risponde” failure while entering/unlocking the Private Vault.

The same primitive was also used directly by Noi ♡ shared-password pairing (180,000 iterations) and recovery (600,000 iterations), creating a second responsiveness risk.

## Security invariants

D1 does **not** lower the KDF cost and does not introduce a data migration.

Unchanged:
- PBKDF2-HMAC-SHA256;
- Vault current iterations: 600,000;
- Vault legacy compatibility: 180,000;
- Noi ♡ pairing iterations: 180,000;
- Noi ♡ recovery iterations: 600,000;
- derived key length: 256 bits where currently requested;
- existing salts;
- AES-GCM payload/envelope formats;
- AAD strings;
- Vault master-key model;
- recovery/pairing package schema.

## Implementation

`lib/src/security/pbkdf2_worker.dart` conditionally selects:
- native/mobile: `pbkdf2_worker_native.dart` using `Isolate.run`;
- Web: `pbkdf2_worker_web.dart` using browser Web Crypto.

Vault adapters delegate to the worker. `SharedPasswordService` no longer constructs `PBKDF2KeyDerivator` directly and awaits the worker for both pairing and recovery.

The native worker clears its temporary UTF-8 secret bytes and isolate-owned salt copy after derivation. No claim is made that Dart `String` memory can be explicitly zeroed.

## Regression contract

`test/v100d1_crypto_responsiveness_test.dart` locks:
1. a standard PBKDF2-SHA256 compatibility vector;
2. a 600,000-iteration main-event-loop heartbeat before KDF completion;
3. a bounded 600k completion timeout;
4. a real Private Vault setup → encrypted write → lock → password unlock → plaintext recovery round trip;
5. source ownership: native `Isolate.run`, Web Crypto, and no direct PBKDF2 in Vault/Noi ♡ service paths.

Existing v0.85/v0.86/v0.87 security tests are updated rather than bypassed.

## Evidence boundary

A green D1 automated gate proves implementation compatibility and trusted responsiveness behavior in the test runtime. It does not prove:
- Android Keystore behavior on a physical device;
- biometric enrollment/invalidation behavior;
- OEM-specific ANR behavior on every handset;
- two-device Noi ♡ E2EE lifecycle.

Those remain in the v1.00-D physical certification matrix. D1 must not be used to mark VAULT-01/02/03/04 or NOI-01/02/03 PASS without the required physical observations.
