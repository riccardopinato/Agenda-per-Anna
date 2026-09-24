import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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

  test('release candidate keeps private working sets isolated end to end',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');

    await store.upsert(
      AgendaItem(
        id: 'rc-task',
        title: 'Release candidate',
        note: 'Persistenza privata',
        date: DateTime(2026, 9, 24),
        type: ItemType.task,
        start: const TimeOfDay(hour: 9, minute: 30),
      ),
    );
    await store.saveJournal(
      DateTime(2026, 9, 24),
      const DayJournal(
        beautiful: 'Flusso RC',
        note: 'Diario isolato',
      ),
    );
    await store.addInboxEntry('Inbox A');

    await store.activateCloudAccount('user-b');

    expect(store.items, isEmpty);
    expect(store.inbox, isEmpty);
    expect(store.journal(DateTime(2026, 9, 24)).beautiful, isEmpty);

    await store.addInboxEntry('Inbox B');
    await store.activateCloudAccount('user-a');

    expect(store.items.map((item) => item.id), contains('rc-task'));
    expect(
      store.journal(DateTime(2026, 9, 24)).beautiful,
      'Flusso RC',
    );
    expect(store.inbox.map((entry) => entry.text), contains('Inbox A'));
    expect(store.inbox.map((entry) => entry.text), isNot(contains('Inbox B')));

    store.dispose();
  });

  test('full restore replaces granular mutations and clears stale deltas',
      () async {
    final store = AgendaStore();
    await store.load();

    await store.upsert(
      AgendaItem(
        id: 'stale-item',
        title: 'Da sostituire',
        note: '',
        date: DateTime(2026, 9, 24),
        type: ItemType.task,
      ),
    );
    await store.saveJournal(
      DateTime(2026, 9, 24),
      const DayJournal(beautiful: 'Delta precedente'),
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    expect(
      state.getKeys().where((key) => key.startsWith('entity_delta_v2_')),
      isNotEmpty,
    );

    final restoredItem = AgendaItem(
      id: 'restored-item',
      title: 'Ripristinato',
      note: 'Baseline nuova',
      date: DateTime(2026, 9, 25),
      type: ItemType.appointment,
    );
    final rawBackup = jsonEncode({
      'format': 'agenda_per_anna_backup',
      'schemaVersion': 1,
      'appVersion': appReleaseVersion,
      'exportedAt': DateTime(2026, 9, 24).toIso8601String(),
      'data': {
        'items': [restoredItem.toJson()],
        'journals': <String, Object>{},
        'months': <String, Object>{},
        'weeks': <String, Object>{},
        'habits': <Object>[],
        'inbox': <Object>[],
      },
    });

    await store.restoreBackup(rawBackup, merge: false);

    expect(store.items.map((item) => item.id), ['restored-item']);
    expect(
      state.getKeys().where((key) => key.startsWith('entity_delta_v2_')),
      isEmpty,
    );

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(reloaded.items.map((item) => item.id), ['restored-item']);
    expect(
      reloaded.items.any((item) => item.id == 'stale-item'),
      isFalse,
    );

    store.dispose();
    reloaded.dispose();
  });

  test('invalid restore cannot mutate active or persisted working state',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Dato stabile');

    await expectLater(
      store.restoreBackup(
        jsonEncode({
          'format': 'invalid_backup',
          'schemaVersion': 1,
          'data': <String, Object>{},
        }),
        merge: false,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(store.inbox.map((entry) => entry.text), contains('Dato stabile'));

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(
      reloaded.inbox.map((entry) => entry.text),
      contains('Dato stabile'),
    );

    store.dispose();
    reloaded.dispose();
  });

  test('release repository keeps hardened Android packaging contract', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final releaseWorkflow =
        File('.github/workflows/build.yml').readAsStringSync();
    final devWorkflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();
    final sizeWorkflow =
        File('.github/workflows/android-size-audit.yml').readAsStringSync();
    final sideloadWorkflow =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final dockerfile = File('Dockerfile').readAsStringSync();
    final appLabWorkflow =
        File('.github/workflows/applab.yml').readAsStringSync();
    final appLabJourney =
        File('.maestro/applab-journey.json').readAsStringSync();
    final authGate =
        File('lib/src/auth/universal_auth_gate.dart').readAsStringSync();
    final androidPrepare =
        File('tool/prepare_android_platform.py').readAsStringSync();

    expect(appReleaseVersion, '0.41.0');
    expect(pubspec, contains('version: 0.41.0+49'));

    expect(releaseWorkflow, contains('--release-signing'));
    expect(releaseWorkflow, contains('--obfuscate'));
    expect(releaseWorkflow, contains('--split-debug-info=build/symbols'));
    expect(releaseWorkflow, contains('--split-per-abi'));
    expect(releaseWorkflow, contains('flutter build appbundle'));
    expect(releaseWorkflow, contains('app-arm64-v8a-release.apk'));
    expect(releaseWorkflow, contains('app-universal-release.apk'));

    expect(devWorkflow, contains('Build Android ARM64 release gate'));
    expect(devWorkflow, contains('--release'));
    expect(devWorkflow, contains('app-arm64-v8a-release.apk'));
    expect(sizeWorkflow, contains('--split-per-abi'));
    expect(sizeWorkflow, contains('app-arm64-v8a-release.apk'));

    expect(sideloadWorkflow, contains('.signing/sideload.jks'));
    expect(sideloadWorkflow, contains('annas-diary-sideload-signing-v2'));
    expect(sideloadWorkflow, contains('--release-signing'));
    expect(sideloadWorkflow, contains('app-arm64-v8a-release.apk'));
    expect(dockerfile, startsWith('FROM ghcr.io/cirruslabs/flutter:3.47.5'));
    expect(dockerfile, contains('flutter pub get --enforce-lockfile'));

    expect(appLabWorkflow, contains('AppLab Production Gate'));
    expect(appLabWorkflow, contains('flutter_version: "3.47.5"'));
    expect(appLabWorkflow, contains('app-arm64-v8a-release.apk'));
    expect(appLabWorkflow, contains('.maestro/applab-smoke.yaml'));
    expect(appLabJourney, contains('"calendar"'));
    expect(appLabJourney, contains('"week"'));
    expect(appLabJourney, contains('"today"'));
    expect(appLabJourney, contains('"memories"'));
    expect(appLabWorkflow, contains('ANNAS_DIARY_APPLAB_AUTH_BYPASS=true'));

    expect(authGate, contains('Continua con Google'));
    expect(authGate, contains('Hai già un account email/password?'));
    expect(
      appLabWorkflow,
      contains('--project-name agenda_per_anna --org com.riccardopinato'),
    );
    expect(
      androidPrepare,
      contains('com.riccardopinato.agendaperanna'),
    );
    expect(androidPrepare, contains('login-callback'));
  });
}
