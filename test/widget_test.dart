import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda shell starts after identity/onboarding gates', (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    await store.load();
    await store.savePreferences(
      store.preferences.copyWith(onboardingDone: true),
    );

    await tester.pumpWidget(
      MaterialApp(home: AgendaRoot(store: store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda per Anna'), findsOneWidget);
    store.dispose();
  });
}
