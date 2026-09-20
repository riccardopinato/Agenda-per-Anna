import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda app starts', (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(AgendaApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Agenda per Anna'), findsOneWidget);
  });
}
