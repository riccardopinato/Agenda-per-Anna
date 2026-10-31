import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('calendar keeps month/week, links, and one-line approved tagline', () {
    final planner = source('lib/src/planner_views.dart');
    expect(planner, contains('Ogni giorno, una storia.'));
    expect(planner, contains('String approvedCalendarTagline('));
    expect(planner, contains('SegmentedButton<_CalendarHubView>'));
    expect(planner, contains('calendar-open-month-notebook'));
    expect(planner, contains('calendar-open-year-overview'));
    expect(planner, contains('TableCalendar<UnifiedAgendaEntry>'));
    expect(planner, contains('onSelectedDateChanged?.call(s)'));
    expect(planner, contains('approved-calendar-hourly-timeline'));
    expect(planner, contains('initiallyExpanded: false'));
    expect(planner, contains('for (var hour = 7; hour <= 22; hour++)'));
    expect(planner, contains('openUnifiedAgendaEntry('));
    expect(planner, contains('AgendaContentFilterBar(store: widget.store)'));
    expect(planner, contains('UnifiedAgendaTile('));
    expect(planner, contains('_CalendarDayContextCard('));
    expect(planner, contains('class DayTimeline extends StatelessWidget'));
  });

  test('More keeps every existing route and renders uniform 58px rows', () {
    final more = source('lib/src/screens/more_screen.dart');
    expect(more, contains('height: 58,'));
    for (final id in [
      'more-search', 'more-inbox', 'more-private-vault',
      'more-explore', 'more-archive', 'more-backup', 'more-cloud',
      'more-settings', 'more-shared',
    ]) {
      expect(more, contains("id: '$id'"));
    }
    expect(more, contains('if (store.hasStorageWarnings)'));
    expect(more, contains('_SyncAttentionCard(store: store)'));
  });

  test('Settings retains all routes and exposes editable holder name', () {
    final settings = source('lib/src/screens/settings_hub.dart');
    expect(settings, contains('settings-hub-edit-name'));
    expect(settings, contains('Inserisci il tuo nome'));
    expect(settings, contains('store.settingsRevision'));
    expect(settings, contains('SettingsScreen(store: store)'));
    for (final route in [
      'settings-hub-appearance', 'settings-hub-personalization',
      'settings-hub-preferences-privacy', 'settings-hub-premium',
      'settings-hub-account', 'settings-hub-backup',
    ]) {
      expect(settings, contains(route));
    }
    expect(settings.split("id: 'settings-hub-premium'").length, 2);
  });

  test('approved tagline is present in five languages', () {
    final planner = source('lib/src/planner_views.dart');
    for (final tagline in [
      'Every day, a story.',
      'Ogni giorno, una storia.',
      'Cada día, una historia.',
      'Chaque jour, une histoire.',
      'Cada dia, uma história.',
    ]) {
      expect(planner, contains(tagline));
    }
  });
}
