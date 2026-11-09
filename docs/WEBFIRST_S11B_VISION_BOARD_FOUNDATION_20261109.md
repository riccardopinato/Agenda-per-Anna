# Anna's Diary — Web-first S11-B: private Vision Board foundation

**Date:** 2026-11-09 · **Scope:** product admission, backward-compatible
sketch metadata, original geometric presets and guarded draft contract.
**Baseline:** Factory `d4ed1185` (Master v27 / Golden v29); Anna base
`0b49de46d43f4747c5cf9425d460f2fc2c7e6cd4`. Only Chat, Web-first,
no native APK, Play, cloud changes or real-user data changes.

## Product admission / ownership
The [Product Bible](PRODUCT_BIBLE.md) explicitly admits a **private, optional**
personal board on the existing Sketchbook. The `DiaryBlockType` enum, existing
`AgendaStore.journals`, editor, `MediaAssetStore`, Trash/backup and
existing `Noi ♡` ACL are preserved. Existing sketch/photo/note/voice flows
remain untouched.

## Exact source delta / gates

| Component | S11-B behavior | Gate |
|---|---|---|
| `DiaryBlock.creativeSubtype` | `DiaryCreativeSubtype.sketch` default; `visionBoard` for sketch blocks only | Legacy JSON and new subtype round-trip |
| `VisionBoardPreset` | Six original layouts: Blank, Dreams, Journeys, Home, Together, Goals; five locales, empty frames and no third-party media/quotes | Locale and geometry fixtures |
| `VisionBoardFoundation.draft` | Creates in-memory sketch board; no silent journal write | Cancel/picker leaves store unchanged |
| `VisionBoardFoundation.duplicate` | New block/page/text/image IDs; existing media asset references; no automatic person/memory links | No overwrite and identical source |
| `VisionBoardFoundation.personalBoards` | Read-only projection over current private journal; archived and shared-only excluded | Scope/isolation filter |
| `VisionBoardFoundation.saveDraft` | Only explicit account-epoch-guarded append through `AgendaStore.saveJournal`; no duplicate IDs | A→B→A, shared-only, existing journal, missing media |
| `showVisionBoardPresetPicker` | Reusable read-only original preview picker for subsequent editor phase | Flutter widget 320dp / IT copy |

No source code or assets from external donors were imported. Preset geometry
and translations were written for this app, no secondary persistent record or
new package is required.

## Out-of-scope / next dependencies
- **S11-C:** actual user-facing editor entry, simplified mode of canonical
  Sketchbook, reliable undo for resizing/page actions, unsaved-edit confirmation,
  transient media cleanup, optional collage layout/crop and detailed visual QA.
- **S11-D:** launch point in Ricordi, private gallery/filters, optional links
  to real authorized memories, duplication lifecycle, trash/restore/export,
  missing-media portable-export hardening and account-scope end-to-end tests.
- **S11-E:** full Web integration, 5-locale responsive/accessibility matrix,
  browser/touch/keyboard/Back test, AppLab and exact-SHA Pages publication.

**Not claimed:** visible new navigation entry or finished board editing,
independently executed physical devices/PWA, offline PWA, user-data migration,
native APK and store release.

## Acceptance protocol
After PR final head: `flutter analyze`, complete Flutter tests including
`test/webfirst_s11b_vision_board_foundation_test.dart`, Web Vault crypto,
Web release build, dedicated Web PR build (changes `lib/**`), AppLab Source
Gate, review without blocking finding and protected squash merge. Then verify
main Development and Pages exact merge SHA; PR Web preview success is not
production Pages success. Real two-phone PWA testing stays `NOT_VERIFIED`
until an observed scenario and device/browser version is recorded.

**Status ledger before CI:** SOURCE_PREPARED / PR_PENDING / EXACT_HEAD_CHECKS
NOT_VERIFIED / MERGE_NOT_VERIFIED / WEB_NOT_VERIFIED / PHYSICAL_NOT_VERIFIED.
Update with run links only once inspected; never infer green checks.
