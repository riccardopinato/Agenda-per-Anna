# Anna's Diary — v1.01 A→F Release Truth Evidence

Factory baseline:
- App-Factory-Core: `47c47f49a7b46812e3bd6f1231c3524f2b52b826`
- Master: v26.6
- Golden Index: v18

## Certified merged steps

### v1.01-A — Module Preferences
- reversible Essential / My Life / Complete / Custom;
- legacy profiles default to Complete;
- Cycle -> Vault dependency closure;
- hidden modules do not delete canonical data;
- merged after exact-head 4/4 repository gates.

### v1.01-B — Personalized Onboarding
- fresh-profile-only preset selection;
- preset + onboarding completion commit atomically at completion;
- My Life recommended;
- first useful action reuses Unified Capture;
- existing profiles do not re-enter;
- merged after exact-head 4/4 repository gates.

### v1.01-C — Dynamic Explore & Personalization
- module-aware Explore and optional entry points;
- one Personalize surface;
- manual toggle -> Custom;
- no second preferences/data/router/sync owner;
- merged after exact-head 4/4 repository gates.

### v1.01-D — Adaptive Home & Quiet UX
- stable Home More secondary navigation;
- Search remains direct;
- Inbox / Noi ♡ direct only when attention-worthy;
- healthy cloud/local-only state stays quiet;
- module-aware Home cards without deleting data;
- PR #107 tested head:
  `359f6773bb7e9723b32702d62d4cf484915bb297`;
- Development #1161 PASS;
- Web #725 PASS;
- Android size #675 PASS;
- AppLab #679 PASS;
- squash merge:
  `70160c60116d5dd24e1226e15d8422588cbac86a`.

### v1.01-E — Polish, Accessibility & Regression
- explicit non-duplicated semantics for onboarding/personalization;
- narrow-screen and five-language regression;
- trusted personalization journey Essential -> Custom -> Complete;
- PR #108 tested head:
  `c68273ff08d02dceeea9f8892db3f7644927cd87`;
- Development #1164 PASS;
- Web #728 PASS;
- Android size #677 PASS;
- AppLab #681 PASS;
- squash merge:
  `8eba54222329742f076de1f31260915e6dad8437`.

## v1.01-F — release-truth closure

This step changes documentation/evidence only. It:
- aligns Product Bible, Roadmap and README with the merged v1.01 reality;
- records the new Factory v26.6 baseline;
- fixes the malformed literal `\\n` between v1.00-C and v1.00-D roadmap rows;
- performs a bounded stale-status/duplicate-owner sweep around v1.01;
- does not change runtime version, billing provider, persistence, navigation or user data.

## Evidence ceiling

v1.01 A→E is IMPLEMENTED / TESTED / CI GREEN / TRUSTED RUNTIME VERIFIED under
the repository exact-head gates.

This record does **not** promote:
- v1.00-D7 physical Android evidence;
- RevenueCat/Google Play real purchase/restore;
- Store Ready;
- Anna ↔ Wonderlog pair certification under the new Cross-App Verification v1.

Those remain explicit later gates.
