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

  testWidgets('Android smoke: storage, media and primary navigation work',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();

    final store = AgendaStore();
    await store.load();

    await store.savePreferences(
      store.preferences.copyWith(onboardingDone: true),
    );
    await store.addInboxEntry('Smoke Android');
    final today = DateTime.now();
    store.birthdays.add(
      BirthdayEntry(
        id: 'smoke-birthday',
        name: 'Compleanno AppLab',
        day: today.day,
        month: today.month,
        reminderDaysBefore: null,
      ),
    );
    await store.savePerson(
      const PersonEntry(
        id: 'smoke-person',
        name: 'Persona AppLab',
        relationship: 'Amica',
        birthdayId: 'smoke-birthday',
        favorite: true,
      ),
    );
    await store.setPin('2468');
    expect(store.verifyPin('2468'), isTrue);

    final mediaId = await MediaAssetStore.instance.put(
      Uint8List.fromList([11, 22, 33, 44, 55, 66, 77, 88]),
    );
    expect(await MediaAssetStore.instance.read(mediaId), isNotNull);

    await tester.pumpWidget(AgendaApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Agenda bloccata'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2468');
    await tester.tap(find.text('Sblocca'));
    await tester.pumpAndSettle();

    expect(find.text('Agenda per Anna'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Mese'), findsOneWidget);
    expect(find.text('Settimana'), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Oggi in breve'), findsOneWidget);
    expect(find.textContaining('Compleanno AppLab'), findsWidgets);
    expect(find.text('Persone importanti'), findsOneWidget);

    await tester.ensureVisible(find.text('Persone importanti'));
    await tester.tap(find.text('Persone importanti'));
    await tester.pumpAndSettle();
    expect(find.text('Persona AppLab'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Mese'), findsWidgets);
    expect(find.text('Contesto della giornata'), findsOneWidget);

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Settimana'), findsWidgets);

    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.text('Oggi'), findsWidgets);
    expect(find.text('Compleanni'), findsOneWidget);
    expect(find.text('Compleanno AppLab'), findsWidgets);

    store.dispose();
  });
}
