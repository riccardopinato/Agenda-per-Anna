part of '../main.dart';

enum RecurringEditScope { single, thisAndFuture, wholeSeries }

extension RecurringEditScopeUi on RecurringEditScope {
  String get label => switch (this) {
        RecurringEditScope.single => 'Solo questa',
        RecurringEditScope.thisAndFuture => 'Questa e successive',
        RecurringEditScope.wholeSeries => 'Tutta la serie',
      };

  String get shortLabel => switch (this) {
        RecurringEditScope.single => 'Questa',
        RecurringEditScope.thisAndFuture => 'Da qui',
        RecurringEditScope.wholeSeries => 'Tutte',
      };
}

DateTime recurrenceDateForRule(
  DateTime start,
  RecurrenceRule rule,
  int offset,
) {
  switch (rule) {
    case RecurrenceRule.none:
      return DateTime(start.year, start.month, start.day);
    case RecurrenceRule.daily:
      return addCivilDays(start, offset);
    case RecurrenceRule.weekly:
      return addCivilDays(start, 7 * offset);
    case RecurrenceRule.monthly:
      final target = DateTime(start.year, start.month + offset, 1);
      final lastDay = DateTime(target.year, target.month + 1, 0).day;
      return DateTime(
        target.year,
        target.month,
        start.day.clamp(1, lastDay).toInt(),
      );
    case RecurrenceRule.yearly:
      final year = start.year + offset;
      final lastDay = DateTime(year, start.month + 1, 0).day;
      return DateTime(
        year,
        start.month,
        start.day.clamp(1, lastDay).toInt(),
      );
  }
}

extension RecurringLifeAgendaStore on AgendaStore {
  List<AgendaItem> recurrenceSeriesFor(AgendaItem item) {
    final seriesId = item.recurrenceSeriesId;
    if (!item.isRecurring || seriesId == null) {
      return <AgendaItem>[item];
    }
    final result = items
        .where((entry) => entry.recurrenceSeriesId == seriesId)
        .toList()
      ..sort((a, b) => a.recurrenceIndex.compareTo(b.recurrenceIndex));
    return result;
  }

  Future<void> createRecurringSeries({
    required AgendaItem template,
    required RecurrenceRule rule,
    required int count,
  }) async {
    if (rule == RecurrenceRule.none || count <= 1) {
      await upsert(template.copyWith(clearRecurrence: true));
      return;
    }

    final safeCount = count.clamp(2, 60).toInt();
    final seriesId = template.recurrenceSeriesId ?? const Uuid().v4();

    for (var index = 0; index < safeCount; index++) {
      final occurrence = template.copyWith(
        date: recurrenceDateForRule(template.date, rule, index),
        recurrenceRule: rule,
        recurrenceSeriesId: seriesId,
        recurrenceIndex: index,
        recurrenceCount: safeCount,
        done: index == 0 ? template.done : false,
      );
      final withIdentity = index == 0
          ? occurrence
          : AgendaItem(
              id: const Uuid().v4(),
              title: occurrence.title,
              note: occurrence.note,
              date: occurrence.date,
              type: occurrence.type,
              category: occurrence.category,
              reminderMinutesBefore: occurrence.reminderMinutesBefore,
              secondaryReminderMinutesBefore:
                  occurrence.secondaryReminderMinutesBefore,
              start: occurrence.start,
              end: occurrence.end,
              done: false,
              pinned: occurrence.pinned,
              recurrenceRule: occurrence.recurrenceRule,
              recurrenceSeriesId: occurrence.recurrenceSeriesId,
              recurrenceIndex: occurrence.recurrenceIndex,
              recurrenceCount: occurrence.recurrenceCount,
            );
      await upsert(withIdentity);
    }
  }

  Future<void> updateRecurringOccurrence(
    AgendaItem edited, {
    RecurringEditScope scope = RecurringEditScope.single,
  }) async {
    if (!edited.isRecurring) {
      await upsert(edited);
      return;
    }

    final series = recurrenceSeriesFor(edited);
    if (series.length <= 1) {
      await upsert(edited.copyWith(clearRecurrence: true));
      return;
    }

    AgendaItem? current;
    for (final entry in series) {
      if (entry.id == edited.id) {
        current = entry;
        break;
      }
    }
    final selected = current ?? edited;

    if (scope == RecurringEditScope.single) {
      await upsert(edited.copyWith(clearRecurrence: true));
      return;
    }

    final targets = scope == RecurringEditScope.wholeSeries
        ? series
        : series
            .where(
              (entry) => entry.recurrenceIndex >= selected.recurrenceIndex,
            )
            .toList();

    final baseIndex = scope == RecurringEditScope.wholeSeries
        ? series.first.recurrenceIndex
        : selected.recurrenceIndex;
    final baseDate = scope == RecurringEditScope.wholeSeries
        ? addCivilDays(
            series.first.date,
            edited.date.difference(selected.date).inDays,
          )
        : edited.date;

    for (final target in targets) {
      final relativeIndex = target.recurrenceIndex - baseIndex;
      final targetDate = recurrenceDateForRule(
        baseDate,
        edited.recurrenceRule,
        relativeIndex,
      );
      await upsert(
        target.copyWith(
          title: edited.title,
          note: edited.note,
          date: targetDate,
          type: edited.type,
          category: edited.category,
          reminderMinutesBefore: edited.reminderMinutesBefore,
          secondaryReminderMinutesBefore:
              edited.secondaryReminderMinutesBefore,
          start: edited.start,
          end: edited.end,
          clearTime: edited.start == null,
          clearReminder: edited.reminderMinutesBefore == null,
          clearSecondaryReminder:
              edited.secondaryReminderMinutesBefore == null,
          pinned: edited.pinned,
        ),
      );
    }
  }

  Future<void> deleteRecurringOccurrence(
    AgendaItem item, {
    RecurringEditScope scope = RecurringEditScope.single,
  }) async {
    if (!item.isRecurring || scope == RecurringEditScope.single) {
      await deleteItem(item.id);
      return;
    }

    final series = recurrenceSeriesFor(item);
    final targets = scope == RecurringEditScope.wholeSeries
        ? series
        : series
            .where(
              (entry) => entry.recurrenceIndex >= item.recurrenceIndex,
            )
            .toList();

    for (final target in targets.reversed) {
      await deleteItem(target.id);
    }
  }
}
