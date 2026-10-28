# Anna's Diary v1.05.x — User-defined HSV appearance (bounded UI feature)

Status: **IN PROGRESS — exact-head CI/AppLab and Codex review pending**.
Source baseline: `main@84abb53c8d2bb55e80c8d6eca78363c35eaf83a1`.
Factory baseline: App-Factory-Core `7b84e33df715cf2a48bda7c7495d0690819bff0f` (Master v26.6 / Golden Index v23).

## Product scope

Keep the five original `AgendaPalette` values and colors unchanged. Add:
- one non-destructive **Custom** choice with tactile HSV saturation/value square and rainbow hue bar (drag or tap);
- editable six-digit HEX code and swatch;
- **Delicate** (existing soft surfaces) and **Expressive** (slightly richer card/navigation styling) appearance intensity;
- local live preview, explicit **Apply** and **Cancel/Back**;
- accessibility labels and all five existing localizations;
- entry points from Personalization and the existing Settings > Appearance section.

## Canonical compatibility contract

`AgendaPreferences` adds `useCustomPalette`, `customColorValue` (opaque ARGB) and `colorIntensity` with defaults that exactly preserve the old visual theme. Color editor persists only after Apply, via the original `AgendaStore.savePreferences`. Theme cache keys include effective seed and intensity. Canonical preferences JSON carries the new fields through local persistence, backup/restore and existing cloud preferences; remote preference projection explicitly reads them without adding a second sync owner. Invalid custom values disable Custom rather than corrupt the selected legacy preset. Data migration/version changes are unnecessary.

No change to app navigation destinations, diary entries, shared content, private vault, Premium, or billing. v1.06 is not started.

## Validation

- Preset seed compatibility and JSON default/fallback regressions.
- Persistence and backup round-trip for custom color and intensity.
- Source contract verifying only Apply commits preferences.
- Localization and entry-route assertions.
- Flutter analyze + tests + Web/ARM64 build.
- AppLab trusted Android run and Codex review on the exact PR head.
- Keep physical-device, stable-signed release, and Play/Store certification **NOT VERIFIED** without separate evidence.

No new package or external picker dependency. The screen is a `part` of the existing Flutter application.
