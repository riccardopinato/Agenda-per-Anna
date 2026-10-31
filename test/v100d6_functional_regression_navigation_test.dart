import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.05-A2 preserves canonical navigation through the new shell', () {
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final more =
        File('lib/src/screens/more_screen.dart').readAsStringSync();

    expect(shell, contains('PlannerScreen(store: widget.store, embedded: true)'));
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    expect(planner, contains('CalendarHubScreen('));
    expect(shell, contains('DiaryMemoriesScreen(store: widget.store)'));
    expect(shell, contains('MoreScreen(store: widget.store)'));
    expect(shell, contains("semanticsId: 'main-nav-today'"));
    expect(shell, contains("semanticsId: 'main-nav-messages'"));
    expect(shell, contains("semanticsId: 'main-nav-memories'"));
    expect(shell, contains("semanticsId: 'main-nav-more'"));
    expect(shell, contains('identifier: semanticsId'));
    expect(shell, contains('key: ValueKey<String>(semanticsId)'));

    expect(more, contains('PersonalSearchConnectionsScreen(store: store)'));
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    expect(search, contains("identifier: 'search_back_button'"));
    expect(more, contains('InboxScreen(store: store)'));
    expect(more, contains('ArchiveScreen(store: store)'));
    expect(more, contains('BackupScreen(store: store)'));
    expect(shell, contains('SharedSpaceHubScreen(store: widget.store)'));
    expect(more, contains('CloudAccountScreen(store: store)'));
    expect(more, contains('SettingsHubScreen(store: store)'));
    expect(more, contains('ExploreScreen(store: store)'));
  });

  test('v1.00-D6 keeps Explore as navigation-only over canonical domains', () {
    final explore =
        File('lib/src/screens/explore_screen.dart').readAsStringSync();

    expect(explore, contains('ShoppingListScreen(store: store)'));
    expect(explore, contains('WorkoutScreen(store: store)'));
    expect(explore, isNot(contains('DiaryMemoriesScreen(store: store)')));
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
    expect(flow, contains('search_back_button'));
    expect(flow, contains('Shopping list'));
    expect(flow, contains('Workout'));
    expect(flow, contains('Life Ecosystem'));
    expect(flow, contains('Account and sync'));

    // D5 entry regression remains a prerequisite for the D6 journey.
    // The offline entry is selected by a stable semantic identifier, not
    // by a localized or historical label that can change with the UI.
    expect(smoke, contains('clearState: true'));
    expect(
      smoke,
      contains("- extendedWaitUntil:\n    visible:\n      id: 'identity-offline-continue'"),
    );
    expect(
      smoke,
      contains("- tapOn:\n    id: 'identity-offline-continue'"),
    );
  });

  test('UI5 Maestro identity selectors use valid nested visibility conditions', () {
    for (final path in <String>[
      '.maestro/applab-smoke.yaml',
      '.maestro/journeys/core-shell.yaml',
      '.maestro/journeys/onboarding.yaml',
      '.maestro/journeys/vault-create.yaml',
    ]) {
      final flow = File(path).readAsStringSync();
      expect(flow, contains("- extendedWaitUntil:\n    visible:\n      id: 'identity-offline-continue'"), reason: path);
      expect(flow, isNot(contains("- extendedWaitUntil:\n    id: 'identity-offline-continue'")), reason: path);
    }
    for (final path in <String>[
      '.maestro/journeys/memories-critical.yaml',
      '.maestro/journeys/navigation-critical.yaml',
      '.maestro/journeys/settings-critical.yaml',
      '.maestro/journeys/vault-correct-unlock.yaml',
      '.maestro/journeys/vault-restart-unlock.yaml',
      '.maestro/journeys/vault-wrong-password.yaml',
    ]) {
      final flow = File(path).readAsStringSync();
      expect(flow, contains("- runFlow:\n    when:\n      visible:\n        id: 'identity-offline-continue'"), reason: path);
      expect(flow, isNot(contains("- runFlow:\n    when:\n      id: 'identity-offline-continue'")), reason: path);
    }
  });
}
