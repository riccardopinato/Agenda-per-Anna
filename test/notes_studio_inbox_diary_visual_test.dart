import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Notes Studio preserves canonical Inbox, capture and diary writers', () {
    final inbox =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final diary =
        File('lib/src/diary/diary_components.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();

    for (final visual in <String>[
      'notes-studio-empty',
      'notes-studio-note-',
      'AnnaOrganicPaperSurface(',
      'AnnaEditorialSectionHeading(',
      'ds6-inbox-search',
      'ds6-inbox-empty-state',
      'padding: EdgeInsets.all(compact ? 8 : 24)',
      'padding: EdgeInsets.all(compact ? 10 : 24)',
      'if (!compact) ...[',
    ]) {
      expect(inbox, contains(visual));
    }
    for (final original in <String>[
      'store.activeInboxEntries',
      'inboxEntriesInCategory(',
      'await store.renameInboxTag(previous, renamed)',
      'await store.toggleInboxPinned(entry.id)',
      'await store.toggleInboxArchived(entry.id)',
      'await store.deleteInboxEntry(entry.id)',
      '_copyToNotes(context, entry)',
      '_convertToTask(context, entry)',
      '_convertToAppointment(context, entry)',
      'onPressed: () => _createCategory(context)',
      'onPressed: () => _manageCategories(context)',
      '_showQuickCapture(',
    ]) {
      expect(inbox, contains(original));
    }
    expect(diary, contains("strings.d3('newNote')"));
    expect(diary, contains('AnnaJournalTypography.editorial(context, size: 24)'));
    expect(diary, contains('FocusWritingScreen('));
    expect(diary, contains('Navigator.pop(context, _controller.text.trim())'));
    expect(capture, contains('store.saveJournal('));
    expect(capture, contains('store.addInboxEntry(value)'));
  });

  testWidgets('Notes Studio empty state remains truthful and Classic reversible',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
      palette: AgendaPalette.rose,
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      supportedLocales: const [Locale('it'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      home: InboxScreen(store: store),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('notes-studio-empty')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ds6-inbox-search')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('notes-studio-empty')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('ds6-inbox-search')),
        findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
