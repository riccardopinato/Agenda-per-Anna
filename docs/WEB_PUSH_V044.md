# Web Push / PWA — v0.44

Anna's Diary uses two notification transports:

- Android native: Firebase Cloud Messaging plus local scheduled notifications.
- Web/iPhone PWA: standards-based Web Push plus the Flutter PWA service worker.

## iPhone / iPad

Web Push is enabled only when Anna's Diary is installed on the Home Screen.
Opening the GitHub Pages URL in a normal Safari tab is not treated as an
installed PWA and the app does not request notification permission there.

Flow:

1. Open Anna's Diary in Safari.
2. Use Share -> Add to Home Screen.
3. Open Anna's Diary from the Home Screen icon.
4. Sign in with the normal Anna's Diary account.
5. Open Settings -> Notifications.
6. Tap **Attiva PWA**.
7. Accept the iOS notification permission.
8. Run **Test Web Push**.

## Noi ♡

A shared-space event is delivered to both registered Android FCM devices and
registered browser Web Push subscriptions. Delivery telemetry stores the
counts separately while retaining aggregate delivery status.

Tapping a PWA notification reopens Anna's Diary and routes to the related
shared space.

## Private reminders

On Android, reminders remain local and are scheduled by the OS.

On the PWA, reminder schedules are mirrored to Supabase. A protected cron job
checks due reminders once per minute and invokes the Push backend using a
server-only token. The token and the private VAPID key are never exposed to
authenticated or anonymous clients.

PWA reminder delivery therefore requires internet connectivity and may occur
within the cron minute rather than at Android exact-alarm precision.

## Security

The shared Edge Function has gateway JWT verification disabled because it also
accepts the database cron request. It implements both authorization paths
itself:

- normal client actions require a valid Supabase bearer token and call
  `auth.getUser()`;
- cron dispatch requires the private `x-cron-token` stored in
  `web_push_config`.

The VAPID private key and cron token live in the backend-only configuration
table. RLS is enabled and client roles have no grants on that table.
