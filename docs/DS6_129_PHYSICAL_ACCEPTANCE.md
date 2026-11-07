# Anna's Diary — DS6 +129 Android physical acceptance and release gate

Status: **CHECKLIST PREPARED — PHYSICAL QA NOT VERIFIED**.
Factory baseline: `App-Factory-Core@3481a8190a5db5965bb22f84832094268d05be98` (Master v27, Golden Index v28).
Product contract: `docs/DS6_PREMIUM_EDITORIAL_10_10_20261107.md` (all ten user-approved designs).
Source predecessor: `1.0.0-rc.6+128 @01151f379ebd9669c3936058aa089433a05a63ae`.
Target (only after all DS6 source PRs merged and gates green): **`1.0.0-rc.6+129`**, same package `com.riccardopinato.agenda_per_anna` and same stable signing identity. A version bump is not itself a tested APK.

## Evidence ladder and mandatory exact-head links

Fill these from actual GitHub Actions output. Do not substitute prior-release evidence.

- Integrated main commit SHA: NOT VERIFIED
- Flutter analyze + complete test run ID/conclusion: NOT VERIFIED
- Web build/deploy run ID/conclusion: NOT VERIFIED
- AppLab Source Gate run ID/conclusion: NOT VERIFIED
- Auto-signed ARM64 workflow run and source SHA: NOT VERIFIED
- Manifest package/versionCode/versionName: NOT VERIFIED
- Verified +128 release-manifest signing certificate SHA256: `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3` (source +128 manifest, not a check against the installed phone).
- Verify +129 certificate SHA256 equals that +128 manifest fingerprint: NOT VERIFIED
- Verified +128 prior artifact SHA256: `d1fa6b9ba8df521a92114ad5da9bc6fbc6ab51bf971eeee660e0cf05331454cd` (prior stable-signed ZIP manifest).
- Exact +129 APK artifact URL, byte length and SHA256: NOT VERIFIED
- In-place install over +128 and record retention: NOT VERIFIED
- Physical devices/OEM/Android/installer signatures: NOT VERIFIED
- Google Play distribution: NOT AUTHORIZED.

The stable signing workflow runs only from trusted main after successful Development checks with a strictly higher versionCode than the first parent. Do not rebuild with a new keystore or re-sign locally. A PR's CI PASS is not an installable production APK.

## Physical QA matrix (PASS / FAIL / BLOCKED / NOT VERIFIED per line)

### A. Update and identity (P0, one real Android phone)
- [ ] Record original +128 package/cert/visible version; secure an independent backup.
- [ ] Install **the exact stable-signed +129 APK** over the installed +128 package (no uninstall or clear data).
- [ ] Verify app starts correctly, same account/profile, original preferences, same locally saved notes, diaries, photos, reminders, people and calendar events.
- [ ] Verify old Inbox categories and archived category renames persist; backup/restore remains safe.
- [ ] Verify no forced onboarding, no silent account/space switch, no new permission creep.
- [ ] Record `adb shell dumpsys package` versionCode, Android fingerprint, artifact SHA and signer fingerprint where available.

### B. Ten approved DS6 journeys (P0/P1)
- [ ] Oggi Premium hierarchy, real-day values, calendar shortcut and privacy masking.
- [ ] Calendario Month/Week, selected day, agenda markers, Il mio mese / Il mio anno, collapsed 07:00–22:00 timeline and canonical +Crea date/time.
- [ ] Ricordi real photo/voice/note/sketch and **truthful media-free fallback**; Timeline, Map, Collections and year navigation preserve original records.
- [ ] Altro Premium profile, search/Inbox, Vault/Explore, Archive/Backup/Cloud/Settings and conditional sync/storage warnings.
- [ ] Impostazioni 5 palettes, custom HSV square/hue, light/dark/system, delicate/expressive, cancel/no-write, apply/persist and Classic mode.
- [ ] Messaggi shared spaces, message/calendar/photos/shopping/members/passwords, restore cached spaces/offline queued state.
- [ ] +Crea exact original primary 5 and extended 5 in original order, 416ms/544ms/100ms cascade; reduced-motion 0ms equivalent and writers functional.
- [ ] Inbox pin/unpin, create/search, tag creation/12 cap, rename in active+archived and persistent after app process restart; Diary tags unaffected; Archive/Trash, copy/convert still valid.
- [ ] Cassaforte **unchanged**. PIN and biometric, encrypted records, FLAG_SECURE screenshot blocking, lock/resume/restore pass as in +128; no private data in Search.
- [ ] Cerca single visible-title character, longer match evidence, 7 combined kind filters, archived optional, newest/oldest/A–Z with stable tie, OCR refresh and native opens.

### C. Shared-space / QR gate (P0, two **distinct** authenticated phones/accounts)
- [ ] Owner creates or selects a space; code is server-issued, 8 alphanumeric characters, 24h expiry enforced by backend.
- [ ] QR style Tramonto/Giardino/Stelle/Acquerello does not modify token, expiry or quiet zone; each variant scans on real camera, classic QR fallback and manual input.
- [ ] Different authenticated users can join with the same still-valid code without duplicate memberships or lost data.
- [ ] Owner regenerates: older invite revoked/invalid, existing memberships retained; non-owner cannot regenerate.
- [ ] Expired invite rejected by server, including a stale cached client; offline and camera-denied paths show truthful fallback.
- [ ] Switch account/device/restart and verify no cross-account shared-space or secret leakage.

### D. Screens/layout/performance (P1/P2)
- [ ] Small phone ~320–360dp, standard ~390dp, large phone and tablet if supported; portrait; landscape if supported.
- [ ] Text scales 1.0 / 1.3 / 1.6; all five languages IT/EN/ES/FR/PT; long translated strings, TalkBack/semantics.
- [ ] 5 palettes incl dark, custom HSV, no hardcoded rose; min interactive 48dp; SafeArea, gesture/3-button bars and keyboard visible.
- [ ] Classic/Hybrid toggle reversible; low-motion OS preference honored; no overflow, hidden controls, animation jank or fake demo content.
- [ ] Offline writes + retry/reconnect queues, memory/CPU usage, source images original media, APK size vs +128.

## Strict exclusion / failure handling

- No source change inside `lib/src/screens/private_vault.dart`, no migrations for visual polish, no new cloud/AI/billing/advertising or forced account sign-in.
- Reject any build that changes package, signer, Vault handling, IDs, sync membership or backed-up records.
- `SOURCE MERGED != CI GREEN != APK SIGNED != PHYSICAL QA != STORE READY`.
- Mark every physical test NOT VERIFIED until a user/device actually runs it; never convert test simulator/Web PASS to physical PASS.
- Play publication is out of scope; delivering a signed APK for user installation is separate from Play rollout.
