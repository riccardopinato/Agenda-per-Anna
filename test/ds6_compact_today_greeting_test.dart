import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  Widget app({
    required double width,
    required String greeting,
    required VoidCallback calendar,
    required VoidCallback classic,
    bool reduceMotion = false,
    bool activeInShell = true,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: AnnaTodayEditorialGreetingToolbar(
                greeting: greeting,
                activeInShell: activeInShell,
                calendarTooltip: 'Calendario',
                classicTooltip: 'Classic',
                onOpenCalendar: calendar,
                onReturnToClassic: classic,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('single-line ticker shares 48dp heading with Calendar and Classic',
      (tester) async {
    var calendarOpens = 0;
    var classicOpens = 0;

    for (final width in [320.0, 390.0, 470.0]) {
      await tester.pumpWidget(app(
        width: width,
        greeting: 'Buon pomeriggio, Riccardo',
        calendar: () => calendarOpens++,
        classic: () => classicOpens++,
      ));
      await tester.pump();

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
      expect(tester.getSize(find.byKey(
        const ValueKey<String>('ds6-today-compact-header'),
      )).height, lessThanOrEqualTo(56));
      expect(tester.getRect(greeting).right,
          lessThanOrEqualTo(tester.getRect(calendar).left + 0.1));
      for (final textWidget in tester.widgetList<Text>(
        find.descendant(of: greeting, matching: find.byType(Text)),
      )) {
        expect(textWidget.maxLines, 1);
        expect(textWidget.softWrap, false);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(calendar);
      await tester.tap(classic);
      expect(tester.takeException(), isNull);
    }

    expect(calendarOpens, 3);
    expect(classicOpens, 3);
  });

  testWidgets('long greeting continuously scrolls left without wrapping',
      (tester) async {
    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Riccardo',
      calendar: () {},
      classic: () {},
    ));
    await tester.pump();
    final marquee = find.byKey(
      const ValueKey<String>('ds6-today-marquee'),
    );
    expect(marquee, findsOneWidget);
    final copies = find.descendant(
      of: marquee,
      matching: find.text('Buon pomeriggio, Riccardo'),
    );
    expect(copies, findsWidgets);
    final initial = tester.getTopLeft(copies.first).dx;
    await tester.pump(const Duration(seconds: 2));
    final later = tester.getTopLeft(copies.first).dx;
    expect(later, lessThan(initial));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced-motion shows one static ellipsized single-line greeting',
      (tester) async {
    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Alessandro Riccardo',
      calendar: () {},
      classic: () {},
      reduceMotion: true,
      textScale: 1.5,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(
      const ValueKey<String>('ds6-today-marquee'),
    ), findsNothing);
    final staticText = tester.widget<Text>(find.byKey(
      const ValueKey<String>('ds6-today-static-greeting'),
    ));
    expect(staticText.data, 'Buon pomeriggio, Alessandro Riccardo');
    expect(staticText.maxLines, 1);
    expect(staticText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticker restarts when an overflowing greeting changes',
      (tester) async {
    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Riccardo',
      calendar: () {},
      classic: () {},
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Same widget position keeps the existing AnimationController mounted.
    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Alessandro',
      calendar: () {},
      classic: () {},
    ));
    await tester.pump();
    final repeated = find.descendant(
      of: find.byKey(const ValueKey<String>('ds6-today-marquee')),
      matching: find.text('Buon pomeriggio, Alessandro'),
    );
    expect(repeated, findsWidgets);
    final before = tester.getTopLeft(repeated.first).dx;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getTopLeft(repeated.first).dx, lessThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden Today tab stops ticker and reactivates on return',
      (tester) async {
    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Riccardo',
      calendar: () {},
      classic: () {},
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(
      const ValueKey<String>('ds6-today-marquee'),
    ), findsOneWidget);

    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Riccardo',
      activeInShell: false,
      calendar: () {},
      classic: () {},
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(
      const ValueKey<String>('ds6-today-marquee'),
    ), findsNothing);
    expect(find.byKey(
      const ValueKey<String>('ds6-today-static-greeting'),
    ), findsOneWidget);

    await tester.pumpWidget(app(
      width: 320,
      greeting: 'Buon pomeriggio, Riccardo',
      calendar: () {},
      classic: () {},
    ));
    await tester.pump();
    final repeated = find.descendant(
      of: find.byKey(const ValueKey<String>('ds6-today-marquee')),
      matching: find.text('Buon pomeriggio, Riccardo'),
    );
    final before = tester.getTopLeft(repeated.first).dx;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getTopLeft(repeated.first).dx, lessThan(before));
    expect(tester.takeException(), isNull);
  });

  test('Editorial Today has no separate brand or quote below greeting', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final start = source.indexOf('if (editorial) ...[\n'
        '                          AnnaTodayEditorialGreetingToolbar(');
    expect(start, greaterThanOrEqualTo(0));
    final stop = source.indexOf('if (!widget.embedded) _DayOpeningCard', start);
    expect(stop, greaterThan(start));
    final editorialHeader = source.substring(start, stop);
    expect(editorialHeader, isNot(contains('Anna’s Diary')));
    expect(editorialHeader, isNot(contains('AnnaEditorialHeader(')));
    expect(editorialHeader, isNot(contains('subtitle: _dailyQuote')));
    expect(editorialHeader, contains('const SizedBox(height: 4)'));
    expect(editorialHeader, contains('activeInShell: widget.activeInShell'));
  });
}
