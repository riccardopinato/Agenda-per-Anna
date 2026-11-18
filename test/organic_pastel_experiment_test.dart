import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it', null);
  });

  tearDown(() {
    AnnaEditorialTodayMode.enabled.value = false;
  });

  test('Organic watercolor is 1200x400 WebP, not the old 360x120', () {
    final bytes = AnnaOrganicPastelWatercolor.bytes;
    expect(bytes.length, greaterThan(30000));
    expect(bytes.length, lessThan(100000)); // bounded offline asset weight
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
    // RIFF VP8 frame width and height are stored in bytes 26–29.
    expect((bytes[26] | (bytes[27] << 8)) & 0x3fff, 1200);
    expect((bytes[28] | (bytes[29] << 8)) & 0x3fff, 400);
  });

  testWidgets('original landscape paints in light and dark without assets',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: brightness,
          ),
        ),
        home: const Scaffold(
          body: Center(
            child: AnnaOrganicPastelLandscape(height: 96),
          ),
        ),
      ));
      expect(
        find.byKey(const ValueKey<String>('organic-pastel-landscape')),
        findsOneWidget,
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('full-bleed Today hero keeps name, controls and safe area',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final width in [320.0, 390.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        var calendarOpens = 0;
        var classicOpens = 0;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF899657),
              brightness: brightness,
            ),
          ),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                viewPadding: EdgeInsets.only(top: 24),
                disableAnimations: true,
              ),
              child: AnnaOrganicPastelBleedHero(
                toolbar: AnnaTodayEditorialGreetingToolbar(
                  greeting: approvedTodayGreeting('it', 'Giulia', 9),
                  calendarTooltip: 'Calendario',
                  classicTooltip: 'Classic',
                  activeInShell: false,
                  onOpenCalendar: () => calendarOpens++,
                  onReturnToClassic: () => classicOpens++,
                ),
              ),
            ),
          ),
        ));
        await tester.pump();
        final hero = find.byKey(
          const ValueKey<String>('organic-pastel-fullbleed-hero'),
        );
        expect(hero, findsOneWidget);
        expect(tester.getSize(hero).width, width);
        expect(tester.getSize(hero).height, 256);
        final landscape = find.byKey(
          const ValueKey<String>('organic-pastel-landscape'),
        );
        expect(landscape, findsOneWidget);
        expect(tester.getSize(landscape).width, width);
        final fade = tester.widget<DecoratedBox>(find.byKey(
          const ValueKey<String>('organic-pastel-hero-fade'),
        ));
        final colors = (fade.decoration as BoxDecoration).gradient!
            as LinearGradient;
        expect(colors.colors.first.a, closeTo(.98, .001));
        expect(colors.colors.last.a, 1.0);
        expect(
          find.byKey(const ValueKey<String>('ds6-today-greeting')),
          findsOneWidget,
        );
        expect(find.text('Buongiorno, Giulia'), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(
            const ValueKey<String>('ds6-today-compact-header'),
          )).dy,
          greaterThanOrEqualTo(24),
        );
        expect(find.byKey(const ValueKey<String>('today-open-calendar')), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey<String>('today-editorial-disable')),
        );
        expect(calendarOpens, 0);
        expect(classicOpens, 1);
        expect(tester.takeException(), isNull);
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Organic sliver shrinks 100dp and keeps the toolbar pinned',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var calendar = 0;
    var classic = 0;
    final toolbar = AnnaTodayEditorialGreetingToolbar(
      greeting: approvedTodayGreeting('it', 'Giulia', 9),
      calendarTooltip: 'Calendario',
      classicTooltip: 'Classic',
      activeInShell: false,
      onOpenCalendar: () => calendar++,
      onReturnToClassic: () => classic++,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: AnnaOrganicPastelHeroSliverDelegate(
                toolbar: toolbar,
                topInset: 24,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 1500)),
          ],
        ),
      ),
    ));
    await tester.pump();
    final hero = find.byKey(
      const ValueKey<String>('organic-pastel-fullbleed-hero'),
    );
    expect(tester.getSize(hero).height, 256);
    // Premium image covers the expanded hero and reveals more landscape
    // as the pinned sliver collapses to the original panorama proportions.
    final image = find.byKey(
      const ValueKey<String>('organic-pastel-landscape'),
    );
    expect(tester.getSize(image).height, closeTo(256, .1));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(tester.getSize(hero).height, closeTo(156, .1));
    expect(tester.getSize(image).height, closeTo(156, .1));
    expect(find.byKey(
      const ValueKey<String>('ds6-today-greeting'),
    ), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('today-open-calendar')), findsNothing);
    await tester.tap(find.byKey(
      const ValueKey<String>('today-editorial-disable'),
    ));
    expect(calendar, 0);
    expect(classic, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Organic owner greeting stays fully visible at 390dp',
      (tester) async {
    AnnaEditorialTodayMode.enabled.value = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      AnnaEditorialTodayMode.enabled.value = false;
    });
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF899657),
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          body: AnnaOrganicPastelBleedHero(
            toolbar: AnnaTodayEditorialGreetingToolbar(
              greeting: approvedTodayGreeting('it', 'Giulia', 14),
              calendarTooltip: 'Calendario',
              classicTooltip: 'Classic',
              activeInShell: false,
              onOpenCalendar: () {},
              onReturnToClassic: () {},
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byKey(
        const ValueKey<String>('ds6-today-greeting'),
      ), findsOneWidget);
      expect(find.byKey(
        const ValueKey<String>('ds6-today-marquee'),
      ), findsNothing);
      final greeting = tester.widget<Text>(find.byKey(
        const ValueKey<String>('ds6-today-static-greeting'),
      ));
      expect(greeting.data, 'Buon pomeriggio, Giulia');
      expect(tester.takeException(), isNull);
    }
  });


  testWidgets('Organic hero scroll QA matrix: small, large, landscape and a11y',
      (tester) async {
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Synthetic name only. These are widget-level simulations, not results
    // from an Android emulator or a physical phone.
    const cases = <({double width, double height, Brightness brightness,
        double scale, String label})>[
      (width: 320, height: 640, brightness: Brightness.light,
          scale: 1, label: 'small-light'),
      (width: 320, height: 640, brightness: Brightness.dark,
          scale: 1.6, label: 'small-dark-large-text'),
      (width: 390, height: 844, brightness: Brightness.light,
          scale: 1.6, label: 'normal-large-text'),
      (width: 390, height: 844, brightness: Brightness.dark,
          scale: 1, label: 'normal-dark'),
      (width: 640, height: 360, brightness: Brightness.light,
          scale: 1, label: 'landscape'),
      (width: 600, height: 880, brightness: Brightness.dark,
          scale: 1.6, label: 'tablet-dark-large-text'),
    ];

    for (final scenario in cases) {
      tester.view.physicalSize = Size(scenario.width, scenario.height);
      tester.view.devicePixelRatio = 1;
      var calendarOpens = 0;
      var classicOpens = 0;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFAD7DAD),
            brightness: scenario.brightness,
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(scenario.scale),
            viewPadding: const EdgeInsets.only(top: 32),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: CustomScrollView(
              key: const ValueKey<String>('organic-qa-scroller'),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: AnnaOrganicPastelHeroSliverDelegate(
                    topInset: 32,
                    toolbar: AnnaTodayEditorialGreetingToolbar(
                      greeting: approvedTodayGreeting(
                        'it', 'Alessandra Riccarda', 14,
                      ),
                      activeInShell: false,
                      calendarTooltip: 'Calendario',
                      classicTooltip: 'Classic',
                      onOpenCalendar: () => calendarOpens++,
                      onReturnToClassic: () => classicOpens++,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 1700),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();

      final hero = find.byKey(
        const ValueKey<String>('organic-pastel-fullbleed-hero'),
      );
      expect(tester.getSize(hero).height, 264, reason: scenario.label);
      expect(tester.getSize(hero).width, scenario.width,
          reason: scenario.label);
      expect(
        tester.getTopLeft(find.byKey(
          const ValueKey<String>('ds6-today-compact-header'),
        )).dy,
        greaterThanOrEqualTo(32),
        reason: scenario.label,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('organic-qa-scroller')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(hero).height, closeTo(164, 1),
          reason: scenario.label);
      expect(find.byKey(const ValueKey<String>('ds6-today-greeting')),
          findsOneWidget);
      expect(tester.takeException(), isNull, reason: scenario.label);

      expect(find.byKey(const ValueKey<String>('today-open-calendar')), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('today-editorial-disable')),
      );
      expect(calendarOpens, 0, reason: scenario.label);
      expect(classicOpens, 1, reason: scenario.label);

      await tester.drag(
        find.byKey(const ValueKey<String>('organic-qa-scroller')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(hero).height, closeTo(264, 1),
          reason: scenario.label);
      expect(tester.takeException(), isNull, reason: scenario.label);
    }
  });

  test('localized owner greeting keeps fallback for empty profile', () {
    for (final locale in ['it', 'en', 'es', 'fr', 'pt']) {
      final blank = approvedTodayGreeting(locale, '  ', 9);
      final named = approvedTodayGreeting(locale, 'Giulia', 9);
      expect(blank.trim(), isNotEmpty);
      expect(named, contains('Giulia'));
      expect(named.length, greaterThan(blank.length));
      expect(blank, isNot(contains('Giulia')));
    }
  });

  testWidgets('week strip uses actual dates and canonical selected-day callback',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    DateTime? selected;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: AnnaOrganicPastelWeekStrip(
          selected: DateTime(2026, 11, 14),
          onSelected: (value) => selected = value,
        ),
      ),
    ));
    expect(
      find.byKey(const ValueKey<String>('organic-pastel-week-strip')),
      findsOneWidget,
    );
    final monday = find.byKey(
      const ValueKey<String>('organic-week-day-2026-11-9'),
    );
    expect(monday, findsOneWidget);
    await tester.tap(monday);
    expect(selected, DateTime(2026, 11, 9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Organic week arrows traverse weeks and dates survive DST',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final selected = DateTime(2026, 10, 31);
    DateTime? changed;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnnaOrganicPastelWeekStrip(
            selected: selected,
            onSelected: (date) => changed = date,
          ),
        ),
      ),
    ));
    // 26 Oct – 1 Nov remains seven distinct civil dates in a DST week.
    for (var delta = 0; delta < 7; delta++) {
      final day = addCivilDays(DateTime(2026, 10, 26), delta);
      expect(
        find.byKey(ValueKey<String>(
          'organic-week-day-${day.year}-${day.month}-${day.day}',
        )),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey<String>('organic-week-prev')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('organic-week-next')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('organic-week-next')));
    expect(changed, DateTime(2026, 11, 7));
    await tester.tap(find.byKey(const ValueKey<String>('organic-week-prev')));
    expect(changed, DateTime(2026, 10, 24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected pastel dock label uses theme foreground in dark mode',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF8670B0),
        brightness: brightness,
      );
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: Scaffold(
          body: AnnaOrganicLiquidTab(
            page: 0,
            selected: true,
            label: 'Oggi',
            icon: Icons.today,
            semanticId: 'selected-organic-day',
            onTap: () {},
          ),
        ),
      ));
      // MaterialApp transitions between ThemeData instances using
      // AnimatedTheme. Wait for the actual dark/light theme to settle
      // before comparing the rendered icon against the inherited scheme.
      await tester.pumpAndSettle();
      // Verify the EFFECTIVE Flutter theme after ThemeData normalization,
      // not the pre-normalized ColorScheme.fromSeed input.
      final actualForeground = Theme.of(
        tester.element(find.byType(AnnaOrganicLiquidTab)),
      ).colorScheme.onSurface;
      final label = tester.widget<Text>(find.text('Oggi'));
      expect(label.style?.color, actualForeground);
      // The icon intentionally blends only 12–16% of the pastel tint into
      // the active foreground; the label must remain pure onSurface.
      final effectiveScheme = Theme.of(
        tester.element(find.byType(AnnaOrganicLiquidTab)),
      ).colorScheme;
      final pastel = Color.lerp(
        effectiveScheme.primary, const Color(0xFF9DC4A6), .58,
      )!;
      final icon = tester.widget<Icon>(find.byIcon(Icons.today));
      expect(
        icon.color,
        Color.lerp(
          actualForeground,
          pastel,
          effectiveScheme.brightness == Brightness.dark ? .16 : .12,
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('all seven weekdays fit without sideways scroll at 320dp',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [320.0, 360.0, 390.0, 600.0]) {
      for (final scale in [1.0, 1.6]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        DateTime? tapped;
        final day = DateTime(2026, 11, 14);
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('it'),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnnaOrganicPastelWeekStrip(
                  selected: day,
                  onSelected: (date) => tapped = date,
                ),
              ),
            ),
          ),
        ));
        final week = find.byKey(
          const ValueKey<String>('organic-pastel-week-strip'),
        );
        final row = find.byKey(
          const ValueKey<String>('organic-week-seven-days'),
        );
        expect(week, findsOneWidget);
        expect(row, findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNothing,
            reason: 'week should not scroll on width $width scale $scale');
        final bounds = tester.getRect(row);
        Rect? previous;
        for (var i = 0; i < 7; i++) {
          final date = addCivilDays(DateTime(2026, 11, 9), i);
          final item = find.byKey(ValueKey<String>(
            'organic-week-day-${date.year}-${date.month}-${date.day}',
          ));
          expect(item, findsOneWidget);
          final box = tester.getRect(item);
          expect(box.left, greaterThanOrEqualTo(bounds.left - .1));
          expect(box.right, lessThanOrEqualTo(bounds.right + .1));
          expect(box.width, greaterThan(0));
          if (previous != null) {
            expect(box.left, greaterThanOrEqualTo(previous.right - .1));
          }
          previous = box;
        }
        expect(tester.takeException(), isNull,
            reason: 'no clipping/overflow on width $width scale $scale');
        final friday = find.byKey(
          const ValueKey<String>('organic-week-day-2026-11-13'),
        );
        final saturday = find.byKey(
          const ValueKey<String>('organic-week-day-2026-11-14'),
        );
        final sunday = find.byKey(
          const ValueKey<String>('organic-week-day-2026-11-15'),
        );
        await tester.tap(friday);
        expect(tapped, DateTime(2026, 11, 13));
        await tester.tap(saturday);
        expect(tapped, DateTime(2026, 11, 14));
        await tester.tap(sunday);
        expect(tapped, DateTime(2026, 11, 15));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Organic paper and bespoke olive action are not M3 cards',
      (tester) async {
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AnnaEditorialSurface(
            tone: AnnaEditorialSurfaceTone.featured,
            onTap: () => tapped++,
            child: AnnaEditorialPrimaryAction(
              label: 'Apri',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => tapped++,
            ),
          ),
        ),
      ),
    ));
    expect(find.byType(AnnaOrganicPaperSurface), findsOneWidget);
    expect(find.byType(AnnaOrganicPastelAction), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.text('Apri'));
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Olive action truncates safely at 320dp and double text size',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var called = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
          ),
          child: Center(
            child: SizedBox(
              width: 148,
              child: AnnaOrganicPastelAction(
                label: 'Apri la Weekly Review della settimana',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => called++,
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(AnnaOrganicPastelAction));
    expect(called, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Organic group row keeps original open and rename callbacks',
      (tester) async {
    var opened = 0;
    var renamed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AnnaOrganicPastelGroupRow(
            title: 'Spazio di prova',
            detail: 'Contenuti condivisi',
            unread: 2,
            onOpen: () => opened++,
            onRename: () => renamed++,
            renameTooltip: 'Rinomina',
            renameKey: 'shared-rename-test',
          ),
        ),
      ),
    ));
    expect(find.byType(AnnaOrganicPaperSurface), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Spazio di prova'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Spazio di prova'));
    expect(opened, 1);
    await tester.tap(find.byKey(const ValueKey('shared-rename-test')));
    expect(renamed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real quick links use enabled modules and 320dp text scaling',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      enabledModules: <AppModule>{},
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnnaOrganicPastelQuickLinks(store: store),
            ),
          ),
        ),
      ),
    ));
    expect(
      find.byKey(const ValueKey('organic-pastel-quick-links')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('organic-quick-calendar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('organic-quick-inbox')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('organic-quick-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('organic-quick-shopping')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('organic-quick-memories')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('organic-quick-commitments')),
      findsOneWidget,
    );
    // MaterialApp may resolve its own fallback locale in a bare widget
    // harness. Assert the real five-language label, not a hardcoded "it".
    final commitmentsTile = find.byKey(
      const ValueKey<String>('organic-quick-commitments'),
    );
    final actualLabel = AnnaStrings.of(
      tester.element(commitmentsTile),
    ).d3('ui5Commitments');
    expect(
      find.descendant(
        of: commitmentsTile,
        matching: find.text(actualLabel),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Impegni shortcut opens the existing 24-hour timeline on the selected day',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      enabledModules: <AppModule>{AppModule.memories},
    );
    final selectedDay = DateTime(2026, 11, 14);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: AnnaOrganicPastelQuickLinks(
          store: store,
          selectedDate: selectedDay,
        ),
      ),
    ));
    expect(
      find.byKey(const ValueKey<String>('organic-quick-commitments')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('organic-quick-memories')),
      findsNothing,
    );
    await tester.tap(find.byKey(
      const ValueKey<String>('organic-quick-commitments'),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AnnaCommitmentsTimelineScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>(
        'commitments-hourly-timeline-screen',
      )),
      findsOneWidget,
    );
    // N18-03 opens Organic Impegni on the compact canonical day list.
    expect(find.byKey(const ValueKey<String>(
      'commitments-organic-compact-list',
    )), findsOneWidget);
    final timeline = find.byKey(
      const ValueKey<String>('commitments-canonical-day-timeline'),
    );
    expect(timeline, findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>(
      'commitments-view-timeline',
    )));
    await tester.pumpAndSettle();
    expect(timeline, findsOneWidget);
    expect(tester.widget<DayTimeline>(timeline).date, selectedDay);
    expect(DayTimeline.startHour, 0);
    expect(DayTimeline.endHour, 24);
    await tester.tap(find.byKey(const ValueKey('today-date-next')));
    await tester.pumpAndSettle();
    expect(tester.widget<DayTimeline>(timeline).date,
        DateTime(2026, 11, 15));
    await tester.tap(find.byKey(const ValueKey('today-date-prev')));
    await tester.pumpAndSettle();
    expect(tester.widget<DayTimeline>(timeline).date, selectedDay);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Impegni premium uses the real timeline in light/dark and small screens',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      AnnaEditorialTodayMode.enabled.value = false;
    });
    final date = DateTime(2026, 11, 14);
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      palette: AgendaPalette.sage,
    );
    store.items.add(AgendaItem(
      id: 'organic-commitment-qa',
      title: 'Visita di controllo',
      date: date,
      type: ItemType.appointment,
      start: const TimeOfDay(hour: 9, minute: 30),
      end: const TimeOfDay(hour: 10, minute: 30),
      note: 'Promemoria sintetico',
    ));
    AnnaEditorialTodayMode.enabled.value = true;

    for (final width in [320.0, 390.0, 600.0]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('it'),
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF899657),
            brightness: brightness,
          )),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.6),
            ),
            child: AnnaCommitmentsTimelineScreen(
              store: store,
              initialDate: date,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byKey(const ValueKey<String>(
          'commitments-organic-header',
        )), findsOneWidget);
        expect(find.byKey(const ValueKey<String>(
          'commitments-organic-compact-list',
        )), findsOneWidget);
        expect(find.text('Visita di controllo'), findsOneWidget);
        expect(find.byKey(const ValueKey<String>(
          'commitments-private-count',
        )), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>(
          'commitments-view-timeline',
        )));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byKey(const ValueKey<String>(
          'commitments-organic-hint',
        )), findsOneWidget);
        expect(find.byKey(const ValueKey<String>(
          'commitments-organic-hour-grid',
        )), findsOneWidget);
        final timeline = find.byKey(const ValueKey<String>(
          'commitments-canonical-day-timeline',
        ));
        expect(tester.widget<DayTimeline>(timeline).organicStyle, isTrue);
        expect(tester.widget<DayTimeline>(timeline).events.single.title,
            'Visita di controllo');
        expect(DayTimeline.startHour, 0);
        expect(DayTimeline.endHour, 24);
        expect(tester.takeException(), isNull,
            reason: 'viewport $width with $brightness at 1.6x text');
      }
    }
  });

  testWidgets('Impegni preserves date navigation and legacy Classic timeline',
      (tester) async {
    final store = AgendaStore();
    addTearDown(store.dispose);
    final day = DateTime(2026, 11, 14);
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: AnnaCommitmentsTimelineScreen(
        store: store,
        initialDate: day,
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>(
      'commitments-organic-compact-list',
    )), findsOneWidget);
    final timeline = find.byKey(const ValueKey<String>(
      'commitments-canonical-day-timeline',
    ));
    expect(timeline, findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>(
      'commitments-view-timeline',
    )));
    await tester.pump();
    expect(tester.widget<DayTimeline>(timeline).organicStyle, isTrue);
    await tester.tap(find.byKey(const ValueKey('today-date-next')));
    await tester.pump();
    expect(tester.widget<DayTimeline>(timeline).date,
        DateTime(2026, 11, 15));
    await tester.tap(find.byKey(const ValueKey('today-date-prev')));
    await tester.pump();
    expect(tester.widget<DayTimeline>(timeline).date, day);
    expect(tester.takeException(), isNull);

    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: AnnaCommitmentsTimelineScreen(
        store: store,
        initialDate: day,
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>(
      'commitments-organic-header',
    )), findsNothing);
    expect(tester.widget<DayTimeline>(timeline).organicStyle, isFalse);
    expect(tester.takeException(), isNull);
  });

  test('Impegni premium never creates a second writer or 12-hour view', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    expect(source, contains('class _AnnaCommitmentsOrganicHeader'));
    expect(source, contains('organicStyle: organic,'));
    expect(source, contains('onTapDown: (details) =>'));
    expect(source, contains('_createAtPosition(context, details.localPosition.dy)'));
    expect(source, contains('await openUnifiedItemComposer('));
    expect(source, contains('await openItemEditor('));
    expect(source, contains('await _showAgendaItemActions('));
    expect(source, contains('static const int endHour = 24;'));
  });

  test('Organic Today places memories after the diary and hides inline timeline',
      () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final planner = source
        .split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    final quickLinks = planner.indexOf('AnnaOrganicPastelQuickLinks(');
    final diary = planner.indexOf('AnnaEditorialTodayOverview(');
    final memories = planner.indexOf('// Keep memories immediately BELOW');
    final nextCards = planner.indexOf('// Hero-first rhythm');
    expect(quickLinks, greaterThan(0));
    expect(diary, greaterThan(quickLinks));
    expect(memories, greaterThan(diary));
    expect(nextCards, greaterThan(memories));
    expect(planner, contains('if (!widget.embedded)'));
    expect(planner, contains('ExpansionTile('));
    expect(planner, contains('selectedDate: day,'));
    expect(source, contains('class AnnaCommitmentsTimelineScreen'));
    expect(source, contains('DayTimeline('));
  });

  test('style experiment is presentation-only and preserves group routes', () {
    final source = File('lib/src/screens/shared_space.dart').readAsStringSync();
    expect(source, contains('AnnaOrganicPastelGroupAvatar()'));
    expect(source, contains('sharedSpaceCanRename('));
    expect(source, contains('sharedUnreadCount(space.id)'));
    expect(source, contains('SharedSpaceScreen('));
    expect(source, contains('markSharedSpaceRead('));
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(shell, contains('isModuleEnabled(AppModule.sharedSpace)'));
    expect(shell, contains('SharedSpaceHubScreen(store: widget.store)'));
    expect(shell, contains('onTap: _openCentralCreate'));
  });
  testWidgets('liquid tabs remain tappable at 320dp in light and dark',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      AnnaEditorialTodayMode.enabled.value = false;
    });
    AnnaEditorialTodayMode.enabled.value = true;
    var selected = -1;
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9D7BAE),
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          bottomNavigationBar: AnnaEditorialDockBar(
            selectedPage: 0,
            onPageSelected: (page) => selected = page,
            labels: const ['Oggi', 'Insieme', 'Ricordi', 'Altro'],
            icons: const [
              Icons.today_outlined,
              Icons.chat_bubble_outline,
              Icons.photo_library_outlined,
              Icons.grid_view_outlined,
            ],
            selectedIcons: const [
              Icons.today,
              Icons.chat_bubble,
              Icons.photo_library,
              Icons.grid_view,
            ],
            semanticIds: const [
              'main-nav-today',
              'main-nav-messages',
              'main-nav-memories',
              'main-nav-more',
            ],
          ),
        ),
      ));
      expect(find.byType(AnnaOrganicLiquidTab), findsNWidgets(4));
      expect(find.byType(AnnaOrganicLiquidDockSurface), findsOneWidget);
      for (var page = 0; page < 4; page++) {
        final tab = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey<String>('liquid-integrated-tab-$page')),
        );
        final decoration = tab.decoration! as BoxDecoration;
        expect(decoration.gradient, isA<RadialGradient>());
        expect(decoration.border, isNull);
        expect(decoration.boxShadow, isNull);
      }
      expect(find.byType(BackdropFilter), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('main-nav-messages')));
      expect(selected, 1);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('glass Create preserves the single action callback',
      (tester) async {
    var createCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AnnaOrganicLiquidCreate(
            label: 'Crea',
            pressed: false,
            released: false,
            onTap: () => createCalls++,
          ),
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('organic-liquid-create-orb')),
        findsOneWidget);
    // The central gel orb must hide the underlying dock line and contain
    // no bright horizontal glare stripe.
    expect(
      find.descendant(
        of: find.byType(AnnaOrganicLiquidCreate),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('main-nav-create')));
    expect(createCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gel capsules fit 360dp with enlarged text without overflows',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      AnnaEditorialTodayMode.enabled.value = false;
    });
    AnnaEditorialTodayMode.enabled.value = true;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: Scaffold(
          bottomNavigationBar: AnnaEditorialDockBar(
            selectedPage: 0,
            onPageSelected: (_) {},
            labels: const ['Oggi', 'Insieme', 'Ricordi', 'Altro'],
            icons: const [
              Icons.today_outlined,
              Icons.chat_bubble_outline,
              Icons.photo_library_outlined,
              Icons.grid_view_outlined,
            ],
            selectedIcons: const [
              Icons.today,
              Icons.chat_bubble,
              Icons.photo_library,
              Icons.grid_view,
            ],
            semanticIds: const [
              'main-nav-today',
              'main-nav-messages',
              'main-nav-memories',
              'main-nav-more',
            ],
          ),
        ),
      ),
    ));
    expect(find.byType(AnnaOrganicLiquidTab), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

}
