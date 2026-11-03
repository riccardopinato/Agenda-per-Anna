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
- **No Edge Function, OAuth callback, database migration or secrets deployed yet.**

**Runtime compatibility gate:** `backend/oauth_broker.mjs` targets Node
(`node:crypto`) and is not directly an executable Supabase Edge Function (Deno).
Port the broker to the Supabase Edge runtime using WebCrypto, checked dependencies
and an authenticated state transaction store before deployment. Do not deploy
the Node mock server as a Deno function or substitute an unauthenticated callback.

**Potential future redirect form (NOT REGISTERED, NOT LIVE):**
`https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback`.
Only register this string in Google Cloud if a deployed, tested Edge Function
really handles the callback. Supabase Edge callbacks from Google cannot depend
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

## Callback design — requires deployment BEFORE Google Console change

The Web OAuth client needs an **exact-match HTTPS callback belonging to a
deployed staging backend**. Neither the callback URL nor a production
Supabase callback is to be invented or copied from a different project.

1. Choose and deploy a distinct staging backend host (or a truly separate
   staging Supabase project after owner has reviewed any cost implications).
   Select an actual stable HTTPS route, e.g. the backend's own
   `/oauth/google-calendar/callback` path, only once its host is known.
2. Register that exact HTTPS URL under **Authorized redirect URIs** on the
   **test** Web OAuth client. Leave JavaScript origins empty unless the
   selected front-end flow truly requires them.
3. Protect the Web client secret **only server-side** in the staging provider
   secret store. Never add it to Flutter, GitHub, logs or chat. Do not add an
   imaginary placeholder URI to Google Cloud.
4. Server callback must validate the one-time pending state and PKCE
   transaction, bind it to the already authenticated app account, exchange
   authorization code **on the backend**, verify OIDC ID-token signature,
   issuer, audience, nonce and Google `sub`, and check the actual granted
   scopes before allowing a link.
5. Token refresh, revocation and encrypted persistence must be scoped by
   app-account + Google subject, and separated from normal Supabase Auth.
   No refresh token or client secret in ordinary preferences/backup/browser
   local storage. A page reload cannot reuse an in-memory-only PKCE session.
6. For Android, a Web OAuth client must **not** use the existing Android
   `io.supabase.annasdiary://login-callback/` directly as its Google redirect.
   A backend continuation and an Android return channel require separate
   review and validation. No authorization is currently attempted.
7. Only after a real provider adapter and reviewed privacy/B3 de-duplication
   guards are ready may the owner approve test-account access and later the
   first outbound event write. Never use private life data as mock fixtures.

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
