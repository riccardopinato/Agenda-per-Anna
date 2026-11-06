import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('DS6 premium quick action stays palette-derived and tappable',
      (tester) async {
    var taps = 0;
    for (final seed in [Colors.pink, Colors.green, Colors.blue]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: AnnaEditorialQuickAction(
                icon: Icons.event_outlined,
                title: 'Appuntamenti',
                subtitle: 'Dati autentici dal chiamante',
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Appuntamenti'), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.event_outlined));
      expect(icon.color, Theme.of(tester.element(find.byIcon(Icons.event_outlined)))
          .colorScheme.primary);
      await tester.tap(find.text('Appuntamenti'));
      expect(tester.takeException(), isNull);
    }
    expect(taps, 3);
  });

  testWidgets('DS6 featured surface respects a contrasting dark palette',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: AnnaEditorialSurface(
            tone: AnnaEditorialSurfaceTone.featured,
            child: AnnaEditorialHeader(
              title: 'Il mio diario',
              eyebrow: 'IL TUO SPAZIO',
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Il mio diario'), findsOneWidget);
    expect(find.text('IL TUO SPAZIO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
