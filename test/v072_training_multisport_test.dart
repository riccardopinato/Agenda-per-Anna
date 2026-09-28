import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  test('free sessions support different sports without a workout plan',
      () async {
    final store = AgendaStore();
    await store.load();

    final run = TrainingSession(
      id: 'run-15',
      title: 'Lungo',
      sport: TrainingSport.running,
      date: DateTime(2026, 9, 28),
      distanceKm: 15,
      durationSeconds: 65 * 60 + 20,
      createdAt: DateTime(2026, 9, 28, 10),
    );
    final bike = TrainingSession(
      id: 'bike-50',
      title: 'Giro in bici',
      sport: TrainingSport.cycling,
      date: DateTime(2026, 9, 27),
      distanceKm: 50,
      durationSeconds: 2 * 3600 + 10 * 60,
      createdAt: DateTime(2026, 9, 27, 10),
    );
    final climbing = TrainingSession(
      id: 'custom',
      title: 'Boulder',
      sport: TrainingSport.other,
      customSport: 'Arrampicata',
      date: DateTime(2026, 9, 26),
      note: 'Sessione libera',
      createdAt: DateTime(2026, 9, 26, 10),
    );

    await store.saveTrainingSession(run);
    await store.saveTrainingSession(bike);
    await store.saveTrainingSession(climbing);

    expect(store.trainingHistory.map((e) => e.id),
        ['run-15', 'bike-50', 'custom']);
    expect(run.durationLabel, '01:05:20');
    expect(run.averagePacePerKm, isNotNull);
    expect(run.averagePacePerKm!.inSeconds, closeTo(261, 1));
    expect(bike.averageSpeedKmh, closeTo(23.08, 0.02));
    expect(climbing.sportLabel, 'Arrampicata');
    expect(run.planId, isEmpty);
    expect(bike.planId, isEmpty);
    store.dispose();
  });

  test('training history survives restart and stays individually addressable',
      () async {
    final first = AgendaStore();
    await first.load();
    await first.saveTrainingSession(
      TrainingSession(
        id: 'history-session',
        title: '50 km bici',
        sport: TrainingSport.cycling,
        date: DateTime(2026, 9, 28),
        distanceKm: 50,
        durationSeconds: 7200,
        note: 'Vento contrario',
        createdAt: DateTime(2026, 9, 28, 9),
      ),
    );
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.trainingSessions, hasLength(1));
    final restored = second.trainingSessions.single;
    expect(restored.id, 'history-session');
    expect(restored.distanceKm, 50);
    expect(restored.durationSeconds, 7200);
    expect(restored.note, 'Vento contrario');
    second.dispose();
  });

  test('plans are optional scheduled templates and appear in Day Hub',
      () async {
    final store = AgendaStore();
    await store.load();
    final monday = DateTime(2026, 9, 28);
    expect(monday.weekday, DateTime.monday);

    final plan = TrainingPlan(
      id: 'plan-a',
      title: 'Scheda A',
      sport: TrainingSport.gym,
      weekdays: const [DateTime.monday, DateTime.thursday],
      exercises: const [
        TrainingExercise(
          id: 'squat',
          name: 'Squat',
          sets: 4,
          reps: '6',
          weightKg: 80,
        ),
      ],
      createdAt: monday,
    );
    await store.saveTrainingPlan(plan);

    expect(store.trainingPlansForDay(monday).single.title, 'Scheda A');
    expect(
      store.trainingPlansForDay(DateTime(2026, 9, 29)),
      isEmpty,
    );
    expect(store.dayHubSnapshot(monday).trainingPlans.single.id, 'plan-a');

    await store.saveTrainingSession(
      TrainingSession(
        id: 'from-plan',
        title: 'Scheda A',
        sport: TrainingSport.gym,
        date: monday,
        exercises: plan.exercises,
        planId: plan.id,
        createdAt: monday,
      ),
    );
    expect(store.trainingHistory.single.planId, plan.id);
    store.dispose();
  });

  test('original workout sheet media survives portable backup restore',
      () async {
    final source = AgendaStore();
    await source.load();
    final bytes = Uint8List.fromList(utf8.encode('%PDF fake workout sheet'));
    final assetId = await MediaAssetStore.instance.put(bytes);

    await source.saveTrainingPlan(
      TrainingPlan(
        id: 'pdf-plan',
        title: 'Preparazione',
        sport: TrainingSport.running,
        weekdays: const [DateTime.tuesday],
        attachmentAssetId: assetId,
        attachmentName: 'scheda.pdf',
        attachmentMimeType: 'application/pdf',
        attachmentSizeBytes: bytes.length,
        createdAt: DateTime(2026, 9, 28),
      ),
    );

    final backup = await source.createBackupJson();
    final decoded = jsonDecode(backup) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final plans = data['trainingPlans'] as List;
    final payload = plans.single as Map<String, dynamic>;
    expect(payload['attachmentAssetId'], isNull);
    expect(payload['attachmentBase64'], isNotEmpty);
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final restoredStore = AgendaStore();
    await restoredStore.load();
    await restoredStore.restoreBackup(backup, merge: false);
    final restored = restoredStore.trainingPlans.single;
    expect(restored.attachmentName, 'scheda.pdf');
    expect(restored.attachmentAssetId, isNotEmpty);
    final restoredBytes =
        await MediaAssetStore.instance.read(restored.attachmentAssetId);
    expect(restoredBytes, bytes);
    restoredStore.dispose();
  });

  test('plans and sessions use existing Trash recovery', () async {
    final store = AgendaStore();
    await store.load();
    final plan = TrainingPlan(
      id: 'trash-plan',
      title: 'Scheda B',
      sport: TrainingSport.gym,
      weekdays: const [DateTime.friday],
      createdAt: DateTime(2026, 9, 28),
    );
    final session = TrainingSession(
      id: 'trash-session',
      title: '15 km corsa',
      sport: TrainingSport.running,
      date: DateTime(2026, 9, 28),
      distanceKm: 15,
      createdAt: DateTime(2026, 9, 28),
    );
    await store.saveTrainingPlan(plan);
    await store.saveTrainingSession(session);

    expect(await store.moveTrainingPlanToTrash(plan.id), isTrue);
    expect(await store.moveTrainingSessionToTrash(session.id), isTrue);
    expect(store.trainingPlans, isEmpty);
    expect(store.trainingSessions, isEmpty);

    final planTrash = store.trash
        .singleWhere((e) => e.kind == TrashEntityKind.trainingPlan);
    final sessionTrash = store.trash
        .singleWhere((e) => e.kind == TrashEntityKind.trainingSession);
    expect(await store.restoreTrashEntry(planTrash.id), isTrue);
    expect(await store.restoreTrashEntry(sessionTrash.id), isTrue);
    expect(store.trainingPlans.single.id, plan.id);
    expect(store.trainingSessions.single.id, session.id);
    store.dispose();
  });

  test('training is account isolated', () async {
    final store = AgendaStore();
    await store.load();

    await store.activateCloudAccount('training-a');
    await store.saveTrainingSession(
      TrainingSession(
        id: 'a',
        title: 'Corsa A',
        sport: TrainingSport.running,
        date: DateTime(2026, 9, 28),
        createdAt: DateTime(2026, 9, 28),
      ),
    );

    await store.activateCloudAccount('training-b');
    expect(store.trainingSessions, isEmpty);
    await store.saveTrainingSession(
      TrainingSession(
        id: 'b',
        title: 'Bici B',
        sport: TrainingSport.cycling,
        date: DateTime(2026, 9, 28),
        createdAt: DateTime(2026, 9, 28),
      ),
    );

    await store.activateCloudAccount('training-a');
    expect(store.trainingSessions.single.id, 'a');
    store.dispose();
  });

  test('v0.72 remains lightweight rather than a full fitness platform', () {
    expect(TrainingSport.values, containsAll([
      TrainingSport.gym,
      TrainingSport.running,
      TrainingSport.cycling,
      TrainingSport.hiking,
      TrainingSport.swimming,
      TrainingSport.other,
    ]));

    final planSource =
        File('lib/src/training_domain.dart').readAsStringSync().toLowerCase();
    expect(planSource, isNot(contains('1rm')));
    expect(planSource, isNot(contains('calorie')));
    expect(planSource, isNot(contains('ai workout')));
    expect(planSource, isNot(contains('exercise database')));
  });
}
