import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  String code(String path) => File(path).readAsStringSync();

  test('main nav is Today Messages +Crea Memories More, with no fifth Calendar tab', () {
    final shell = code('lib/src/screens/home_inbox_search.dart');
    for (final id in [
      'main-nav-today', 'main-nav-messages', 'main-nav-create',
      'main-nav-memories', 'main-nav-more', 'main-rail-messages',
    ]) {
      expect(shell, contains(id));
    }
    expect(shell, isNot(contains("'main-nav-calendar'")));
    expect(shell, isNot(contains("'main-rail-calendar'")));
    expect(shell, contains('SharedSpaceHubScreen(store: widget.store)'));
    expect(shell, contains('widget.store.preferences.startTab'));
    expect(shell, contains('StartTab.calendar'));
    expect(shell, contains('CalendarHubScreen(store: widget.store)'));
    expect(shell, contains('initialDate: DateTime.now()'));
  });

  test('Today retains a direct calendar route and personalized greeting', () {
    final planner = code('lib/src/planner_views.dart');
    final localization = code('lib/src/localization.dart');
    expect(planner, contains("'today-open-calendar'"));
    expect(planner, contains('approvedTodayGreeting('));
    expect(planner, contains('widget.store.preferences.displayName'));
    expect(planner, contains('strings.languageCode'));
    expect(planner, contains('DateTime.now().hour'));
    expect(planner, contains('CalendarHubScreen(store: widget.store)'));
    expect(planner, contains('widget.onSelectedDateChanged?.call(selected)'));
    expect(planner, contains('initialDate: _captureDay'));
    expect(planner, contains('UnifiedCaptureEntryPoint.month'));
    expect(localization, contains('String get navMessages'));
    for (final value in ['Messaggi', 'Messages', 'Mensajes', 'Mensagens']) {
      expect(localization, contains(value));
    }
  });

  test('Shared Space is not duplicated in More but retains original owner', () {
    final more = code('lib/src/screens/more_screen.dart');
    final shell = code('lib/src/screens/home_inbox_search.dart');
    expect(more, isNot(contains("id: 'more-shared'")));
    expect(shell, contains('SharedSpaceHubScreen(store: widget.store)'));
    for (final id in [
      'more-search', 'more-inbox', 'more-explore', 'more-private-vault',
      'more-archive', 'more-backup', 'more-cloud', 'more-settings',
    ]) {
      expect(more, contains("id: '$id'"));
    }
    expect(more, contains('_SyncAttentionCard(store: store)'));
  });

  test('five mobile slots balance Messages and Memories around Create', () {
    // Page indices are unchanged for the stack, start-tab storage and rail.
    expect(
      List<int>.generate(4, MainShell.bottomBarSlotForPage),
      <int>[0, 1, 3, 4],
    );
    expect(
      List<int?>.generate(5, MainShell.pageForBottomBarSlot),
      <int?>[0, 1, null, 2, 3],
    );

    final shell = code('lib/src/screens/home_inbox_search.dart');
    final destinations = shell
        .split('List<Widget> _bottomDestinations(AnnaStrings strings)')[1]
        .split('List<NavigationRailDestination> _railDestinations')[0];
    final positions = <int>[
      destinations.indexOf("semanticsId: 'main-nav-today'"),
      destinations.indexOf("semanticsId: 'main-nav-messages'"),
      destinations.indexOf("key: ValueKey<String>('main-nav-create-space')"),
      destinations.indexOf("semanticsId: 'main-nav-memories'"),
      destinations.indexOf("semanticsId: 'main-nav-more'"),
    ];
    expect(positions.every((position) => position >= 0), isTrue);
    expect(positions, orderedEquals(positions.toList()..sort()));
    expect(destinations, contains('enabled: false'));
    expect(
      shell,
      contains('selectedIndex: MainShell.bottomBarSlotForPage(index)'),
    );
    expect(shell, contains('onDestinationSelected: _selectBottomDestination'));
    expect(shell, contains('Center(child: _centralCreateButton(context))'));
    // Desktop rail keeps its original four destinations, with no gap.
    expect(shell, contains('selectedIndex: index,'));
    expect(shell, contains('destinations: _railDestinations(strings)'));
  });
}
