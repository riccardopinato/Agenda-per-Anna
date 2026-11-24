import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/planner_source_parts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('v136 Organic notebook controls at 320dp / 1.6x: $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var monthOpens = 0;
      var yearOpens = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AnnaOrganicCalendarNotebookLink(
                    key: const ValueKey<String>('v136-month-link'),
                    label: 'Il mio mese',
                    icon: Icons.auto_awesome_outlined,
                    onPressed: () => monthOpens++,
                  ),
                  AnnaOrganicCalendarNotebookLink(
                    key: const ValueKey<String>('v136-year-link'),
                    label: 'Il mio anno',
                    icon: Icons.insights_outlined,
                    onPressed: () => yearOpens++,
                  ),
                  const AnnaOrganicCalendarEmptyAgenda(
                    label: 'Nessun impegno',
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      expect(find.byType(AnnaOrganicCalendarNotebookLink), findsNWidgets(2));
      expect(find.byType(AnnaOrganicCalendarEmptyAgenda), findsOneWidget);
      expect(find.byType(AnnaOrganicPaperSurface), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('v136-month-link')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('v136-year-link')));
      await tester.pump();
      expect(monthOpens, 1);
      expect(yearOpens, 1);
      expect(tester.takeException(), isNull);
    });
  }

  test('v136 Calendar only decorates canonical month, week and agenda', () {
    final source = readPlannerSourceParts();
    final hub = source.split('class _CalendarHubScreenState')[1]
        .split('class CalendarScreen')[0];
    final month = source.split('class _CalendarScreenState')[1]
        .split('/// Approved Oggi R3')[0];
    final week = source.split('class _WeekScreenState')[1]
        .split('class _WeekHero')[0];

    expect(hub, contains('AnnaOrganicCalendarNotebookLink('));
    expect(hub, contains('MediaQuery.textScalerOf(context).scale(1) > 1.3'));
    expect(hub, contains('MonthScreen(store: widget.store)'));
    expect(hub, contains('YearScreen(store: widget.store)'));
    expect(hub, contains('IndexedStack('));
    expect(hub, contains('AnnaJournalCard(')); // Classic still reachable.
    expect(month, contains('TableCalendar<UnifiedAgendaEntry>'));
    expect(month, contains('markerBuilder: (context, day, loadedEvents)'));
    expect(month, contains('isSameDay(day, selected)'));
    expect(month, contains('loadedEvents.length && i < 3'));
    expect(month, contains('eventLoader: (day) =>'));
    expect(month, contains('selectedDayPredicate: (d) => isSameDay(d, selected)'));
    expect(month, contains('onDaySelected: (s, f)'));
    expect(month, contains("approved-calendar-hourly-timeline"));
    expect(month, contains('initiallyExpanded: false'));
    expect(month, contains('AnnaOrganicCalendarEmptyAgenda('));
    expect(month, contains('UnifiedAgendaTile('));
    expect(week, contains('AnnaEditorialCalendarWeekSummary('));
    expect(week, contains('_WeekDayCard('));
    expect(week, contains('WeekFocusCard('));
    expect(week, contains('WeekPrioritiesCard('));
    expect(week, contains('WeekMemoryCard('));
  });
}
