import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open shared detail remains hidden after A to B to A', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'active_account_v1': 'user-a',
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    await tester.runAsync(store.load);
    expect(store.activeAccountId, 'user-a');

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
    await tester.pumpAndSettle();
    expect(find.text(space.name), findsOneWidget);

    await tester.runAsync(() => store.activateCloudAccount('user-b'));
    await tester.pumpAndSettle();
    expect(find.text(space.name), findsNothing);
    expect(find.text(const AnnaStrings('en').d3('sharedSessionExpired')),
        findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.runAsync(() => store.activateCloudAccount('user-a'));
    await tester.pumpAndSettle();
    expect(find.text(space.name), findsNothing,
        reason: 'A→B→A must not revalidate a stale detail route');
    expect(find.text(const AnnaStrings('en').d3('sharedSessionExpired')),
        findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('separately routed shared hub cannot leak A after B or A again',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'active_account_v1': 'user-a',
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    await tester.runAsync(store.load);
    expect(store.activeAccountId, 'user-a');

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      home: SharedSpaceHubScreen(store: store),
    ));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('together-stale-account-session')),
        findsNothing);

    await tester.runAsync(() => store.activateCloudAccount('user-b'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('together-stale-account-session')),
        findsOneWidget);
    expect(
      find.text(sharedSpaceVerificationCopy('en', 'sessionChanged')),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.runAsync(() => store.activateCloudAccount('user-a'));
    await tester.pumpAndSettle();
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
