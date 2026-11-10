# Anna's Diary — S13: Vision Board Web-first acceptance & stabilization

**Date:** 10 November 2026. **Scope:** source regressions, truthful release evidence,
and an operator-ready PWA test ledger. No new product feature.

## Baseline and audited release facts

- **S12 PR:** [#299](https://github.com/riccardopinato/Agenda-per-Anna/pull/299)
  merged by squash at `9a1e000f7322ae412ac4abf4b185ab49031e8776`.
- **PR head:** `1bd2d69e3151e7bec94c91540f25601154d27007`.
  PR [Development](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42837734224)
  and [AppLab Source Gate](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42837734041)
  passed. PR [Web build](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42837734608)
  passed after retry of a Flutter SDK setup issue; the PR deploy job was
  correctly skipped.
- **Main exact-sha:** [Development checks](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42838930186)
  PASS; [GitHub Pages build and deploy](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42838930043)
  PASS **on attempt 2**. Attempt 1 timed out in `syncing_files`, then was
  cancelled; the retry reused the matching artifact and succeeded.
- **Published route:** https://riccardopinato.github.io/Agenda-per-Anna/.
  GitHub deploy PASS is source publication evidence, **not** evidence that a
  user's installed PWA refreshed to that commit.
- **S13 base:** `main@9a1e000f7322ae412ac4abf4b185ab49031e8776`.
  **S13 PR:** [#301](https://github.com/riccardopinato/Agenda-per-Anna/pull/301).
  S13 CI/merge/Pages results must be filled from the actual resulting runs;
  do not inherit S12's PASS as evidence for S13.

## Synthetic S13 checks (separate from physical acceptance)

`test/webfirst_s13_visionboard_acceptance_test.dart` extends S11-B/C/D/E
and S12 regression suites, without duplicating stores or the editor:

1. **30 independently stored photo assets**, distributed well outside old
   normalized 0..1 page coordinates: guarded draft save, existing-board edit,
   vector arrow and freeform text preservation, ZIP backup, restore into a
   clean synthetic state, all 30 media IDs/bytes recovered.
2. **World/camera invariance** through eight alternating pans, zoom 0.2x,
   successive scene growth and insertion-point reprojection. Any visible-world
   jump at `getMaxScaleOnAxis` sub-1x zoom is a regression.
3. **Narrow 320dp editor** shows a reachable pinned `Aggiungi alla tela`
   control, opens the Foto/Testo/Freccia/Disegna menu, and has no Flutter
   layout exception.

This proves only what the fixtures check. In particular, 30 tiny synthetic
byte arrays are **not** a device RAM, JPEG decoding, FPS or 30-photo PWA
performance benchmark.

## Manual acceptance sheet — operators: actual PWA A and PWA B

Use the latest confirmed production commit (not the PR SHA) and a controlled
test profile with **synthetic/non-personal** material. Record for each case:
`ID | date/time Europe/Rome | tester | device model | OS | browser and version |
installed PWA/tab | visible app/build identity | result PASS/FAIL/BLOCKED |
reproduction/evidence location`.

Do **not** put personal images, memories, journal text, OAuth tokens, private
links or unredacted backup files in GitHub issues. When source build identity
isn't exposed by the UI, mark `BUILD_IDENTITY_NOT_VERIFIED`; do not infer it
from the current git main.

| ID | Priority | Action | Expected | Status |
|---|---|---|---|---|
| S13-01 | P0 | On A and B: open production Pages URL, refresh/reopen each installed PWA | Correct new UI; existing diary content unchanged | NOT_VERIFIED |
| S13-02 | P0 | Global Crea + from Oggi, Calendario, Ricordi and Altro, using private context | Vision Board entry works; hidden in shared-only context | NOT_VERIFIED |
| S13-03 | P1 | New blank board: add >10 real photos, text and arrows, pan/zoom beyond first frame | No slot limit, add-content remains visible, no page accidentally added | NOT_VERIFIED |
| S13-04 | P1 | Use two fingers to zoom, draw arrow/ink with chosen tool, repeat at near/far zoom | Touch gestures, cursor mapping and strokes remain anchored | NOT_VERIFIED |
| S13-05 | P1 | Pan far in both axes; insert text/photo at visible center; zoom out/in, recenter | Content remains where placed, no snap, loss or distortion | NOT_VERIFIED |
| S13-06 | P0 | Save → close PWA → reopen → Ricordi → re-edit → save | All objects and photo assets retained after refresh | NOT_VERIFIED |
| S13-07 | P1 | Edit, undo, redo, exit with unsaved changes → discard | Whole-board history consistent, no silently persisted discarded draft | NOT_VERIFIED |
| S13-08 | P0 | Open pre-S12 board and original multipage Sketchbook | Old 3:4 layout preserved; Sketchbook still adds pages | NOT_VERIFIED |
| S13-09 | P0 | Account A→B→A while board editor/save/Trash dialog open | Stale writes rejected, no leakage between accounts | NOT_VERIFIED |
| S13-10 | P0 | All→Shared-only→All with gallery open; test Noi ♡ | Private board immediately hidden and never auto-shared | NOT_VERIFIED |
| S13-11 | P0 | Link a private memory; move board to Trash and restore | Links, IDs and media retained | NOT_VERIFIED |
| S13-12 | P0 | Export ZIP and JSON, restore ZIP to clean controlled device, inspect 30 photo assets | All IDs, association and photo bytes preserved; corrupt/missing asset fails safely | NOT_VERIFIED |
| S13-13 | P1 | Export PNG via OS file picker after pan/zoom | Exactly visible viewport exported, legible and not empty | NOT_VERIFIED |
| S13-14 | P1 | 320/360/390dp + tablet, light/dark, IT/EN/ES/FR/PT | No clipped controls, overflow, missing labels or inaccessible entry | NOT_VERIFIED |
| S13-15 | P1 | VoiceOver/TalkBack and hardware keyboard on A/B | Understandable labels/focus and actionable editor buttons | NOT_VERIFIED |
| S13-16 | P1 | On both devices, open/save 30 real photos; cold/warm; track FPS, latency and peak memory | Capture measurements; no invented threshold or PASS | NOT_MEASURED |

Existing [S11-E PWA-01..14](WEBFIRST_S11E_VISION_BOARD_HARDENING_PWA_QA_20261110.md)
remain independent and **NOT_VERIFIED**. S12 changes the + action for a
single-page Vision Board; S11-E PWA-04's old `add/delete page` step applies
only to the **traditional Sketchbook**, not to the new board.

### Manual triage rule

- **P0 failure** (data loss, auth/identity leakage, media restore, backup or
  data-scope mismatch) → BLOCKING_NOW; capture a sanitized reproduction,
  stop release acceptance and open a narrowly scoped fix PR.
- **P1 regression** (gesture/viewport, visual, keyboard, rendering, PNG) →
  FIX_CURRENT_STEP when attributable to S13 or S12; reproduce as widget/source
  test if possible before code changes.
- **Browser/PWA caches:** try controlled refresh/reopen first; record cache
  version mismatch separately. Do not delete personal local app data as a
  generic cache-clearing workaround.
- **No signal** (e.g. unavailable second test device) → NOT_VERIFIED,
  not inferred PASS.
- **Feature limits unchanged:** full-world PNG/PDF, minimap, magnetic
  alignment, drag-and-drop, APK/Play, collaborative boards, and offline PWA
  guarantees are separate future product admissions.

## S13 completion boundary

Source QA is eligible for merge only with identical PR-head required checks
green, no unresolved actionable review or branch conflict, and a safe merge.
After merge, collect exact-main Development and Pages deploy evidence. Mark
this stage `SOURCE_QA_COMPLETE` only for verified source workflows.
`TWO_PWA_PHYSICAL_ACCEPTANCE` remains `MANUAL_QA_PENDING` until operators
supply actual device results.
