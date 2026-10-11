import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.00-D6 preserves the four canonical shell destinations', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(home, contains('HomeScreen(store: widget.store)'));
    expect(home, contains('CalendarScreen(store: widget.store)'));
    expect(home, contains('WeekScreen(store: widget.store)'));
    expect(home, contains('PlannerScreen(store: widget.store)'));

    expect(home, contains('PersonalSearchConnectionsScreen(store: store)'));
    expect(home, contains('InboxScreen(store: store)'));
    expect(home, contains('ArchiveScreen(store: store)'));
    expect(home, contains('BackupScreen(store: store)'));
    expect(home, contains('SharedSpaceHubScreen(store: store)'));
    expect(home, contains('CloudAccountScreen(store: store)'));
    expect(home, contains('SettingsScreen(store: store)'));
    expect(home, contains('ExploreScreen(store: store)'));
  });

  test('v1.00-D6 keeps Explore as navigation-only over canonical domains', () {
    final explore =
        File('lib/src/screens/explore_screen.dart').readAsStringSync();

    expect(explore, contains('ShoppingListScreen(store: store)'));
    expect(explore, contains('WorkoutScreen(store: store)'));
    expect(explore, contains('DiaryMemoriesScreen(store: store)'));
    expect(explore, contains('PeopleScreen(store: store)'));
    expect(explore, contains('LifeEcosystemScreen(store: store)'));

    expect(explore, isNot(contains('SharedPreferences')));
    expect(explore, isNot(contains('LocalStateStore')));
    expect(explore, isNot(contains('MediaAssetStore')));
  });

  test('v1.00-D6 preserves the single Unified Capture entry path', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(home, contains('return showUnifiedCapture('));
    expect(capture, contains('Future<void> showUnifiedCapture('));
    expect(capture, contains('_UnifiedCaptureAction.text'));
    expect(capture, contains('_UnifiedCaptureAction.voice'));
    expect(capture, contains('_UnifiedCaptureAction.photo'));
    expect(capture, contains('_UnifiedCaptureAction.inbox'));
    expect(capture, contains('_UnifiedCaptureAction.task'));
    expect(capture, contains('_UnifiedCaptureAction.event'));
    expect(capture, contains('_UnifiedCaptureAction.birthday'));
    expect(capture, contains('_UnifiedCaptureAction.person'));
    expect(planner, contains('UnifiedCaptureEntryPoint.day'));
  });

  test('v1.00-D6 AppLab covers the post-D5 navigation regression', () {
    final journey =
        File('.maestro/applab-journey.json').readAsStringSync();
    final flow =
        File('.maestro/journey/d6-functional-navigation.yaml')
            .readAsStringSync();
    final smoke =
        File('.maestro/applab-smoke.yaml').readAsStringSync();

    expect(journey, contains('"name": "functional-navigation"'));
    expect(
      journey,
      contains('.maestro/journey/d6-functional-navigation.yaml'),
    );
    expect(flow, contains('Search and connect'));
    expect(flow, contains('Shopping list'));
    expect(flow, contains('Workout'));
    expect(flow, contains('Life Ecosystem'));
    expect(flow, contains('Account and sync'));

    // D5 entry regression remains a prerequisite for the D6 journey.
    expect(smoke, contains('Use on this device'));
    expect(smoke, contains('clearState: true'));
  });
}
