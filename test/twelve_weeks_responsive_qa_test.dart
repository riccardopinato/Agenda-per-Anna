import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in <double>[320, 360, 600]) {
    for (final scale in <double>[1, 2]) {
      testWidgets('12-week preview $width dp at ${scale}x text',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('it'),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 760),
              textScaler: TextScaler.linear(scale),
            ),
            child: const TwelveWeeksConceptPreview(),
          ),
        ));
        expect(find.byKey(const ValueKey('anna-12w-native-preview')),
            findsOneWidget);
        for (var step = 0; step < 3; step++) {
          final next = find.byKey(const ValueKey('anna-12w-next'));
          await tester.ensureVisible(next);
          await tester.pumpAndSettle();
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.byKey(const ValueKey('anna-12w-simulate')),
            findsOneWidget);
        final agree = find.byType(CheckboxListTile).last;
        await tester.ensureVisible(agree);
        await tester.pumpAndSettle();
        await tester.tap(agree);
        await tester.pumpAndSettle();
        final simulate = find.byKey(const ValueKey('anna-12w-simulate'));
        await tester.ensureVisible(simulate);
        await tester.pumpAndSettle();
        await tester.tap(simulate);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('anna-12w-done')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
