import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Noi shared composer exposes the same Note Sketch Photo diary tools',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'active_account_v1': 'user-a',
      });

      const strings = AnnaStrings('en');
      final store = AgendaStore();
      await tester.runAsync(store.load);

      final space = SharedSpace(
        id: 'space-a',
        ownerId: 'user-a',
        name: 'Noi ♡',
        role: 'owner',
        createdAt: DateTime.utc(2026, 9, 23),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: SharedSpaceScreen(
            store: store,
            space: space,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.d3('ourDiary')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, strings.d3('note')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sketch'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, strings.d3('photoLabel')), findsOneWidget);

      await tester.tap(find.text(strings.d3('share')));
      await tester.pumpAndSettle();

      expect(find.text(strings.d3('sharedDiary')), findsOneWidget);
      expect(find.text(strings.d3('note')), findsWidgets);
      expect(find.text('Sketch'), findsWidgets);
      expect(find.text(strings.d3('photoLabel')), findsWidgets);
      expect(find.text(strings.appointment), findsOneWidget);
      expect(find.text(strings.d3('toDo')), findsOneWidget);

      store.dispose();
    },
  );
}
