# Anna's Diary

Flutter app for personal planning, private diary and the shared **Noi ♡** space.

Current release line: **v0.31.0**.

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


## v0.31.0 — Shared Diary Parity 2.0

Private diary and Noi ♡ now share the same diary UI components for Note, Photo and Sketch: the same section shell, content cards, edit/caption/delete dialogs, photo viewer frame and full Sketchbook editor. Shared-only collaboration controls (hearts, comments and read receipts) are layered on top of the common diary component instead of maintaining a separate visual implementation.
