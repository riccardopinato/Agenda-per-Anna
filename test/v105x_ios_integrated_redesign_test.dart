import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integrated iOS Journal layout keeps all approved sections', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final memories = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final settings = File('lib/src/screens/settings_hub.dart').readAsStringSync();
    final common = File('lib/src/ios_journal_design.dart').readAsStringSync();

    expect(planner, contains('AnnaJournalSectionHeading(title: strings.diary)'));
    expect(planner, contains('WidgetStatePropertyAll'));
    expect(planner, contains('SegmentedButton<_CalendarHubView>'));
    expect(memories, contains("'memories-editorial-hero'"));
    expect(memories, contains('AnnaJournalPageHeader('));
    expect(more, contains('AnnaJournalSectionHeading('));
    expect(settings, contains("id: 'settings-hub-appearance'"));
    expect(common, contains('return Material('));
  });
}
