import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('recurrence dates are civil-calendar safe', () {
    expect(
      recurrenceDateForRule(
        DateTime(2024, 2, 29),
        RecurrenceRule.yearly,
        1,
      ),
      DateTime(2025, 2, 28),
    );
    expect(
      recurrenceDateForRule(
        DateTime(2027, 1, 31),
        RecurrenceRule.monthly,
        1,
      ),
      DateTime(2027, 2, 28),
    );
    expect(
      recurrenceDateForRule(
        DateTime(2026, 9, 26),
        RecurrenceRule.weekly,
        2,
      ),
      DateTime(2026, 10, 10),
    );
  });

  test('agenda item recurrence metadata is backward compatible', () {
    final legacy = AgendaItem.fromJson({
      'id': 'legacy',
      'title': 'Legacy',
      'note': '',
      'date': DateTime(2026, 9, 26).toIso8601String(),
      'type': ItemType.task.name,
      'category': AgendaCategory.personal.name,
    });
    expect(legacy.isRecurring, isFalse);
    expect(legacy.recurrenceRule, RecurrenceRule.none);
    expect(legacy.recurrenceCount, 1);

    final recurring = AgendaItem(
      id: 'recurring',
      title: 'Corso',
      note: '',
      date: DateTime(2026, 9, 26),
      type: ItemType.appointment,
      recurrenceRule: RecurrenceRule.weekly,
      recurrenceSeriesId: 'series-1',
      recurrenceIndex: 2,
      recurrenceCount: 6,
    );
    final restored = AgendaItem.fromJson(recurring.toJson());
    expect(restored.isRecurring, isTrue);
    expect(restored.recurrenceSeriesId, 'series-1');
    expect(restored.recurrenceIndex, 2);
    expect(restored.recurrenceCount, 6);
  });

  test('series creation persists linked ordinary agenda items', () async {
    final store = AgendaStore();
    await store.load();

    await store.createRecurringSeries(
      template: AgendaItem(
        id: 'first',
        title: 'Controllo mensile',
        note: '',
        date: DateTime(2027, 1, 31),
        type: ItemType.task,
      ),
      rule: RecurrenceRule.monthly,
      count: 4,
    );

    expect(store.items, hasLength(4));
    final seriesId = store.items.first.recurrenceSeriesId;
    expect(seriesId, isNotNull);
    expect(
      store.items.every((item) => item.recurrenceSeriesId == seriesId),
      isTrue,
    );
    expect(
      store.items.map((item) => item.date).toList(),
      [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
        DateTime(2027, 4, 30),
      ],
    );

    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(reloaded.items, hasLength(4));
    expect(
      reloaded.items.every((item) => item.recurrenceSeriesId == seriesId),
      isTrue,
    );
    reloaded.dispose();
  });

  test('this-and-future edit leaves earlier occurrence untouched', () async {
    final store = AgendaStore();
    await store.load();

    await store.createRecurringSeries(
      template: AgendaItem(
        id: 'first',
        title: 'Allenamento',
        note: '',
        date: DateTime(2026, 10, 1),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 18, minute: 0),
      ),
      rule: RecurrenceRule.weekly,
      count: 4,
    );

    final series = store.recurrenceSeriesFor(store.items.first);
    final second = series[1];
    await store.updateRecurringOccurrence(
      second.copyWith(
        title: 'Allenamento serale',
        date: DateTime(2026, 10, 9),
      ),
      scope: RecurringEditScope.thisAndFuture,
    );

    final updated = store.recurrenceSeriesFor(store.items.first);
    expect(updated.first.title, 'Allenamento');
    expect(updated.first.date, DateTime(2026, 10, 1));
    expect(updated[1].title, 'Allenamento serale');
    expect(updated[1].date, DateTime(2026, 10, 9));
    expect(updated[2].date, DateTime(2026, 10, 16));
    expect(updated[3].date, DateTime(2026, 10, 23));
    store.dispose();
  });

  test('future-series delete reuses Trash lifecycle', () async {
    final store = AgendaStore();
    await store.load();

    await store.createRecurringSeries(
      template: AgendaItem(
        id: 'first',
        title: 'Pagamento',
        note: '',
        date: DateTime(2026, 10, 5),
        type: ItemType.task,
      ),
      rule: RecurrenceRule.monthly,
      count: 4,
    );

    final series = store.recurrenceSeriesFor(store.items.first);
    await store.deleteRecurringOccurrence(
      series[2],
      scope: RecurringEditScope.thisAndFuture,
    );

    expect(store.items, hasLength(2));
    expect(store.trash, hasLength(2));
    expect(
      store.trash.every((entry) => entry.kind == TrashEntityKind.item),
      isTrue,
    );
    store.dispose();
  });
}
