import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/app_version.dart';
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

  test('account switch archives and restores isolated working profiles',
      () async {
    final legacy = await SharedPreferences.getInstance();
    final state = await LocalStateStore.instance.open(
      legacyPreferences: legacy,
    );

    const habitsA = '[{"id":"a","name":"Profilo A"}]';
    const habitsB = '[{"id":"b","name":"Profilo B"}]';

    await state.writeBatch({
      'active_account_v1': 'user-a',
      'habits_v1': habitsA,
      'account_profiles_v1': jsonEncode({
        'user:user-b': {
          'habits_v1': habitsB,
        },
      }),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.activeAccountId, 'user-a');
    expect(store.habits.map((habit) => habit.id), ['a']);

    await store.activateCloudAccount('user-b');

    expect(store.activeAccountId, 'user-b');
    expect(store.habits.map((habit) => habit.id), ['b']);
    expect(state.getString('active_account_v1'), 'user-b');
    expect(state.getString('habits_v1'), habitsB);

    final profiles = Map<String, dynamic>.from(
      jsonDecode(state.getString('account_profiles_v1')!) as Map,
    );
    final archivedA = Map<String, dynamic>.from(
      profiles['user:user-a'] as Map,
    );
    expect(archivedA['habits_v1'], habitsA);

    await store.activateCloudAccount('user-a');

    expect(store.activeAccountId, 'user-a');
    expect(store.habits.map((habit) => habit.id), ['a']);
    expect(state.getString('habits_v1'), habitsA);

    store.dispose();
  });

  test('backup restore commits complete structured state and clears sync marker',
      () async {
    final store = AgendaStore();
    await store.load();

    final rawBackup = jsonEncode({
      'format': 'agenda_per_anna_backup',
      'schemaVersion': 1,
      'appVersion': appReleaseVersion,
      'exportedAt': DateTime(2026, 9, 23).toIso8601String(),
      'data': {
        'items': <Object>[],
        'journals': <String, Object>{},
        'months': <String, Object>{},
        'weeks': <String, Object>{},
        'habits': [
          {'id': 'restored', 'name': 'Ripristinata'},
        ],
        'inbox': <Object>[],
      },
    });

    await store.restoreBackup(rawBackup, merge: false);

    expect(store.habits.map((habit) => habit.id), ['restored']);
    expect(store.localSnapshots, isNotEmpty);

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    expect(
      jsonDecode(state.getString('habits_v1')!),
      [
        {'id': 'restored', 'name': 'Ripristinata'},
      ],
    );
    expect(state.getBool('cloud_force_full_sync_v1'), isNull);

    final exported =
        Map<String, dynamic>.from(jsonDecode(await store.createBackupJson()));
    expect(exported['appVersion'], appReleaseVersion);

    store.dispose();
  });
}
