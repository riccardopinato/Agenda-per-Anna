import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda app boots into the first-run experience', (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    await store.load();

    await tester.pumpWidget(
      AgendaApp(
        store: store,
        authGateBypass: true,
        lifecycleSyncEnabled: false,
      ),
    );
    await tester.pump();

    expect(find.text('La tua agenda, davvero tua.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });
}
