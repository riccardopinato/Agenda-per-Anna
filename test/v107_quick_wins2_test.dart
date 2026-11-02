import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('capture ranking is stable, reflects usage, and never drops actions', () {
    final actions = ['text', 'photo', 'task', 'voice', 'sketch', 'inbox'];
    final ranked = qw2RankCaptureActions(
      actions, {'inbox': 4, 'task': 9, 'photo': 4}, (s) => s,
    );
    expect(ranked, ['task', 'photo', 'inbox', 'text', 'voice', 'sketch']);
    expect(qw2RankCaptureActions(actions, {}, (s) => s), actions);
    expect(ranked.toSet().length, actions.length);
  });

  test('favorites limit, deduplication, disabled modules are fail closed', () {
    expect(Qw2UiSettings.normalizeFavorites(
      ['shopping', 'shopping', 'workout', 'vault', 'people', 'sharedSpace'],
      {'shopping', 'workout', 'people', 'sharedSpace'},
    ), ['shopping', 'workout', 'people']);
    expect(Qw2UiSettings.normalizeFavorites(
        ['privateVault'], {'shopping', 'workout'}), isEmpty);
  });

  test('capture counters are local, validated and account scoped', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AgendaStore();
    await Qw2UiSettings.recordCaptureChoice(store, 'task', null);
    await Qw2UiSettings.recordCaptureChoice(store, 'task', null);
    final counts = await Qw2UiSettings.captureCounts(store);
    expect(counts['task'], 2);
    expect(counts.containsKey('private content'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('qw2_captureCounts_guest'), contains('"task":2'));
    store.dispose();
  });

  test('five languages include QW2 action copy', () {
    for (final language in ['en', 'it', 'es', 'fr', 'pt']) {
      for (final key in ['inboxEvent', 'inboxEventSaved',
        'moreFavorites', 'chooseFavorites', 'editFavorites',
        'settingsSearch', 'settingsNoMatch']) {
        expect(quickWins2Copy(language, key), isNotEmpty);
      }
      final strings = AnnaStrings(language);
      expect(quickWinText(strings, 'undo'), isNotEmpty);
      expect(quickWinText(strings, 'undoFailed'), isNotEmpty);
    }
  });

  test('canonical editor only invokes Inbox handoff after save succeeds', () {
    final editor = File('lib/src/widgets_editors.dart').readAsStringSync();
    final inbox = File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(editor, contains('if (onSaved != null) await onSaved(base);'));
    expect(editor, contains('await store.upsert('));
    expect(inbox, contains('duplicateOf: draft,'));
    expect(inbox, contains('onSaved: (saved) async'));
    expect(inbox, contains("value: 'event'"));
    expect(inbox, contains('await store.deleteInboxEntry(entry.id);'));
  });

  test('QW2 presentation paths reuse existing routes and no cloud schema', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final settings = File('lib/src/screens/settings_hub.dart').readAsStringSync();
    final undo = File('lib/src/today_quick_wins.dart').readAsStringSync();
    expect(capture, contains('for (var i = 0; i < 4; i++)'));
    expect(capture, contains('Qw2UiSettings.recordCaptureChoice('));
    expect(capture, contains('subtitleFor('));
    expect(more, contains('Qw2FavoritesSection('));
    final favorites = File('lib/src/quick_wins2.dart').readAsStringSync();
    expect(favorites, contains('maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78'));
    expect(favorites, contains('child: ListView('));
    expect(settings, contains("ValueKey('qw2-settings-search')"));
    expect(undo, contains('jsonEncode(current.toJson()) != savedFingerprint'));
    expect(undo, contains('final writtenFingerprint = jsonEncode(postponed.toJson());'));
    expect(undo, contains('jsonEncode(saved.toJson()) == writtenFingerprint'));
    expect(undo, contains('SnackBarAction('));
  });

  testWidgets('settings search matches the Spanish name placeholder',
      (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AnnaStrings.supportedLocales,
      home: SettingsHubScreen(store: store),
    ));
    await tester.enterText(
        find.byKey(const ValueKey('qw2-settings-search')), 'nombre');
    await tester.pump();
    expect(find.byKey(const ValueKey('settings-hub-edit-name')),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('settings search finds backup and removes unrelated tiles',
      (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: SettingsHubScreen(store: store),
    ));
    final input = find.byKey(const ValueKey('qw2-settings-search'));
    expect(input, findsOneWidget);
    await tester.enterText(input, 'backup');
    await tester.pump();
    expect(find.byKey(const ValueKey('settings-hub-backup')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-hub-appearance')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
