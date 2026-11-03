# v1.07 — Quick Wins 2 (QW2-01…05)

Approved by user on 2 November 2026. Scope is five source-only,
small Flutter daily-use UX improvements. They reuse the existing app
models, editor, navigation and account gate, without changing the
cloud database, Vault or RevenueCat. This is NOT Privacy PR #200 and
does not promote that draft to a certified state.

| ID | Behaviour | Acceptance / guard |
| --- | --- | --- |
| QW2-01 | After moving an incomplete non-recurring private task to tomorrow, the snackbar offers **Undo**. | The action restores only the date, only if account is unchanged and the full saved serialized item is identical to the post-save snapshot. Modified, missing, recurring or sensitive entries fail closed. |
| QW2-02 | The Inbox item menu offers **Turn into appointment**. | Opens an unsaved prefilled draft in canonical `openItemEditor`; cancel leaves Inbox alone. The existing Inbox item is deleted only after successful event write and if account and source text are unchanged. |
| QW2-03 | Central **Crea** initially offers four actions; they are subsequently ordered by deliberate user selections. | Stable sorting, all ten actions remain accessible in More; date-specific captions follow date picker. Only action-key counts (no content) are stored in local UI prefs scoped to the current account. |
| QW2-04 | **Altro** contains an optional strip of at most three favorites. | Chooser offers only enabled, ordinary destinations already reachable via Explore. Vault and Cycle are not offered as quick shortcuts. Local account-scoped preferences; disabling a module removes it from visible favorites. |
| QW2-05 | Search in **Impostazioni** opens the existing setting destinations. | Filters on localized labels and functional synonyms for notifications, privacy, colors, backup and sync; empty query preserves the existing editorial layout. No new settings routes or persistence. |

## Validation

- `test/v107_quick_wins2_test.dart`: stable ranking, 3-favorite constraints, locally scoped choice count, EN/IT/ES/FR/PT labels, source integration checks and settings search widget.
- Existing `test/v107_quick_wins_test.dart` and full Flutter tests must remain green.
- Development/Web/AppLab checks must pass on the **exact** PR head before merge; newly added action count is a click-selection heuristic, not a telemetry service or analytics history.
- No automatic Android release, no Play distribution and no asserted real-device acceptance. The current signed APK +120 is older than this source.
- Sensitive entries in draft PR #200 must stay protected; QW2 does not modify the privacy schema or merge the draft. New APK requires higher `versionCode` and distinct release gates.
