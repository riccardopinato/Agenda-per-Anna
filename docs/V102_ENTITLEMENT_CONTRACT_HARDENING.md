# Anna's Diary — v1.02-B Entitlement Contract Hardening

Status: **COMPLETED — merged after 4/4 exact-head gates**

Factory baseline:
- App-Factory-Core `47c47f49a7b46812e3bd6f1231c3524f2b52b826`
- Master v26.6
- Golden Index v18
- `GOLDEN_ENTITLEMENT_CONTRACT_FLUTTER_v1` — COPY-READY provider-agnostic contract

## Goal

Make Premium access state inspectable and provider-agnostic without replacing
RevenueCat or changing the existing product/paywall model.

## Contract

Anna keeps this boundary:

`UI -> PremiumEntitlementService -> RevenueCat adapter -> Store`

Feature modules depend on `PremiumCapability` / `allows(...)`. They do not call
RevenueCat directly and do not own product IDs.

The service now exposes `PremiumEntitlementSnapshot` with:
- access state;
- paid entitlement state;
- provenance;
- provider observation timestamp;
- store-service state.

Provenance is explicit:
- `localDefault`: no paid provider state is configured/observed;
- `providerVerified`: access state came from RevenueCat CustomerInfo;
- `qaOverride`: non-store preview/debug capability only;
- `unknown`: provider/configuration state could not establish an entitlement.

## Offline / unknown policy

Anna does not invent a second subscription grace clock. RevenueCat CustomerInfo
remains the provider authority and its SDK/provider cache owns subscription
lifecycle semantics.

If a transient failure happens after a provider-backed state was already
observed in the running service, Anna preserves that last provider-backed
snapshot rather than deleting user data or silently rewriting Premium-owned
history.

An unknown/unavailable provider never deletes, rewrites or hides user-owned
historical data. Existing FREE diary/agenda/Vault/cycle-core behavior remains
available by Product Bible contract.

## Store / QA truth

`ANNA_PREMIUM_PREVIEW` stays a QA/debug-only mechanism and is surfaced as
`qaOverride`, never as provider verification.

Store release remains fail-closed:
- preview must be OFF;
- RevenueCat public platform key must exist;
- paid access still derives from CustomerInfo entitlement `premium`.

The Premium Store QA report now records entitlement provenance and observation
time, without exposing API keys or raw account identifiers.

## Provider decision

No direct Play Billing migration is introduced. App Factory v26.6 explicitly
separates the generic entitlement contract from the billing provider adapter.
The existing RevenueCat path is retained because there is no evidence-based
reason to replace it.

## Code hygiene

Bounded sweep result:
- RevenueCat `Purchases.*` calls remain confined to
  `lib/premium_entitlement_service.dart`;
- Cycle/UI feature screens remain provider-agnostic;
- no second entitlement service, billing repository or product-limit store was
  introduced;
- no obsolete provider path was found to remove.

## Evidence ceiling

Automated repository gates can establish implementation/test/build/trusted
runtime evidence. They do not prove a real Google Play purchase or restore.

Real Monthly/Lifetime purchase, reinstall and restore remain **v1.02-C —
BLOCKED ON EXTERNAL DISTRIBUTION** until executed from Google Play Internal
Testing on the exact signed candidate.
