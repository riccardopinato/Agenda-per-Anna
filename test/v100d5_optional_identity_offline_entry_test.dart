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

  testWidgets('first launch offers an explicit device-only path', (tester) async {
    final store = AgendaStore();
    await store.load();
    await store.savePreferences(
      store.preferences.copyWith(appLanguage: AppLanguage.english),
    );

    await tester.pumpWidget(AgendaApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Use on this device'), findsOneWidget);
    expect(
      find.text(
        'Your diary works on this device without an account. '
        'Sign in only for cross-device sync and Noi ♡.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Use on this device'));
    await tester.pumpAndSettle();

    expect(store.localEntrySelected, isTrue);
    expect(store.activeAccountId, isNull);
    expect(find.text('Your agenda, truly yours.'), findsOneWidget);

    store.dispose();
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
