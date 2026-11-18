import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Insieme remote verification states are translated in five locales', () {
    for (final locale in <String>['it', 'en', 'es', 'fr', 'pt']) {
      for (final key in <String>[
        'listChecked', 'cached', 'emptyUnknown', 'lastChecked', 'notChecked',
      ]) {
        final text = sharedSpaceVerificationCopy(locale, key);
        expect(text, isNotEmpty, reason: '$locale / $key');
        expect(text, isNot(key), reason: '$locale / $key');
      }
      expect(
        sharedSpaceVerificationCopy(locale, 'listChecked'),
        isNot(sharedSpaceVerificationCopy(locale, 'cached')),
      );
      expect(
        sharedSpaceVerificationCopy(locale, 'lastChecked'),
        isNot(sharedSpaceVerificationCopy(locale, 'notChecked')),
      );
    }
    expect(sharedSpaceVerificationCopy('de', 'cached'),
        sharedSpaceVerificationCopy('en', 'cached'));
  });

  test('Shared hub never equates cached data with remote verification', () {
    final source = File('lib/src/screens/shared_space.dart').readAsStringSync();
    expect(source, contains('bool _remoteListVerified = false;'));
    expect(source, contains('_remoteListVerified = true;'));
    expect(source, contains('_remoteListVerified = false;'));
    expect(source, contains("'emptyUnknown'"));
    expect(source, contains("lastRefreshAt == null ? 'notChecked' : 'lastChecked'"));
    expect(source, isNot(contains("title = AnnaStrings.of(context).d3('sharedSyncedShort');")));
    // Existing privacy, role and retry ownership remains in its canonical file.
    expect(source, contains('sharedSpaceCanRename('));
    expect(source, contains('widget.store.pendingSharedInteractionCount'));
    expect(source, contains('widget.store.pendingSharedMediaCount'));
    expect(source, contains('markSharedSpaceRead('));
  });
  test('Shared tab rebuilds and remounts on account scope switch', () {
    final shell = File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(shell, contains('widget.store.accountRevision'));
    expect(shell, contains('ValueKey<String>(widget.store.sharedSpacesCacheStorageKey)'));
    expect(shell, contains('SharedSpaceHubScreen(store: widget.store)'));
    expect(shell, contains('widget.store.preferences.isModuleEnabled(AppModule.sharedSpace)'));
    expect(shell, contains('PersonalizationScreen(store: widget.store)'));
  });

}
