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

  test('first launch exposes an explicit device-only path', () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final identity =
        File('lib/src/screens/universal_identity.dart').readAsStringSync();
    final strings = File('lib/src/localization_d3.dart').readAsStringSync();

    expect(
      shell,
      contains(
        'store.activeAccountId == null &&\n'
        '              !store.localEntrySelected',
      ),
    );
    expect(shell, contains('return UniversalIdentityScreen(store: store);'));
    expect(identity, contains('Future<void> _continueOffline() async'));
    expect(identity, contains('await widget.store.continueWithoutAccount();'));
    expect(identity, contains("d3('continueOffline')"));
    expect(strings, contains('"continueOffline": <String, String>'));
    expect(strings, contains('"offlineEntryHint": <String, String>'));
  });

  test('device-only selection and guest data survive process restart', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    await store.addInboxEntry('Guest survives restart');
    store.dispose();

    final restored = AgendaStore();
    await restored.load();

    expect(restored.localEntrySelected, isTrue);
    expect(restored.accountScopeResolved, isTrue);
    expect(restored.activeAccountId, isNull);
    expect(
      restored.inbox.map((entry) => entry.text),
      contains('Guest survives restart'),
    );

    restored.dispose();
  });

  test('guest and authenticated account scopes never merge implicitly', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    await store.addInboxEntry('Guest only');

    await store.activateCloudAccount('user-a');

    expect(store.activeAccountId, 'user-a');
    expect(store.inbox.map((entry) => entry.text), isNot(contains('Guest only')));

    await store.addInboxEntry('Account only');
    await store.continueWithoutAccount();

    expect(store.activeAccountId, isNull);
    expect(store.localEntrySelected, isTrue);
    expect(store.inbox.map((entry) => entry.text), contains('Guest only'));
    expect(
      store.inbox.map((entry) => entry.text),
      isNot(contains('Account only')),
    );

    await store.activateCloudAccount('user-a');

    expect(store.inbox.map((entry) => entry.text), contains('Account only'));
    expect(
      store.inbox.map((entry) => entry.text),
      isNot(contains('Guest only')),
    );

    store.dispose();
  });

  test('external entry points wait for the selected account scope', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final flow = File('.maestro/applab-smoke.yaml').readAsStringSync();

    expect(mainSource, contains('Future<void> _waitForEntryScope'));
    expect(mainSource, contains('Future<void> _runAfterEntryScope'));
    expect(
      mainSource,
      contains('_handleIncomingShareCapture(context, store, capture)'),
    );
    expect(
      mainSource,
      contains('_handleIncomingEcosystemUri('),
    );
    expect(
      mainSource,
      contains("if (action == 'quick_capture')"),
    );
    expect(
      mainSource,
      contains('_handleLocalReminderAction(store, payload)'),
    );
    expect(shell, isNot(contains('integrationTest || bypassIdentityForTesting')));
    expect(
      flow,
      contains(
        '(Usa su questo dispositivo|Use on this device|Usar en este dispositivo|Utiliser sur cet appareil|Usar neste dispositivo)',
      ),
    );
  });

  test('persisted account working set is immediately available offline',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');
    await store.addInboxEntry('Account local copy');
    store.dispose();

    final restored = AgendaStore();
    await restored.load();

    expect(restored.activeAccountId, 'user-a');
    expect(restored.accountScopeResolved, isTrue);
    expect(
      restored.inbox.map((entry) => entry.text),
      contains('Account local copy'),
    );

    restored.dispose();
  });
}
