import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Agenda app starts', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    await tester.pumpAndSettle();
    expect(find.text('Agenda per Anna'), findsOneWidget);
  });
}
