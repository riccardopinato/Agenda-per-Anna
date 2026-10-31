import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('Today uses one primary capture action and prioritizes the diary', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final planner = source
        .split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];

    expect(planner, contains('FloatingActionButton.extended('));
    expect(planner, contains('UnifiedCaptureEntryPoint.day'));
    expect(
      planner,
      isNot(contains(
        'onPressed: () => openUnifiedItemComposer(context, widget.store, day)',
      )),
    );
    expect(planner, contains('maxWidth: AnnaDesignTokens.readingContentWidth'));

    final diaryPosition =
        planner.indexOf('JournalEditor(store: widget.store, date: day)');
    final streamPosition = planner.indexOf('_DayLifeStream(');
    final timelinePosition = planner.indexOf('ExpansionTile(');
    expect(diaryPosition, greaterThan(0));
    expect(streamPosition, greaterThan(diaryPosition));
    expect(timelinePosition, greaterThan(streamPosition));
    expect(planner, contains('AnnaJournalSectionHeading(title: strings.diary)'));
    expect(planner, contains('today-pinned-section'));
  });

  test('More retains canonical routes and clearer pastel groups', () {
    final source = File('lib/src/screens/more_screen.dart').readAsStringSync();
    expect(source, contains('AnnaJournalSectionHeading('));
    expect(source, contains('AnnaPastelIcon(icon: icon, domain: domain)'));
    expect(source, contains('AnnaDesignTokens.compactContentWidth'));
    for (final id in [
      'more-search',
      'more-inbox',
      'more-explore',
      'more-private-vault',
      'more-archive',
      'more-backup',
      'more-cloud',
      'more-settings',
    ]) {
      expect(source, contains("id: '$id'"));
    }
    expect(source, contains('_SyncAttentionCard(store: store)'));
    expect(source, contains('SettingsHubScreen(store: store)'));
  });

  test('Settings retains stable routes and constrained Web layout', () {
    final source = File('lib/src/screens/settings_hub.dart').readAsStringSync();
    expect(source, contains('AnnaJournalSectionHeading('));
    expect(source, contains('AnnaDesignTokens.compactContentWidth'));
    for (final id in [
      'settings-hub-personalization',
      'settings-hub-preferences-privacy',
      'settings-hub-premium',
      'settings-hub-account',
      'settings-hub-backup',
    ]) {
      expect(source, contains("id: '$id'"));
    }
    for (final route in [
      'PersonalizationScreen(store: store)',
      'SettingsScreen(store: store)',
      'CloudAccountScreen(store: store)',
      'BackupScreen(store: store)',
    ]) {
      expect(source, contains(route));
    }
  });

  testWidgets('Pastel icon uses a 48dp footprint in light and dark',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: brightness,
          ),
          home: const Scaffold(
            body: AnnaPastelIcon(
              icon: Icons.favorite_outline,
              domain: AnnaVisualDomain.shared,
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AnnaPastelIcon)),
        const Size(48, 48),
      );
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    }
  });
}
