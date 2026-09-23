import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
  });

  test('supported SharedPreferences state migrates into structured storage',
      () async {
    const privatePayload = '{"legacy":"private"}';
    const pendingPayload = '[{"legacy":true}]';

    SharedPreferences.setMockInitialValues({
      'items_v1': privatePayload,
      'active_account_v1': 'user-a',
      'shared_pending_user-a_space-a': pendingPayload,
      'annas_diary_seen_shared_push_events_v1': <String>['push-1'],
    });

    final legacy = await SharedPreferences.getInstance();
    final state = await LocalStateStore.instance.open(
      legacyPreferences: legacy,
    );

    expect(state.getString('items_v1'), privatePayload);
    expect(state.getString('active_account_v1'), 'user-a');
    expect(
      state.getString('shared_pending_user-a_space-a'),
      pendingPayload,
    );
    expect(
      state.getString('annas_diary_seen_shared_push_events_v1'),
      isNull,
    );

    // The migration is deliberately non-destructive for v0.32 rollback safety.
    expect(legacy.getString('items_v1'), privatePayload);
  });

  test('structured state supports writes removal and prefix enumeration',
      () async {
    final legacy = await SharedPreferences.getInstance();
    final state = await LocalStateStore.instance.open(
      legacyPreferences: legacy,
    );

    await state.setString('journals_v1', '{"day":"one"}');
    await state.setString(
      'shared_pending_user-a_space-a',
      '[{"id":"pending"}]',
    );

    expect(state.getString('journals_v1'), '{"day":"one"}');
    expect(
      state.getKeys().where((key) => key.startsWith('shared_pending_')),
      contains('shared_pending_user-a_space-a'),
    );

    await state.remove('journals_v1');
    expect(state.containsKey('journals_v1'), isFalse);
  });

  test('AgendaStore transparently reads a legacy journal after migration',
      () async {
    final journalPayload = jsonEncode({
      '2026-09-23': {
        'beautiful': 'Ricordo migrato',
        'note': 'Conservato',
        'mood': 'good',
        'gratitude': <String>['Noi'],
        'completedHabitIds': <String>[],
        'blocks': <Object>[],
      },
    });

    SharedPreferences.setMockInitialValues({
      'journals_v1': journalPayload,
    });

    final store = AgendaStore();
    await store.load();

    final migrated = store.journal(DateTime(2026, 9, 23));
    expect(migrated.beautiful, 'Ricordo migrato');
    expect(migrated.note, 'Conservato');
    expect(migrated.mood, DayMood.good);
    expect(migrated.gratitude, <String>['Noi']);

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    expect(state.getString('journals_v1'), journalPayload);

    store.dispose();
  });
}
