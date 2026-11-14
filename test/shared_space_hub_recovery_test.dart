import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('shared group cache is read only for the authenticated active account',
      () {
    expect(
      sharedSpaceHubAuthorizedAccount(
        signedIn: true,
        cloudUserId: 'account-with-two-spaces',
        activeAccountId: 'account-with-two-spaces',
      ),
      'account-with-two-spaces',
    );
    expect(
      sharedSpaceHubAuthorizedAccount(
        signedIn: true,
        cloudUserId: 'account-with-two-spaces',
        activeAccountId: 'other-account',
      ),
      isNull,
    );
    expect(
      sharedSpaceHubAuthorizedAccount(
        signedIn: false,
        cloudUserId: 'account-with-two-spaces',
        activeAccountId: 'account-with-two-spaces',
      ),
      isNull,
    );
    expect(
      sharedSpaceHubAuthorizedAccount(
        signedIn: true,
        cloudUserId: null,
        activeAccountId: 'account-with-two-spaces',
      ),
      isNull,
    );
  });

  test('group recovery guidance exists in all five supported languages', () {
    for (final locale in ['it', 'en', 'es', 'fr', 'pt']) {
      for (final key in ['unavailable', 'empty', 'preserved', 'account']) {
        expect(sharedSpaceHubRecoveryCopy(locale, key), isNotEmpty);
        expect(sharedSpaceHubRecoveryCopy(locale, key), isNot(key));
      }
    }
  });

  test('empty membership read cannot overwrite the cached list', () {
    final file = File('lib/src/screens/shared_space.dart').readAsStringSync();
    final start = file.indexOf('class _SharedSpaceHubScreenState');
    final end = file.indexOf('class SharedSpaceScreen', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final hub = file.substring(start, end);
    final begin = hub.indexOf('if (result.isEmpty) {');
    final nextSave = hub.indexOf('await _saveSpacesCache(result', begin);
    expect(begin, greaterThanOrEqualTo(0));
    expect(nextSave, greaterThan(begin));
    final emptyResponsePath = hub.substring(begin, nextSave);
    expect(emptyResponsePath, contains('return;'));
    expect(emptyResponsePath, isNot(contains('_saveSpacesCache(')));
    expect(emptyResponsePath, isNot(contains('setString(')));
    expect(emptyResponsePath, contains('spaces = const [];'));
    // Previously cached groups remain hidden and cannot trigger a duplicate
    // create-another-group action while membership is unverified.
    expect(hub, contains('if (spaces.isEmpty && !_localListPreserved)'));
    expect(hub, contains('else if (spaces.isNotEmpty) ...['));
    expect(hub, contains('if (_authorizedAccount != expectedAccount) {'));
  });

  test('global shared-agenda refresh does not erase account-scoped cache',
      () {
    final source =
        File('lib/src/agenda_store.dart').readAsStringSync();
    final begin = source.indexOf('Future<void> refreshSharedAgendaCache(');
    final end = source.indexOf('Future<void> _bindUnifiedRealtime(', begin);
    expect(begin, greaterThanOrEqualTo(0));
    expect(end, greaterThan(begin));
    final refresh = source.substring(begin, end);
    expect(
      refresh,
      contains('spaces.isNotEmpty ||'),
    );
    expect(
      refresh,
      contains('prefs.getString(sharedSpacesCacheStorageKey) == null'),
    );
    // A real empty membership response can still remove groups from the
    // active UI; this check is only about preserving the prior local cache.
    expect(refresh, contains('_sharedAgendaSpaces'));
    expect(refresh, contains('..clear()'));
  });

  test('session binding has symmetrical listeners and suppresses stale loads',
      () {
    final source = File('lib/src/screens/shared_space.dart')
        .readAsStringSync();
    final begin = source.indexOf('class _SharedSpaceHubScreenState');
    final end = source.indexOf('class SharedSpaceScreen', begin);
    final hub = source.substring(begin, end);
    expect(hub,
        contains('CloudSyncService.instance.addListener(_onAccountOrSessionChanged)'));
    expect(hub,
        contains('CloudSyncService.instance.removeListener(_onAccountOrSessionChanged)'));
    expect(hub,
        contains('widget.store.accountRevision.addListener(_onAccountOrSessionChanged)'));
    expect(hub,
        contains('widget.store.accountRevision.removeListener(_onAccountOrSessionChanged)'));
    expect(hub, contains('_validLoad(account, generation, request)'));
  });
}
