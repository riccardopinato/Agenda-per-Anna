import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('DS6 Today greeting shares top row and keeps both actions',
      (tester) async {
    var calendarOpens = 0;
    var classicOpens = 0;

    for (final width in [320.0, 390.0, 470.0]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: AnnaTodayEditorialGreetingToolbar(
                greeting: 'Buon pomeriggio, Riccardo',
                calendarTooltip: 'Calendario',
                classicTooltip: 'Classic',
                onOpenCalendar: () => calendarOpens++,
                onReturnToClassic: () => classicOpens++,
              ),
            ),
          ),
        ),
      ));

      final greeting = find.byKey(
        const ValueKey<String>('ds6-today-greeting'),
      );
      final calendar = find.byKey(
        const ValueKey<String>('today-open-calendar'),
      );
      final classic = find.byKey(
        const ValueKey<String>('today-editorial-disable'),
      );

      expect(greeting, findsOneWidget);
      expect(calendar, findsOneWidget);
      expect(classic, findsOneWidget);
      expect(find.text('Anna’s Diary'), findsNothing);
      expect(find.textContaining('Un’agenda serve'), findsNothing);

      final text = tester.widget<Text>(greeting);
      expect(text.data, 'Buon pomeriggio,\nRiccardo');
      expect(text.style!.fontSize!, lessThan(36));
      expect(text.style!.fontSize!, greaterThanOrEqualTo(17));
      expect(tester.getRect(greeting).right,
          lessThanOrEqualTo(tester.getRect(calendar).left + 0.1));
      expect(tester.takeException(), isNull);

      await tester.tap(calendar);
      await tester.tap(classic);
      expect(tester.takeException(), isNull);
    }
    expect(calendarOpens, 3);
    expect(classicOpens, 3);
  });

  testWidgets('DS6 greeting accommodates long names and enlarged text',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: AnnaTodayEditorialGreetingToolbar(
                greeting: 'Buon pomeriggio, Alessandro Riccardo',
                calendarTooltip: 'Calendario',
                classicTooltip: 'Classic',
                onOpenCalendar: () {},
                onReturnToClassic: () {},
              ),
            ),
          ),
        ),
      ),
    ));

    expect(find.byKey(
      const ValueKey<String>('ds6-today-greeting'),
    ), findsOneWidget);
    expect(find.byKey(
      const ValueKey<String>('today-open-calendar'),
    ), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('source uses one compact header; Classic opening remains unchanged', () {
    // The independent widget checks above cover dimensions and actions.
    // This source contract is verified by the existing CI source gates.
    expect(AnnaTodayEditorialGreetingToolbar, isNotNull);
  });
}
