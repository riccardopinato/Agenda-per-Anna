# Anna's Diary — v1.00-D4 Functional Completion Audit

Baseline audited: `main @ 152c528619f2f67d28f62408fff16447224c4579` after v1.00-D3.

Factory baseline: App-Factory-Core `a4a97ca`, Master v25.1, with the current Flutter localization Golden already applied by D3.

## Purpose

D4 is a product-reality audit. It does not add a new domain, database, sync engine or feature family.

The audit checks whether the user-facing product promised by `docs/PRODUCT_BIBLE.md` is actually reachable and wired end to end:

`entry point -> UI -> canonical domain/store -> persistence/lifecycle -> service boundary -> regression/runtime evidence`.

Classification:

- **COMPLETE** — implementation is reachable and follows the canonical ownership path with meaningful automated evidence.
- **PARTIAL** — implementation exists, but an explicitly required runtime/physical/distribution proof or user path is incomplete.
- **MOCK** — user-facing behavior is simulated or placeholder-only.
- **BROKEN** — shipped behavior contradicts the product contract or a required path cannot work as specified.
- **DUPLICATE** — competing canonical implementations/stores exist for the same product responsibility.
- **NOT CONNECTED** — code/integration exists or is registered but is intentionally not connected to the product flow yet.

## Executive verdict

**v1.00 is NOT FUNCTIONALLY COMPLETE yet.**

There is one confirmed P0 functional blocker:

> Ordinary local/offline use is architecturally implemented in `AgendaStore`, but is not reachable from the normal application entry flow because `AgendaRoot` requires a signed-in cloud session and `UniversalIdentityScreen` provides no guest/offline continuation.

This violates the canonical Product Bible contract that ordinary personal content is local-first, cloud services are optional, and login/network loss must not block access to local content already owned by the user.

No second Life Core, Memory store, Search implementation, Capture database or Privacy store was found. No user-facing MOCK implementation was confirmed in the canonical core.

## Functional completion matrix

| Product area | Status | Evidence / finding | Required action |
| --- | --- | --- | --- |
| App entry / optional identity / guest mode | **BROKEN — P0** | `AgendaRoot` returns `UniversalIdentityScreen` whenever `cloud.signedIn == false`. The identity screen exposes Google and legacy email/account navigation but no offline/guest continuation. | D5 must restore an explicit local-first entry path and regression-test it. |
| Guest working set | **NOT CONNECTED — P0** | `AgendaStore` still owns a real `guest` scope and account deletion/sign-out restores it, but normal app routing immediately returns to mandatory identity. | Connect the existing guest scope; do not invent another local profile system. |
| Home / Month / Week / Today / Year | **COMPLETE** | MainShell uses one four-tab shell; Year is reachable from Home/memories/sketch context; Today is the canonical day projection. | Preserve. |
| Unified Capture | **COMPLETE** | Home/Month/Week/Today/Inbox/external entry points converge on `showUnifiedCapture`; note/voice/photo write to DayJournal/DiaryBlock + MediaAssetStore; task/event/birthday/person delegate to existing domains. | Preserve one-path invariant. |
| Private diary — note/photo/voice/sketch/templates | **COMPLETE** | Canonical DayJournal/DiaryBlock path, MediaAssetStore, Sketchbook, template and lifecycle coverage are present and regression-tested. | Preserve. |
| Memories / Recall / People / Places Lite | **COMPLETE** | Derived memory references and relationship/place projections reuse canonical diary data; no second memory/places database found. | Preserve. |
| Search / Connections | **COMPLETE** | Legacy `SearchScreen` is removed; `PersonalSearchConnectionsScreen` is canonical and connected from Home. | Preserve. |
| Life Archive | **COMPLETE** | Derived projection over diary, agenda, workout and archived Inbox; source domains remain authoritative. | Preserve. |
| Inbox / organization | **COMPLETE** | Reachable from Home/search/capture; existing persistence, archive and Trash semantics retained. | Preserve. |
| Shopping | **COMPLETE** | Reachable through Explore; private/shared implementations reuse existing local/shared lifecycle paths. | Preserve. |
| Workout | **COMPLETE** | Reachable through Explore/day/archive; sessions/plans use existing private lifecycle and backup paths. | Preserve. |
| Birthdays / reminders / recurring life | **COMPLETE** | Reachable from Home, People, Planner and Unified Capture with existing reminder/recurrence infrastructure. | Preserve. |
| Noi ♡ shared agenda / diary / memories / interactions | **COMPLETE implementation; PARTIAL physical evidence** | Shared hub and detail surfaces are reachable; offline queues, permissions and shared memories exist. Physical multi-device behavior remains an external D gate. | Keep implementation; close physical matrix before certification. |
| Private Vault / Password Vault | **COMPLETE implementation; PARTIAL physical evidence** | Vault setup/relock/wrong-password/restart persistence passed AppLab D2. Android Keystore/biometric/FLAG_SECURE still require physical-device evidence. | No parallel vault. Complete D physical matrix. |
| Cycle Tracker | **COMPLETE implementation** | Protected Vault-only domain, deterministic projections, reminders, Premium capability checks and private report are implemented. | Preserve privacy boundary. |
| Backup / restore / snapshots | **COMPLETE implementation; PARTIAL physical evidence** | D3/C code paths and tests cover staging, reference-safe commit and rollback. Real Android document-provider/file-picker matrix remains physical-only evidence. | Complete physical file-provider validation. |
| Open Life Export | **COMPLETE implementation; PARTIAL physical evidence** | Markdown/JSON/media/sketch export exists on canonical data with exclusions. Physical file delivery remains a D gate. | Complete physical export validation. |
| Cloud sync / account / account deletion | **PARTIAL** | Sync/account/data-rights implementation exists, but the optional-cloud contract is broken at app entry by mandatory identity. | Repair entry routing; preserve current account isolation/sync queues. |
| Notifications / widget / launcher shortcuts / share target | **COMPLETE implementation; PARTIAL physical evidence** | Native paths and AppLab/CI contracts exist; real notification delivery/share/shortcut behavior is still listed in D physical evidence. | Complete physical matrix only; no new native subsystem. |
| External calendar overlay | **COMPLETE implementation** | Read-only Android projection with explicit platform boundary; no duplicate calendar store. | Preserve. |
| Localization EN/IT/ES/FR/PT | **COMPLETE** | D3 passed Development, Web, Android size audit and AppLab on one SHA and is merged. | Preserve D3 regression gate. |
| Web/PWA supported flows | **COMPLETE for supported scope** | Web build is a permanent gate; native-only capabilities are explicitly degraded rather than simulated. | Preserve explicit capability messaging. |
| Premium / RevenueCat | **PARTIAL — distribution evidence** | Entitlement service, custom paywall, offering diagnostics and release guardrails exist. Real purchase/restore proof remains Google Play Internal Testing evidence. | Do not fake entitlement proof; close in distribution/store readiness. |
| Life Ecosystem — Anna / Wonderlog | **COMPLETE for certified E1 scope** | Wonderlog ↔ Anna runtime bridge is the certified compatible integration. | Preserve protocol/ownership boundary. |
| Life Ecosystem — Notes / TrailPath / SleepMax / CashMate | **NOT CONNECTED BY DESIGN** | Registry marks these integrations `planned`; no claim of active sync is made. | Leave planned unless separately approved. |
| Duplicate canonical domains | **COMPLETE — none confirmed** | No competing Search, Life Core, Memory DB, Capture DB, Privacy store or alternate backup owner found. | Keep REUSE-FIRST constraint. |
| User-facing mock surfaces | **COMPLETE — none confirmed in audited canonical core** | Planned ecosystem items are labeled planned; QA diagnostics are diagnostics, not simulated production behavior. | Keep status labels truthful. |
| Release/Product Truth | **PARTIAL / pre-release** | Runtime/pubspec/Product Bible remain `0.99.0+109` / v0.99 while v1.00 hardening steps are pre-release. This is acceptable only while 1.0 is explicitly not claimed. Roadmap D1/D2/D3 status had drifted. | Keep 0.99 identity until blockers/certification close; align roadmap and D4 audit now. |

