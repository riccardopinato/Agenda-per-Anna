# Anna's Diary — Google Play Data Safety operator matrix

This document is an implementation-derived checklist for Play Console. It is
not a substitute for reviewing the final Play Console questions and current
Google policy at submission time.

## Core principle

Anna's Diary is local-first. An account is optional for ordinary private use.
Cloud sync, Noi ♡, remote push and Premium purchase state use external services
only when the corresponding feature is active.

## Data categories and handling

| Area | Data | Local / transmitted | Purpose | Notes |
|---|---|---|---|---|
| Authentication | account UUID, email, display name, avatar when supplied | transmitted to Supabase/provider | login, account isolation, sync | Google-first; legacy email sign-in may exist |
| Private sync | supported agenda/diary/domain records | transmitted to Supabase only when cloud account/sync is used | multi-device sync | ordinary local mode does not require cloud |
| Private media sync | user-selected diary media included by sync | transmitted when synced | multi-device data | no automatic AI analysis service |
| Noi ♡ | shared content and collaboration metadata | transmitted to Supabase | shared spaces | only with explicit shared use |
| Shared passwords | ciphertext + protocol metadata | transmitted to Supabase | E2EE shared credentials | plaintext password is encrypted client-side |
| Push | FCM token / Web Push endpoint + delivery metadata | transmitted to Firebase/Supabase/Web Push infrastructure | notifications | necessary for remote delivery |
| Premium | anonymous technical app-user/install identifier, purchase/entitlement metadata and linked account identifier when available | transmitted to RevenueCat/store in configured Store builds | entitlement check, purchases and restore | RevenueCat may initialize at app startup; no diary/Vault/Cycle content |
| Calendar | device calendar events | local read-only access | optional calendar overlay | not uploaded as canonical Anna data |
| Camera/photos | user-selected/captured photos | local by default; may sync/share by explicit feature | diary/memories | OCR is on-device |
| Microphone/audio | user-recorded voice notes | local by default; may sync by explicit feature | diary | no automatic transcription service |
| Vault | notes/credentials | local encrypted | private storage | excluded from normal sync/search/backup |
| Cycle Tracker | intimate health observations | local encrypted in Vault | private cycle tracking | excluded from normal sync/RevenueCat/analytics |
| Diagnostics | current app does not implement general product analytics | local unless user explicitly copies/shares diagnostics | troubleshooting | do not claim analytics collection that is not shipped |

## Sharing / sale

- No sale of personal data is part of the product contract.
- Service providers process data only for the selected technical function.
- Noi ♡ content is intentionally shared with members authorized by the user.

## Security statements that are supportable

- transport encryption is used for cloud service traffic;
- Supabase authorization/RLS protects account-scoped backend data;
- Vault content is encrypted locally;
- Password Noi ♡ plaintext is encrypted client-side before backend storage;
- backup/export is user initiated.

Do not claim D7 PHYSICAL DEVICE VERIFIED until the physical matrix passes.

## Account and data deletion

In-app:
- Account & sync -> Delete account and data.

Web:
- public `delete-account.html`;
- the page opens `?account=delete` in the Web app;
- the user authenticates and runs the canonical delete-account path.

Local-only users have no cloud account; their local data can be removed in-app
or by clearing/uninstalling the application.

## Health apps declaration

Anna's Diary is in scope for Google Play Health apps policy because it contains:

- **Period Tracking**: menstrual-cycle logging, prediction and fertility-awareness estimates;
- **Activity and Fitness**: workout plans/history and recorded exercise sessions.

Operator action in Play Console:
1. Open **Policy > App content > Health apps**.
2. Declare **Period Tracking**.
3. Declare **Activity and Fitness**.
4. Do not declare Anna's Diary as a regulated medical device under the current product contract.
5. Ensure the store description contains the non-medical-device disclaimer.
6. Keep the Privacy Policy linked both in Play Console and inside the app.
7. Re-review the declaration if future features add medication, disease-management,
   clinical decision support, Health Connect or sensor-based medical functionality.

Cycle/fertility projections are deterministic estimates and the in-app Cycle
Tracker already states that they are not contraception, diagnosis or medical
advice.

## Play Console operator checks before submission

1. Re-read the current Data Safety questionnaire.
2. Reconcile every answer with `legal/privacy.html`.
3. Confirm all third-party SDK data practices for the exact release dependency set.
4. Enter the deployed privacy-policy URL.
5. Enter the deployed account-deletion URL.
6. Confirm account deletion removes associated backend data, not merely disables login.
7. Confirm any retained data and retention reason, if introduced later, is disclosed.
8. Re-run this review whenever Firebase, Supabase, RevenueCat, analytics or ads dependencies change.
