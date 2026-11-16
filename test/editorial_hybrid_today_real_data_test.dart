import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  // Legacy Editorial Hybrid widget snapshots intentionally exercise the
  // Classic editorial components, not the newly promoted Organic skin.
  // The independently tested Organic Home retains its own widget suite.
  setUp(() => AnnaEditorialTodayMode.enabled.value = false);

  AgendaStore makeStore() {
    final store = AgendaStore();
    addTearDown(store.dispose);
    return store;
  }

  Widget app(Widget child) => MaterialApp(
    locale: const Locale('it'),
    supportedLocales: const [Locale('it'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  test('style is device-local and not synced through AgendaPreferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AnnaEditorialTodayMode.ensureLoaded();
    // Organic is now the official default if the local style key is absent.
    expect(AnnaEditorialTodayMode.enabled.value, isTrue);
    expect(await AnnaEditorialTodayMode.setEnabled(true), isTrue);
    expect(AnnaEditorialTodayMode.enabled.value, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AnnaEditorialTodayMode.storageKey), isTrue);
    expect(const AgendaPreferences().toJson().containsKey(
      AnnaEditorialTodayMode.storageKey,
    ), isFalse);
    expect(await AnnaEditorialTodayMode.setEnabled(false), isTrue);
    expect(preferences.getBool(AnnaEditorialTodayMode.storageKey), isFalse);
  });

  testWidgets('editorial diary hero keeps canonical action, without duplicate counters', (tester) async {
    var openedDiary = 0;
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      store: makeStore(),
      today: DateTime(2026, 11, 16),
      hideDetails: false,
      onOpenWeek: () {},
      onOpenDiary: () => openedDiary++,
    )));
    expect(find.byKey(const ValueKey('editorial-today-real-overview')), findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-today-diary-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-today-week-hero')), findsOneWidget);
    expect(find.text('La mia settimana'), findsOneWidget);
    expect(find.byType(AnnaEditorialActionPair), findsNothing);
    expect(find.text('Impegni'), findsNothing);
    expect(find.text('Attività'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('Il mio diario'), findsOneWidget);
    expect(find.text('Il tuo diario'), findsNothing);
    expect(find.byKey(const ValueKey('editorial-today-diary-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-today-diary-icon')), findsNothing);
    await tester.tap(find.byType(FilledButton).first);
    expect(openedDiary, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy hides both genuine diary statistics without removing actions', (tester) async {
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      store: makeStore(),
      today: DateTime(2026, 11, 16),
      hideDetails: true,
      onOpenWeek: () {},
      onOpenDiary: () {},
    )));
    expect(find.byType(AnnaEditorialActionPair), findsNothing);
    expect(find.text('•••'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact diary has no redundant emblem',
      (tester) async {
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      store: makeStore(),
      today: DateTime(2026, 11, 16),
      hideDetails: false,
      onOpenWeek: () {},
      onOpenDiary: () {},
    )));
    final card = find.byKey(const ValueKey('editorial-today-diary-hero'));
    final title = find.byKey(const ValueKey('editorial-today-diary-title'));
    final icon = find.byKey(const ValueKey('editorial-today-diary-icon'));
    expect(find.text('Il mio diario'), findsOneWidget);
    expect(find.text('Il tuo diario'), findsNothing);
    expect(find.text('Diario iniziato'), findsNothing);
    final weekly = find.byKey(const ValueKey('editorial-today-week-hero'));
    expect(tester.getSize(card).height, tester.getSize(weekly).height);
    expect(tester.getSize(card).width, tester.getSize(weekly).width);
    expect(icon, findsNothing);
    expect(tester.getRect(title).width, greaterThan(100));
    expect(find.byType(FilledButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact diary adapts to 320dp width and enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final overview = AnnaEditorialTodayOverview(
      store: makeStore(),
      today: DateTime(2026, 11, 16),
      hideDetails: false,
      onOpenWeek: () {},
      onOpenDiary: () {},
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      supportedLocales: const [Locale('it'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: SingleChildScrollView(child: overview),
        ),
      ),
    ));
    expect(find.text('Il mio diario'), findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-today-diary-icon')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Organic Home keeps the single Impegni shortcut above its diary hero', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final overview = File('lib/src/editorial_today_home.dart').readAsStringSync();
    final home = planner
        .split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    final shortcut = home.indexOf('AnnaOrganicPastelQuickLinks(');
    final diary = home.indexOf('AnnaEditorialTodayOverview(');
    expect(shortcut, greaterThanOrEqualTo(0));
    expect(diary, greaterThan(shortcut));
    expect(overview, isNot(contains('AnnaEditorialActionPair(')));
    expect(overview, isNot(contains("d3('ui5Commitments')")));
    expect(overview, isNot(contains("d3('ui5Activities')")));
  });

  testWidgets('two diary/week cards use authentic journal dates and open both canonical actions',
      (tester) async {
    final store = makeStore();
    store.journals['2026-11-16'] = const DayJournal(note: 'Un giorno vero');
    store.journals['2026-11-17'] = const DayJournal(beautiful: 'Un momento bello');
    store.journals['2026-11-15'] = const DayJournal(note: 'La settimana scorsa');
    store.journals['2026-11-18'] = DayJournal(
      blocks: [DiaryBlock(
        id: 'archived-card-qa',
        type: DiaryBlockType.note,
        createdAt: DateTime(2026, 11, 18),
        text: 'Non deve contare',
        archived: true,
      )],
    );
    expect(annaTodayAnnotatedDayCounts(store, DateTime(2026, 11, 16)),
        (all: 3, week: 2));
    var diaryOpened = 0;
    var reviewOpened = 0;
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      store: store,
      today: DateTime(2026, 11, 16),
      hideDetails: false,
      onOpenDiary: () => diaryOpened++,
      onOpenWeek: () => reviewOpened++,
    )));
    expect(find.text('3 giornate annotate'), findsOneWidget);
    expect(find.text('2/7 giornate annotate'), findsOneWidget);
    expect(find.text('La mia settimana'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.tap(find.byType(FilledButton).last);
    expect(diaryOpened, 1);
    expect(reviewOpened, 1);
    expect(tester.takeException(), isNull);
  });

  test('the diary name is first-person in every supported locale', () {
    const expected = <String, String>{
      'it': 'Il mio diario',
      'en': 'My diary',
      'es': 'Mi diario',
      'fr': 'Mon journal',
      'pt': 'O meu diário',
    };
    for (final entry in expected.entries) {
      expect(AnnaStrings(entry.key).d3('ui5DayDiary'), entry.value);
    }
  });

  test('classic paths and canonical data still exist inside opt-in Oggi', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final preferences = File('lib/src/screens/personalization_screen.dart').readAsStringSync();
    final shell = File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(planner, contains('widget.store.dayHubSnapshot(day)'));
    expect(planner, contains('AnnaEditorialTodayMode.enabled.value'));
    expect(planner, contains('AnnaEditorialTodayOverview('));
    expect(planner, contains('_TodayCompactSummary(snapshot: snapshot)'));
    expect(planner, contains('AgendaContentFilterBar(store: widget.store)'));
    expect(planner, contains('_TodayCompactDiaryPreview('));
    expect(planner, contains('_DayMemoryRecallCard('));
    expect(planner, contains('DayTimeline('));
    expect(planner, contains("'today-open-calendar'")); // Classic-only AppBar, not Organic header.
    expect(planner, contains('AnnaOrganicPastelQuickLinks('));
    expect(planner, contains("'editorial-today-return'"));
    expect(planner, contains('onPressed: () => _selectDay(DateTime.now())'));
    expect(planner, contains('showUnifiedCapture('));
    expect(preferences, contains("'personalization-editorial-home'"));
    expect(shell, contains('Center(child: _centralCreateButton(context))'));
    expect(shell, contains('PlannerScreen('));
    expect(shell, contains('activeInShell: index == 0'));
    expect(planner, contains('widget.activeInShell'));

  });

  test('Hybrid Home has no filter bar or stale invisible content filter', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final shell = File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final start = planner.indexOf('class _PlannerScreenState');
    final end = planner.indexOf('class _CalendarDayContextCard', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final home = planner.substring(start, end);
    // Only the Hybrid Home loses the chips; Classic and Calendar retain them.
    expect(home, contains("if (!editorial) ...["));
    expect(home, contains('AgendaContentFilterBar(store: widget.store)'));
    // Calendar/Week now pass an optional notebook presentation flag on
    // separate lines. Count the real widget invocations, not one formatting.
    expect(
      RegExp(r'AgendaContentFilterBar\(\s*store:\s*widget\.store')
          .allMatches(planner).length,
      4,
    );
    expect(planner.split('calendarNotebook: editorial,').length - 1, 2);
    // When a global filter was chosen elsewhere, reset it after the frame
    // so Hybrid never silently hides private/shared items.
    expect(home, contains('widget.store.agendaContentFilter != AgendaContentFilter.all'));
    expect(home, contains('widget.activeInShell &&'));
    expect(home, contains('ModalRoute.of(context)?.isCurrent == true'));
    expect(home, contains('ModalRoute.of(context)?.isCurrent != true'));
    expect(shell, contains('activeInShell: index == 0'));

    expect(home, contains('WidgetsBinding.instance.addPostFrameCallback'));
    expect(home, contains('widget.store.setAgendaContentFilter(AgendaContentFilter.all)'));
  });

  test('mode selection has copy for all five target locales', () {
    for (final language in ['it', 'en', 'es', 'fr', 'pt']) {
      expect(annaEditorialTodayModeLabel(
        language, returnToClassic: false,
      ), isNotEmpty);
      expect(annaEditorialTodayModeLabel(
        language, returnToClassic: true,
      ), isNotEmpty);
      expect(annaEditorialTodayModeDescription(language), isNotEmpty);
    }
  });
}
