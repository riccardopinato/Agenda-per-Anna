# Anna's Diary — Audit 10/10 approved mock-ups and delivery readiness
Date: 2026-10-31. Evidence: current GitHub main as of merged #170 and #169.
Factory source baseline: App-Factory-Core@632a66dce4aa00e8e1700b0a3e4dfc7ea008197c, CURRENT v27. This ledger is source-evidence only; it is not a physical certification.

## Source-to-approval trace

| Screen | Confirmed in source | Remaining verification |
|---|---|---|
| 1 Oggi / bar | Account name + localized time greeting, existing daily well-wishing, Calendar top-right, Oggi · Messaggi · (+) Crea · Ricordi · Altro (#168) | Live personalization name, Android small-screen navigation and account switch |
| 2 Calendario | Month/week, month/year shortcuts, selected date and 07:00–22:00 collapsed hourly timeline (#167, #168) | Tap routes and selected-day capture on device |
| 3 Ricordi | Real-media editorial For You hero, Timeline, year filters, existing people/places/collections; no invented media (prior UI5) | Photos, memory history gestures and large data on phone |
| 4 Altro | 8 uniform-height direct rows, Shared Space moved to Messages (#167, #168) | Conditional enable/disable modules and reachability |
| 5 Impostazioni | Name shortcut, grouped account/appearance/privacy/Premium/backup, five legacy palettes plus HSV/Hue custom (#167, pre-existing) | Light/dark, custom color persistence, contrast and accessibility |
| 6 Messaggi | Existing server 24h reusable 8-character invite, 4 local QR themes and scanner (#166); **owner can rename existing groups** without changing UUID via migration and UI (#170) | **Mandatory** two separate authenticated users; two reusable joins, QR camera, expiry/regeneration, non-owner rename denial, name sync |
| 7 + Crea | All 10 original actions retained, selected Calendar day; smoother stagger and Reduce Motion preserving non-Crea animations (#164, #169) | Device animation visual QA, rapid tapping and all writers |
| 8 Inbox | Tags derived from notes; rename active/archived, category filters, creation via existing note editor (#163) | **Mandatory** phone: create → rename → filter → restart → archived notes; multi-account isolation |
| 9 Cassaforte privata | Explicit NO REDESIGN; Notes/Passwords/PIN/biometrics/recovery preserved | Existing release-native Vault privacy and lock smoke; do not alter |
| 10 Cerca e collega | Title-only one-letter results; multi-field evidence, 7 kinds, archive and newest/oldest/A–Z (#163) | Search with actual notes/OCR and date sorting on Android |

### Scope distinction
"Rinomina gruppi" is supported for the user-created/shared spaces listed in Messaggi. Private Vault is unchanged: it currently has **Notes** and **Passwords** sections, not a separate group taxonomy. Do not invent or migrate private Vault group data.

## Backend evidence
Project: `agenda-per-anna`, Supabase `pxsxlorntswypdbeerzw`.
Applied `owner_shared_space_rename_v109` with live migration ID `20261031204747`.
Verified read-only metadata: `public.rename_shared_space(uuid,text)` exists; authenticated can execute; anon cannot; public wrapper SECURITY INVOKER; private implementation SECURITY DEFINER with `auth.uid()` owner check and row lock. No user space records were renamed during deployment. A real owner/non-owner interaction remains unverified.

## APK provenance and release boundary
- Already-built signed candidate: `1.0.0-rc.4+113`, source `4fbeb1c94ce6d47cdff04149788b725251653c26`, artifact SHA-256 `a66bd6c37e4d417c099e12273b0345d2e64167fe99c0c30b671429a7607bd1b8`; **does not include #169/#170**. Its evidence level is `ARTIFACT_BUILT`, physical status `PENDING`.
- New source identity reserved by this PR: `1.0.0-rc.5+114` (strictly higher versionCode).
- New APK build, stable signing, device-install-over-old, in-place data and key retention: **NOT YET VERIFIED**.
- Use existing manually triggered `.github/workflows/sideload-arm64.yml`, stable keystore and `annas-diary-light-arm64`; no ad-hoc key, no automatic APK from PR. Check manifest fingerprint against the previous certificate `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3`.

## Release blockers (must all pass)
1. Latest source passes exact-head Flutter analyze/test, Web, AppLab Source Gate and bounded review.
2. Manual stable-signed ARM64 candidate built **from the merged current main SHA** for `rc.5+114`.
3. Validate SHA-256, cert, package, Android permissions and size; no data reset.
4. Android physical Inbox tag create/rename/filter/persist (active and archived).
5. Two-device shared invite and renamed-group sync, including non-owner denial and 24h expiry; QR native scan/decoding.
6. +Crea motion smoothness, Reduced Motion, all 10 actions, navigation (small screens, dark mode) and real memory media.
7. Local Vault unlock/lock/privacy smoke remains intact. Stop release certification if any step fails.

**No Store-ready or physical-certified status is implied by any source PR or GitHub Actions success.**
