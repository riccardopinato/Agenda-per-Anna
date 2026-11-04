# Google Calendar — Two-phase OAuth staging contract (03/11/2026)

**SOURCE ONLY / NOT DEPLOYED.** Current Supabase Edge Function `gcal-oauth-callback` v1 is still a 503 kill-switch. Neither Google Calendar nor the production Supabase database have been contacted. PR #199 stays Draft / DO NOT MERGE.

## Why two-phase instead of cross-site browser cookies

The existing Supabase Auth session belongs to the production app and the new staging endpoint lives on another origin. Third-party cookies would be unreliable on Android external browsers and Flutter Web. The new flow never sends the Supabase JWT, Google tokens or a confirmation handle in a redirect URL. A one-time Google OAuth `state` is in the authorization URL, as required by the protocol. The backend parks a **temporary encrypted grant** on callback, then the already authenticated app must explicitly confirm and consume a second independent one-time handle.

### Proposed HTTP contract (not active yet)

1. **POST `/start`** from an already signed-in Anna's Diary client, over HTTPS with `Authorization: Bearer <Supabase production JWT>`. The backend verifies the JWT by calling the read-only production Supabase Auth `GET /auth/v1/user` endpoint with the production publishable/legacy-anon key. The account ID is derived from the signed response, never user body or an unverified JWT claim. A 10-minute `state`, PKCE verifier, nonce, account hash, and independent 256-bit completion handle are stored encrypted. The caller receives `authorizationUrl`, `handle`, and expiry as an HTTPS JSON response, with `Cache-Control: no-store`. **Only the app keeps the handle in short-lived memory.**
2. The app opens `authorizationUrl` in the system browser. Google shows a separate Calendar consent screen; no automatic elevation of the existing login scopes. The Web client secret stays on the staging server.
3. **GET `/gcal-oauth-callback?code=...&state=...`** is a public **browser** callback, so the gateway must use `verify_jwt=false`; it trusts neither query parameters nor caller identity. It atomically consumes the state from a private table, validates redirect/state/TTL, exchanges the code with PKCE, verifies the ID token using Google JWKS/RS256 and actual granted scopes, and stores a separate encrypted, expiring pending grant. It **does not activate any account link** or expose tokens, Google identity or completion handle in HTML or logs.
4. The app calls authenticated **POST `/preview`** with the handle in a JSON body. It receives only a status plus the Google subject and verified email (when available) for review. The handle remains private. Wrong-account requests cannot see or consume the pending grant.
5. After a specific in-app user confirmation, **POST `/confirm`** with `explicitConfirmation:true` and the handle. The server re-verifies the current production Supabase session, performs an account-bound atomic DELETE RETURNING of the pending grant, encrypts the Google credentials under a separate account+Google-subject context and records the link. Only **then** is consent linked. The result returns no provider token.
6. If the user declines, the session expires or the account changes, the grant is not activated. Explicit disconnection/revocation and token rotation require additional implementations before live authorization.

### Files

- `two_phase_core.mjs`: start → callback → preview → confirm with two independent 256-bit state/handle values.
- `production_identity.mjs`: read-only production Supabase Auth `/user` verifier. Supports a *public* publishable or correctly identified legacy anon key; rejects service-role/secret keys. Only the authenticated user UUID is returned.
- `confirmation_ports.mjs`: encrypted `create`/scoped `read`/account-bound atomic `take` for pending confirmation.
- `migrations/gcal_staging_two_phase_completion_v1.sql`: table `gcal_stage.oauth_completions` with RLS and no anon/authenticated grants; applied **only** to `pdanpljacyozslrutsor`.
- `two_phase_core.test.mjs`: mock-only tests covering no link before confirmation, denied consent, wrong account, replay, expired transactions, verified email and read-only Supabase Auth verification.

### Essential deployment blockers

- A reviewed Deno Edge HTTP router enforcing trusted origin, HTTPS-only POST body, bearer-based production identity, strict no-store response headers, callback CSP/referrer policy, timeouts and size/rate controls. `verify_jwt=false` at the gateway does **not** mean the app endpoints are anonymous.
- Privileged backend connection to the **staging** database, persistent atomic SQL adapters, correct connection pooling and TLS. The tables are intentionally private and inaccessible through the normal Data API.
- Staging-only Google Web client ID/secret, production **public** Supabase API key, and a random 256-bit AES-GCM master key in Supabase Edge Function Secrets. No value is to be sent in chat or stored in GitHub.
- Secure link lifecycle: token refresh/revoke/re-auth, logging redaction, key rotation, account switch and unlink behavior. Google Testing refresh tokens may have a seven-day expiry.
- Staging privacy disclosures, user approval before actual Google consent, B3/duplicate-event inventory and explicit Calendar owner selection. No automatic write, no remote delete.
- Register the exact callback URL on Google Cloud **only after** the real callback implementation is deployed and verified. The existing production redirect `https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback` must not be reused.

The older `webcrypto_core.mjs` `GcalStageBroker` and `oauth_staging.dart` contain an exploratory cookie/client-managed flow. They are **not the selected integration path**; the two-phase server-owned implementation is the current design. Neither flow is imported by the deployed `index.ts`.

Never merge this staging PR into production or enable the direct Google Calendar writer without a separate integration review, user consent, Android B3 duplicate reconciliation and physical QA.
