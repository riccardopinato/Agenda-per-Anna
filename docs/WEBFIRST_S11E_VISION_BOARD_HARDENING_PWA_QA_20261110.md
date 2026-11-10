# Anna's Diary — S11-E Vision Board: source hardening and real PWA acceptance

**2026-11-10 · Repository:** `riccardopinato/Agenda-per-Anna`
**Baseline:** App-Factory-Core `d4ed1185d36d419228fba6b57a979cde308bd321`,
Master v27 / Golden Index v29 (resolved once during S11-A; no new central
bootstrap). **Previous main S11-D:** `3251cd5a6a68dbd175000dd680be4d5e7f95c70f`;
[CI](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42785919074)
and [Pages deployment](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42785919433)
both SUCCESS on the same SHA.

## Scope approved, exclusions and risk order

S11-E is a hardening/evidence release, not a new app or app version. Web/PWA
first; no native APK, Play change, permissions, cloud/service schema,
automatic transfer to `Noi ♡`, new Gallery store, AI/ML or further
Vision Board product features. In particular, no offline PWA behavior change:
the user explicitly deferred offline/Web guarantees.

1. **P1 account isolation:** S11-D's `VisionBoardMemories.moveToTrash`
   checked scope before calling the legacy Trash mutator, but the mutator
   wrote journal and Trash without an epoch guard. The S11-E change adds
   optional `scopeGuard` and `expectedBlock` to the **existing**
   `AgendaStoreLifecycle.moveDiaryBlockToTrash`, uses the canonical
   `_persistEntityMutations` serial queue with account recheck and scope
   rejection rollback, and leaves other legacy callers unchanged.
   Reject stale card identity and unreadable journal/Trash storage. Failure
   restores only the exact in-memory projection, never another account.
2. **P1 media draft/GC race:** the media GC used to delete every unreferenced
   local content asset even when a concurrently open Sketchbook had newly
   imported an image not yet saved. `MediaAssetStore.putForDraft` reserves
   content-addressed IDs *before* asynchronous storage, reference-counts
   simultaneous editors, and `prune` honors these temporary leases. Editor
   disposal releases its own references; the existing canonical maintenance
   runs after closing (12s delay, only while originating scope is current).
   Abandoned images become GC-eligible after the final editor closes; saved
   journal/Trash references protect committed photos. No eagerly invoked
   direct image deletion or alternate media database.
3. **P2 integrity of JSON backup:** the existing S11-D ZIP/Open Export
   preflight now also guards `createBackupJson`; missing live/trashed Vision
   Board photos fail closed instead of appearing recoverable. Ordinary
   Sketchbook data and legacy serialization are unchanged.
4. **P2 responsive/localization:** the S11-D gallery uses five original
   locales and accessible visible buttons. Automated S11-E test checks
   320dp dark layout, scoped-hidden private cards and button labels.
   No claim of screen-reader parity from widget-only tests.

## Automated evidence — inspect exact head and merge SHA, do not infer
- `test/webfirst_s11e_vision_board_hardening_test.dart`: concurrent editor
  retain/release with interleaved prune, persisted media references and ZIP,
  stale board ID guarded Trash, concurrent A→B→A Trash consistency,
  missing media JSON backup for live/Trash, five-language gallery labels,
  320dp dark mode and shared-only filter.
- S11-B/C/D suites remain regression gates. PR source checks must include
  Flutter analyze/full test suite/C2/Web Vault crypto/Web release, dedicated
  PR Web build and AppLab Source Gate on an **identical head SHA**, no
  outstanding review blocker, and strict-main required status checks.
- After merge, record Development `push main` and Pages `push main`
  on **one exact merge SHA**. A green PR preview is not a production deploy.
- No separate physical/media-release/performance PASS is implied by CI.

## Manual 2-PWA acceptance matrix (operator action required)

**Operators:** device A (user account), device B (Anna's account or their
separate local scope); record device model, OS, browser + version, PWA versus
browser tab, exact visible app release/build SHA, time and screenshots **with
personal details redacted**. Never upload personal journals, photos, account
tokens or backup passwords in an issue or test record.

