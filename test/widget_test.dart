import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda app starts', (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('La mia giornata'), findsWidgets);
    expect(find.text('Cattura'), findsOneWidget);
  });
}
