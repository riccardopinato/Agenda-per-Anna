import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-contract regression for v1.08. This does not replace interactive
/// real-device, screenshot, or runtime frame-timing verification.
void main() {
  String source(String path) => File(path).readAsStringSync();

  test('motion v1.08 is presentation-only and supports reduced motion', () {
    final app = source('lib/main.dart');
    final motion = source('lib/src/motion_v108.dart');
    final tokens = source('lib/src/theme_semantics.dart');
    expect(app, contains("part 'src/motion_v108.dart';"));
    expect(motion, contains('AnnaDesignTokens.animationsEnabled(context)'));
    expect(tokens, contains('media?.disableAnimations'));
    expect(tokens, contains('media?.accessibleNavigation'));
    expect(motion, contains('class AnnaMotionReveal'));
    expect(motion, contains('class AnnaMotionStagger'));
    expect(motion, contains('widget.order.clamp(0, 4)'));
    expect(motion, contains('IgnorePointer('));
    expect(motion, isNot(contains('saveJournal(')));
    expect(motion, isNot(contains('Navigator.push(')));
  });

  test('M02–07 preserve canonical four tabs, date source and single Crea sheet', () {
    final shell = source('lib/src/screens/home_inbox_search.dart');
    final planner = source('lib/src/planner_views.dart');
    final capture = source('lib/src/unified_capture.dart');
    expect(shell, contains('AnnaMotionReveal('));
    expect(shell, contains('IndexedStack(index: index, children: pages)'));
    expect(shell, contains('StartTab.calendar.index'));
    expect(shell, contains('DateTime.now()'));
    expect(shell, contains('AnimatedScale('));
    expect(capture, contains('showModalBottomSheet<_UnifiedCaptureAction>'));
    expect(capture, contains('var showAllActions = false'));
    for (final action in ['text', 'photo', 'voice', 'task', 'sketch']) {
      expect(capture, contains('_UnifiedCaptureAction.$action'));
    }
    expect(planner, contains("identifier: 'ui5-today-date-strip'"));
    expect(planner, contains('AnnaMotionStagger('));
    expect(planner, contains('AnnaMotionReveal('));
    expect(planner, contains('TableCalendar<UnifiedAgendaEntry>('));
    expect(planner, contains('onSelectedDateChanged?.call(s)'));
  });

  test('M10 uses only confirmed canonical saves for positive visual feedback', () {
    final capture = source('lib/src/unified_capture.dart');
    final motion = source('lib/src/motion_v108.dart');
    expect(capture, contains('AnnaMotionV108.showSaveSuccess(context)'));
    expect(capture, contains('if (!context.mounted) return;'));
    expect(motion, contains('showSaveSuccess(BuildContext context)'));
    expect(motion, contains('Overlay.maybeOf(context)'));
    expect(motion, isNot(contains('store.saveJournal(')));
  });

  test('M08–20 use real memory identities and preserve UI5 entry points', () {
    final memories = source('lib/src/diary/diary_memories.dart');
    final search = source('lib/src/diary/diary_global_search.dart');
    final collections = source('lib/src/screens/memory_collections_screen.dart');
    final photo = source('lib/src/diary/diary_sketchbook.dart');
    final motion = source('lib/src/motion_v108.dart');

    expect(memories, contains('PageView.builder('));
    expect(memories, contains('suggestions.take(3)'));
    expect(memories, contains('_suggestionsExpanded'));
    expect(memories, contains('_expandedTimelineMonths'));
    expect(memories, contains('Scrollable.ensureVisible('));
    expect(memories, contains('_highlightTimelineMonth'));
    expect(memories, contains("identifier: 'memory-map-canvas'"));
    expect(memories, contains('place.latestMemory'));
    expect(memories, contains('AnnaMotionMapPin('));
    expect(memories, contains('AnnaThenNowWipe('));
    expect(motion, contains('class AnnaThenNowWipe'));
    expect(memories, contains("v108-photo-"));
    expect(photo, contains("v108-photo-"));
    expect(collections, contains("v108-album-"));
    expect(collections, contains('memoryCollectionReferencesById'));
    expect(search, contains("key: const ValueKey<String>('ui5-search-results')"));
    expect(search, contains('AnnaMotionStagger('));
    expect(search, contains('DiaryBlockType.voice'));
    expect(search, contains("ui5SearchNoResults"));
    expect(memories, contains('_DiaryGlobalSearchScreen('));
  });
}
