import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DS5 retains one date selector, editor and canonical calendar views', () {
    final p = File('lib/src/planner_views.dart').readAsStringSync();
    final d = File('lib/src/editorial_calendar.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains("part 'src/editorial_calendar.dart';"));
    expect(p, contains('ValueListenableBuilder<bool>('));
    expect(p, contains('valueListenable: AnnaEditorialTodayMode.enabled'));
    expect(p, contains('SegmentedButton<_CalendarHubView>'));
    expect(p, contains('CalendarScreen('));
    expect(p, contains('WeekScreen('));
    expect(p, contains('IndexedStack('));
    expect(p, contains('AnnaEditorialCalendarPanel('));
    expect(p, contains('AnnaEditorialCalendarWeekSummary('));
    expect(p, contains('AnnaJournalCard(')); // Classic visual preserved.
    expect(p, contains('calendar-open-month-notebook'));
    expect(p, contains('calendar-open-year-overview'));
    expect(p, contains('MonthScreen(store: widget.store)'));
    expect(p, contains('YearScreen(store: widget.store)'));
    expect(p, contains('TableCalendar<UnifiedAgendaEntry>'));
    expect(p, contains('selectedDayPredicate: (d) => isSameDay(d, selected)'));
    expect(p, contains('widget.onSelectedDateChanged?.call(s)'));
    expect(p, contains('approved-calendar-hourly-timeline'));
    expect(p, contains('initiallyExpanded: false'));
    expect(p, contains('for (var hour = 7; hour <= 22; hour++)'));
    expect(p, contains('initialTime: TimeOfDay(hour: hour, minute: 0)'));
    expect(p, contains('initialType: ItemType.appointment'));
    expect(p, contains('await openItemEditor('));
    expect(p, contains('openUnifiedAgendaEntry('));
    expect(p, contains('AgendaContentFilterBar(store: widget.store)'));
    expect(p, contains('UnifiedAgendaTile('));
    expect(p, contains('_CalendarDayContextCard('));
    expect(p, contains('showCalendarFreeSlots('));
    expect(d, isNot(contains('saveJournal(')));
    expect(d, isNot(contains('openItemEditor(')));
    expect(d, isNot(contains('CloudSyncService')));
    expect(d, isNot(contains('MemoryRepository')));
  });

  testWidgets('Editorial calendar surface stays legible at 320dp large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: SingleChildScrollView(
            child: AnnaEditorialCalendarPanel(
              key: const ValueKey('editorial-calendar-responsive'),
              enabled: true,
              featured: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ogni giorno, una storia.'),
                  OutlinedButton.icon(
                    onPressed: () => pressed = true,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Il mio mese'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('editorial-calendar-responsive')),
        findsOneWidget);
    expect(find.byType(AnnaEditorialSurface), findsOneWidget);
    expect(find.text('Ogni giorno, una storia.'), findsOneWidget);
    await tester.tap(find.text('Il mio mese'));
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Classic calendar surface still uses original Card',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnnaEditorialCalendarPanel(
          enabled: false,
          child: Text('Il mio anno'),
        ),
      ),
    ));
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(AnnaEditorialSurface), findsNothing);
    expect(find.text('Il mio anno'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Editorial week summary shows only supplied event counts',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: AnnaEditorialCalendarWeekSummary(
          start: DateTime(2026, 11, 2),
          end: DateTime(2026, 11, 8),
          eventCount: 3,
          completedTasks: 1,
          totalTasks: 2,
        ),
      ),
    ));
    expect(find.byType(AnnaEditorialSurface), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
