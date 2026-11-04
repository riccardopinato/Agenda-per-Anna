// STAGING ONLY: intentionally not imported from lib/main.dart.
// Adapts existing canonical private AgendaItem objects, never SharedEntry.
import 'package:agenda_per_anna/main.dart';
import 'calendar_staging.dart';

GcalDraft? projectPrivateAppointmentForGoogle(
  AgendaItem item, {
  required String timeZone,
}) {
  if (item.type != ItemType.appointment || item.title.trim().isEmpty) {
    return null;
  }
  final start = item.start;
  final end = item.end;
  if ((start == null) != (end == null)) return null;
  return GcalDraft(
    localId: item.id,
    title: item.title,
    date: item.date,
    startMinutes: start == null ? null : start.hour * 60 + start.minute,
    endMinutes: end == null ? null : end.hour * 60 + end.minute,
    timeZone: timeZone,
  );
}

/// Deterministic bounded initial candidate projection. The store must have a
/// resolved authenticated account, never the implicit guest/local scope.
/// This does not invoke the Google API, request permissions or persist data.
List<GcalDraft> prepareGoogleCalendarCandidates(
  AgendaStore store, {
  required String timeZone,
  DateTime? now,
  int maxItems = 200,
}) {
  if (!store.entryScopeReady ||
      store.activeAccountId == null ||
      maxItems < 1 ||
      maxItems > 200) {
    return const <GcalDraft>[];
  }
  final today = now ?? DateTime.now();
  final from = DateTime(today.year, today.month, today.day);
  final until = DateTime(today.year + 1, today.month, today.day);
  final eligible = store.items
      .where((item) =>
          item.type == ItemType.appointment &&
          !item.date.isBefore(from) &&
          item.date.isBefore(until))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return eligible
      .map((item) => projectPrivateAppointmentForGoogle(
            item, timeZone: timeZone))
      .whereType<GcalDraft>()
      .take(maxItems)
      .toList(growable: false);
}
