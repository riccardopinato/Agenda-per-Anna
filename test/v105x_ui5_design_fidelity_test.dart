import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('DF01–07: one central Crea and original capture with date, Sketch and templates', () {
    final shell = read('lib/src/screens/home_inbox_search.dart');
    final capture = read('lib/src/unified_capture.dart');
    final calendar = read('lib/src/planner_views.dart');
    expect(shell, contains("identifier: 'main-nav-create'"));
    expect(shell, contains("identifier: 'main-rail-create'"));
    expect(shell, contains('StartTab.calendar.index'));
    expect(shell, contains('DateTime.now()'));
    expect(shell, contains('await showUnifiedCapture('));
    expect(shell, contains('AnimatedScale('));
    expect(shell, contains('AnnaDesignTokens.animationsEnabled(context)'));
    expect(calendar, contains('onSelectedDateChanged?.call(s)'));
    expect(calendar, contains('widget.embedded ? null : FloatingActionButton.extended'));
    for (final id in ['main-nav-today', 'main-nav-calendar', 'main-nav-memories', 'main-nav-more']) {
      expect(shell, contains(id));
    }
    expect(capture, contains("identifier: 'capture-effective-date'"));
    expect(capture, contains('showDatePicker('));
    expect(capture, contains('_UnifiedCaptureAction.sketch'));
    expect(capture, contains('_UnifiedCaptureAction.templates'));
    expect(capture, contains('DiarySketchbookScreen('));
    expect(capture, contains('await store.applyDiaryTemplate('));
    expect(capture, contains('var showAllActions = false'));
    expect(capture, contains('showModalBottomSheet<_UnifiedCaptureAction>'));
  });

  test('DF08–20: Oggi is overview-first with just two journal previews and one memory teaser', () {
    final planner = read('lib/src/planner_views.dart');
    final screen = planner.split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    expect(screen.indexOf('_TodayCompactSummary('),
        lessThan(screen.indexOf('_TodayCompactDiaryPreview(')));
    expect(screen, contains('DateStrip('));
    expect(screen, contains("identifier: 'ui5-today-date-strip'"));
    expect(screen, contains('onSelected: _selectDay'));
    expect(screen, contains('if (widget.embedded)'));
    expect(planner, contains('blocks.take(2)'));
    expect(planner, contains("ValueKey<String>('ui5-today-memory-teaser')"));
  });

  test('DF15–24: dedicated anniversary carousel and compact expandable suggestions', () {
    final memories = read('lib/src/diary/diary_memories.dart');
    final perTe = memories.split('Widget _forYouView(')[1]
        .split('Widget _timelineMemoryCard(')[0];
    expect(perTe, contains('PageView.builder('));
    expect(perTe, contains('snapshot.onThisDay'));
    expect(perTe, contains('snapshot.sameMonthPastYears'));
    expect(perTe, contains("ui5-anniversary-year-"));
    expect(perTe, contains('suggestions.take(3)'));
    expect(perTe, contains('_suggestionsExpanded'));
    expect(perTe.indexOf('PageView.builder('),
        lessThan(perTe.indexOf('suggestions.take(3)')));
  });

  test('DF25–28: month accordion, authentic counts and year picker retain session state', () {
    final memories = read('lib/src/diary/diary_memories.dart');
    expect(memories, contains('_expandedTimelineMonths'));
    expect(memories, contains('_selectedTimelineYear'));
    expect(memories, contains('DropdownButton<int>('));
    expect(memories, contains('Scrollable.ensureVisible('));
    expect(memories, contains("key: const PageStorageKey<String>('ui5-timeline-scroll')"));
    expect(memories, contains("identifier: 'memories-timeline-list'"));
    expect(memories, contains('bucket.length'));
  });

  test('DF29–35: fresh global search with accessible type filters and direct memory result', () {
    final source = read('lib/src/diary/diary_global_search.dart');
    final parent = read('lib/src/diary/diary_memories.dart');
    expect(parent, contains('_DiaryGlobalSearchScreen('));
    expect(source, contains('includeArchived: false'));
    expect(source, contains('DiaryBlockType.note'));
    expect(source, contains('DiaryBlockType.photo'));
    expect(source, contains('DiaryBlockType.sketch'));
    expect(source, contains('DiaryBlockType.voice'));
    expect(source, contains("key: const ValueKey<String>('ui5-search-results')"));
    expect(source, contains("key: ValueKey<String>('ui5-search-result-"));
    expect(source, contains('Text(strings.d3(\'ui5SearchNoResults\')'));
    expect(source, contains('onPressed: () => setState(() => _type = null)'));
    expect(source, contains('final TextEditingController _query = TextEditingController()'));
    expect(source, contains('final ScrollController _scroll = ScrollController()'));
    expect(source, contains('DiaryPhotoViewerScreen('));
    expect(source, contains('_DiarySearchItemScreen('));
  });

  test('UI5 labels exist for all five supported languages', () {
    final labels = read('lib/src/localization_d3.dart');
    for (final key in ['ui5Create', 'ui5ForYou', 'ui5OnThisDay',
      'ui5ShowAll', 'ui5SearchHint', 'ui5SearchNoResults',
      'ui5MemoryCount', 'ui5MemoryTeaser', 'ui5DayDiary']) {
      final row = labels.split('\n').firstWhere(
        (line) => line.contains('"$key": <String, String>'));
      for (final language in ['en', 'it', 'es', 'fr', 'pt']) {
        expect(row, contains('"$language":'));
      }
    }
  });
}
