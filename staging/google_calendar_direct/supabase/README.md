# Anna's Diary — Supabase Google Calendar STAGING

**Status 03/11/2026:** Supabase project is live; the OAuth Edge Function is
intentionally **LOCKED**. No real Google OAuth flow or Calendar API access.

## Deployed resources (test project only)

- Organization: `fzieziuyodhojemtzeya` (Supabase Free, quoted 0 USD/month).
- Supabase staging project: `anna-calendar-staging`, ref `pdanpljacyozslrutsor`, region `eu-central-1`.
- Production `agenda-per-anna`, ref `pxsxlorntswypdbeerzw`, is a different project and was not modified.
- Applied migration: `gcal_staging_private_oauth_store_v1` (source in `migrations/`).
- Private `gcal_stage.oauth_pending` and `gcal_stage.oauth_links` tables:
  no anon/authenticated grants; RLS enabled; zero rows at latest check.
  A two-entry INFO advisor finding (`rls_enabled_no_policy`) is intentional
  for these private backend-only tables, **not** approval to expose them.
- Deployed Supabase Edge Function `gcal-oauth-callback` **v1, ACTIVE**.
- Actual HTTPS base:
  `https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback`.
- `verify_jwt=false` on this function only: required for a future Google
  browser callback. The deployed code **never** exchanges a code or reads
  tokens and always returns 503 except its locked health response. Its public
  availability is not equivalent to OAuth readiness.
- No Google credentials or extra paid resources configured.

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

## Blocking gates before live OAuth

1. Implement secure app-to-browser handoff. The first-party browser navigates
   to the staging host so that a `Secure; HttpOnly; SameSite=Lax` cookie
   can bind start to callback. A cross-origin XHR cookie alone is unreliable.
   The handoff must be short-lived and one-time; no production JWT in URL.
2. Verify production **Supabase Auth user identity** at the server boundary
   without changing production Auth configuration. Derive account ID from
   verified JWT, never from caller-supplied JSON.
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
