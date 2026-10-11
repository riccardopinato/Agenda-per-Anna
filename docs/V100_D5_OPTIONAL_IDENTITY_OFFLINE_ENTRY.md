# Anna's Diary — v1.00-D5 Optional Identity & Offline Entry Repair

Baseline: `main @ f6a803426f109f88196c543e4e00ae3dc9a47b21` after v1.00-D4.

Factory baseline: App-Factory-Core `a4a97ca`, Master v25.1. No new domain, account store or persistence architecture is introduced.

## Purpose

D5 closes the P0 identified by the v1.00-D4 Functional Completion Audit: ordinary local-first content must be reachable and usable without requiring a cloud account.

The repair reuses the existing `AgendaStore` guest/account working-set architecture and makes identity optional at app entry.

## Product contract after D5

- A fresh install can choose **Use on this device** and enter the normal onboarding/application without signing in.
- Google sign-in remains available for users who want account-backed sync and Noi ♡.
- Existing email/password access remains available for legacy/existing accounts.
- Guest data persists locally across process restart.
- Guest and authenticated account working sets remain isolated.
- Signing in does not implicitly claim, merge or erase guest content.
- Explicit sign-out switches back to the preserved guest working set.
- A persisted authenticated working set remains locally accessible when cloud initialization, connectivity or session refresh is unavailable.
- Noi ♡ and other genuinely cloud/account-only operations remain account-gated.
- Share target, Life Ecosystem deep links, widget/launcher actions, notification opens and shared push navigation are deferred until an explicit guest/account scope is ready.

## Implementation

### Entry routing

`AgendaRoot` no longer waits for cloud initialization before allowing ordinary local use.

Routing is now:

1. resolve the persisted local working set;
2. if a live authenticated cloud user differs from the active local account, bind that account transactionally;
3. if there is no account and the user has never selected device-only mode, show the identity choice;
4. otherwise open onboarding/MainShell with the already-selected local scope.

The `ANNAS_DIARY_INTEGRATION_TEST` build define no longer bypasses identity routing. It remains available only for deterministic test storage/runtime behavior.

### Device-only selection

`AgendaStore.continueWithoutAccount()` activates the existing guest scope when needed and persists `local_entry_selected_v1`.

No second guest/profile database is created.

### Scope isolation

The historical first-login behavior that could claim an existing guest working set into a newly authenticated account has been removed.

Switching between:

`guest -> user:<id> -> guest`

archives and restores the two profiles independently through the existing transactional account-profile mechanism.

### Offline authenticated use

Startup and resume no longer interpret an unavailable/signed-out cloud client as an implicit user sign-out. If an authenticated account working set was the selected local scope, it remains readable/writable locally until the user explicitly disconnects the account.

Cloud synchronization remains conditional on a live authenticated cloud session.

### Cloud-only surfaces

Noi ♡ remains explicitly account-gated. From guest mode its call to action opens **Account & sync** rather than sending the user back to an app-wide login wall.

### External entry points

External intents wait on `AgendaStore.entryScopeReady` before they can navigate or mutate canonical data. This covers:

- Android/share capture;
- Life Ecosystem inbound links;
- home widget / launcher Capture and Today actions;
- local-notification opens;
- shared push opens and initial Web Push navigation.

This prevents a queued launch action from writing into a guest scope before the user has selected guest vs account.

## Regression coverage

`test/v100d5_optional_identity_offline_entry_test.dart` covers:

- explicit device-only choice on first launch;
- persistence of device-only selection and guest content across restart;
- guest/account non-merging in both directions;
- immediate local availability of a persisted account working set without requiring a live cloud session;
- source-level contract that external entry points are routed through the entry-scope gate;
- AppLab contract that a clean install actually chooses device-only mode instead of bypassing identity.

The AppLab smoke journey starts from clean state, requires the multilingual **Use on this device** action, then continues through onboarding and the existing deep runtime journey. A restart must stay inside the selected local scope.

## Acceptance

D5 is mergeable only when the final PR head has the applicable repository gates green, including Development checks and AppLab Trusted Verify. Web and Android-size workflows remain required when triggered by their path filters.

D5 does not claim physical-device evidence and does not bump release metadata from `0.99.0+109`.

## Result

When merged with all required gates green, the D4 P0 is closed: Anna's Diary is genuinely local-first at entry, cloud identity is optional for ordinary personal use, and account-only capabilities remain explicitly gated.
