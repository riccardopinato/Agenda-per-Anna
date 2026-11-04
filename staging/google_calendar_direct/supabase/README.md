# Anna's Diary — Supabase Google Calendar STAGING

## STAGING VERIFIED DEPLOY — 04/11/2026 (AUTHORITATIVE STATUS)

- Project: `anna-calendar-staging` `pdanpljacyozslrutsor` only. The 10-module backend candidate was **DEPLOYED as Edge Function version 6** from GitHub source `374b5ecb5975eb2c280e54ca97e12e7f96e95693`, entrypoint `index_ready.mjs`, `verify_jwt=false` for the browser callback.
- Deployment identity: `ezbr_sha256=ca73ce888dea0ebc391b6817318d768adadfb0af580250ede2690d52d3864633`. Runtime version and dual-gate source were retrieved again through Supabase.
- Live consent requires **BOTH** `ANNA_GCAL_STAGING_ENABLE=approved-for-live-oauth-testing` and `ANNA_GCAL_STAGING_LIVE_APPROVED_20261104=owner-authorized-google-consent`. The second variable was **never set by ChatGPT**, and the owner has not confirmed setting it; thus, **NO LIVE GOOGLE OAUTH is authorized or verified**.
- Local GitHub Actions Deno preflight tested a locked server, including first flag ON/second flag OFF, and validated health/503. The public Supabase HTTPS URL was **NOT reachable for direct HTTP verification from the available environment**, so external runtime smoke is **NOT VERIFIED**. Supabase reports function ACTIVE v6, which is deploy-state evidence, not an external request result.
- `gcal_stage.oauth_pending`, `oauth_completions`, `oauth_links`, both budget tables all remain at **0 rows**. Production project `pxsxlorntswypdbeerzw` was not modified.
- Flutter staging-only two-phase client, HTTP transport, review/confirmation panel and tests are on PR #199. **Not imported by production routes; no Android signed QA APK or real user session/browser completion**.
- To finish a real provider/Flutter test, a human must register the exact redirect URI in Google Cloud TEST, operate tester consent and verify the real device/browser session. Never paste secrets, provider tokens, authorization codes or app JWTs in ChatGPT.

**Historical sections below reflect their 03/11 or earlier 04/11 snapshots; this latest status supersedes statements that the deployed function is only the original v1/v5 placeholder.**


**Status 03/11/2026:** Supabase project is live; the OAuth Edge Function is
intentionally **LOCKED**. No real Google OAuth flow or Calendar API access.

## Deployed resources (test project only)

- Organization: `fzieziuyodhojemtzeya` (Supabase Free, quoted 0 USD/month).
- Supabase staging project: `anna-calendar-staging`, ref `pdanpljacyozslrutsor`, region `eu-central-1`.
- Production `agenda-per-anna`, ref `pxsxlorntswypdbeerzw`, is a different project and was not modified.
- Applied migration: `gcal_staging_private_oauth_store_v1` (source in `migrations/`).
- Private `gcal_stage.oauth_pending`, `gcal_stage.oauth_completions`, and `gcal_stage.oauth_links` tables:
  no anon/authenticated grants; RLS enabled; zero rows at latest check.
  An INFO advisor finding (`rls_enabled_no_policy`) is intentional
  for these private backend-only tables, **not** approval to expose them.
- Deployed Supabase Edge Function `gcal-oauth-callback` **v1, ACTIVE**.
- Actual HTTPS base:
  `https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback`.
- `verify_jwt=false` on this function only: required for a future Google
  browser callback. The deployed code **never** exchanges a code or reads
  tokens and always returns 503 except its locked health response. Its public
  availability is not equivalent to OAuth readiness.
- 04/11/2026: owner confirmed entry of four named staging Edge Function Secrets directly in Supabase; secret presence, value correctness and runtime injection were NOT independently verified. No real OAuth is active.

## Source implementation (not deployed or connected)

- `functions/gcal-oauth-callback/webcrypto_core.mjs` ports critical backend
  cryptographic primitives from Node to browser-standard WebCrypto usable in
  Supabase Edge/Deno: PKCE, state/nonce, AES-GCM envelope, Google JWKS RSA
  signature verification, OIDC claims, least-privilege Calendar scope checks,
  and fail-closed transaction broker.
- `webcrypto_core.test.mjs` runs mock-only Node 22 WebCrypto tests.
- `db_ports.mjs` supplies source-only, injected SQL Postgres ports:
  encrypted `INSERT ... ON CONFLICT`, atomic `DELETE ... RETURNING` for
  one-time OAuth state, and encrypted link upsert in private `gcal_stage`.
  `db_ports.test.mjs` verifies SQL shapes and input validation.
  **No database client or credentials are connected in the deployed Function.**
