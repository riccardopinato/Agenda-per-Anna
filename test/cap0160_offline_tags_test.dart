import 'dart:io';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  const codes = ['it', 'en', 'es', 'fr', 'pt'];
  final fixture = <String, String>{
    'it': 'Ieri passeggiata nel bosco, passeggiata bellissima con amici',
    'en': 'Yesterday hiking through forest, hiking near mountain trails',
    'es': 'Ayer caminata por bosque, caminata cerca montaña hermosa',
    'fr': 'Hier promenade forêt, promenade avec montagne superbe',
    'pt': 'Ontem caminhada floresta, caminhada perto montanha bonita',
  };
  final wanted = <String, String>{
    'it': 'passeggiata', 'en': 'hiking', 'es': 'caminata',
    'fr': 'promenade', 'pt': 'caminhada',
  };

  test('CAP-0160 all five locales use explicit original words', () {
    for (final language in codes) {
      final text = fixture[language]!;
      final suggestions = Cap0160TagSuggester.propose(
        text: text,
        languageCode: language,
        scopeReady: true,
        authorizedPrivateCorpus: const [],
      );
      expect(suggestions, isNotEmpty, reason: language);
      expect(suggestions.length, lessThanOrEqualTo(4));
      expect(suggestions.first.tag, wanted[language], reason: language);
      expect(suggestions.first.reason, 'text_frequency');
    }
  });

  test('CAP-0160 stopwords, URL/email and existing tags are never suggested', () {
    final result = Cap0160TagSuggester.propose(
      text: 'La montagna montagna bellissima https://private.test/privato '
          'nome@example.org',
      languageCode: 'it',
      scopeReady: true,
      currentTags: ['montagna'],
      authorizedPrivateCorpus: const [],
    );
    expect(result.map((x) => x.tag), isNot(contains('montagna')));
    expect(result.map((x) => x.tag), isNot(contains('privato')));
    expect(result.map((x) => x.tag), isNot(contains('example')));
    expect(result.map((x) => x.tag), isNot(contains('nome')));
    expect(result.map((x) => x.tag), contains('bellissima'));
  });

  test('CAP-0160 missing account scope, shared-only, or unknown locale fails shut', () {
    final sources = [
      const Cap0160PrivateDocument(id: '1', text: 'segreto nascosto'),
    ];
    for (final options in [
      (ready: false, shared: false, language: 'it'),
      (ready: true, shared: true, language: 'it'),
      (ready: true, shared: false, language: 'de'),
    ]) {
      final suggestions = Cap0160TagSuggester.propose(
        text: 'segreto segreto',
        languageCode: options.language,
        scopeReady: options.ready,
        sharedOnly: options.shared,
        authorizedPrivateCorpus: sources,
      );
      expect(suggestions, isEmpty);
    }
  });

  test('CAP-0160 smoothed IDF deterministic, source duplicates ignored', () {
    final corpus = [
      const Cap0160PrivateDocument(id: '1', text: 'montagna sentiero'),
      const Cap0160PrivateDocument(id: '1', text: 'montagna montagna'),
      const Cap0160PrivateDocument(id: '2', text: 'montagna'),
      const Cap0160PrivateDocument(id: '3', text: 'viaggio'),
    ];
    List<Cap0160TagSuggestion> compute(List<Cap0160PrivateDocument> docs) =>
        Cap0160TagSuggester.propose(
          text: 'montagna sentiero montagna viaggio',
          languageCode: 'it', scopeReady: true,
          authorizedPrivateCorpus: docs,
        );
    final a = compute(corpus);
    final b = compute([corpus[0], corpus[2], corpus[3]]);
    expect(a.map((x) => x.tag), b.map((x) => x.tag));
    expect(a.map((x) => x.score), b.map((x) => x.score));
    expect(a.first.reason, 'tf_idf');
  });

  test('CAP-0160 5000 items processed via a strict 512-document bound', () {
    var visited = 0;
    Iterable<Cap0160PrivateDocument> corpus() sync* {
      for (var i = 0; i < 5000; i++) {
        visited++;
        yield Cap0160PrivateDocument(
          id: '$i', text: 'collina sentiero bosco',
        );
      }
    }
    final result = Cap0160TagSuggester.propose(
      text: 'collina collina bosco',
      languageCode: 'it', scopeReady: true,
      authorizedPrivateCorpus: corpus(),
    );
    expect(result, isNotEmpty);
    expect(visited, Cap0160TagSuggester.maxCorpusDocs);
  });

  test('CAP-0160 source selectors do not mix Inbox, diary, shared, archives', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();

    await store.addInboxEntry('sentiero bosco sentiero');
    await store.addInboxEntry('collina bosco');
    final current = store.inbox.firstWhere(
      (item) => item.text == 'sentiero bosco sentiero');
    final date = DateTime(2026, 11, 5);
    final private = DiaryBlock(
      id: 'diary-source',
      type: DiaryBlockType.note,
      createdAt: date,
      text: 'fotografia fotografia lago',
    );
    await store.saveJournal(date, DayJournal(blocks: [
      private,
      DiaryBlock(
        id: 'hidden', type: DiaryBlockType.note,
        createdAt: date, text: 'segreto segreto segreto',
        archived: true,
      ),
    ]));

    final inbox = Cap0160TagSuggester.forInbox(store, current, 'it');
    expect(inbox.map((x) => x.tag), contains('sentiero'));
    expect(inbox.map((x) => x.tag), isNot(contains('fotografia')));
    expect(inbox.map((x) => x.tag), isNot(contains('segreto')));
    final diary = Cap0160TagSuggester.forDiary(store, date, private, 'it');
    expect(diary.map((x) => x.tag), contains('fotografia'));
    expect(diary.map((x) => x.tag), isNot(contains('sentiero')));
    expect(diary.map((x) => x.tag), isNot(contains('segreto')));

    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(Cap0160TagSuggester.forInbox(store, current, 'it'), isEmpty);
    expect(Cap0160TagSuggester.forDiary(store, date, private, 'it'), isEmpty);
    store.agendaContentFilter = AgendaContentFilter.all;

    final guard = Cap0160TagEditGuard(store);
    expect(guard.isCurrent, isTrue);
    final oldEpoch = store.accountScopeEpoch;
    // Cloud sync may bump every UI revision; this is NOT an account switch.
    store.signals.bumpAll();
    expect(store.accountScopeEpoch, oldEpoch);
    expect(guard.isCurrent, isTrue);
    await store.activateCloudAccount('account-B');
    expect(guard.isCurrent, isFalse);
    expect(Cap0160TagSuggester.forInbox(store, current, 'it'), isEmpty);
    expect(Cap0160TagSuggester.forDiary(store, date, private, 'it'), isEmpty);
    await store.activateCloudAccount(null);
    expect(store.accountScopeEpoch, oldEpoch + 2);
    expect(guard.isCurrent, isFalse); // Switching A -> B -> A is stale.
    store.dispose();
  });

  testWidgets('CAP-0160 chip previews draft only; cancel never commits',
      (tester) async {
    List<String>? result;
    // The default English Material delegate is available without additional
    // localization wiring; the five-language word fixtures are tested above.
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            result = await showOrganizationTagsEditor(
              context,
              initialTags: ['existing'],
              offlineProposals: const [
                Cap0160TagSuggestion('montagna', 2.0, 'tf_idf'),
              ],
            );
          },
          child: const Text('Open tags'),
        ),
      )),
    ));
    await tester.tap(find.text('Open tags'));
    await tester.pumpAndSettle();
    // Assert the actual draft chip; avoid coupling the gate to a fallback
    // localization delegate installed by the widget test harness.
    expect(find.byKey(const ValueKey('cap0160-chip-montagna')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cap0160-chip-montagna')));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'existing, montagna');
    // The dialog has exactly one TextButton: Cancel (five locales).
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  test('CAP-0160 dialogs must keep writer outside the ranker', () {
    final engine = File('lib/src/cap0160_offline_tags.dart').readAsStringSync();
    final editor = File('lib/src/diary/diary_components.dart').readAsStringSync();
    final inbox = File('lib/src/screens/home_inbox_search.dart')
        .readAsStringSync();
    expect(engine, isNot(contains('setDiaryTags(')));
    expect(engine, isNot(contains('setInboxTags(')));
    expect(engine, isNot(contains('CloudSyncService.instance')));
    expect(editor, contains('offlineProposals: proposals'));
    expect(editor, contains('final guard = Cap0160TagEditGuard(widget.store)'));
    expect(inbox, contains('final guard = Cap0160TagEditGuard(store)'));
    expect(editor, contains('normalizeOrganizationTags(controller.text.split('));
  });
}
