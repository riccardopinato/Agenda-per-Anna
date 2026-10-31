import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('Journal theme keeps the canonical seed and picker accent behavior', () {
    for (final seed in [
      AgendaPalette.rose.seed,
      AgendaPalette.lilac.seed,
      const Color(0xFF356BAC),
    ]) {
      for (final brightness in Brightness.values) {
        final scheme =
            ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
        for (final expressive in [false, true]) {
          final input = ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            navigationBarTheme: NavigationBarThemeData(
              indicatorColor: expressive
                  ? scheme.secondaryContainer
                  : scheme.primaryContainer,
            ),
          );
          final decorated = AnnaJournalTheme.apply(input);

          expect(decorated.colorScheme, equals(scheme));
          expect(decorated.useMaterial3, isTrue);
          expect(
            decorated.navigationBarTheme.indicatorColor,
            expressive ? scheme.secondaryContainer : scheme.primaryContainer,
          );
          expect(
            decorated.navigationBarTheme.height,
            AnnaDesignTokens.journalDockHeight,
          );
          expect(
            decorated.textTheme.bodyLarge?.fontFamily,
            AnnaJournalTypography.uiFamily,
          );
          expect(
            decorated.appBarTheme.foregroundColor,
            scheme.onSurface,
          );
        }
      }
    }
  });

  test('offline Manrope/Lora variable fonts and OFL notices are bundled',
      () async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/fonts/licenses/'));
    for (final family in ['Manrope', 'Lora']) {
      expect(pubspec, contains('family: $family'));
      final filename = family == 'Manrope'
          ? 'assets/fonts/Manrope-VF.ttf'
          : 'assets/fonts/Lora-VF.ttf';
      expect(pubspec, contains('asset: $filename'));
      final asset = await rootBundle.load(filename);
      expect(asset.lengthInBytes, greaterThan(100000));
      // Standard TrueType scaler header, including variable TrueType fonts.
      expect(asset.getUint32(0, Endian.big), 0x00010000);
      final license = await rootBundle.loadString(
        'assets/fonts/licenses/$family-OFL.txt',
      );
      expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
    }
  });

  test('Journal styling remains presentation-only with a fixed bottom bar', () {
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final theme = File('lib/src/ios_journal_design.dart').readAsStringSync();
    final app = File('lib/src/app_shell.dart').readAsStringSync();
    expect(shell, contains('bottomNavigationBar: useRail'));
    expect(shell, contains('child: NavigationBar('));
    expect(shell, contains('IndexedStack(index: index, children: pages)'));
    expect(shell, contains('Theme.of(context).navigationBarTheme.indicatorColor'));
    for (final key in [
      'main-nav-today',
      'main-nav-messages',
      'main-nav-memories',
      'main-nav-more',
    ]) {
      expect(shell, contains(key));
    }
    expect(theme, isNot(contains('savePreferences(')));
    expect(theme, isNot(contains('CloudSyncService')));
    expect(app, contains('AnnaJournalTheme.apply(ThemeData('));
    expect(app, contains('prefs.effectiveSeedColor'));
    expect(app, contains('AnnaJournalTypography.registerLicensesOnce()'));
  });

  testWidgets('Large page title supports dark mode and large text scale',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final brightness in [Brightness.light, Brightness.dark]) {
      final colors =
          ColorScheme.fromSeed(seedColor: AgendaPalette.rose.seed, brightness: brightness);
      await tester.pumpWidget(MaterialApp(
        theme: AnnaJournalTheme.apply(ThemeData(
          useMaterial3: true,
          colorScheme: colors,
        )),
        home: const Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: AnnaJournalContent(
                child: AnnaJournalPageHeader(
                  title: 'La tua giornata',
                  eyebrow: 'MERCOLEDÌ 28 OTTOBRE',
                  subtitle: 'Appuntamenti, pensieri e ricordi',
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('La tua giornata'), findsOneWidget);
      expect(find.text('Appuntamenti, pensieri e ricordi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Journal card is semantic seed-aware and keeps body readable',
      (tester) async {
    for (final seed in [
      AgendaPalette.rose.seed,
      AgendaPalette.sky.seed,
      const Color(0xFF315B87),
    ]) {
      await tester.pumpWidget(MaterialApp(
        theme: AnnaJournalTheme.apply(ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
        )),
        home: const Scaffold(
          body: AnnaJournalCard(
            domain: AnnaVisualDomain.today,
            hero: true,
            child: AnnaJournalSectionHeading(
              title: 'Il mio diario',
              action: Icon(Icons.chevron_right),
            ),
          ),
        ),
      ));
      expect(find.text('Il mio diario'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
