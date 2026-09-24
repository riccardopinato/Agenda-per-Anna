import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda app starts', (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    await store.load();
    await store.savePreferences(
      store.preferences.copyWith(onboardingDone: true),
    );

    await tester.pumpWidget(
      AgendaApp(
        store: store,
        authGateBypass: true,
        lifecycleSyncEnabled: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Agenda per Anna'), findsOneWidget);
    store.dispose();
  });
}
