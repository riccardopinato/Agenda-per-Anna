# Anna's Diary — v1.00-A Full Product Reality Audit

Baseline audited: `v0.99.0+109`, `main @ a87f69fd897bbc98f495c42d5d7d55a1e36b9b04`.

This audit follows the Master Prompt v21 evidence ladder. It distinguishes implementation from runtime, physical-device and distribution evidence.

## Product reality verdict

The current architecture does **not** need a new Life Core, Memory database, Today database, Places database, Capture engine or Privacy store.

The canonical model is already consolidated around:
- `AgendaStore` and its established domain records;
- `DayJournal / DiaryBlock` for private narrative content;
- derived projections such as `DayHubSnapshot`, `DayLifeEntry`, `DiaryBlockReference`, `MemoryRecallSnapshot` and `LifeArchiveEntry`;
- one Unified Capture surface writing through existing canonical paths;
- explicit lifecycle, data-safety, privacy and ecosystem service layers.

## Confirmed gaps before 1.0

### P0
1. Password Noi ♡ still lacks a physical two-device/two-account E2EE lifecycle proof.
2. Repository evidence does not prove production deployment of migration `027_shared_password_hardening_v086.sql`.
3. Backup/restore does not yet implement the Master Prompt v21 physical staging → reference-safe commit → deterministic rollback contract.
4. If the public 1.0 release is monetized, real RevenueCat purchase/restore proof must come from Google Play Internal Testing.

### P1
1. Superseded legacy `SearchScreen` remains dead code.
2. Core localization is incomplete on Home, search/memory and Backup/Open Export surfaces.
3. Long-history scalability lacks a regression budget at meaningful diary volume.
4. Backup/Open Export file-picker workflows are not physically verified.
5. Trusted AppLab coverage does not yet include every release-critical native/data-safety/store path.

### P2
1. Home contains too many secondary destinations for the daily-use surface.
2. Android package growth needs an explicit budget. v0.99 ARM64 measured 35.86 MiB; bundled ML Kit OCR contributes roughly 10.55 MiB and remains justified unless a lighter solution preserves current product value.

## Evidence boundary

The v0.99 code head was trusted-runtime verified by AppLab, but no claim is made that all file-system, store billing, two-device E2EE or iOS flows are physically/distribution verified.

## 1.0 hardening sequence

1. **v1.00-B — Golden Core Cleanup & Localization**
2. **v1.00-C — Data Safety v21 Hardening**
3. **v1.00-D — Security / Native Physical Certification**
4. **v1.00-E — Distribution & Store Readiness**

Each step must close its own automated gates before the next implementation step begins. Physical/store-only gates remain explicitly BLOCKED rather than being represented as automated proof.
