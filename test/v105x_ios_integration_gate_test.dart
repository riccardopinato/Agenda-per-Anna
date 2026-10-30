import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Integrated iOS Journal preserves all five approved destinations', () {
    final shell = File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final memories = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final settings = File('lib/src/screens/settings_hub.dart').readAsStringSync();
    final cards = File('lib/src/ios_journal_design.dart').readAsStringSync();

    for (final destination in [
      'PlannerScreen(store: widget.store, embedded: true)',
      'CalendarHubScreen(',
      'DiaryMemoriesScreen(store: widget.store)',
      'MoreScreen(store: widget.store)',
    ]) {
      expect(shell, contains(destination));
    }
    expect(planner, contains('AnnaJournalSectionHeading(title: strings.diary)'));
    expect(planner, contains('SegmentedButton<_CalendarHubView>'));
    expect(planner, contains("identifier: 'calendar-open-month-notebook'"));
    expect(planner, contains("identifier: 'calendar-open-year-overview'"));
    expect(planner, contains('JournalEditor(store: widget.store, date: day)'));
    expect(memories, contains("'memories-editorial-hero'"));
    expect(memories, contains('AnnaJournalPageHeader('));
    expect(more, contains("id: 'more-settings'"));
    expect(more, contains('_SyncAttentionCard(store: store)'));
    expect(settings, contains("id: 'settings-hub-appearance'"));
    expect(settings, contains('AppearanceColorsScreen(store: store)'));
    expect(cards, contains('return Material('));
  });

  test('Shared appearance state is backward-compatible across screen lanes', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final editor = File('lib/src/screens/appearance_colors.dart').readAsStringSync();
    expect(store, contains("payload.containsKey('useCustomPalette')"));
    expect(store, contains("payload.containsKey('colorIntensity')"));
    expect(editor, contains("'appearance-hue-slider'"));
    expect(editor, contains("'appearance-saturation-slider'"));
    expect(editor, contains("'appearance-brightness-slider'"));
    expect(editor, contains('if (saving || !hexValid) return;'));
    expect(editor, contains('appearanceInvalidHex'));
  });
}
