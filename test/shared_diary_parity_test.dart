import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Noi shared composer exposes the same Note Sketch Photo diary tools',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'active_account_v1': 'user-a',
      });

      final store = AgendaStore();
      await store.load();

      final space = SharedSpace(
        id: 'space-a',
        ownerId: 'user-a',
        name: 'Noi ♡',
        role: 'owner',
        createdAt: DateTime.utc(2026, 9, 23),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SharedSpaceScreen(
            store: store,
            space: space,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Il nostro diario'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Nota'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sketch'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Foto'), findsOneWidget);

      await tester.tap(find.text('Condividi'));
      await tester.pumpAndSettle();

      expect(find.text('Diario condiviso · Noi ♡'), findsOneWidget);
      expect(find.text('Nota'), findsWidgets);
      expect(find.text('Sketch'), findsWidgets);
      expect(find.text('Foto'), findsWidgets);
      expect(find.text('Appuntamento'), findsOneWidget);
      expect(find.text('Da fare'), findsOneWidget);

      store.dispose();
    },
  );
}
