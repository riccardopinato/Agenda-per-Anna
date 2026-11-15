import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manual visual-evidence job only. Regular flutter test skips screenshots.
// Contents are empty/synthetic local state: no production account or media.
const organicCaptureEnabled =
    bool.fromEnvironment('ANNA_ORGANIC_CAPTURE', defaultValue: false);

void main() {
  Future<void> captureToday(
    WidgetTester tester, {
    required bool populated,
  }) async {
    debugPrint('ORGANIC_CAPTURE STEP 1: initialize locale');
    await initializeDateFormatting('it_IT', null);
    debugPrint('ORGANIC_CAPTURE STEP 2: load fonts');
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf'));
    final lora = FontLoader('Lora')
      ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf'));
    await Future.wait([manrope.load(), lora.load()]);
    debugPrint('ORGANIC_CAPTURE STEP 3: icon font');
    // Widget tests otherwise substitute squares for Material icon glyphs.
    // The CI capture workflow provides Flutter SDK's bundled original font.
    // File I/O under testWidgets' fake-async zone never completes.
    // Use runAsync only for the local SDK font bytes; UI remains Flutter.
    final iconBytes = await tester.runAsync(() async {
      final iconFont = File('test/fixtures/MaterialIcons-Regular.otf');
      if (!await iconFont.exists()) return null;
      return await iconFont.readAsBytes();
    });
    if (iconBytes != null) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes))))
          .load();
    }
    // Widget tests do not host Android's external-calendar MethodChannel.
    // Mock only the read-only status result; no real account/calendars touched.
    const externalCalendarChannel =
        MethodChannel('annas_diary/external_calendar');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      externalCalendarChannel,
      (call) async => call.method == 'status'
          ? <String, Object>{'granted': false}
          : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(
          externalCalendarChannel,
          null,
        ));
    debugPrint('ORGANIC_CAPTURE STEP 4: prefs and theme');
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

    debugPrint('ORGANIC_CAPTURE STEP 5: store and widget');
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      onboardingDone: true,
      displayName: 'Giulia', // synthetic fixture, exercises the real greeting
      palette: AgendaPalette.sage,
    );
    addTearDown(store.dispose);
    if (populated) {
      // Pure test-memory fixture: zero production credentials or data writes.
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      // An authentic diary-block model, but synthetic and in-memory only.
      // This exercises the no-fake-photo note fallback in Ricordi.
      final memoryDate = DateTime(date.year - 1, date.month, date.day);
      store.journals[AgendaStore.dateKey(memoryDate)] = DayJournal(
        blocks: [
          DiaryBlock(
            id: 'organic-demo-memory',
            type: DiaryBlockType.note,
            createdAt: memoryDate,
            text: 'Il nostro picnic al parco',
          ),
        ],
      );
      store.items.addAll([
        AgendaItem(
          id: 'organic-demo-breakfast',
          title: 'Colazione insieme',
          note: '',
          date: date,
          type: ItemType.task,
          done: true,
        ),
        AgendaItem(
          id: 'organic-demo-weekend',
          title: 'Prenotare il weekend',
          note: '',
          date: date,
          type: ItemType.task,
        ),
        AgendaItem(
          id: 'organic-demo-picnic',
          title: 'Picnic al parco',
          note: '',
          date: date,
          type: ItemType.appointment,
          start: const TimeOfDay(hour: 16, minute: 0),
          end: const TimeOfDay(hour: 17, minute: 0),
        ),
      ]);
    }
    debugPrint('ORGANIC_CAPTURE STEP 6: pumpWidget');
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    // The live shell has repeating motion (e.g. greeting ticker) and can
    // never settle. Capture a deterministic frame after bounded time while
    // retaining the real widget tree and authentic empty local state.
    debugPrint('ORGANIC_CAPTURE STEP 7: decode art in real async zone');
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(AnnaOrganicPastelWatercolor.bytes),
        context,
      );
    });
    debugPrint('ORGANIC_CAPTURE STEP 7B: bounded frame pumps');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 850));

    expect(
      find.byKey(const ValueKey<String>('organic-pastel-landscape')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey<String>('main-nav-create')),
      findsOneWidget,
    );
    debugPrint('ORGANIC_CAPTURE STEP 8: golden capture');
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        populated
            ? 'goldens/organic_pastel_today_populated_390.png'
            : 'goldens/organic_pastel_today_390.png',
      ),
    );
    debugPrint('ORGANIC_CAPTURE STEP 8B: scroll and capture compact hero');
    final scroll = find.byKey(const ValueKey<String>(
      'organic-pastel-collapsing-scroll',
    ));
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(0, -390));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      tester.getSize(find.byKey(
        const ValueKey<String>('organic-pastel-fullbleed-hero'),
      )).height,
      lessThanOrEqualTo(140),
    );
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        populated
            ? 'goldens/organic_pastel_today_populated_collapsed_390.png'
            : 'goldens/organic_pastel_today_collapsed_390.png',
      ),
    );
    debugPrint('ORGANIC_CAPTURE STEP 8C: render dedicated Impegni premium');
    if (populated) {
      // This synthetic item is injected AFTER the Home screenshots so they
      // stay comparable across PRs. It never leaves the in-memory test store.
      final today = DateTime.now();
      store.items.add(AgendaItem(
        id: 'organic-premium-commitments-capture',
        title: 'Passeggiata ai Colli',
        date: DateTime(today.year, today.month, today.day),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 9, minute: 30),
        end: const TimeOfDay(hour: 10, minute: 30),
        note: 'Porta la macchina fotografica',
      ));
    }
    // Use the real AgendaApp theme/localization and push the real quick-link
    // route. A bare MaterialApp uses headless test Ahem (black rectangles)
    // instead of the shipped Manrope font; that is NOT meaningful visual QA.
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 500));
    final quickLink = find.byKey(
      const ValueKey<String>('organic-quick-commitments'),
    );
    expect(quickLink, findsOneWidget);
    // Do NOT ensureVisible here: it positions the quick tile at y≈44,
    // UNDER the pinned Organic hero, and the hero correctly intercepts
    // the tap. At 390×844 the tile is already fully visible, both with
    // the hero expanded and after the existing 390dp scroll capture.
    final tileRect = tester.getRect(quickLink);
    expect(tileRect.top, greaterThan(120));
    expect(tileRect.bottom, lessThan(760));
    await tester.tap(quickLink);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey<String>('commitments-organic-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('commitments-organic-hour-grid')),
      findsOneWidget,
    );
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        populated
            ? 'goldens/organic_commitments_premium_populated_390.png'
            : 'goldens/organic_commitments_premium_empty_390.png',
      ),
    );
    debugPrint('ORGANIC_CAPTURE STEP 9: drain and cleanup');
    expect(tester.takeException(), isNull);
    // Staggered Motion and delayed card timers must fully drain before
    // teardown; a pending delay is not evidence of pixel failure.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('Organic Pastel — isolated screenshot scenario', (tester) async {
    await captureToday(
      tester,
      populated: const bool.fromEnvironment(
        'ANNA_ORGANIC_POPULATED',
        defaultValue: false,
      ),
    );
  }, skip: !organicCaptureEnabled, timeout: const Timeout(Duration(seconds: 110)));
}
