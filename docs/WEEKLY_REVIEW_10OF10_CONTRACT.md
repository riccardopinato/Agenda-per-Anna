# Weekly Review CAP-0111 (approved 10/10 in Chat)

Status: SOURCE IMPLEMENTATION CANDIDATE. Physical Android QA NOT VERIFIED.

Approved experience: (1) card below Today opening while preserving Timeline/Per te/Esplora; (2) adaptive Sun/Mon and compact weekdays/completed; (3) balanced private task counts; (4) select real DayJournal.beautiful memories or free-write; (5) one focus and three priorities; (6) soft completion + reopen; (7) chronological archive; (8) opt-in notifications OFF by default; (9) iOS Journal motion and reduced motion; (10) final design approved.

Canonical writers: AgendaStore.week()/saveWeek(), same record as WeekScreen. Additive WeekData.reviewCompletedAt; legacy data remains readable. Preferences are serialized via AgendaPreferences. CAP-0111 task counts are private and reflect current done status, not actual completion dates. No automatic changes to tasks, no new store.

Notifications: NotificationService.schedule() one-shot horizon of 8 weeks, reconciled on Today card and save/setting changes; no permission prompts on startup. Device delivery and long-term scheduling still need physical validation.

Release: versionCode +118 prepared; successful source CI and stable signed workflow required, then physical in-place QA. Existing +117 remains separate and physically NOT VERIFIED.