- Current `index.ts` is **a kill-switch**, not a live adapter. It deliberately
  does NOT import or call `webcrypto_core.mjs`.
- `functions/gcal-oauth-callback` must not be deployed with the broker
  enabled until the remaining integration gates are implemented and audited.

## Selected source contract — two-phase OAuth, no cross-site cookie dependency

The active design is documented in [TWO_PHASE_OAUTH_CONTRACT.md](TWO_PHASE_OAUTH_CONTRACT.md).
The older experimental `GcalStageBroker` remains mock-only and must not be
deployed or mixed with this server-owned implementation.

- `two_phase_core.mjs`: app-authenticated start, single-use Google callback,
  encrypted pending consent, app-authenticated preview and explicit confirmation.
- `production_identity.mjs`: verifies an existing production Supabase JWT
  with the **read-only production Auth /user endpoint**, never with a
  user-provided account ID, and never connects to the production database.
- `confirmation_ports.mjs`: backend-only atomic scoped completion persistence.
- `migrations/gcal_staging_two_phase_completion_v1.sql`: applied on
  `pdanpljacyozslrutsor` only, with RLS enabled and no client grants.
- `two_phase_core.test.mjs`: mock-only security and account-switch tests.

The deployed Edge Function remains the original **503 kill-switch**, and the
new two-phase implementation has **no user-facing live endpoints yet**.

## Reviewed, NOT deployed: Deno runtime bootstrap and HTTP host

- `functions/gcal-oauth-callback/http_handler.mjs`: HTTP `start`,
  `preview`, `confirm` and browser `callback`, with production Supabase
  session verification on app routes, origin allowlist, bounded JSON requests,
  `no-store` headers and non-leaking HTML callback. Defaults to disabled.
- `functions/gcal-oauth-callback/index_ready.mjs`: source-only
  **activation-gated** Deno bootstrap. Loads a pinned Postgres.js package
  (`npm:postgres@3.4.7`), uses `SUPABASE_DB_URL` with TLS / no prepared
  statements and refuses any database URL that does not belong to
  `pdanpljacyozslrutsor` staging. Verifies real Anna account through the
  existing **read-only production Supabase Auth** endpoint.
- Exact enabling value is `ANNA_GCAL_STAGING_ENABLE=approved-for-live-oauth-testing`,
  deliberately **NOT set** or deployed. The running `index.ts` remains the
  original locked handler; there is NO endpoint for real OAuth yet.
- All required private environment entries, if separately approved later:
  `ANNA_GCAL_STAGING_WEB_CLIENT_ID` (nonsecret),
  `ANNA_GCAL_STAGING_WEB_CLIENT_SECRET` (sensitive),
  `ANNA_GCAL_PRODUCTION_PUBLISHABLE_KEY` (public/legacy anon only),
  `ANNA_GCAL_STAGING_AES256_KEY_BASE64` (32 random bytes, secret).
  `SUPABASE_DB_URL` is supplied by Supabase automatically. The last
  variable must never be enabled until independently tested under exact-head
  CI and explicitly approved.
- Never put environment values, Google credentials, DB passwords or tokens in
  this PR, ChatGPT, Flutter, GitHub Actions logs, screenshots, or the device APK.

