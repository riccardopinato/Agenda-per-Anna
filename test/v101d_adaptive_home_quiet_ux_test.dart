import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home keeps only high-frequency or attention-worthy direct actions', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(home, contains("identifier: 'home_more_menu'"));
    expect(home, contains("ValueKey<String>('home-more-menu')"));
    expect(home, contains('PersonalSearchConnectionsScreen(store: store)'));
    expect(home, contains('if (store.activeInboxEntries.isNotEmpty)'));
    expect(
      home,
      contains(
        'prefs.isModuleEnabled(AppModule.sharedSpace) &&\n'
        '                  store.totalSharedUnreadCount > 0',
      ),
    );

    final appBarStart = home.indexOf('appBar: AppBar(');
    final moreMenuStart = home.indexOf(
      "identifier: 'home_more_menu'",
      appBarStart,
    );
    expect(appBarStart, greaterThanOrEqualTo(0));
    expect(moreMenuStart, greaterThan(appBarStart));
    final directActions = home.substring(appBarStart, moreMenuStart);

    expect(directActions, isNot(contains('Icons.inventory_2_outlined')));
    expect(directActions, isNot(contains('Icons.backup_outlined')));
    expect(directActions, isNot(contains('Icons.cloud_done_outlined')));
    expect(directActions, isNot(contains('Icons.settings_outlined')));
  });

  test('healthy sync and intentional device-only use stay quiet', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(home, contains('final intentionalLocalOnly'));
    expect(home, contains('final healthyCloud'));
    expect(
      home,
      contains('if (intentionalLocalOnly || healthyCloud)'),
    );
    expect(home, contains("ValueKey<String>('home-sync-attention')"));
    expect(home, contains('CloudConnectionState.error'));
    expect(home, contains('store.hasSharedSyncError'));
    expect(home, contains('pending > 0'));
  });

  test('Home presentation follows module preferences without deleting data', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(home, contains('AppModule.privateVault'));
    expect(home, contains('AppModule.people'));
    expect(home, contains('AppModule.habits'));
    expect(home, contains('AppModule.memories'));
    expect(home, contains('showBirthdays: peopleEnabled'));
    expect(home, contains('if (showBirthdays) ...['));
    expect(
      home,
      contains(
        'if (store.preferences.isModuleEnabled(AppModule.memories))',
      ),
    );
    expect(
      home,
      contains(
        'if (store.preferences.isModuleEnabled(AppModule.habits))',
      ),
    );

    expect(home, isNot(contains('removeWhere((module)')));
    expect(home, isNot(contains('deleteModule')));
  });

  test('secondary operational journeys use the stable More destination', () {
    final smoke = File('.maestro/applab-smoke.yaml').readAsStringSync();
    final account = File('.maestro/journey/account.yaml').readAsStringSync();
    final archive = File('.maestro/journey/archive.yaml').readAsStringSync();
    final backup = File('.maestro/journey/backup.yaml').readAsStringSync();
    final shared = File('.maestro/journey/shared.yaml').readAsStringSync();
    final trash = File('.maestro/journey/trash.yaml').readAsStringSync();
    final regression =
        File('.maestro/journey/d6-functional-navigation.yaml')
            .readAsStringSync();

    expect(smoke, contains("id: 'more-settings'"));
    expect(account, contains("id: 'more-cloud'"));
    expect(archive, contains("id: 'more-archive'"));
    expect(backup, contains("id: 'more-backup'"));
    expect(shared, contains("id: 'more-shared'"));
    expect(trash, contains("id: 'more-archive'"));
    expect(regression, contains("id: 'more-search'"));
    expect(regression, contains("id: 'more-inbox'"));
    expect(regression, contains("id: 'more-explore'"));
    expect(regression, contains("id: 'more-cloud'"));
  });

  test('new D navigation copy stays in the canonical five-language catalog', () {
    final localization =
        File('lib/src/localization_d3.dart').readAsStringSync();

    for (final key in const ['homeMore', 'homeExploreAreasCount']) {
      final start = localization.indexOf('"$key": <String, String>');
      expect(start, greaterThanOrEqualTo(0), reason: 'missing $key');
      final end = localization.indexOf('},', start);
      final entry = localization.substring(start, end);
      for (final locale in const ['"en"', '"it"', '"es"', '"fr"', '"pt"']) {
        expect(entry, contains(locale), reason: '$key missing $locale');
      }
    }
  });
}
