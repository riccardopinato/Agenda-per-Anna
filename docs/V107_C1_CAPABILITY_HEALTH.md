# v1.07-C1 — CAP-0077 Permission / Capability Health

Scope: Android Settings Hub entry with on-demand, read-only capability
inspection. It reuses the current local-notification, Android Calendar Provider,
calendar overlay and remote push owners. No new store, migration, permission,
cloud provider, scheduler or onboarding permission wall.

Status semantics: permission granted != capability available != service healthy
!= user-visible delivery. Even a successful inspection is only AVAILABLE, not
DELIVERED or PHYSICAL PASS. Notifications and reminder channel are inspected
separately. Missing exact-alarm capability is described as possible inexact
fallback, not a fatal error. Remote push stays UNKNOWN/not-verified until an
explicit delivery test in the existing Notification settings. Calendar provider
read/write access is read back without prompting; account-scoped export state
does not prove Google/provider reception. Disabled optional integrations are
not represented as a successful sync.

The screen refreshes on Android resume and on explicit user action; the user
may open the existing Android notification settings or calendar sync controls
to request the necessary permissions themselves. No automatic repair changes
user consent. Web/iOS explicitly return UNSUPPORTED for these native probes
and retain their own existing notification settings.

Localization: EN/IT/ES/FR/PT with English fallback. No private event titles,
calendar names, notification contents, tokens or Vault data are logged or shown.

Evidence: deterministic state-model and read-only source-contract tests.
Physical Android revocation/reauthorization, channel disabling, OEM exact-alarm
fallback, provider availability and actual notification receipt: NOT VERIFIED.
