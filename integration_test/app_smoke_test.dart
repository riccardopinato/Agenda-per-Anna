import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android smoke: local data, media, and current UI5 navigation',
      (tester) async {
    // Exercise the mobile bottom bar rather than the tablet NavigationRail.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await initializeDateFormatting('it_IT', null);
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();

    final store = AgendaStore();
    addTearDown(store.dispose);
    await store.load();
    await store.savePreferences(
      store.preferences.copyWith(onboardingDone: true),
    );

    await store.addInboxEntry('Smoke Android');
    expect(store.inbox.any((entry) => entry.text == 'Smoke Android'), isTrue);

    final mediaId = await MediaAssetStore.instance.put(
      Uint8List.fromList([11, 22, 33, 44, 55, 66, 77, 88]),
    );
    expect(await MediaAssetStore.instance.read(mediaId), isNotNull);

    // This is a navigation/storage smoke, not an identity, Vault or biometric
    // acceptance test. Identity is bypassed only for this synthetic fixture.
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();

    final bar = find.byType(NavigationBar);
    expect(bar, findsOneWidget);
    expect(tester.widget<NavigationBar>(bar).destinations, hasLength(4));

    const destinations = <String>[
      'main-nav-today',
      'main-nav-messages',
      'main-nav-memories',
      'main-nav-more',
    ];
    for (final id in destinations) {
      expect(find.byKey(ValueKey<String>(id)), findsOneWidget);
    }

    for (var index = 1; index < destinations.length; index++) {
      await tester.tap(find.byKey(ValueKey<String>(destinations[index])));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(bar).selectedIndex, index);
    }

    await tester.tap(find.byKey(const ValueKey<String>('main-nav-today')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(bar).selectedIndex, 0);

    // +Crea is a separate central action, never an extra bottom-bar tab.
    expect(find.bySemanticsIdentifier('main-nav-create'), findsOneWidget);
  });
}
