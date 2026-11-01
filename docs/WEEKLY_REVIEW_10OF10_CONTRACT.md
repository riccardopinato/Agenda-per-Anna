# Weekly Review CAP-0111 (approved 10/10 in Chat)

Status: **CLOSED — SOURCE MERGED / USER-ACCEPTED GENERAL PASS**. Physical technical certification per-scenario **NOT VERIFIED**.

Approved experience: (1) card below Today opening while preserving Timeline/Per te/Esplora; (2) adaptive Sun/Mon and compact weekdays/completed; (3) balanced private task counts; (4) select real DayJournal.beautiful memories or free-write; (5) one focus and three priorities; (6) soft completion + reopen; (7) chronological archive; (8) opt-in notifications OFF by default; (9) iOS Journal motion and reduced motion; (10) final design approved.

Canonical writers: AgendaStore.week()/saveWeek(), same record as WeekScreen. Additive WeekData.reviewCompletedAt; legacy data remains readable. Preferences are serialized via AgendaPreferences. CAP-0111 task counts are private and reflect current done status, not actual completion dates. No automatic changes to tasks, no new store.

Notifications: NotificationService.schedule() one-shot horizon of 8 weeks, reconciled on Today card and save/setting changes; no permission prompts on startup. Device delivery and long-term scheduling still need physical validation.

Release: `1.0.0-rc.6+118` (`versionCode 118`) signed ARM64 **BUILT** from `main@b05c6c3cad1a0dbb7c66ba639ad8c4d0612cf96b` via [Actions #41317266363](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41317266363), artifact ID 13087996964. Source Development/Web/Android-native checks green; AppLab Source Gate green at PR #201 head. User tested the app, liked it, and reported «Sembra funzionare tutto»; explicitly approved CAP-0111 closure. Treat this as functional user acceptance, NOT a complete physical evidence matrix. Keep specific backup/restore, cross-device, notification-delivery, signing-on-device, privacy and Play gates NOT VERIFIED unless independently demonstrated. Previous +117 physical evidence remains distinct.
