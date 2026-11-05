# Anna's Diary — Recovery of approved R3/R4/R5 mockups (5 Nov 2026)

**Scope:** PR #251, merged as `main@1b9ea9513e6d6be920457d7af5d17dea84c55403` after Flutter/Web/AppLab PASS. R3/R4 independent visual smoke: [Actions #42052066982](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42052066982), source-only test ancestor `863d12ed7b1b4b587567dbe153a77fb49844697b`. New signed +126 remains separately gated. Factory baseline: `App-Factory-Core@42ad47a9ebacc55ae901ea55a01a6855e320377d`, Master v27 / Golden Index v28.

**Evidence basis:** audit V2 supplied by the user (`Anna_Diary_Audit_Recupero_Chat_Mockup_2026-11-05_V2.md`); original R1 global-search HTML referenced via the user's Library link; repo contracts `APPROVED_10_MOCKUPS_IMPLEMENTATION_CONTRACT.md`, `V108_MOTION_VISUAL_POLISH_FINAL_DESIGN_CONTRACT.md` and `WEEKLY_REVIEW_10OF10_CONTRACT.md`. Full chat transcripts / inline visual image baselines not fully retrievable here; this ledger does not claim otherwise.

| Audit item | Approved source | Implementation | Acceptance proof |
|---|---|---|---|
| D01 Calendar | 31 Oct 2/10 R4: 07–22 hourly tap | Empty slot and hour label invoke existing item editor with selected date/hh:00, appointment selected; no persistence until explicit editor Save | `test/approved_calendar_more_fidelity_test.dart` source contract, native CI + manual actual tap/save |
| D02 Oggi | 31 Oct 1/10 R3 visually approved: one date + arrows | Embedded Oggi uses one date and prev/next `addCivilDays` (DST-safe); legacy standalone Planner keeps its DateStrip | updated UI5 tests, Maestro selector + round-trip |
| D03 Oggi greeting | 31 Oct 1/10 R3: wish directly below personal greeting | Dynamic `_dailyQuote(day, strings).$2` is AppBar subtitle, duplicate opening card removed only from embedded Oggi | source + physical small/large text review |
| D04 +Crea | 31 Oct 7/10 R5: 416ms sheet, 544ms cascade, 100ms inter-item | `AnnaMotionStagger(captureCascade:true)` and Capture sheet durations restored; Reduce Motion still zero duration; QW2 actions preserved | `test/approved_capture_cascade_test.dart`, CI |
| D05 Inbox | 31 Oct 8/10 R1: pinned 'In evidenza' separate | Read-only grouped list index; pinned/unpinned labels; canonical pin state and tag editor unchanged | pure grouping tests + UI source |
| D06 Search | 31 Oct 10/10 R1: examples/help/reset | Local sample term chips, correct one-letter help, reset chips/archive/order, canonical matcher unchanged; no Vault | `approved_mockup_recovery_r03_test.dart`, search policy tests |
| D07 Fav/shared | Mockup 4/10 exclusive Messages vs QW2 2 Nov optional favorites | Later explicit QW2 override retained, no new permanent More tile; icon switched heart->groups; persisted favorites retained | quick wins tests |
| D08 Visual matrix | 70 screenshot baseline candidates | **NOT VERIFIED**: no user-approved pixel baselines or 70 real device screenshots | requires screenshot review on real renderer |
| D09 Responsive | More 58dp/IME/scale | **NOT VERIFIED**, not silently altered outside this PR | small/large font 1/1.3/1.6, keyboard, 5 locales |
| D10 Search direct hit | existing navigation canonical; not unambiguously approved deep-link for each type | **UNALTERED**, future UX improvement candidate | test exact-hit behavior separately |
| D11 Calendar grid reflow | M07 grid transform | **NOT VERIFIED**, existing AnimatedScale preserved | physical Web/native visual comparison |
| D12 Runtime | QR art, two-account member/owner, notifications, Vault | **NOT VERIFIED**, no cloud or native release changes | requires real devices and acceptance |

## Delivery gates

1. Exact branch SHA: `Development checks` (Flutter analyze + tests + Web release), AppLab Source Gate, Web compile, blocking review threads.
2. Merge only if source gates and review pass, and branch matches current main.
3. Visual QA: baseline frames from approved prototypes and matching app runtime; capture actual, not synthetic screenshots; compare 70-matrix only after frames are present. Do not call CI 'pixel perfect'.
4. Native/physical QA: signed update after a separate monotonic version bump `+126`; no Play launch; user updates in place, no app deletion, no data reset.
5. Privacy: no new database, account/sync owner, or sharing rules. No changes to protected Privacy V2 and Google Direct draft branches.

## Unresolved follow-up

Preserve all earlier approved screen contracts not touched by this PR (10-screen UI5, Weekly Review, QR, Vault). Reconcile any additional full transcript/mockup evidence when accessible. Real visual comparisons cannot be substituted with a source string match.
