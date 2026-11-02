# v1.07 — Five daily-use quick wins

Scope: single Flutter implementation, no new schema, account path,
cloud contract or runtime permission.

1. **Duplicate with date selection** opens an editable, unsaved draft from
   an existing private agenda item, with recurrence links cleared.
2. **Move to tomorrow** acts only on incomplete, non-recurring private tasks,
   re-reads the canonical entity, and reuses `AgendaStore.upsert` and
   its existing reminder reconciliation.
3. **To catch up** is an Oggi-only derived overdue task surface, with a
   three-item summary and more-list; honours private/shared filter and
   privacy masking.
4. **Tomorrow preview** derives visible private/shared records from
   `unifiedForDay` and opens the existing next-day planner.
5. **Appointment overlaps** are advisory before save; visible and authorized
   agendas plus already available/consented external calendar events use
   the same intervals as free-slot calculation. A user may save anyway.
   Tasks do not occupy time; an edited event does not overlap itself.
   External calendar information may be partial. Recurrence beyond
   the edited date is not exhaustively checked.

Validation: `test/v107_quick_wins_test.dart` covers date boundaries,
overdue exclusions, recurring safety, interval edges, overnight cases and
localization in EN/IT/ES/FR/PT.

Status: source PR #206 MERGED on main d67c64e2; exact-head Development/Web/AppLab gates PASS. Build +120 prepared; APK and physical QA NOT VERIFIED.
Android signed APK, install, physical QA and visual acceptance: NOT VERIFIED.
