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

  test('CAP-0160 Unicode email and 4000-unit cut never leak partial tags', () {
    final mail = Cap0160TagSuggester.propose(
      text: 'joséphine@example.org montagna montagna',
      languageCode: 'it',
      scopeReady: true,
      authorizedPrivateCorpus: const [],
    );
    expect(mail.map((value) => value.tag), isNot(contains('josé')));
    expect(mail.map((value) => value.tag), isNot(contains('joséphine')));
    expect(mail.map((value) => value.tag), contains('montagna'));

    final cut = Cap0160TagSuggester.propose(
      text: "${' '.padRight(3995)}montagna",
      languageCode: 'it',
      scopeReady: true,
      authorizedPrivateCorpus: const [],
    );
    expect(cut, isEmpty);

    // Cutting a full or partial Unicode email TLD must never expose either
    // the local part or the domain as an offline tag proposal.
    for (final padding in [3978, 3981]) {
      final emailAtBoundary = Cap0160TagSuggester.propose(
        text: "${' '.padRight(padding)}joséphine@example.museum",
        languageCode: 'it',
        scopeReady: true,
        authorizedPrivateCorpus: const [],
      );
      expect(emailAtBoundary, isEmpty, reason: 'padding=$padding');
    }
  });

  test('CAP-0160 Latin canonical-equivalent tags collapse, not accents', () {
    expect(normalizeOrganizationTags(['café', 'cafe\u0301', 'cafe']),
        ['café', 'cafe']);
    final result = Cap0160TagSuggester.propose(
      text: 'cafe\u0301 cafe\u0301 passeggiata',
      languageCode: 'it',
      scopeReady: true,
      currentTags: ['café'],
      authorizedPrivateCorpus: const [],
    );
    expect(result.map((value) => value.tag), isNot(contains('cafe\u0301')));
    expect(result.map((value) => value.tag), contains('passeggiata'));
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
    final readyOnProfileNotifications = <bool>[];
    store.shellRevision.addListener(() {
      readyOnProfileNotifications.add(store.entryScopeReady);
    });
    store.addListener(() {
      readyOnProfileNotifications.add(store.entryScopeReady);
    });
    await store.activateCloudAccount('account-B');
    expect(readyOnProfileNotifications, isNotEmpty);
    expect(readyOnProfileNotifications, everyElement(isTrue));
    expect(guard.isCurrent, isFalse);
    expect(Cap0160TagSuggester.forInbox(store, current, 'it'), isEmpty);
    expect(Cap0160TagSuggester.forDiary(store, date, private, 'it'), isEmpty);
    readyOnProfileNotifications.clear();
    await store.activateCloudAccount(null);
    expect(readyOnProfileNotifications, isNotEmpty);
    expect(readyOnProfileNotifications, everyElement(isTrue));
    expect(store.accountScopeEpoch, oldEpoch + 2);
    expect(guard.isCurrent, isFalse); // Switching A -> B -> A is stale.
    store.dispose();
  });

  test('CAP-0160 guarded writers reject stale profile edits', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    await store.addInboxEntry('passeggiata privata');
    final oldEntry = store.inbox.first;
    final day = DateTime(2026, 11, 5);
    final block = DiaryBlock(
      id: 'tag-source',
      type: DiaryBlockType.note,
      createdAt: day,
      text: 'pensiero privato',
    );
    await store.saveJournal(day, DayJournal(blocks: [block]));
    final guard = Cap0160TagEditGuard(store);

    await store.activateCloudAccount('different-owner');
    await expectLater(
      store.setInboxTags(oldEntry.id, ['segreto'], scopeGuard: guard),
      throwsA(isA<Cap0160ScopeChanged>()),
    );
    await expectLater(
      store.setDiaryTags(day, block.id, ['segreto'], scopeGuard: guard),
      throwsA(isA<Cap0160ScopeChanged>()),
    );
    expect(store.inbox.where((entry) => entry.id == oldEntry.id), isEmpty);
    await store.activateCloudAccount(null);
    expect(store.inbox.firstWhere((entry) => entry.id == oldEntry.id).tags,
        isEmpty);
    expect(store.journal(day).blocks.first.tags, isEmpty);
    store.dispose();
  });

  test('CAP-0160 simultaneous Save/profile switch never writes into B', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    await store.addInboxEntry('passeggiata privata');
    final entry = store.inbox.first;
    final guard = Cap0160TagEditGuard(store);
    final write = store.setInboxTags(entry.id, ['privato'], scopeGuard: guard);
    final switchAccount = store.activateCloudAccount('account-B');
    try {
      await write;
    } on Cap0160ScopeChanged {
      // A rejected in-flight write is an allowed fail-closed outcome.
    }
    await switchAccount;
    expect(store.inbox.any((item) => item.id == entry.id), isFalse);
    await store.activateCloudAccount(null);
    expect(store.inbox.firstWhere((item) => item.id == entry.id).tags,
        anyOf(isEmpty, equals(['privato'])));
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

  testWidgets('CAP-0160 Inbox suggestions are inline; Cancel remains nonwriting',
      (tester) async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    await store.addInboxEntry('montagna montagna sentiero');

    await tester.pumpWidget(MaterialApp(
      home: InboxScreen(store: store),
    ));
    await tester.pumpAndSettle();
    final suggestion = find.byKey(
        const ValueKey('cap0160-inline-montagna'));
    expect(suggestion, findsOneWidget);
    expect(store.inbox.single.tags, isEmpty);
    await tester.tap(suggestion);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).last)
        .controller!.text, contains('montagna'));
    // The first TextButton in the tag editor is Cancel, not Save.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(TextButton),
    ).last);
    await tester.pumpAndSettle();
    expect(store.inbox.single.tags, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('CAP-0160 inline suggestions are only draft callbacks',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Cap0160InlineTagSuggestions(
        languageCode: 'it',
        proposals: const [
          Cap0160TagSuggestion('passeggiata', 2, 'text_frequency'),
        ],
        onSelected: (tag) => selected = tag,
      )),
    ));
    expect(find.text('Tag suggeriti'), findsOneWidget);
    expect(find.byKey(const ValueKey('cap0160-inline-passeggiata')),
        findsOneWidget);
    expect(selected, isNull);
    await tester.tap(find.byKey(
        const ValueKey('cap0160-inline-passeggiata')));
    expect(selected, 'passeggiata');
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
    expect(editor, contains('Cap0160InlineTagSuggestions('));
    expect(inbox, contains('Cap0160InlineTagSuggestions('));
    expect(editor, contains('preselectedTag: tag'));
    expect(inbox, contains('preselectedTag: tag'));
    expect(editor, contains('final guard = Cap0160TagEditGuard(widget.store)'));
    expect(inbox, contains('final guard = Cap0160TagEditGuard(store)'));
    expect(editor, contains('normalizeOrganizationTags(controller.text.split('));
  });
}
