# P1 #226 — voluntary user buffer in realistic day (2026-11-04)

This is a conservative enhancement of the existing RealisticDayAdvisor, not automatic rescheduling or an ML predictor.

- Real visible time is computed using existing unified authorized calendar and real free-slot service. The optional buffer of 0, 15, 30 or 60 minutes is saved only as a **local per-account SHA-256 keyed preference**, bounded 0–120 and never mixes accounts. Original freeMinutes is preserved; usableMinutes is freeMinutes minus voluntary buffer, floored at zero.
- Today UI shows both actual free time and after-buffer time, with honest scope text: unscheduled task durations, unavailable external calendars and unknown time remain excluded. Task count never implies duration.
- Privacy hide/dismiss behavior remains intact and local. No background nudge, notification, reschedule or write to calendar/diary/task.
- Test: 9–21 free-time baseline, clamp, no false task-duration assumption, nullable slots. Test physical provider coverage, overnight/multiscreen, account switch and large text before release. Device/Google Direct #199 and privacy #215 remain distinct.
- This is a **partial #226 increment**: canonical per-task duration capture (not presently stored by normal task editor), opt-in workload preferences and reversible task split action require a subsequent separate Product Bible-safe migration/UX decision. Do not treat existing task count as duration.
