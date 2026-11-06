# Anna's Diary — DS6 Premium Editorial (10/10 APPROVED)

Status: **USER-APPROVED DESIGN; IMPLEMENTATION IN PROGRESS**. This file does not certify a signed APK, a merged PR, physical-device validation, or Play distribution.

Factory baseline: `riccardopinato/App-Factory-Core@3481a8190a5db5965bb22f84832094268d05be98` — CURRENT Master v27 / Golden Index v28.
App starting source: `riccardopinato/Agenda-per-Anna@01151f379ebd9669c3936058aa089433a05a63ae`, `1.0.0-rc.6+128`.
Product authority: `docs/PRODUCT_BIBLE.md`; previous ten-screen contract: `docs/APPROVED_10_MOCKUPS_IMPLEMENTATION_CONTRACT.md`. DS6 represents a **subsequent visual premium pass**, not a replacement for the earlier contract.

## Frozen DS6 decision ledger

Every item below was explicitly APPROVED in Chat, 6–7 November 2026; 0 rejected, 0 undecided.

1. **Oggi Premium Editorial:** Lora/Manrope hierarchy, quieter hero, structured day content and quick actions; original data, navigation, privacy masking and reversible Classic/Hybrid.
2. **Calendario Editorial Notebook Premium:** Month/Week, day markers, agenda, Il mio mese/Il mio anno, original date editor, initially collapsed 07:00–22:00 timeline.
3. **Ricordi Editorial Album Premium:** genuine media or truthful text-only fallback, anniversary, timeline, year chips, collections/map, original references.
4. **Altro Premium Personal Hub:** profile context plus quick Search/Inbox, personal Vault/Explore, archive/backup/cloud/settings; maintain ALL reachable routes and status truth.
5. **Impostazioni iOS Essenziale Premium:** 5 existing color palettes, HSV 2D/Hue, light/dark/system, delicate/expressive; reuse existing appearance owner and settings paths.
6. **Editorial Together Premium:** existing messages, space/calendar/photos/shopping/members/shared-passwords; server-owned 8-character/24h invite, same-code QR with 4 local styles, manual fallback and owner-only regenerate; genuine camera and two-device QA required.
7. **Crea Motion Premium:** exact original primary/expanded action order and writer, 416ms sheet, 544ms action, 100ms cascade TOP→BOTTOM, micro-bounce, Reduce Motion and selected calendar day preserved.
8. **Inbox Premium Notes Studio:** pinned/ordinary/archived/trash, filter/search/copy/convert/capture, user-owned multi-tag categories up to 12 per note, atomic rename in active/archived/trash, Diario tags untouched.
9. **Privacy First:** private Vault **NO REDESIGN**; route linkage only, no changes to biometric/PIN, AES-GCM, FLAG_SECURE, records, recovery, keystore or navigation inside Vault.
10. **Cerca e collega Premium:** derived global search, combined type filters, include archive, single-character visible title only, longer queries show truthful match evidence when not visible in title; newest/oldest/A–Z stable; never index Vault.

## Reuse-first audit on +128

| Item | Pre-existing source | DS6 remaining |
| --- | --- | --- |
| 1–3 | `editorial_hybrid_design.dart`, `editorial_today_home.dart`, `editorial_calendar.dart`, `diary/editorial_memories.dart` | Premium visual hierarchy, truthful/accessible polish |
| 4–5 | Existing More/SettingsHub/AppearanceColorsScreen, single ColorScheme and local mode | Editorial groups and discoverability, never duplicate persistence |
| 6 | `screens/shared_space.dart`, `shared_invite_qr.dart` | Style polish, verify backend join/expiry/ACL physically |
| 7 | `unified_capture.dart` and `motion_v108.dart` already contain exact timings | Avoid duplicate animation; visual review only |
| 8 | Inbox UI, `setInboxTags`, `renameInboxTag` | Editorial treatment and robust persistence/restore/identity QA |
| 9 | `screens/private_vault.dart` | **No source edits allowed** except verified original routing outside Vault |
| 10 | `approved_search_policy.dart` already owns one-char filter, match evidence and sorting | Result presentation and match-evidence tests |

## Implementation sequence / stage gates

- **S1 (P0):** freeze contract and source baseline, shared palette-driven premium primitives, tests; bounded PR and exact-head checks.
- **S2 (P1):** home/calendar/memories presentation-only PR(s). Preserve Classic and original selected-date/media ownership.
- **S3 (P1/P2):** More/Settings/Shared visual-only PR(s); privacy boundary stays unchanged. Verify QR on two distinct real devices later.
- **S4 (P1):** Inbox/Search visual treatment and tests. Motion existing spec first: only implement proven missing delta.
- **S5 (P0):** exact-head Flutter analyze/test/Web, AppLab Source Gate, review and merge checks; then if eligible an incremented +129 signed candidate via trusted-main release workflow; collect artifact SHA-256 and cert fingerprint. Physical in-place update over +128, two-device QR, Vault security, offline, account-switch, screenshots and all 5 languages remain **NOT VERIFIED** until performed.

## Mandatory safety / acceptance

No schema, UUID, sync, storage, cloud, account, protected data, router, signature or media migrations for a visual-only change. No fake user content or placeholder photo reaches production. All visible changes localized for IT/EN/ES/FR/PT, keyboard/safe-area/text scale/light/dark/system/HSV/Reduce Motion supported, >=48dp accessible targets. Maintain `main` protection, exact-head CI and AppLab source gate; physical/runtime/distribution gates remain separately labelled. No Play publication in this roadmap. **Do not claim DS6 fully delivered from a merged source commit alone.**
