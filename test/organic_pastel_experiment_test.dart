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

  test('Organic watercolor is true 576x192 WebP, not the old 360x120', () {
    final bytes = AnnaOrganicPastelWatercolor.bytes;
    expect(bytes.length, greaterThan(6000));
    expect(bytes.length, lessThan(20000)); // bounded offline asset weight
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
    // RIFF VP8 frame width and height are stored in bytes 26–29.
    expect((bytes[26] | (bytes[27] << 8)) & 0x3fff, 576);
    expect((bytes[28] | (bytes[29] << 8)) & 0x3fff, 192);
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
        expect(colors.colors.first.a, 1.0);
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
        await tester.tap(
          find.byKey(const ValueKey<String>('today-open-calendar')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('today-editorial-disable')),
        );
        expect(calendarOpens, 1);
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
    // The source image has a fixed 3:1 panorama, not a stretched 232dp cover.
    final image = find.byKey(
      const ValueKey<String>('organic-pastel-landscape'),
    );
    expect(tester.getSize(image).height, closeTo(130, .1));
    expect(find.byKey(
      const ValueKey<String>('organic-pastel-vector-sky'),
    ), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(tester.getSize(hero).height, closeTo(156, .1));
    expect(tester.getSize(image).height, closeTo(130, .1));
    expect(find.byKey(
      const ValueKey<String>('ds6-today-greeting'),
    ), findsOneWidget);
    await tester.tap(find.byKey(
      const ValueKey<String>('today-open-calendar'),
    ));
    await tester.tap(find.byKey(
      const ValueKey<String>('today-editorial-disable'),
    ));
    expect(calendar, 1);
    expect(classic, 1);
    expect(tester.takeException(), isNull);
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

  testWidgets('compact phone keeps seven real day controls scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnnaOrganicPastelWeekStrip(
            selected: DateTime(2026, 11, 14),
            onSelected: (_) {},
          ),
        ),
      ),
    ));
    expect(
      find.byKey(const ValueKey<String>('organic-pastel-week-strip')),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(tester.takeException(), isNull);
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
            labels: const ['Oggi', 'Messaggi', 'Ricordi', 'Altro'],
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
            labels: const ['Oggi', 'Messaggi', 'Ricordi', 'Altro'],
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
