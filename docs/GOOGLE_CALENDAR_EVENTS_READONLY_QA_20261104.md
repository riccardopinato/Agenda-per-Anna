# Anna's Diary — Google Calendar events, read-only source integration

Status: source candidate in draft PR #199; staging-only UI activated exclusively by ANNA_GCAL_STAGING_QA=true; NOT a production feature or release.

## Source-of-truth and product scope

App Factory baseline: riccardopinato/App-Factory-Core@e6bfa7e395d07d6856cd99b195f5b8eeb50ce18e (Master v27, Golden Index v28, Registry v2, Google Auth Supabase Flutter v1).

Product Bible: external calendar integration is read-only and privacy/ownership rules prevail. Existing Android Calendar Provider overlay, optional B3 Android sync, shared-space data, backups and production Supabase are untouched.

## Functional slice

1. The staging OAuth link was independently proven through real physical consent, confirm, calendar list, process restart and unlink.
2. Owner-only event reading: authenticated POST /events on the existing isolated staging Edge function. Requires production app identity JWT, account-scoped per-minute quota 6, exact Google subject + server-stored encrypted token, confirmed calendar ownership (calendar.events.owned).
3. Backend uses GET Google Calendar API events.list, explicit RFC3339 UTC from/until, 32-day maximum range, 60-event page, singleEvents=true, time order, cancelled excluded and bounded 64 KiB response. Recurrence instances, all-day exclusive end and event IDs are preserved. If Google returns nextPageToken, the response says truncated=true; no claim of complete coverage and no unbounded pagination.
4. On-device page available from Calendar and Settings ONLY in a QA build. User selects saved Google account, owned calendar, month and explicitly taps Leggi eventi del mese. Reader calendars are excluded with explanatory text.
5. Read-only comparison runs ON DEVICE against private canonical AgendaItem appointments and the first line of ordinary DayJournal notes. Same normalized title+day -> possible correspondence. Time within 15 minutes -> stronger suggestion. Multiple matches marked ambiguous. Source calendar ID + event ID remain separate from local canonical IDs. Nothing is automatically imported, linked or persisted.
6. Android calendar overlay remains separate; no duplicate source merge is done silently.

## Privacy and safety

- Server returns ONLY event ID, title, normalized start/end, recurring/iCal source IDs. No attendees, descriptions, locations, guests, Google tokens, authorization codes or raw provider responses.
- Flutter keeps a temporary view model; it is discarded on navigation/restart. No storage or backup of Google event content.
- Diary text remains local, never uploaded to Google or Supabase for matching.
- HTTPS backend verifies existing production app session JWT. JWTs are never in URLs.
- Staging-only database rate budget migration; no table for imported events.
- Production Supabase ref pxsxlorntswypdbeerzw is not a write target.
- All event operations against Google are GET. No mutation API is present.

## Acceptance gates

- Node: owner-only authorization, range bounds, safe parsing, all-day and recurring, fail-closed errors, no writes, identity/rate budget gate.
- Flutter: parser, transport, deterministic matching, ambiguity, QA analyze/test and signed ARM64 build.
- Staging: migration and RLS checks before deploying new Edge code.
- Physical: reconnect test account (last QA check unlinked it), select owned personal calendar, preview a chosen month, compare with one known local appointment, confirm holiday reader calendar excluded; ensure no auto-import or Google event modification.
- Pagination limitation is explicitly shown in UI.

## Deferred (requires separate approvals, privacy and B3 dedupe review)

Persistent confirmed source-reference linking, non-owner event read consent/scopes, background and paginated event synchronization, cross-provider dedupe, conflict resolution, event creation/update/deletion, broader multi-device and refresh lifecycle QA. No production merge solely from this source slice.
