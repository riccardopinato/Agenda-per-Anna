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
}
