import 'dart:io';

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

  test('multisport sessions preserve sport-specific optional metrics', () async {
    final store = AgendaStore();
    await store.load();

    final run = await store.addTrainingSession(
      sport: TrainingSport.running,
      date: DateTime(2026, 9, 28),
      title: 'Lungo',
      durationMinutes: 75,
      distanceKm: 15,
      elevationMeters: 120,
      rpe: 7,
    );
    final bike = await store.addTrainingSession(
      sport: TrainingSport.cycling,
      date: DateTime(2026, 9, 27),
      durationMinutes: 120,
      distanceKm: 50,
    );
    final gym = await store.addTrainingSession(
      sport: TrainingSport.gym,
      date: DateTime(2026, 9, 26),
      details: 'Squat 4x6 @ 80 kg',
    );

    expect(store.trainingSessions, hasLength(3));
    expect(store.trainingSessionsForSport(TrainingSport.running).single.id, run.id);
    expect(store.trainingSessionsForSport(TrainingSport.cycling).single.id, bike.id);
    expect(store.trainingSessionsForSport(TrainingSport.gym).single.id, gym.id);
    expect(store.averageSpeedKmh(bike), closeTo(25, 0.001));
    expect(store.pacePerKm(run)!.inSeconds, 300);
    expect(gym.distanceKm, 0);
    store.dispose();
  });

  test('training plans share the same canonical record model', () async {
    final store = AgendaStore();
    await store.load();

    final plan = await store.addTrainingPlan(
      title: 'Scheda A/B',
      sport: TrainingSport.gym,
      details: 'A: squat, panca\nB: stacco, trazioni',
      notes: 'Progressione 4 settimane',
    );

    expect(plan.isPlan, isTrue);
    expect(store.trainingPlans.single.details, contains('squat'));
    expect(store.trainingSessions, isEmpty);
    store.dispose();
  });

  test('training persists across restart and account profiles', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('training-a');
    await store.addTrainingSession(
      sport: TrainingSport.running,
      date: DateTime(2026, 9, 28),
      distanceKm: 15,
      durationMinutes: 75,
    );
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(reloaded.trainingRecords, hasLength(1));
    await reloaded.activateCloudAccount('training-b');
    expect(reloaded.trainingRecords, isEmpty);
    await reloaded.addTrainingSession(
      sport: TrainingSport.cycling,
      date: DateTime(2026, 9, 28),
      distanceKm: 50,
      durationMinutes: 120,
    );
    await reloaded.activateCloudAccount('training-a');
    expect(reloaded.trainingRecords.single.sport, TrainingSport.running);
    reloaded.dispose();
  });

  test('training survives backup and Trash restore', () async {
    final source = AgendaStore();
    await source.load();
    final session = await source.addTrainingSession(
      sport: TrainingSport.hiking,
      date: DateTime(2026, 8, 12),
      distanceKm: 12.5,
      elevationMeters: 950,
      durationMinutes: 300,
      notes: 'Dolomiti',
    );
    final backup = await source.createBackupJson();

    expect(await source.moveTrainingRecordToTrash(session.id), isTrue);
    final trashed = source.trash.single;
    expect(trashed.kind, TrashEntityKind.trainingRecord);
    expect(await source.restoreTrashEntry(trashed.id), isTrue);
    expect(source.trainingRecords.single.elevationMeters, 950);
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    final restored = AgendaStore();
    await restored.load();
    await restored.restoreBackup(backup, merge: false);
    expect(restored.trainingRecords.single.sport, TrainingSport.hiking);
    expect(restored.trainingRecords.single.distanceKm, closeTo(12.5, 0.001));
    restored.dispose();
  });

  test('v0.72 architecture uses existing private sync path', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final domain = File('lib/src/training_domain.dart').readAsStringSync();
    final screen = File('lib/src/screens/training_screen.dart').readAsStringSync();

    expect(store, contains("static const _trainingKey = 'training_v1'"));
    expect(domain, contains("type: 'training'"));
    expect(screen, contains('Carica scheda .txt / .md'));
    expect(screen, contains('TrainingSport.running'));
    expect(screen, contains('TrainingSport.cycling'));
    expect(screen, contains('TrainingSport.gym'));
    expect(store.toLowerCase(), isNot(contains('training_engine')));
  });

  test('v0.72 release metadata is aligned', () {
    expect(appReleaseVersion, '0.72.0');
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: 0.72.0+82'));
  });
}
