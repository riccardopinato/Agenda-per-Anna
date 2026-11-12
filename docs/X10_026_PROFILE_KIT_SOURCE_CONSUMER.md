# X10-026 — Source-only consumer adoption candidate

Factory baseline Core@c5adc147046beb7024629466d10eeb799c3c2619. In this PR the production Flutter dependency resolver imports the **real shared pure-Dart profile kit v0.1.0** pinned to immutable archive commit `1d1a8628e25f58b788b013cf6955763d00363cdc`, package path `19-APP-FACTORY-10X/flutter_kits/profile`. No fork of the source is copied.

The added Flutter test exercises the actual dependency in this consumer's toolchain, not just the archive kit CI. Only a **source compatibility pilot**: it does not wire the app profile UI, persistence, backups, OAuth, notifications or analytics. There is no migration, no existing preference overwrite, and no new Android permission, network provider or billing. Source+CI on this app remains distinct from real device testing; the other consumer also must independently pass CI.

Rollback: remove the sole `factory_profile_kit` git dependency and the test, and regenerate `pubspec.lock` using the same toolchain; existing app stores remain unchanged. No Golden promotion follows from adding this dependency.

**Anna specific gate: Product Bible/DS6 and Private Vault behavior remain authoritative; no user data/path changed. Only merge after exact-head Development and AppLab Source checks plus independent review.**

## Follow-up source consumer runtime projection (X10-026)

`AgendaStore.factoryProfileSnapshot` now builds a **read-only**, runtime-available `factory_profile_kit` profile from the canonical current `AgendaPreferences` object. This does not install a new preferences store, migrate Vault/backup fields, opt users into analytics, enable login or alter the UI. Two regression tests check locale/theme/display name projection and unchanged serialized store data. The kit's `ProfileTheme` is a *view*, never a replacement for `AgendaThemeMode`. Revert by removing the single root import, one getter and its tests; no stored data format changed.
