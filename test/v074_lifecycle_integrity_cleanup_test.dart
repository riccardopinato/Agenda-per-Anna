import 'dart:io';

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

  test('shopping and workout Trash survive complete backup restore', () async {
    final source = AgendaStore();
    await source.load();

    final shopping = await source.addShoppingItem(
      'Yogurt',
      quantity: '4',
      category: ShoppingCategory.dairy,
    );
    final plan = await source.addWorkoutPlan(
      name: 'Forza A',
      sport: WorkoutSport.gym,
      exercises: source.parseWorkoutPlanText('Panca 4x8 @ 60kg'),
    );
    final session = await source.addWorkoutSession(
      sport: WorkoutSport.running,
      date: DateTime(2026, 9, 29),
      title: '15 km',
      distanceKm: 15,
      durationSeconds: 3900,
      plan: plan,
    );

    expect(await source.moveShoppingItemToTrash(shopping!.id), isTrue);
    expect(await source.moveWorkoutPlanToTrash(plan.id), isTrue);
    expect(await source.moveWorkoutSessionToTrash(session.id), isTrue);

    final backup = await source.createBackupJson();
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final restored = AgendaStore();
    await restored.load();
    await restored.restoreBackup(backup, merge: false);

    expect(restored.shoppingItems, isEmpty);
    expect(restored.workoutPlans, isEmpty);
    expect(restored.workoutSessions, isEmpty);
    expect(
      restored.trash.map((entry) => entry.kind).toSet(),
      containsAll({
        TrashEntityKind.shoppingItem,
        TrashEntityKind.workoutPlan,
        TrashEntityKind.workoutSession,
      }),
    );

    for (final entry in [...restored.trash]) {
      expect(await restored.restoreTrashEntry(entry.id), isTrue);
    }

    expect(restored.shoppingItems.single.name, 'Yogurt');
    expect(restored.workoutPlans.single.name, 'Forza A');
    expect(restored.workoutSessions.single.title, '15 km');
    expect(restored.workoutSessions.single.distanceKm, 15);
    restored.dispose();
  });

  test('purging an old workout plan version never mutates history', () async {
    final store = AgendaStore();
    await store.load();

    final plan = await store.addWorkoutPlan(
      name: 'Palestra A',
      sport: WorkoutSport.gym,
      exercises: store.parseWorkoutPlanText('Panca 4x8 @ 60kg'),
    );
    final session = await store.addWorkoutSession(
      sport: WorkoutSport.gym,
      date: DateTime(2026, 9, 29),
      title: 'Allenamento A',
      plan: plan,
    );

    expect(await store.moveWorkoutPlanToTrash(plan.id), isTrue);
    final oldTrash = store.trash.singleWhere(
      (entry) => entry.kind == TrashEntityKind.workoutPlan,
    );

    await store.saveWorkoutPlan(
      plan.copyWith(
        name: 'Palestra B',
        exercises: store.parseWorkoutPlanText('Squat 5x5 @ 80kg'),
      ),
    );

    expect(
      await store.purgeTrashEntry(
        oldTrash.id,
        createSafetySnapshot: false,
      ),
      isTrue,
    );

    expect(store.workoutPlans.single.id, plan.id);
    expect(store.workoutPlans.single.name, 'Palestra B');
    final historical = store.workoutSessions.singleWhere(
      (value) => value.id == session.id,
    );
    expect(historical.planName, 'Palestra A');
    expect(historical.exercises.single.name, 'Panca');
    expect(historical.exercises.single.loadKg, 60);
    store.dispose();
  });

  test('Noi shopping delete stays in shared tombstones, not private Trash',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('v074-shared-shopping');

    final entry = await store.addSharedShoppingItem(
      'space-v074',
      'Pasta',
      quantity: '2 pacchi',
      category: ShoppingCategory.pantry,
    );
    expect(entry, isNotNull);
    expect(store.sharedShoppingItems('space-v074'), hasLength(1));
    expect(store.trash, isEmpty);

    await store.deleteSharedShoppingItem('space-v074', entry!);

    expect(store.sharedShoppingItems('space-v074'), isEmpty);
    expect(
      store.trash,
      isEmpty,
      reason:
          'Collaborative rows must use shared tombstones instead of private recoverable copies.',
    );
    store.dispose();
  });

  test('historical feature tests do not own current release coordinates', () {
    final files = Directory('test')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .where((file) => !file.path.endsWith('release_metadata_test.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains("expect(appReleaseVersion, '")),
        reason:
            '${file.path} hardcodes the current runtime release version; keep it only in the canonical metadata gate.',
      );
      expect(
        source,
        isNot(contains("contains('version: 0.")),
        reason:
            '${file.path} hardcodes the current pubspec release coordinates; keep them only in the canonical metadata gate.',
      );
    }
  });
}
