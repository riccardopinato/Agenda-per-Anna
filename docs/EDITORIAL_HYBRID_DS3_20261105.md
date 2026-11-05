# Anna's Diary — Editorial Hybrid DS3: attached dock and hero-first Home

**Date:** 5 November 2026. **Authorization:** user requested Step 3 and bundled Home refinements with one signed APK.
**Factory:** riccardopinato/App-Factory-Core@42ad47a9ebacc55ae901ea55a01a6855e320377d (Master v27 / Golden Index v28).
**Source base:** main@681aa88c4f0a813a59996877b3227375e5bd5cee (post PR #258).
**Release candidate:** 1.0.0-rc.6+127, package `com.riccardopinato.agenda_per_anna`, unchanged stable signing certificate.

## Changes
- New `AnnaEditorialDockBar`: 4 navigable destinations + 1 reserved center Crea slot, original IDs/order, 48dp min touch targets, Manrope, full-width DS1 dock with SafeArea and existing ColorScheme/HSV; no route ownership.
- `MainShell` uses it only with `AnnaEditorialTodayMode.enabled`; Classic keeps original `NavigationBar`. Tablet `NavigationRail` is unchanged. The ONE original `_centralCreateButton` retains selection/haptic/release animation and `showUnifiedCapture`; an optional presentation-only dock-color surround is added in Editorial mode.
- Existing `PlannerScreen` derived cards are built once: Classic retains review-first order, Editorial moves the journal hero and its two real-data tiles before Weekly Review/Realistic Day. Existing diary, memories, tasks, calendar, rituals, reminders, pinned, privacy and timeline remain.
- PR #258's chip-free Editorial Today and foreground/route-guarded global filter reset remain in place; all other views preserve their content filter controls.
- No schema/account/sync/backup/vault change. No Design Lab #254 merge; no Play publication.

## Validation and installation gate
- Exact head Flutter analyze/full tests/Web, AppLab review checks; protected merge.
- After main checks PASS: existing stable-signed ARM64 workflow on strictly monotonic +127, no ephemeral keystore, verify package/version/cert/manifest/SHA256.
- Phone: install over +126 without uninstalling, switch Classic/Hybrid, check all four tabs, +Crea, back/Calendar, private/shared filters, gesture insets, 320dp/large text/dark/custom palette.
- All on-device visual, update-in-place and data-retention results are **NOT VERIFIED** until actual user test.
