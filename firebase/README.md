# Firebase push setup — Anna's Diary

The app keeps Supabase as the source of truth. Firebase is used only as the
transport for remote push notifications.

## Android app

Register an Android app in Firebase with this package name:

`com.riccardopinato.agenda_per_anna`

Download `google-services.json` and place it at:

`firebase/google-services.json`

The release workflow detects this file automatically, enables the Google
Services Gradle plugin and builds with `FIREBASE_ENABLED=true`.

The Firebase client config is not an admin credential. Never place a Firebase
service-account private key in this repository.

## Supabase Edge Function secret

The deployed `send-shared-push` Edge Function expects this Supabase secret:

`FIREBASE_SERVICE_ACCOUNT_JSON`

Its value must be the complete service-account JSON generated from the Firebase
project. Store it only under Supabase Edge Functions secrets.

The function:
- validates the signed-in Supabase user;
- verifies membership in the requested Shared Space;
- sends only to the other members' registered devices;
- deduplicates each shared update;
- removes invalid/unregistered FCM tokens.

## Notification channel

Remote Noi ♡ notifications use Android channel:

`annas_diary_shared_v1`

and drawable:

`notification_icon`
