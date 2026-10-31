import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

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
}
