import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('DS6 notebook preserves the canonical calendar child',
      (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnaEditorialCalendarPanel(
              enabled: true,
              featured: true,
              padding: EdgeInsets.all(16),
              child: Text('Canonical month grid'),
            ),
          ),
        ),
      ));
      expect(find.text('Canonical month grid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('DS6 notebook Classic fallback does not add premium surface',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnnaEditorialCalendarPanel(
          enabled: false,
          child: Text('Classic calendar'),
        ),
      ),
    ));
    expect(find.text('Classic calendar'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(AnnaEditorialSurface), findsNothing);
  });
}
