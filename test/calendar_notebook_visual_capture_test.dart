import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PR-only Flutter renderer evidence. All data are synthetic local fixtures;
// this test never opens production accounts, external calendars or Vault.
const calendarCaptureEnabled =
    bool.fromEnvironment('ANNA_CALENDAR_CAPTURE', defaultValue: false);
const calendarCapturePopulated =
    bool.fromEnvironment('ANNA_CALENDAR_POPULATED', defaultValue: false);

void main() {
  testWidgets('Calendar notebook — real Flutter month/week screenshots',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    await (FontLoader('Manrope')
          ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf')))
        .load();
    await (FontLoader('Lora')
          ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf')))
        .load();

    final iconBytes = await tester.runAsync(() async {
      final file = File('test/fixtures/MaterialIcons-Regular.otf');
      return await file.exists() ? file.readAsBytes() : null;
    });
    if (iconBytes != null) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes))))
          .load();
    }

    const channel = MethodChannel('annas_diary/external_calendar');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'status'
          ? <String, Object>{'granted': false}
          : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    await AnnaEditorialTodayMode.ensureLoaded();
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      onboardingDone: true,
      displayName: 'Giulia',
      palette: AgendaPalette.rose,
    );
    if (calendarCapturePopulated) {
      store.items.addAll([
        AgendaItem(
          id: 'calendar-notebook-appointment-fixture',
          title: 'Visita al museo',
          note: '',
          date: date,
          type: ItemType.appointment,
          start: const TimeOfDay(hour: 10, minute: 30),
          end: const TimeOfDay(hour: 11, minute: 30),
        ),
        AgendaItem(
          id: 'calendar-notebook-task-fixture',
          title: 'Preparare le fotografie',
          note: '',
          date: date,
          type: ItemType.task,
          done: false,
        ),
      ]);
    }

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final homeContext = tester.element(find.byType(Scaffold).first);
    Navigator.of(homeContext).push(MaterialPageRoute<void>(
      builder: (_) => CalendarScreen(store: store),
    ));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey<String>(
      'editorial-calendar-month-grid',
    )), findsOneWidget);
    await expectLater(
      find.descendant(
        of: find.byType(CalendarScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(
        calendarCapturePopulated
            ? 'goldens/anna_calendar_notebook_month_populated_390.png'
            : 'goldens/anna_calendar_notebook_month_empty_390.png',
      ),
    );

    // Also inspect the actual below-the-fold agenda, not only the month grid.
    await tester.drag(
      find.descendant(
        of: find.byType(CalendarScreen),
        matching: find.byType(ListView),
      ).first,
      const Offset(0, -520),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await expectLater(
      find.descendant(
        of: find.byType(CalendarScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(calendarCapturePopulated
          ? 'goldens/anna_calendar_notebook_month_agenda_populated_390.png'
          : 'goldens/anna_calendar_notebook_month_agenda_empty_390.png'),
    );

    // The SAME app/store feeds WeekScreen and keeps all seven canonical days.
    Navigator.of(tester.element(find.byType(CalendarScreen))).push(
      MaterialPageRoute<void>(
        builder: (_) => WeekScreen(store: store),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey<String>(
      'editorial-calendar-week-summary-rule',
    )), findsOneWidget);
    await expectLater(
      find.descendant(
        of: find.byType(WeekScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(
        calendarCapturePopulated
            ? 'goldens/anna_calendar_notebook_week_populated_390.png'
            : 'goldens/anna_calendar_notebook_week_empty_390.png',
      ),
    );

    // Scroll beyond the overview AND into the selected day's event card.
    // A single -600 drag used to leave the data-rich day below the fold,
    // producing byte-identical empty/populated evidence for the seven days.
    final weekList = find.descendant(
      of: find.byType(WeekScreen),
      matching: find.byType(ListView),
    ).first;
    await tester.drag(weekList, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.drag(weekList, const Offset(0, -390));
    await tester.pump(const Duration(milliseconds: 450));
    if (calendarCapturePopulated) {
      // A text match in ListView's offscreen cache is insufficient: it must
      // actually occupy visible pixels in the recorded screenshot.
      final appointment = find.text('Visita al museo');
      await tester.scrollUntilVisible(
        appointment,
        160,
        scrollable: find.descendant(
          of: find.byType(WeekScreen),
          matching: find.byType(Scrollable),
        ).first,
        maxScrolls: 12,
      );
      await tester.pump(const Duration(milliseconds: 450));
      expect(appointment, findsWidgets);
      final viewport = tester.getRect(weekList);
      final eventRect = tester.getRect(appointment.first);
      expect(eventRect.top, greaterThanOrEqualTo(viewport.top));
      expect(eventRect.bottom, lessThanOrEqualTo(viewport.bottom));
    }
    await expectLater(
      find.descendant(
        of: find.byType(WeekScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(calendarCapturePopulated
          ? 'goldens/anna_calendar_notebook_week_days_populated_390.png'
          : 'goldens/anna_calendar_notebook_week_days_empty_390.png'),
    );

    // Render the actual CalendarHub used from Home, not just the two
    // standalone screens. This checks the original non-M3 selector and
    // the existing My Month / My Year links in a real Flutter route.
    Navigator.of(homeContext).pop(); // Week -> Month detail
    await tester.pump(const Duration(milliseconds: 350));
    Navigator.of(homeContext).pop(); // Month detail -> Home
    await tester.pump(const Duration(milliseconds: 350));
    Navigator.of(homeContext).push(MaterialPageRoute<void>(
      builder: (_) => CalendarHubScreen(store: store),
    ));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey<String>(
      'calendar-open-month-notebook',
    )), findsOneWidget);
    expect(find.byKey(const ValueKey<String>(
      'calendar-open-year-overview',
    )), findsOneWidget);
    expect(find.byKey(const ValueKey<String>(
      'organic-calendar-mode-month',
    )), findsOneWidget);
    await expectLater(
      find.descendant(
        of: find.byType(CalendarHubScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(calendarCapturePopulated
          ? 'goldens/anna_calendar_hub_month_populated_390.png'
          : 'goldens/anna_calendar_hub_month_empty_390.png'),
    );

    await tester.tap(find.byKey(const ValueKey<String>(
      'organic-calendar-mode-week',
    )));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.descendant(
        of: find.byType(CalendarHubScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(calendarCapturePopulated
          ? 'goldens/anna_calendar_hub_week_populated_390.png'
          : 'goldens/anna_calendar_hub_week_empty_390.png'),
    );

    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }, skip: !calendarCaptureEnabled,
      timeout: const Timeout(Duration(seconds: 110)));
}
