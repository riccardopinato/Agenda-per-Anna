import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  DayHubSnapshot day({String note = ''}) => DayHubSnapshot(
    date: DateTime(2026, 11, 5),
    agenda: const [],
    birthdays: const [],
    workouts: const [],
    pendingTaskCount: 0,
    appointmentCount: 0,
    journal: DayJournal(note: note),
  );

  Widget app(Widget child) => MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  test('style is device-local and not synced through AgendaPreferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AnnaEditorialTodayMode.ensureLoaded();
    expect(AnnaEditorialTodayMode.enabled.value, isFalse);
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

  testWidgets('real-day editorial hero opens canonical caller action', (tester) async {
    var openedDiary = 0;
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      snapshot: day(note: 'Nota vera, non una demo'),
      hideDetails: false,
      onOpenDiary: () => openedDiary++,
      onOpenCalendar: () {},
      onOpenDay: () {},
    )));
    expect(find.byKey(const ValueKey('editorial-today-real-overview')), findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-today-diary-hero')), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Nota vera, non una demo'), findsNothing);
    await tester.tap(find.byType(FilledButton).first);
    expect(openedDiary, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy mode masks the day state and counts', (tester) async {
    await tester.pumpWidget(app(AnnaEditorialTodayOverview(
      snapshot: day(note: 'Informazione privata'),
      hideDetails: true,
      onOpenDiary: () {},
      onOpenCalendar: () {},
      onOpenDay: () {},
    )));
    expect(find.text('•••'), findsNWidgets(3));
    expect(find.text('Informazione privata'), findsNothing);
    expect(tester.takeException(), isNull);
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
    expect(planner, contains('today-open-calendar'));
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
    expect(planner.split('AgendaContentFilterBar(store: widget.store)').length - 1, 4);
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
