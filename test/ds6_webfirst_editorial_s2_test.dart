import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// DS6 Web-first S2: Flutter widget/source evidence, NOT installed PWA or
/// screenshot acceptance. No private data, backend, APK or new data owners.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  Widget app(Widget child, {
    Color seed = Colors.teal,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    locale: const Locale('it'),
    supportedLocales: const [
      Locale('it'), Locale('en'), Locale('es'), Locale('fr'), Locale('pt'),
    ],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  DayHubSnapshot emptyDay() => DayHubSnapshot(
    date: DateTime(2026, 11, 8),
    agenda: const [],
    birthdays: const [],
    workouts: const [],
    pendingTaskCount: 0,
    appointmentCount: 0,
    journal: const DayJournal(note: 'Testo personale riservato'),
  );

  testWidgets('Oggi editorial hero retains real actions and hides note text',
      (tester) async {
    var diaryOpenCount = 0;
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      snapshot: emptyDay(),
      hideDetails: true,
      onOpenDiary: () => diaryOpenCount++,
      onOpenCalendar: () {},
      onOpenDay: () {},
    )));
    expect(find.byKey(const ValueKey<String>('editorial-today-accent-rule')),
        findsOneWidget);
    expect(find.text('Il mio diario'), findsOneWidget);
    expect(find.text('Testo personale riservato'), findsNothing);
    expect(find.text('•••'), findsNWidgets(2));
    await tester.tap(find.byType(FilledButton).first);
    expect(diaryOpenCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Calendario keeps supplied child and authentic week date',
      (tester) async {
    await tester.pumpWidget(app(Column(
      children: [
        const AnnaEditorialCalendarPanel(
          enabled: true,
          featured: true,
          child: Text('Original month grid'),
        ),
        AnnaEditorialCalendarWeekSummary(
          start: DateTime(2026, 11, 2),
          end: DateTime(2026, 11, 8),
          eventCount: 3,
          completedTasks: 1,
          totalTasks: 2,
        ),
      ],
    )));
    expect(find.text('Original month grid'), findsOneWidget);
    expect(find.byKey(
        const ValueKey<String>('editorial-calendar-notebook-rule')),
        findsOneWidget);
    expect(find.byKey(
        const ValueKey<String>('editorial-calendar-week-date')),
        findsOneWidget);
    expect(find.textContaining('2 nov'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Classic calendar keeps the original surface', (tester) async {
    await tester.pumpWidget(app(const AnnaEditorialCalendarPanel(
      enabled: false,
      child: Text('Calendario Classic'),
    )));
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Calendario Classic'), findsOneWidget);
    expect(find.byType(AnnaEditorialAccentRule), findsNothing);
    expect(find.byType(AnnaEditorialDateLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shared notebook date label fits small screen and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final dark in [false, true]) {
      await tester.pumpWidget(app(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(children: [
              AnnaEditorialDateLabel(text: 'Domenica 8 novembre 2026'),
              SizedBox(height: 8),
              AnnaEditorialDateLabel(
                text: 'Domenica 8 novembre 2026', onMedia: true,
              ),
            ]),
          ),
        ),
        seed: Colors.purple,
        brightness: dark ? Brightness.dark : Brightness.light,
      ));
      expect(find.byType(AnnaEditorialDateLabel), findsNWidgets(2));
      expect(find.text('Domenica 8 novembre 2026'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    }
  });

  test('Ricordi uses authentic record dates with unchanged media routes', () {
    final source = File('lib/src/diary/editorial_memories.dart')
        .readAsStringSync();
    expect(source, contains('AnnaEditorialDateLabel('));
    expect(source, contains('onMedia: true'));
    expect(source, contains('block.hasPhotoMedia'));
    expect(source, contains('_coverPreview(context, record)'));
    expect(source, contains('_openPhoto(record)'));
    expect(source, contains('_openRecord(record)'));
    expect(source, isNot(contains('saveJournal(')));
    expect(source, isNot(contains('Supabase')));
  });
  testWidgets('Notebook week summary survives large text and palette variants',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 760);
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(app(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 760),
              textScaler: const TextScaler.linear(1.6),
            ),
            child: AnnaEditorialCalendarWeekSummary(
              start: DateTime(2026, 11, 2),
              end: DateTime(2026, 11, 8),
              eventCount: 3,
              completedTasks: 1,
              totalTasks: 2,
            ),
          ),
          brightness: brightness,
          seed: Colors.deepOrange,
        ));
        expect(find.byKey(const ValueKey<String>(
          'editorial-calendar-week-summary-rule',
        )), findsOneWidget);
        expect(find.byKey(const ValueKey<String>(
          'editorial-calendar-week-date',
        )), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'week summary width $width brightness $brightness');
      }
    }
  });

  test('Quaderno illustrato keeps real month and all seven week days',
      () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final month = source
        .split('class _CalendarScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    final week = source
        .split('class _WeekScreenState')[1]
        .split('class _WeekHero')[0];
    final dayCard = source
        .split('class _WeekDayCard')[1]
        .split('class WeekMemoryCard')[0];
    expect(month, contains('TableCalendar<UnifiedAgendaEntry>'));
    expect(month, contains('selectedDayPredicate: (d) => isSameDay(d, selected)'));
    expect(month, contains('eventLoader: (day) =>'));
    expect(month, contains('todayDecoration: BoxDecoration('));
    expect(month, contains('markersMaxCount: 3'));
    expect(month, contains('widget.onSelectedDateChanged?.call(s)'));
    expect(week, contains('for (int i = 6; i >= 0; i--)'));
    expect(dayCard, contains('organic-week-day-'));
    expect(dayCard, contains('captureDate: day,'));
    expect(dayCard, contains('UnifiedAgendaTile(store: store, entry: item'));
    expect(dayCard, contains('AnnaOrganicPastel.surface(context)'));
  });


  testWidgets('Calendar notebook filters keep localized words intact',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(app(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(1.6),
        ),
        child: AgendaContentFilterBar(
          store: store,
          calendarNotebook: true,
        ),
      ),
    ));
    expect(find.byKey(const ValueKey<String>(
      'calendar-notebook-filter-wrap',
    )), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    for (final value in AgendaContentFilter.values) {
      final pill = find.byKey(ValueKey<String>(
        'calendar-notebook-filter-${value.name}',
      ));
      expect(pill, findsOneWidget);
      final label = tester.widget<Text>(
        find.descendant(of: pill, matching: find.byType(Text)).first,
      );
      expect(label.maxLines, 1);
      expect(label.softWrap, false);
    }
    await tester.tap(find.byKey(ValueKey<String>(
      'calendar-notebook-filter-${AgendaContentFilter.values.last.name}',
    )));
    await tester.pump();
    expect(store.agendaContentFilter, AgendaContentFilter.values.last);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(app(AgendaContentFilterBar(store: store)));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(SegmentedButton<AgendaContentFilter>),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Original journal calendar selector keeps the Classic M3 separate',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 720);
      for (final dark in [false, true]) {
        bool? selection;
        await tester.pumpWidget(app(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 720),
              textScaler: const TextScaler.linear(1.6),
            ),
            child: AnnaOrganicCalendarModePicker(
              monthSelected: true,
              monthLabel: 'Mese',
              weekLabel: 'Settimana',
              onSelected: (value) => selection = value,
            ),
          ),
          brightness: dark ? Brightness.dark : Brightness.light,
        ));
        expect(find.byType(SegmentedButton), findsNothing);
        expect(find.byKey(
            const ValueKey<String>('organic-calendar-mode-month')),
            findsOneWidget);
        await tester.tap(find.byKey(
            const ValueKey<String>('organic-calendar-mode-week')));
        expect(selection, false);
        expect(tester.takeException(), isNull);
      }
    }
  });

}
