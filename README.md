# Anna's Diary

Flutter app for personal planning, private diary and the shared **Noi ♡** space.

Current release line: **v0.30.1**.

## Core areas

- Private agenda and planner: Today / Week / Month / Year.
- Private diary: Note, Photo and full vector Sketchbook.
- Noi ♡: shared agenda plus the same Note / Photo / Sketch diary tools.
- I nostri ricordi: shared memories grouped by memories, days, months, years and timeline.
- Offline-first private/shared queues with deterministic cloud reconciliation.
- Supabase Auth, Database, Realtime and private Storage.
- Firebase Cloud Messaging for Android Noi ♡ push notifications.
- Local reminders with notification diagnostics and repair tools.
- Local/JSON backup and account-scoped safety snapshots.

## Quality gates

GitHub Actions runs Flutter analyze and tests on main. Release builds are manual and use Flutter 3.47.5 for reproducibility.

See `docs/ARCHITECTURE.md` and `supabase/README.md` for implementation details.
