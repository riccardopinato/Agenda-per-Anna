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

  test('multisport sessions calculate pace and speed without gym assumptions',
      () async {
    final store = AgendaStore();
    await store.load();

    final run = await store.addWorkoutSession(
      sport: WorkoutSport.running,
      date: DateTime(2026, 9, 28),
      title: 'Lungo',
      distanceKm: 15,
      durationSeconds: 3600,
    );
    final bike = await store.addWorkoutSession(
      sport: WorkoutSport.cycling,
      date: DateTime(2026, 9, 27),
      title: 'Giro bici',
      distanceKm: 50,
      durationSeconds: 7200,
    );

    expect(store.workoutPerformanceLabel(run), '4:00 /km');
    expect(store.workoutPerformanceLabel(bike), '25.0 km/h');
    expect(store.workoutHistory.map((session) => session.title),
        ['Lungo', 'Giro bici']);
    store.dispose();
  });

  test('workout plans parse structured rows and preserve free text', () async {
    final store = AgendaStore();
    await store.load();

    final parsed = store.parseWorkoutPlanText(
      'Panca 4x8 @ 60kg\n'
      'Squat | 5 | 5 | 80kg\n'
      'Corsa facile 30 min',
    );

    expect(parsed, hasLength(3));
    expect(parsed[0].name, 'Panca');
    expect(parsed[0].sets, 4);
    expect(parsed[0].reps, '8');
    expect(parsed[0].loadKg, 60);
    expect(parsed[1].sets, 5);
    expect(parsed[1].loadKg, 80);
    expect(parsed[2].name, 'Corsa facile 30 min');

    final plan = await store.addWorkoutPlan(
      name: 'Forza A',
      sport: WorkoutSport.gym,
      exercises: parsed,
    );
    final session = await store.addWorkoutSession(
      sport: plan.sport,
      date: DateTime(2026, 9, 28),
      plan: plan,
    );

    expect(session.planName, 'Forza A');
    expect(session.exercises, hasLength(3));
    store.dispose();
  });

  test('workout sessions and plans persist across restart', () async {
    final first = AgendaStore();
    await first.load();
    final plan = await first.addWorkoutPlan(
      name: 'Preparazione 10 km',
      sport: WorkoutSport.running,
      exercises: first.parseWorkoutPlanText(
        'Riscaldamento 15 min\n6x1000m\nDefaticamento 10 min',
      ),
    );
    await first.addWorkoutSession(
      sport: WorkoutSport.running,
      date: DateTime(2026, 9, 28),
      title: 'Ripetute',
      distanceKm: 10.5,
      durationSeconds: 3150,
      effort: 8,
      note: 'Buone sensazioni',
      plan: plan,
    );
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.workoutPlans.single.name, 'Preparazione 10 km');
    expect(second.workoutSessions.single.title, 'Ripetute');
    expect(second.workoutSessions.single.distanceKm, 10.5);
    expect(second.workoutSessions.single.effort, 8);
    expect(second.workoutSessions.single.planName, 'Preparazione 10 km');
    second.dispose();
  });

  test('workouts use existing Trash and restore losslessly', () async {
    final store = AgendaStore();
    await store.load();
    final plan = await store.addWorkoutPlan(
      name: 'Palestra A',
      sport: WorkoutSport.gym,
      exercises: store.parseWorkoutPlanText('Panca 4x8 @ 60kg'),
    );
    final session = await store.addWorkoutSession(
      sport: WorkoutSport.cycling,
      date: DateTime(2026, 9, 28),
      title: 'Bici',
      distanceKm: 50,
      durationSeconds: 7200,
    );

    expect(await store.moveWorkoutPlanToTrash(plan.id), isTrue);
    expect(await store.moveWorkoutSessionToTrash(session.id), isTrue);
    expect(store.workoutPlans, isEmpty);
    expect(store.workoutSessions, isEmpty);

    final sessionTrash = store.trash
        .firstWhere((entry) => entry.kind == TrashEntityKind.workoutSession);
    final planTrash = store.trash
        .firstWhere((entry) => entry.kind == TrashEntityKind.workoutPlan);

    expect(await store.restoreTrashEntry(sessionTrash.id), isTrue);
    expect(await store.restoreTrashEntry(planTrash.id), isTrue);
    expect(store.workoutSessions.single.distanceKm, 50);
    expect(store.workoutPlans.single.exercises.single.loadKg, 60);
    store.dispose();
  });

  test('workouts survive existing backup restore pipeline', () async {
    final source = AgendaStore();
    await source.load();
    await source.addWorkoutPlan(
      name: 'Nuoto',
      sport: WorkoutSport.swimming,
      exercises: source.parseWorkoutPlanText('Riscaldamento 400m\n8x100m'),
    );
    await source.addWorkoutSession(
      sport: WorkoutSport.swimming,
      date: DateTime(2026, 9, 28),
      title: 'Piscina',
      distanceKm: 2,
      durationSeconds: 2700,
    );
    final backup = await source.createBackupJson();
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final restored = AgendaStore();
    await restored.load();
    await restored.restoreBackup(backup, merge: false);
    expect(restored.workoutPlans.single.name, 'Nuoto');
    expect(restored.workoutSessions.single.distanceKm, 2);
    restored.dispose();
  });

  test('workouts remain isolated across account profiles', () async {
    final store = AgendaStore();
    await store.load();

    await store.activateCloudAccount('workout-a');
    await store.addWorkoutSession(
      sport: WorkoutSport.running,
      date: DateTime(2026, 9, 28),
      title: 'Account A',
    );

    await store.activateCloudAccount('workout-b');
    expect(store.workoutSessions, isEmpty);
    expect(store.workoutPlans, isEmpty);
    await store.addWorkoutPlan(
      name: 'Account B',
      sport: WorkoutSport.gym,
    );

    await store.activateCloudAccount('workout-a');
    expect(store.workoutSessions.single.title, 'Account A');
    expect(store.workoutPlans, isEmpty);
    store.dispose();
  });

  test('v0.72 reuses private agenda_records and adds no workout backend table',
      () {
    final storeSource = File('lib/src/agenda_store.dart').readAsStringSync();
    final domainSource = File('lib/src/workout_domain.dart').readAsStringSync();
    final migrations = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .join('\n')
        .toLowerCase();

    expect(storeSource, contains("static const _workoutsKey = 'workouts_v1'"));
    expect(domainSource, contains("type: 'workout_session'"));
    expect(domainSource, contains("type: 'workout_plan'"));
    expect(migrations, isNot(contains('create table workout')));
    expect(migrations, isNot(contains('create table public.workout')));
  });

}
