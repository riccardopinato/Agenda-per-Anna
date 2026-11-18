import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AgendaStore store;
  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = AgendaStore();
    // Bootstrap real storage outside the Flutter FakeAsync widget frame.
    await store.load();
    await store.activateCloudAccount('user-a');
    expect(store.activeAccountId, 'user-a');
  });
  tearDown(() async {
    store.dispose();
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  testWidgets('open shared detail remains hidden after A to B to A', (tester) async {
    final space = SharedSpace(
      id: 'test-space-a',
      ownerId: 'user-a',
      name: 'Account A private shared space',
      role: 'owner',
      createdAt: DateTime.utc(2026, 11, 18),
    );

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      home: SharedSpaceScreen(store: store, space: space),
    ));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text(space.name), findsOneWidget);

    await tester.runAsync(() => store.activateCloudAccount('user-b'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text(space.name), findsNothing);
    expect(find.text(const AnnaStrings('en').d3('sharedSessionExpired')),
        findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.runAsync(() => store.activateCloudAccount('user-a'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text(space.name), findsNothing,
        reason: 'A→B→A must not revalidate a stale detail route');
    expect(find.text(const AnnaStrings('en').d3('sharedSessionExpired')),
        findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('separately routed shared hub cannot leak A after B or A again',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      home: SharedSpaceHubScreen(store: store),
    ));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
        find.byKey(const ValueKey<String>('together-stale-account-session')),
        findsNothing);

    await tester.runAsync(() => store.activateCloudAccount('user-b'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
        find.byKey(const ValueKey<String>('together-stale-account-session')),
        findsOneWidget);
    expect(
      find.text(sharedSpaceVerificationCopy('en', 'sessionChanged')),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.runAsync(() => store.activateCloudAccount('user-a'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
        find.byKey(const ValueKey<String>('together-stale-account-session')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('stale-session UI is localized in all five supported languages', () {
    for (final language in <String>['it', 'en', 'es', 'fr', 'pt']) {
      final copy = sharedSpaceVerificationCopy(language, 'sessionChanged');
      expect(copy, isNotEmpty);
      expect(copy, isNot('sessionChanged'));
    }
  });

}
