# Template QA — Anna's Diary gentle rituals + diary gallery

**Baseline:** `main@2c77c764ecf9982817aee8fc6ecc31ee75b741f9` (PR #290/#291 merged); Factory `d4ed1185d36d419228fba6b57a979cde308bd321`. Source QA test only is in an independent PR.

## Automated / source gates

- Existing `test/v104_daily_rituals_test.dart`: default disabled, bounded times, backup restore, idempotent same-day ritual and five-language copy.
- Existing `test/v105x_audit_maintenance_test.dart`: no record before editor save; canceled draft and failed local write must preserve editable content.
- New `test/template_pilot_preview_widget_test.dart`: native gallery → preview → Back → preview → Use in diary, returning one preset only after confirmation.
- Required exact-head Development checks, Web build and UI5/AppLab Source Gate; main-push CI and Pages identity independently verified.

## Manual acceptance — NOT VERIFIED on real browser/phone

| ID | Execution | PASS criteria |
|---|---|---|
| A-01 | With rituals OFF by default, open template gallery | Free originals visible; no auto reminder, no private note created |
| A-02 | Preview Morning, press Back, close editor | Nothing saved |
| A-03 | Preview Evening → Use in diary → Cancel editor | Nothing saved or shared |
| A-04 | Save one edited diary template, reload, export and restore in isolated profile | Same private DiaryBlock, no duplicate or missing media |
| A-05 | Turn on morning ritual and repeat start on same date | Only one `ritual:morning` block, existing one reused |
| A-06 | Deny notifications and toggle reminders; review time zone/DST | No unrequested OS permission, reminders reflect real schedule and OFF state |
| A-07 | Switch A→B→A, then reopen same preview/draft | No stale save or exposure to the wrong account |
| A-08 | 320dp, 2× text, RTL if supported, voice reader; IT/EN/ES/FR/PT | No clipping, understandable buttons, translated preview |
| A-09 | Inspect Vault and Noi ♡ boundaries | No new sharing, Vault read, sync or access from template preview |

**Evidence:** exact SHA, version/build, browser or phone model/OS, account scope (no personal identifiers), scenario ID, observed output, redacted screenshots/logs. Vault remains untouched. Physical hardware, notifications and real two-account QA remain NOT VERIFIED until performed.
