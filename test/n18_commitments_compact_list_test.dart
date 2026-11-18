import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 18 Nov mock-up N18-03: visual switch only, original agenda and writers.
void main() {
  // ExternalCalendarService is a device-only read bridge. Keep widget
  // fixtures deterministic; no platform calendar or personal data are read.
  const externalChannel = MethodChannel('annas_diary/external_calendar');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUpAll(() async {
    await initializeDateFormatting('it', null);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    messenger.setMockMethodCallHandler(
      externalChannel,
      (call) async => call.method == 'status'
          ? <String, Object>{'granted': false}
          : null,
    );
  });
  tearDownAll(() => messenger.setMockMethodCallHandler(externalChannel, null));
  tearDown(() => AnnaEditorialTodayMode.enabled.value = false);

  testWidgets('Journal opens on real compact tasks and appointments; full timeline remains',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final day = DateTime(2026, 11, 14);
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      palette: AgendaPalette.rose,
    );
    store.items.addAll([
      AgendaItem(
        id: 'n18-task', title: 'Preparare una sorpresa',
        note: '', date: day, type: ItemType.task,
      ),
      AgendaItem(
        id: 'n18-appointment', title: 'Un caffè insieme',
        note: '', date: day, type: ItemType.appointment,
        start: const TimeOfDay(hour: 10, minute: 15),
        end: const TimeOfDay(hour: 11, minute: 15),
      ),
    ]);
    AnnaEditorialTodayMode.enabled.value = true;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: AnnaCommitmentsTimelineScreen(
        store: store,
        initialDate: day,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 260));
    final list = find.byKey(
      const ValueKey<String>('commitments-organic-compact-list'),
    );
    final timeline = find.byKey(
      const ValueKey<String>('commitments-canonical-day-timeline'),
    );
    expect(list, findsOneWidget);
    expect(find.text('Preparare una sorpresa'), findsOneWidget);
    expect(find.text('Un caffè insieme'), findsOneWidget);
    expect(timeline, findsNothing);
    expect(find.byKey(const ValueKey<String>(
      'commitments-list-create',
    )), findsOneWidget);
    expect(store.items.length, 2);

    await tester.tap(find.byKey(
      const ValueKey<String>('commitments-view-timeline'),
    ));
    await tester.pump(const Duration(milliseconds: 260));
    expect(list, findsNothing);
    expect(timeline, findsOneWidget);
    expect(tester.widget<DayTimeline>(timeline).date, day);
    expect(DayTimeline.startHour, 0);
    expect(DayTimeline.endHour, 24);

    await tester.tap(find.byKey(
      const ValueKey<String>('commitments-view-list'),
    ));
    await tester.pump(const Duration(milliseconds: 260));
    expect(list, findsOneWidget);
    expect(timeline, findsNothing);
    expect(store.items.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty Journal list is truthful; Classic keeps original timeline',
      (tester) async {
    final store = AgendaStore();
    addTearDown(store.dispose);
    final day = DateTime(2026, 11, 14);
    AnnaEditorialTodayMode.enabled.value = true;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: AnnaCommitmentsTimelineScreen(store: store, initialDate: day),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AnnaOrganicCalendarEmptyAgenda), findsOneWidget);
    expect(find.byKey(const ValueKey<String>(
      'commitments-organic-compact-list',
    )), findsOneWidget);

    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('classic-root'),
      locale: const Locale('it'),
      home: AnnaCommitmentsTimelineScreen(store: store, initialDate: day),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey<String>(
      'commitments-organic-compact-list',
    )), findsNothing);
    final timeline = find.byKey(
      const ValueKey<String>('commitments-canonical-day-timeline'),
    );
    expect(timeline, findsOneWidget);
    expect(tester.widget<DayTimeline>(timeline).organicStyle, isFalse);
    expect(tester.takeException(), isNull);
  });

  test('compact presentation reuses canonical data and callback owners', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final start = source.indexOf('class _AnnaCommitmentsTimelineScreenState');
    final end = source.indexOf('class _AnnaCommitmentsOrganicHeader', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final screen = source.substring(start, end);
    expect(screen, contains('widget.store.dayHubSnapshot(_selected)'));
    // The canonical Android external-calendar cache must be loaded when
    // entering Impegni and whenever the selected civil day changes.
    expect(screen, contains('ExternalCalendarService.instance.initialize()'));
    expect(screen, contains('_loadSelectedCalendarDay(_selected)'));
    expect(screen, contains('ExternalCalendarService.instance.loadRange(start, end)'));
    expect(screen, contains('unawaited(_loadSelectedCalendarDay(date))'));
    expect(screen, contains('UnifiedAgendaTile('));
    expect(screen, contains('compact: true,'));
    expect(screen, contains('AnnaOrganicJournalFilterPill('));
    expect(screen, contains("'commitments-view-timeline'"));
    expect(screen, contains("'commitments-view-list'"));
    expect(screen, contains('DayTimeline('));
    expect(screen, contains("'commitments-list-create'"));
    expect(screen, contains('captureDate: _selected,'));
    expect(screen, contains('entryPoint: UnifiedCaptureEntryPoint.day,'));
    expect(screen, isNot(contains('await widget.store.save')));
    expect(screen, isNot(contains('AgendaStore()')));
  });
}
