import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda root renders the first-run experience', (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AgendaRoot(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('La tua agenda, davvero tua.'), findsOneWidget);
    expect(find.text('Continua con Google'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
