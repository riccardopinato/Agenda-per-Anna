# Google Calendar → Anna's Diary — Phase R1 (read-only provider + diary correspondence)

Updated: 2026-11-04
Factory baseline: riccardopinato/App-Factory-Core@8052b45b771bf3c5694fc6dd8d037bd83233b37a (Master v27, Index v28)
Starting Anna main: ab5360b78187a643e2b101be21e6951441406059

## Product contract

The existing Android calendar-provider reader (`ExternalCalendarService`) is
currently the only live external source used by this phase. If an account's
Google Calendar is synchronized in Android and the user grants calendar
access, its events can be projected into Today / Calendar / Unified Agenda.

**Do not call this Google Calendar Direct API integration.** Direct access on
Web/PWA/iPhone requires the separate, reviewed OAuth provider integration in
staging PR #199. That PR remains DRAFT / LOCKED. It is not a dependency imported
into this source PR; no token, Google Cloud redirect, consent screen or API call
is activated here.

## User flow

1. User enables external-calendar display and chooses device calendars in
   existing Settings; no new automatic provider permission is requested.
2. External events appear as read-only projections alongside canonical
   appointments. Existing provider error and permissions indicators remain.
3. Opening an external event shows:
   - its source/calendar and read-only disclosure;
   - **already linked** if a diary note with the stable source-occurrence ID
     exists in the account-scoped DayJournal;
   - **review possible matches** if other notes on the event's day include the
     normalized title; these are only heuristic candidates;
   - **not linked**, **in Trash**, or **unavailable for future/today**.
4. For a past event, **Create diary memory** opens a *user-editable* draft.
   Potential matches prompt for review before opening the draft.
5. Only explicit Save creates/updates one ordinary private `DiaryBlock`
   through the existing `AgendaStore.saveJournal` path. Reopening edits that
   same ID rather than making another linked memory.

## Data guarantees

- The external event is never copied to canonical appointments automatically.
- No automatic diary import, no automatic writing to device/Google calendars.
- No separate link database, provider token, background sync or schema migration.
- No automatic fuzzy linking, merging, deletion or overwrite of unrelated notes.
- Stable link key derives from calendar ID and a timezone-independent
  provider occurrence key (Android event ID + original UTC milliseconds).
  The original diary day is retained if the device timezone later moves
  the same event into another civil day. Provider IDs can still change
  after account/provider migration; same-title matches are review warnings,
  never verified links or automatic mergers.
- Account scope must be ready and unchanged before save. An existing Trash
  entry blocks silently recreating a recoverable memory/day.
- Existing DayJournal blocks remain intact. No Vault, Noi, attachments or
  other account data are part of correspondence lookup.
- On a failed local save the draft editor reopens so the user can copy/retry.
- The Android B3 outgoing writer already present in the product is unchanged:
  this phase neither enables it nor grants write permission.
- External event descriptions may be sensitive; the user explicitly reviews
  the draft before deciding to store it in Anna's private diary and its normal
  optional backup/sync lifecycle.

## Test plan / evidence ladder

Automatic source tests cover: no silent import, past-only eligibility,
unlinked/review/linked distinctions, deterministic per-calendar/occurrence IDs,
same-event update idempotency, account mismatch, preservation of unrelated
notes, blank text, and stripping Android export markers from diary drafts.

To validate **physical/provider behavior**, still test on Android with a real
synced Google calendar: permission granted/denied; multiple selected calendars;
all-day and overnight recurring occurrences; source event edited/deleted
after showing; privacy masking and app/account switching; local offline
capture; uninstall/reinstall/backups and Trash restoration. Do not claim
this gate is PASS from unit tests alone.

## Deferred R2: Google Calendar Direct read

On an expressly authorized, controlled staging setup: complete and security-
review the two-phase OAuth bridge from PR #199; obtain verified account
consent; use read-only scopes appropriate to direct event enumeration; add a
server/provider adapter and account-scoped lifecycle with pagination,
rate-limit, refresh/revoke, stale-read and privacy treatment; map provider
identity to the existing `ExternalCalendarEvent` projection without storing
remote events as canonical journal data. Keep missing/expired consent
fail-closed and disclose when Web/PWA has no provider.

## Deferred W1: outbound sync (separate authorization)

Only after read QA and consent may a different change implement explicit
Anna→Google writes, with preview/dry run, stable ownership/ETag, idempotent
create/retry, conflict review, rate limits, deletion semantics, duplicate
inventory with legacy Android B3 writer, recovery and independently gated
physical tests. No silent bidirectional sync or remote-triggered diary delete.

PR #199 staging security and Privacy #215 review remain separate independent
gates. Never merge or release them implicitly as part of R1.
