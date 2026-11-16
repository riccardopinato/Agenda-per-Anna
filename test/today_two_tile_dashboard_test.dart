import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required AgendaStore store,
    required DateTime date,
    required bool hidden,
    required VoidCallback onDiary,
    required VoidCallback onWeek,
    required double textScale,
    required Brightness brightness,
  }) => MaterialApp(
    locale: const Locale('it'),
    supportedLocales: const [Locale('it'), Locale('en'), Locale('es'),
      Locale('fr'), Locale('pt')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF899657),
          brightness: brightness),
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AnnaEditorialTodayOverview(
              store: store,
              selectedDate: date,
              hideDetails: hidden,
              onOpenDiary: onDiary,
              onOpenWeek: onWeek,
            ),
          ),
        ),
      ),
    ),
  );

  test('journal days are genuine, per week, excluding empty records', () {
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.journals['2026-11-16'] = const DayJournal(note: 'Pensiero privato');
    store.journals['2026-11-18'] =
        const DayJournal(beautiful: 'Una bella giornata');
    store.journals['2026-11-20'] = const DayJournal();
    store.journals['2026-11-23'] = const DayJournal(note: 'Altra settimana');
    expect(AnnaEditorialTodayOverview.annotatedDays(
        store, DateTime(2026, 11, 16)), 2);
    expect(AnnaEditorialTodayOverview.annotatedDays(
        store, DateTime(2026, 11, 22)), 2);
    expect(AnnaEditorialTodayOverview.annotatedDays(
        store, DateTime(2026, 11, 23)), 1);
    expect(store.journals.length, 4);
  });

  testWidgets('two equal dashboard tiles, privacy and existing callbacks',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.journals['2026-11-16'] = const DayJournal(note: 'Vero');
    var diaryTaps = 0;
    var weekTaps = 0;
    await tester.pumpWidget(harness(
      store: store,
      date: DateTime(2026, 11, 16),
      hidden: false,
      onDiary: () => diaryTaps++,
      onWeek: () => weekTaps++,
      textScale: 1,
      brightness: Brightness.light,
    ));
    final diary = find.byKey(const ValueKey('editorial-today-diary-hero'));
    final week = find.byKey(const ValueKey('editorial-today-week-card'));
    expect(diary, findsOneWidget);
    expect(week, findsOneWidget);
    expect(tester.getSize(diary).width,
        closeTo(tester.getSize(week).width, .1));
    expect(tester.getSize(diary).height,
        closeTo(tester.getSize(week).height, .1));
    expect(find.text('La mia settimana'), findsOneWidget);
    expect(find.text('1 giornata annotata'), findsOneWidget);
    await tester.tap(find.descendant(
        of: diary, matching: find.byType(FilledButton)).first);
    await tester.tap(find.descendant(
        of: week, matching: find.byType(FilledButton)).first);
    expect(diaryTaps, 1);
    expect(weekTaps, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(harness(
      store: store,
      date: DateTime(2026, 11, 16),
      hidden: true,
      onDiary: () {},
      onWeek: () {},
      textScale: 1,
      brightness: Brightness.dark,
    ));
    expect(find.text('1 giornata annotata'), findsNothing);
    expect(find.text('•••'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow large text remains usable without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(harness(
      store: store,
      date: DateTime(2026, 11, 16),
      hidden: false,
      onDiary: () {},
      onWeek: () {},
      textScale: 1.6,
      brightness: Brightness.dark,
    ));
    expect(find.byKey(const ValueKey('editorial-today-diary-hero')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-today-week-card')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
