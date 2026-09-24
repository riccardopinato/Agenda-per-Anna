# Google Auth production setup — v0.41

Anna's Diary v0.41 uses Supabase Auth as the single identity provider and Google as the primary sign-in method.

## Runtime flow

- Web: Supabase OAuth redirects back to `https://riccardopinato.github.io/Agenda-per-Anna/`.
- Android: Supabase OAuth opens in the system browser and returns through `io.supabase.annasdiary://login-callback/`.
- Legacy email/password accounts remain available only as a compatibility sign-in path.
- Noi ♡ never owns a separate account or credential form.

## Google OAuth application

Configure one Google **Web application** OAuth client.

Authorized redirect URI:

`https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback`

Scopes:

- `openid`
- `email`
- `profile`

Register the Google client ID and client secret in the Google provider of the Supabase Auth project.

## Supabase redirect allow list

The Auth redirect allow list must contain both:

- `https://riccardopinato.github.io/Agenda-per-Anna/`
- `io.supabase.annasdiary://login-callback/`

The mobile URI is also generated into the Android manifest by `tool/prepare_android_platform.py`.

## Android release certificate

v0.41 deliberately uses OAuth through the system browser, so an Android Google OAuth client is not required by this flow.

For future native Google Credential Manager integration, the current stable sideload/release certificate fingerprint is:

SHA-1:

`AA:BB:7D:49:D4:B0:E7:99:90:F9:5E:70:CB:74:E9:85:4F:0B:CF:16`

SHA-256:

`58:28:0A:02:07:8A:61:0D:47:F9:CF:91:0E:4B:AC:97:99:2A:B3:64:C7:C0:5A:8E:18:DA:F9:34:DA:5A:CA:58`

These fingerprints are public certificate identifiers, not signing secrets.

## Release verification

Before shipping:

1. Google provider enabled in Supabase.
2. Both redirect URLs are allow-listed.
3. Google consent screen uses the Anna's Diary branding.
4. Existing email/password user can still sign in.
5. Google OAuth user lands on the same global account scope on Android and Web.
6. Sign-out returns to the universal identity screen without deleting local archived account data.