| ID | Device(s) | Test action | Expected result | Current status |
|---|---|---|---|---|
| PWA-01 | A/B | Close, reopen and refresh installed Web PWA after Pages SHA verified | Latest published UI; previous diary/media unaffected | NOT_VERIFIED |
| PWA-02 | A/B | Ricordi > Per te > Le mie Vision Board, open existing board and return | Private gallery renders, layout readable and Back correct | NOT_VERIFIED |
| PWA-03 | A | Create each of six original templates, add photos and text, drag/resize, try collage Template/Grid/Cascade | Photo IDs remain valid, controls usable on touch, no overflow | NOT_VERIFIED |
| PWA-04 | A | Add/delete page, Undo/Redo, resize text/image, close with dirty state | Expected history; discard dialog; draft not saved if discarded | NOT_VERIFIED |
| PWA-05 | A | Import photograph, discard without Save, reopen; also save and reopen | No phantom board/photo; committed photo survives refresh and media cleanup | NOT_VERIFIED |
| PWA-06 | A/B | Switch A→B→A while gallery/picker/editor or Trash confirmation is open | Stale edit/delete rejected; no private data crosses profiles | NOT_VERIFIED |
| PWA-07 | A/B | Switch content filter All→Shared only→All without closing Gallery | Personal board hidden immediately, restored on private mode | NOT_VERIFIED |
| PWA-08 | A | Link a valid personal diary block, delete/restore board via canonical Trash | Valid links only; media and links retained on recovery | NOT_VERIFIED |
| PWA-09 | A→new controlled device | Export complete ZIP and JSON, import ZIP on clean isolated profile; compare media hashes and associations | All photos/related IDs preserved; failed/corrupt media refuses misleading export | NOT_VERIFIED |
| PWA-10 | A | Export PNG via operating-system Save picker | PNG opens and contains visible strokes/photos/text, no silent failure | NOT_VERIFIED |
| PWA-11 | A/B | 320, 360, 390 and tablet-width layouts; light/dark, IT/EN/ES/FR/PT | No clipped action, safe area, text overflow or unreadable state | NOT_VERIFIED |
| PWA-12 | A/B | iOS VoiceOver or Android TalkBack; keyboard focus, button names, contrast, reduce motion | Focus order and controls understandable and actionable | NOT_VERIFIED |
| PWA-13 | A/B | Profile actual time to open 20-photo board and save after editing, cold/warm PWA | Report measured p50/p95/peak memory without invented threshold | NOT_MEASURED |
| PWA-14 | A/B | Optional shared-space flow after personal gallery use | No automatic private publishing, shared ACL unchanged | NOT_VERIFIED |

**Deferral:** offline PWA read/write and native APK/Play are
`DEFERRED_BY_USER` and `OUT_OF_SCOPE`, not PASS or FAIL.
**No PDF Vision Board editor/export introduced:** current existing Sketchbook
exposes a page PNG export. Full PDF board export would be a separately
admitted product feature, not an implicit S11-E requirement.

## Triage and QA release policy

- If any PWA-06/07/09 scope or data-integrity case fails, mark **P1 BLOCKER**,
  reproduce in a synthetic fixture and fix through a new protected PR; never
  mark manually verified based on the Flutter suite alone.
- If PWA-03/04/11/12 fails on an actual screen, capture width, OS/browser,
  tool mode, minimal reproduction and severity; don't include private images.
- When a manual case passes, update this matrix with tester, hardware,
  date, exact SHA and safe evidence. Do not fill in PASS based on anticipation.
- The resulting status after source merge is **SOURCE_IMPLEMENTED +
  CI_VERIFIED + PAGES_VERIFIED** only if exact runs succeeded, while physical
  cases remain **MANUAL_QA_PENDING**.

## Reuse / donor / Golden disposition

The S11-E race defense is a local implementation adaptation around the
existing MediaAssetStore and CAP-0160 scope guards. It does **not** promote
the Draft Infinite Canvas/Ink Golden or create an unproven Golden contract.
A reusable media-draft lease capability for Notes-Ecosistema may be proposed
only after independent donor licensing, account-isolation and cross-app
acceptance; the current implementation is a candidate, not certified donor.
