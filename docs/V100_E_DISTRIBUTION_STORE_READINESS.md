# Anna's Diary — v1.00-E Distribution & Store Readiness

Status: **COMPLETED — RELEASE-CANDIDATE PREPARATION; external Play/physical gates pending**

Baseline:
- app main before E: `05835127393240292effb1bfe45938c2f4295a61`;
- Factory baseline: App-Factory-Core `fa3c0679de393f1cb13c2fed2be314d1a1269353`, Master v25.1;
- release candidate metadata introduced by E: `1.0.0-rc.1+110`.

## Purpose

v1.00-E turns the hardened 1.0 line into a distribution-ready release candidate.
It does not redefine the product domains and does not relax D7 physical evidence.

## Android / Google Play contract

The generated Android platform is pinned to:
- `compileSdk = 36`;
- `targetSdk = 36`;
- MainActivity `launchMode=singleTop`, compatible with external payment verification flows;
- stable secret-backed release signing;
- Android App Bundle output for Play distribution.

The production release workflow must verify:
- target SDK 36 on the built APK;
- 16 KB ZIP alignment using Android SDK `zipalign -P 16`;
- AAB/APK SHA-256 reports and retained obfuscation symbols.

Current Google Play policy requires new apps and app updates submitted after
31 August 2026 to target Android 16 / API 36 or newer.

## Premium / RevenueCat contract

The existing Premium architecture remains canonical:
- entitlement: `premium`;
- preview OFF in store builds;
- store release requires the RevenueCat Android public SDK key;
- Premium Store QA never bypasses CustomerInfo;
- current Offering must expose Monthly and Lifetime packages before purchase QA is ready.

External distribution proof still requires:
1. signed AAB uploaded to Google Play Internal Testing;
2. products/base plans mapped into RevenueCat;
3. installation from the Play testing link;
4. real tester purchase;
5. entitlement activation;
6. reinstall/account recovery + restore;
7. Lifetime verification with a clean tester/product state.

CI can prove build/configuration readiness, not a real Play transaction.

The Premium Store QA workflow is intentionally **manual and fail-closed** while
`REVENUECAT_ANDROID_API_KEY` is not configured in GitHub Actions. A normal
`main` push must not become red merely because the external Store environment
has not been provisioned yet. When Store QA is requested, the workflow refuses
to build unless stable signing and the RevenueCat Android public SDK key are
all present.

## Privacy / Data Safety

The public Web artifact publishes:
- `privacy.html`;
- `terms.html`;
- `delete-account.html`.

The account-deletion resource opens the Web account-management route
`?account=delete`, allowing an account holder to sign in and execute the same
canonical remote account deletion without reinstalling Android.

`docs/PLAY_STORE_DATA_SAFETY.md` is the operator source for the Play Console
Data Safety form. The form must be kept consistent with the public privacy policy.

## Google Play Health apps policy

Anna's Diary contains health-related functionality even though health is not
the primary product category.

The Play Console Health apps declaration must include:
- **Period Tracking** for the Vault-only Cycle Tracker;
- **Activity and Fitness** for Workout plans/history.

The app already presents localized cycle/fertility warnings that estimates are
not contraception, diagnosis or medical advice. v1.00-E additionally:
- links the public Privacy Policy from the in-app Privacy Center;
- adds the required non-medical-device disclaimer to the Play listing operator
  copy;
- documents the Health apps declaration categories in
  `docs/PLAY_STORE_DATA_SAFETY.md`.

Play Console submission remains a manual/external distribution action.

## Supabase OAuth redirect for Web account deletion

The Google-first deletion flow preserves `?account=delete` through
`CloudSyncService.signInWithGoogle(returnToAccountDeletion: true)` and returns
to:

`https://riccardopinato.github.io/Agenda-per-Anna/?account=delete`

Supabase Auth only honors a `redirectTo` destination that matches the project's
configured Redirect URLs. Before Store Ready, verify that this exact production
URL (or an appropriately scoped production allow-list pattern) is present in
Supabase Auth URL Configuration and execute one real Google OAuth deletion-flow
test. CI cannot inspect or prove the hosted Auth dashboard configuration.

## Supabase external security boundary

The production Supabase project is currently on the **Supabase Free plan**.
Supabase leaked password protection is available on Pro and above, so the
current advisor cannot be cleared on the active plan.

Before Store Ready is claimed, choose one explicitly:
- upgrade Supabase and enable/verify leaked-password protection; or
- revise the Store Ready security requirement with an accepted risk decision.

This does not fabricate a D7 physical PASS.

## D7 relationship

D7 remains blocked until its real-device matrix is complete. Because E changes
the release candidate, final physical certification for a public 1.0 release
must reference the exact final release-candidate APK/manifest, not an older build.

## Automated acceptance criteria

- release metadata is `1.0.0-rc.1+110` and canonical metadata tests agree;
- Android generation pins API 36 and billing-safe launch mode;
- production workflow verifies 16 KB APK ZIP alignment;
- release/store workflows remain fail-closed without signing and RevenueCat config;
- public privacy, terms and account-deletion pages are deployed;
- Web account deletion route reaches the canonical Account & sync screen;
- Data Safety/operator documentation reflects actual app flows;
- Development, Web, Android size audit and AppLab are green on the final PR head.

## External completion criteria

v1.00-E may be merged as release-candidate preparation, but **STORE READY**
cannot be claimed until:
- D7 final physical matrix passes on the final candidate;
- Google Play Internal Testing purchase + restore pass;
- Play Console Data Safety is completed from the operator matrix;
- privacy URL and deletion URL are configured in Play Console;
- Play App Signing/upload-key setup is confirmed;
- Supabase leaked-password warning is resolved or formally accepted under a
  revised release requirement.
