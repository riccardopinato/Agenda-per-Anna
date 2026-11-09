# Anna's Diary — S11-C Vision Board editor and collage

**Date:** 9 November 2026. **Scope:** Web-first feature, private diary editor only.
**Factory baseline:** `App-Factory-Core@d4ed1185d36d419228fba6b57a979cde308bd321`
(Master v27 / Golden Index v29), resolved at S11-A and carried forward
without repeating bootstrap. **Anna base:** `main@260dd753a3f7d1b7cd501ce38cf6e4a78ea773b3`
(after S11-B PR #292 and separate template QA PR #293).

## Product and source boundaries

- Product Bible S11 admission remains authoritative: optional personal/private
  boards, no new database, sync service, image database, schema migration,
  billing, shared space, Vault, ML or third-party images.
- Add one optional action **Vision Board** only in the private
  `DiaryComposerSection`; the same section used for Noi ♡ does not receive it.
- Create: read-only S11-B preset picker → draft
  (`VisionBoardFoundation.draft`) → existing `DiarySketchbookScreen` in
  `visionBoardMode` → `saveDraft` with account epoch guard. Cancel/save-failure
  keeps journal unchanged; editor save callback closes only on acknowledged
  canonical write.
- Edit: existing `DiaryBlockType.sketch` with `creativeSubtype.visionBoard`
  automatically reopens in Vision Board mode. `saveExistingPrivateVisionBoard`
  enforces active account scope and exact current block identity; rejects
  stale content, archived board and missing image before the canonical
  `AgendaStore.saveJournal` write. Original sketches remain Sketchbook mode.
- The card retains `DiarySketchPagePreview` and canonical ID, media refs,
  text title, Cestino and archive lifecycle.
- Collage: `VisionBoardCollage.arrange` is **pure Dart geometry**. It can
  place photos in original S11-B rectangle frames, an adaptive grid or an
  eight-image maximum cascade (then grid). Photos are not duplicated, cropped,
  re-encoded or transmitted. Content is editable afterward with existing
  selection/resize and media ID ownership.
- Editor: original pen, text, image, selection, lasso and zoom remain.
  Vision Board mode adds bounded full-document undo/redo snapshots for
  moves, resize slider gestures, add/duplicate/delete page and collage; a
  non-drag selection does not generate a mutation. Ordinary Sketchbook retains
  existing per-page history, with resize undo improvement.
- Vision Board back: non-persisted edits trigger a localized five-language
  discard dialog; Keep editing preserves the draft, Discard writes nothing.
  Failed Save leaves editor open. Tool changes and selection alone are not
  treated as content edits.
- Existing image export PNG remains available. S11-C does not certify
  portable PNG/PDF layout export or lossless restoration across browsers.
  Transient media housekeeping after cancellation remains follow-up S11-D.

## Regression / acceptance checks

- `test/webfirst_s11c_vision_board_editor_test.dart`: real frames are
  consumed, original media references/IDs preserved, geometry bounded;
  guarded edit roundtrip leaves unrelated diary records intact; stale board
  reference and A→B→A rejected, shared-only and archived rejected, missing
  media rejected; 320dp widget test for back confirmation and failed save.
- `test/webfirst_s11b_vision_board_foundation_test.dart` must continue to
  pass for old sketch JSON and five localized original templates.
- Full Flutter tests, analyze, visual comparator, Web Vault crypto, release
  build, Web PR build, AppLab Source Gate must all finish on the **exact PR
  head**; merge only when ruleset's strict main freshness and mandatory
  `check` and `UI5 source and visual-flow contracts` are satisfied.
- After merge verify `push main` Development and Pages **same merge SHA**.
- Keep two-PWA, keyboard, touch, responsive devices, accessibility and offline
  browser QA `NOT_VERIFIED` until real manual evidence exists; do not
  generate APK or change Play state.

## Out-of-scope S11-D / S11-E

S11-D: dedicated Ricordi gallery, authorized memory links, thorough Cestino
and backup/restore portability, media cleanup after discarded photos and
photo-missing reporting. S11-E: physical Web/PWA usability and accessibility
matrix, performance, definitive release evidence. Any layout-engine Golden
or donor admission requires separate reuse/licensing review.

**Documentation status:** source proposal, not proof of GitHub checks; exact
head/run IDs and main Pages status must be read from GitHub after execution.
