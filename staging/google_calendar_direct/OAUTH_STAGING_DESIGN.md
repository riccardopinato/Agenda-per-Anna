# Google Calendar OAuth STAGING — boundary and next implementation gates

**State (3 November 2026): SOURCE ONLY / DRAFT / NO GOOGLE ACCESS.**

This document records the Google Cloud *test* configuration established by the
owner and the safe boundary for the follow-up app/backend implementation.
It is not evidence that any Google account has consented or that a token was
issued. The existing Supabase authentication and the production OAuth client
remain unchanged.

## Verified by owner screenshots / confirmation

- Google Cloud project display name: `Anna Diary Calendar Test`.
- Intended project ID: `anna-diary-calendar-test` (as shown at creation).
- Google Calendar API: **enabled** on the new project.
- Google Auth Platform: **External / Testing**.
- Two authorized test accounts: owner confirmed self + Anna; addresses must
  never be committed or copied into test fixtures.
- OAuth Data Access:
  - `https://www.googleapis.com/auth/calendar.events.owned`
  - `https://www.googleapis.com/auth/calendar.calendarlist.readonly`
- A **Web application** client labelled `Anna's Diary Calendar STAGING`
  was created. Client secret was saved privately by the owner.
- **No authorized redirect URI is registered yet.** This is intentional until
  an independently deployed staging callback exists.
- Existing production Google OAuth is on `My Maps Project` and configured
  through `agenda-per-anna` Supabase. **Do not replace the production Google
  provider client ID/secret, callback or login scopes.**
- The production project's Calendar API was also enabled during setup; this
  does NOT grant access to any user's calendar.

## Supabase HTTPS staging project provisioned — 03/11/2026

- Project: `anna-calendar-staging`, ref `pdanpljacyozslrutsor`.
- Organization: `fzieziuyodhojemtzeya`, **Free**; Supabase quoted `0 USD/month` before creation.
- Region: `eu-central-1`; status verified `ACTIVE_HEALTHY`.
- Project base URL: `https://pdanpljacyozslrutsor.supabase.co`.
- Existing production ref `pxsxlorntswypdbeerzw` remains an independent active project.
- **Now deployed:** private `gcal_stage.oauth_pending` and `gcal_stage.oauth_links`
  tables (RLS, no anon/authenticated grants, empty), and `gcal-oauth-callback`
  Edge Function v1 with `verify_jwt=false`. The function is intentionally
  LOCKED (503) and does not perform OAuth or access Google.
- **Not deployed:** WebCrypto broker/Google code exchange, persistent adapters,
  Supabase session verification, login/start/return and any secret.
  Source and evidence: [Supabase staging README](supabase/README.md).

**Runtime compatibility gate:** `backend/oauth_broker.mjs` targets Node
(`node:crypto`) and is not directly an executable Supabase Edge Function (Deno).
Port the broker to the Supabase Edge runtime using WebCrypto, checked dependencies
and an authenticated state transaction store before deployment. Do not deploy
the Node mock server as a Deno function or substitute an unauthenticated callback.

**Deployed endpoint address, but callback logic NOT ACTIVE or registered in Google:**
`https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback`.
Only register this string in Google Cloud after the Edge Function implements,
passes and enables real authenticated callback handling. The currently
deployed kill-switch is NOT adequate for live OAuth. Supabase Edge callbacks from Google cannot depend
solely on an incoming Supabase Authorization JWT: implement single-use state
verification and verified account binding. Keep service secrets and token
encryption key exclusively server-side. This document makes no claim that a
working callback exists.

## Source delivered in this PR

- `oauth_staging.dart` provides an independent Authorization Code + PKCE S256
  request with secure random `state` and `nonce`, narrow scopes, explicit
  app-account binding, a ten-minute deadline, once-only callback acceptance,
  account-switch rejection and access-denied handling.
- `test/google_calendar_oauth_staging_test.dart` exercises mock-only flow
  invariants. Fake authorization codes never leave unit tests.
- The module is **not imported by `lib/`**. It does not perform an HTTP
  request, register a Flutter deep link, receive the live browser callback,
  exchange a code, parse an ID token, refresh a token, persist a link, or
  modify the live Supabase project.

## Selected callback design (SOURCE ONLY, not live)

The selected backend design is the **server-owned two-phase OAuth flow**
documented in [Supabase staging — Two-phase OAuth contract](supabase/TWO_PHASE_OAUTH_CONTRACT.md).

- The authenticated app first calls `POST /start` with its existing
  **production Supabase user JWT** in an HTTPS Authorization header.
  The staging server verifies that session through the production Auth
  `GET /auth/v1/user` endpoint **without modifying production**.
- The server creates one-use Google OAuth state/PKCE/nonce and independently
  generates a 256-bit **completion handle** returned only to the app in
  an authenticated JSON response. No Supabase session or handle appears in
  Google/browser URLs.
- Google's browser callback at
  `https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback`
  atomically consumes state, verifies Google's token and scope, and stores
  an expiring encrypted **pending grant**. The callback alone **never
  activates a link** and returns no tokens.
- The app then uses authenticated `POST /preview` and separately
  `POST /confirm` (explicit consent) with its private handle. Completion
  is account-scoped and atomic, so an account switch or replay fails closed.
- Backend storage is restricted to the staging project's private `gcal_stage`
  schema with RLS and no access to anon/authenticated clients. The staging
  secrets and any database connection must never target production.
- `http_handler.mjs` and `index_ready.mjs` implement source-only HTTP
  routing, CORS, secret and activation gates; `index_ready.mjs` is **NOT
  deployed**. The live Edge `index.ts` remains locked with 503 responses.
  A third-party browser cookie is no longer the selected solution; the
  app-bound one-time completion handle replaces that requirement.
- Do not register the Google redirect until the genuine, security-checked
  callback has been deployed and tested. Never use the production Supabase
  callback or alter its existing Google login client.

## Conditions that keep the Google writer blocked

- OAuth provider token/refresh and Google identity unverified.
- No deployed callback or authenticated backend exchange.
- No reviewed encrypted account-scoped token/link storage.
- No user-facing separate Calendar consent / calendar-owner selector.
- No privacy policy updated for Google Calendar direct exports.
- No B3 Android historical export inventory / user choice.
- No real account / physical Android + Web test evidence.
- Product Bible read-only overlay vs explicit outbound writer needs an
  explicit approved clarification before any production activation.

Testing-only Google refresh tokens may expire after seven days. Public
distribution with sensitive Google Calendar scopes may require Google
verification; testing mode is not a substitute for public approval.

## References

- https://developers.google.com/identity/protocols/oauth2/web-server
- https://developers.google.com/identity/openid-connect/openid-connect
- https://developers.google.com/workspace/calendar/api/auth
- https://developers.google.com/identity/protocols/oauth2/production-readiness/overview
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://datatracker.ietf.org/doc/html/rfc7636

**RELEASE STATE: NO MERGE. NO APK. NO LIVE GOOGLE REQUESTS.**

### Deno WebCrypto staging update (03/11/2026)

`supabase/functions/gcal-oauth-callback/webcrypto_core.mjs` now implements
WebCrypto PKCE, AES-GCM and verified Google ID-token primitives with Node 22
mock tests. It is **not invoked** by the deployed `index.ts` kill-switch.
The staging database migration was executed only on project
`pdanpljacyozslrutsor`. The next gate is the authenticated cross-project
Supabase session + one-time browser handoff + atomic transaction and link-store
adapters, followed by end-to-end staging tests and separate user approval
before a live test-account OAuth flow.