## P0 finding — mandatory identity breaks local-first

### Canonical contract

`docs/PRODUCT_BIBLE.md` requires:

- ordinary personal content to remain usable without a cloud account;
- cloud services to be optional for multi-device sync, Noi ♡, remote push and account operations;
- login or network loss not to block ordinary local content already owned by the user.

### Current routing

`lib/src/app_shell.dart` currently routes:

```dart
if (!cloud.signedIn) {
  return UniversalIdentityScreen(store: store);
}
```

`lib/src/screens/universal_identity.dart` has no guest/offline action. When cloud credentials are absent, the Google button is disabled and the user still cannot enter the local app.

At the same time, `AgendaStore` still implements a `guest` account scope, and sign-out/account-erasure code explicitly restores that guest working set.

Therefore the data architecture supports local-first operation but the product routing does not expose it.

### D5 acceptance target

D5 should repair the existing routing, not create a new identity architecture.

Required behavior:

1. First launch with no cloud configuration can continue to onboarding and the normal local app.
2. A signed-out user can choose **Continue offline / Use on this device**.
3. Guest content persists across process restart.
4. Signing in remains optional and transactionally switches to the cloud account scope.
5. Signing out returns to the existing guest working set instead of trapping the user on identity.
6. Losing network while signed in never blocks already-local personal content.
7. Noi ♡, remote push and cloud-only actions remain clearly account-gated.
8. Guest -> signed-in and signed-in -> guest transitions do not merge or leak account-scoped content implicitly.
9. External Capture/Today launch intents resolve only after the selected guest/account scope is ready.
10. Automated tests cover cold start, no-cloud build, guest restart, sign-in/out isolation and offline signed-in access.

## Evidence-limited items that are not D4 code failures

The following remain explicit evidence gates rather than reasons to rewrite working domains:

- Android document provider/file picker backup and Open Life Export;
- Vault biometric/Keystore/FLAG_SECURE physical behavior;
- Noi ♡ shared-password two-device lifecycle;
- Android share target and launcher shortcuts;
- real Android notification delivery;
- real RevenueCat purchase/restore through Google Play Internal Testing;
- Supabase leaked-password protection external Auth configuration.

These must remain BLOCKED/PENDING at their actual evidence level until physically/distribution verified.

## D4 conclusion

**Audit status: COMPLETE. Product functional-completion verdict: NOT COMPLETE.**

The remediation sequence should start with the single confirmed product-contract blocker rather than adding new features:

- **v1.00-D5 — Optional Identity & Offline Entry Repair** — P0.
- **v1.00-D6 — Functional Regression & Navigation Completion** — end-to-end guest/account/capture/core-surface regression and any secondary reachability defects exposed by D5.
- **v1.00-D7 — Native Physical Evidence Closure** — finish the existing D matrix without changing claims.
- **v1.00-E — Distribution & Store Readiness** — RevenueCat/Play and remaining external production gates.

No release metadata bump to 1.0 is justified by D4 alone.
