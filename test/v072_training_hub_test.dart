import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/app_version.dart';
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

  test('multisport sessions support running and cycling without gym fields',
      () async {
    final store = AgendaStore();
    await store.load();

    await store.createTrainingSession(
      sport: TrainingSport.running,
      date: DateTime(2026, 9, 28),
      title: 'Lungo',
      distanceKm: 15,
      durationSeconds: 3900,
      notes: 'Buone sensazioni',
    );
    await store.createTrainingSession(
      sport: TrainingSport.cycling,
      date: DateTime(2026, 9, 27),
      distanceKm: 50,
      durationSeconds: 7800,
    );

    expect(store.trainingSessions, hasLength(2));
    expect(store.trainingDistanceForSport(TrainingSport.running), 15);
    expect(store.trainingDistanceForSport(TrainingSport.cycling), 50);
    expect(store.trainingSessions.first.exercises, isEmpty);
    store.dispose();
  });

  test('gym plan can carry exercises and an attached sheet', () async {
    final store = AgendaStore();
    await store.load();
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final plan = await store.createTrainingPlan(
      title: 'Scheda A',
      sport: TrainingSport.gym,
      exercises: const [
        TrainingExercise(name: 'Squat', sets: 4, reps: 8, weightKg: 80),
        TrainingExercise(name: 'Panca', sets: 4, reps: 6, weightKg: 60),
      ],
      attachmentName: 'scheda.pdf',
      attachmentMimeType: 'application/pdf',
      attachmentBase64: base64Encode(bytes),
    );

    expect(plan.hasAttachment, isTrue);
    expect(store.trainingPlans.single.exercises, hasLength(2));

    final roundTrip = TrainingEntry.fromJson(plan.toJson());
    expect(roundTrip.attachmentName, 'scheda.pdf');
    expect(roundTrip.exercises.first.name, 'Squat');
    store.dispose();
  });

  test('session linked to plan can preserve a workout snapshot', () async {
    final store = AgendaStore();
    await store.load();
    final plan = await store.createTrainingPlan(
      title: 'Palestra full body',
      sport: TrainingSport.gym,
      exercises: const [
        TrainingExercise(name: 'Stacco', sets: 3, reps: 5),
      ],
    );

    await store.createTrainingSession(
      sport: TrainingSport.gym,
      date: DateTime(2026, 9, 28),
      planId: plan.id,
      exercises: plan.exercises,
    );

    final session = store.trainingSessions.single;
    expect(session.planId, plan.id);
    expect(session.exercises.single.name, 'Stacco');
    store.dispose();
  });

  test('training persists and remains account isolated', () async {
    final first = AgendaStore();
    await first.load();
    await first.activateCloudAccount('training-a');
    await first.createTrainingSession(
      sport: TrainingSport.running,
      date: DateTime(2026, 9, 28),
      distanceKm: 10,
    );
    first.dispose();

    final second = AgendaStore();
    await second.load();
    await second.activateCloudAccount('training-a');
    expect(second.trainingSessions.single.distanceKm, 10);

    await second.activateCloudAccount('training-b');
    expect(second.trainingEntries, isEmpty);
    await second.createTrainingSession(
      sport: TrainingSport.swimming,
      date: DateTime(2026, 9, 28),
      distanceKm: 2,
    );

    await second.activateCloudAccount('training-a');
    expect(second.trainingSessions.single.sport, TrainingSport.running);
    second.dispose();
  });

  test('training survives backup and Trash restore', () async {
    final source = AgendaStore();
    await source.load();
    final session = await source.createTrainingSession(
      sport: TrainingSport.cycling,
      date: DateTime(2026, 9, 28),
      distanceKm: 50,
      durationSeconds: 7200,
    );
    final backup = await source.createBackupJson();

    expect(await source.moveTrainingEntryToTrash(session.id), isTrue);
    final deleted = source.trash.single;
    expect(deleted.kind, TrashEntityKind.trainingEntry);
    expect(await source.restoreTrashEntry(deleted.id), isTrue);
    expect(source.trainingSessions.single.distanceKm, 50);
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final restored = AgendaStore();
    await restored.load();
    await restored.restoreBackup(backup, merge: false);
    expect(restored.trainingSessions.single.sport, TrainingSport.cycling);
    expect(restored.trainingSessions.single.durationSeconds, 7200);
    restored.dispose();
  });

  test('v0.72 uses existing private sync and release contract', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final domain = File('lib/src/training_domain.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(store, contains("static const _trainingKey = 'training_v1'"));
    expect(domain, contains("type: 'training'"));
    expect(appReleaseVersion, '0.72.0');
    expect(pubspec, contains('version: 0.72.0+82'));
  });
}
