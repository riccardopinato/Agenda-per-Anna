# Google Calendar direct V1 — B3 migration, test and privacy gate

**Only a STAGING design.** No access to a live Google account, no import or delete. The operational writer in main remains Android Calendar Provider B3; it is independent of the dormant direct API staging.

## First-sync dry-run — mandatory

1. Resolve **app account + Google subject + owned calendar ID** and present all three as separate identities. Account/owner/calendar must be confirmed in the UI.
2. Check whether B3 Android export is enabled for the **same Android calendar** and refuse direct writes until it is disabled. Reading another calendar remains allowed.
3. List/diff the **existing Android B3 exports** via its durable `ownerKey` and `[AnnaDiary:...]` marker, intersected with the chosen Google destination by calendar ID and time window. Do not equate those markers with Google API `extendedProperties.private.annasDiarySourceHash`; those are different ownership systems.
4. Build an **offline preview**: candidates from canonical private appointments, already linked API IDs, likely B3 duplicates, title/date/time mismatches, skipped records and unknown/ambiguous matches. Offer user choices `skip existing period` or `manually review matches`; do not silently bulk delete, overwrite, re-create or claim a match.
5. Record an explicit **review receipt** keyed to the exact app identity, selected Google subject/calendar, candidate snapshot/hash and B3 destination; invalidate it if any input changes. A global boolean with no provenance is insufficient for production activation.
6. Only after an explicit, separate consent, preview and provider test may the final adapter invoke the writer. If the network fails after POST, use GET by stable ID and ownership marker before retrying. Stop on 409, 412 or foreign content; never overwrite a user's Google edits.

## Privacy / lifecycle constraints

- Never include shared `Noi ♡`, Vault, passwords, diaries, attachments, notes, tasks or auto-generated content in Google export.
- The **Privacy #215 branch is not integrated**. On any future integration, private `isSensitive` appointments must be excluded (not merely assigned Google visibility=private). For this staging, the activation privacy review is a gate, **not proof of implemented filtering**.
- No calendar content may be included in telemetry or debug logs; no unencrypted Google tokens in local backup or account/preferences.
- Google `visibility=private` does NOT mean encryption. Do not offer E2EE or secure sharing claims.
- Account switch, revocation, restore, Android uninstall/reinstall and token expiry invalidate prior authorizations and previews. Disconnect must not delete the user's Google events automatically.
- Read-only external-calendar overlay is not an authoritative import. Direct Google API sync must never write Google-origin events back into `AgendaStore` silently.

## Tests by evidence level

| Gate | Automated staging requirement | Real proof still missing |
|---|---|---|
| Identity and OAuth | Verify subject mismatch, expired/refused/revoked scopes and account switch fail-closed in mocks | Google OAuth test account / consent callback / refresh |
| Calendar choice | Owner-only list for `calendar.events.owned`; deny writer/reader | Google calendar list under each test account |
| B3 duplicates | B3 enabled, old exports unreviewed or changed calendar all block writes | Android Calendar Provider history + Google destination comparison |
| Data projection | Private appointments only, max 200 next year, valid date, no note/media | Scope/recurrence/sensitivity review on +121 and future privacy |
| Remote API writes | Mock HTTP, idempotency, ETag, conditional PATCH, recovered mapping | Google API test calendar GET/POST/PATCH, 401/403/429 |
| Failure safety | Simulate network loss, retry and foreign remote content; no auto deletion | Airplane mode, process death, concurrent device/account |
| Client security | No secrets in repository, log, backup, SharedPreferences; token ports remain unimplemented | Keystore/Keychain/secure Web session audit |
| Platforms | Analyze + test + Web build in PR, no main imports | Native Android/real browser; iOS not available/certified |

**Activation is blocked until:** user Google Cloud setup + consent, verified provider adapter, secure token ownership/refresh, account identity confirmation, B3 dry-run with recorded review, privacy filter for any sensitive data, and physical/provider QA. Only after explicit approval may a separate integration PR merge; no signed release from #199.
