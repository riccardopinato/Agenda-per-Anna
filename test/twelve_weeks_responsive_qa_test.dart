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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: const TwelveWeeksConceptPreview(),
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
        // The fixed navigation stays reachable even on 320dp / 2x.
        // Long-body scroll + confirmation is covered separately by the
        // full-size widget test; real screen-reader/physical QA stays open.
        expect(find.byKey(const ValueKey('anna-12w-actions')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