**Owner-reported secret entry was performed directly through**
[Supabase Edge Function Secrets](https://supabase.com/dashboard/project/pdanpljacyozslrutsor/functions/secrets)
**but this is NOT approval for real test-account OAuth.** Do not register
Google's redirect until a real callback is actually deployed and verified.

## Blocking gates before live OAuth

1. Complete the two-phase app-to-browser handoff and HTTP routing:
   authenticate start/preview/confirm via a verified Supabase Auth JWT sent in
   the Authorization header, never a URL; Google browser callback uses only
   server-bound one-time state; the app holds an independent private one-time
   completion handle and must explicitly confirm. No third-party cookies.
2. Connect `production_identity.mjs` to a reviewed server-only staging Edge
   HTTP router. Pin the read-only existing production Supabase Auth /user URL
   and use only its **public** publishable/anon key. Never trust a user-supplied
   account ID or unverified JWT claim.
3. Connect and integration-test the source-only Postgres ports to a server-side
   **transaction-pooler** connection using a reviewed Deno PostgreSQL driver;
   configure one connection per instance, no prepared statements and required
   TLS. The SQL schema and injected query adapter exist but are NOT wired to
   the deployed `index.ts`. Complete key rotation, revocation, refresh and
   recovery policy. Never use in-memory state in production.
4. Use a private **staging-only** Edge Function secret store for Google Web
   client ID/secret and the independently generated 256-bit AES encryption
   key. Never transmit secrets in chat, git, browser, APK or screenshots.
5. Implement callback, browser return, connection status and account switch
   gates; handle Google's testing refresh-token lifecycle and browser errors.
6. Update and review privacy policy; resolve Android B3 duplicate inventory
   and owner-only calendar selector. Only then request separate permission
   for real consent/testing using owner+Anna test accounts.
7. A real callback must be deployed and tested **before** registering its
   exact URL in Google Cloud. Do NOT yet register the URL above as OAuth
   Authorized redirect URI merely because its kill-switch is reachable.
8. Never merge PR #199 into `main` or release the APK during staging.

## Verification evidence

- Supabase reported Edge Function `gcal-oauth-callback` version 1 `ACTIVE`
  with `verify_jwt=false`.
- Postgres migration succeeded; subsequent query returned
  `pending_count=0` and `link_count=0`.
- Direct public HTTP smoke test could not be run from the current tool
  environment; treat runtime URL behavior as **NOT VERIFIED** until tested.
- GitHub Actions added to test `webcrypto_core.test.mjs` on the exact PR head.
  CI pass is source evidence only; not an end-to-end provider test.

Official references:
- https://supabase.com/docs/guides/functions
- https://supabase.com/docs/guides/functions/auth
- https://supabase.com/docs/guides/functions/secrets
- https://developers.google.com/identity/protocols/oauth2/web-server
- https://developers.google.com/identity/openid-connect/openid-connect


## 04/11/2026 — source-only authenticated request budgets

- New `request_budget.mjs` and `request_budget.test.mjs`: atomic PostgreSQL per-account/per-action minute quotas, account ID hashed, no caller clock, explicit 429 when exhausted, fail-closed 503 on SQL outage.
- `http_handler.mjs` requires a durable request budget before an enabled router can be constructed. `index_ready.mjs` wires it to the **staging-only** SQL connection. Existing deployed `index.ts` remains unchanged and locked.
- Migration `migrations/gcal_staging_rate_budget_v1.sql` **APPLIED TO STAGING on 04/11/2026** (Supabase history version `20261104002607`). Verified private `gcal_stage.oauth_request_budget`, RLS enabled, zero rows, zero anon/authenticated schema usage and table SELECT rights. Backend still remains dormant; request budget was not exercised through live HTTP.
- This mitigates **authenticated app endpoints only**. Public Google browser callback and unauthenticated ingress require an independent trusted-edge IP/provider rate-limit design; never claim this migration mitigates those flood paths.
- Neither successful CI nor the user's confirmation of 4/4 secret entries proves a live Google consent/callback, token refresh, provider revocation, Cloud redirect, Android connection or privacy/B3 acceptance.


## 04/11/2026 — public OAuth callback budget and mock E2E

- Added `callback_budget.mjs` with a **global 30-per-minute** atomic PostgreSQL quota shared by staging Edge isolates, without trusting spoofable IP/forwarded headers. Syntactic callback shape and URI length are checked before any database call; invalid requests return non-leaking HTML 400, over-quota 429, unavailable budget 503. No Google code is exchanged when the quota denies a request.
- Migration `gcal_staging_callback_budget_v1` **APPLIED ONLY TO STAGING**, Supabase history version `20261104010325`: table `gcal_stage.oauth_callback_budget` present, empty, RLS ON, anon/authenticated have no schema usage/table SELECT rights. Read-only `EXPLAIN` for the atomic UPSERT PASS.
- `index_ready.mjs` source-only bootstrap now requires both authenticated request budget and global callback budget; the deployed `index.ts` remains the unchanged 503 kill-switch.
- Added `oauth_http_integration.test.mjs` to mock the complete two-phase HTTP start/callback/preview/confirm/disconnect path, wrong-account access, replay and local unlink/provider revocation. CI workflow now includes callback budget and this end-to-end mocked test. **On this SHA, CI results must be checked independently**; writing tests to a branch is not proof they passed.
- Global PostgreSQL budget does **NOT** prevent abusive traffic from hitting Edge ingress or DB. Trusted upstream/WAF-level admission protection and Deno runtime/provider/device QA remain open. No redirect, real Google consent, credential verification, active deploy, PR merge or release was performed.
