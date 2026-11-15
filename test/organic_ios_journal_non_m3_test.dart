import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Original iOS Journal chrome is independent of Material 3 visual widgets.
/// These tests cover presentation and route contracts, NOT physical acceptance.
void main() {
  testWidgets('Journal row preserves large touch target and canonical callback',
      (tester) async {
    var taps = 0;
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final width in [320.0, 390.0, 600.0]) {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
            useMaterial3: true, // The row must not inherit an M3 ListTile.
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: brightness,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 720),
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: AnnaOrganicJournalRow(
                  identifier: 'ios-journal-qa-row',
                  icon: Icons.auto_stories_outlined,
                  domain: AnnaVisualDomain.today,
                  title: 'Il mio quaderno personale',
                  subtitle: 'Un posto per i ricordi importanti',
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        ));
        final row = find.byKey(
            const ValueKey<String>('ios-journal-qa-row'));
        expect(row, findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(58));
        expect(tester.takeException(), isNull);
        await tester.tap(row);
        expect(taps, greaterThan(0));
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Journal hairline is decorative, not another control',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnnaOrganicJournalRule()),
    ));
    expect(find.byType(AnnaOrganicJournalRule), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('More, Settings and Memories use original chrome only in Organic mode',
      () {
    final more = File('lib/src/screens/more_screen.dart')
        .readAsStringSync();
    final settings = File('lib/src/screens/settings_hub.dart')
        .readAsStringSync();
    final primarySettings = File('lib/src/screens/backup_settings.dart')
        .readAsStringSync();
    final memories = File('lib/src/diary/editorial_memories.dart')
        .readAsStringSync();
    final chrome = File('lib/src/organic_journal_chrome.dart')
        .readAsStringSync();

    expect(more, contains('AnnaOrganicJournalRow('));
    expect(settings, contains('AnnaOrganicJournalRow('));
    expect(more, contains('if (AnnaOrganicPastel.enabled(context))'));
    expect(settings, contains('if (AnnaOrganicPastel.enabled(context))'));
    expect(more, contains('return Semantics(')); // Classic fallback.
    expect(settings, contains('return Semantics('));
    expect(primarySettings, contains('Widget _journalSettingsCard('));
    expect(primarySettings, contains('AnnaOrganicPaperSurface(child: child)'));
    expect(primarySettings, contains('SimpleCard(child: child)'));
    expect(memories, contains('AnnaOrganicJournalRule()'));
    expect(memories, contains('DiaryBlockType.photo && block.hasPhotoMedia'));
    expect(memories, contains('_coverPreview(context, record)'));
    expect(memories, contains('_openRecord(record)'));
    expect(chrome, isNot(contains('ListTile(')));
    expect(chrome, isNot(contains('FilledButton(')));
  });
}
