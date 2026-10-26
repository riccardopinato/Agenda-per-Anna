import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.05-A3 makes Today the only daily hub', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final legacy =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(planner, contains("identifier: 'today-focus-card'"));
    expect(planner, contains("today-pinned-section"));
    expect(planner, contains("identifier: 'today-wellbeing-card'"));
    expect(planner, contains('widget.store.unifiedUpcoming(DateTime.now())'));
    expect(planner, contains('widget.store.pendingUnifiedTaskCount'));
    expect(planner, contains('widget.store.activeInboxEntries.length'));
    expect(planner, contains('AgendaContentFilter.sharedOnly'));

    expect(legacy, isNot(contains('class HomeScreen')));
    expect(legacy, isNot(contains('class _HomeFocusCard')));
    expect(legacy, isNot(contains("identifier: 'home_more_menu'")));
    expect(legacy, isNot(contains("ValueKey<String>('home-more-menu')")));
  });

  test('v1.05-A3 keeps operational warnings in More, not Today', () {
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final shared =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(more, contains('_SyncAttentionCard(store: store)'));
    expect(more, contains('store.hasStorageWarnings'));
    expect(more, contains('strings.v100StorageWarning'));
    expect(shared, contains('class _SyncAttentionCard'));
    expect(shared, contains("ValueKey<String>('sync-attention')"));

    expect(planner, isNot(contains('store.hasStorageWarnings')));
    expect(planner, isNot(contains('_SyncAttentionCard(store:')));
  });

  test('v1.05-A3 removes superseded Home-only Vault presentation', () {
    final vault =
        File('lib/src/screens/private_vault.dart').readAsStringSync();
    final legacy =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(vault, isNot(contains('class PrivateVaultHomeCard')));
    expect(vault, contains('class PrivateVaultScreen'));
    expect(legacy, isNot(contains('PrivateVaultHomeCard(')));
  });

  test('v1.05-A3 runtime journey verifies the consolidated Today surface', () {
    final flow = File('.maestro/journey/today.yaml').readAsStringSync();

    expect(flow, contains("id: 'today-focus-card'"));
    expect(flow, contains('scrollUntilVisible:'));
    expect(flow, contains('assertVisible:'));
  });
}
