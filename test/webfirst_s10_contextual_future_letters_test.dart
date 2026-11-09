import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synthetic records only. Source/widget regression, not physical-PWA,
/// encrypted letter delivery, native notification or shared-sync proof.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStateStore.instance.resetForTesting();
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
  });

  DiaryBlockReference reference(
    String id,
    DateTime day, {
    List<String> tags = const [],
    List<String> personIds = const [],
    bool archived = false,
  }) => DiaryBlockReference(
        date: day,
        block: DiaryBlock(
          id: id,
          type: DiaryBlockType.note,
          createdAt: day,
          text: 'Synthetic diary note',
          tags: tags,
          personIds: personIds,
          archived: archived,
        ),
      );

  test('S10 recall excludes future letters and stale person links', () {
    final today = DateTime(2026, 11, 9);
    final picks = ContextualMemorySelector.choose(
      today: today,
      authorizedPersonIds: const {'known-person'},
      authorizedPrivateMemories: [
        reference('letter', DateTime(2025, 11, 9),
            tags: const [futureLetterTag],
            personIds: const ['known-person']),
        reference('orphan', DateTime(2026, 10, 8),
            personIds: const ['deleted-person']),
        reference('known', DateTime(2026, 10, 7),
            personIds: const ['known-person']),
        reference('anniversary', DateTime(2025, 11, 9)),
        reference('archived', DateTime(2024, 11, 9), archived: true),
      ],
    );
    expect(picks.map((item) => item.reference.block.id),
        ['anniversary', 'known']);
    expect(picks.map((item) => item.reason),
        ['anniversary', 'person']);
  });

  test('S10 contextual limit and sensitive tags still fail closed', () {
    final today = DateTime(2026, 11, 9);
    final input = [
      for (var i = 0; i < 14; i++)
        reference('p-$i', DateTime(2025, 11, 9)),
      reference('cycle', DateTime(2025, 11, 9),
          tags: const ['Ciclo']),
      reference('vault', DateTime(2025, 11, 9),
          tags: const ['vault']),
    ];
    final first = ContextualMemorySelector.choose(
      today: today, authorizedPrivateMemories: input, limit: 100);
    final second = ContextualMemorySelector.choose(
      today: today, authorizedPrivateMemories: input.reversed, limit: 100);
    expect(first, hasLength(2));
    expect(first.map((item) => item.reference.block.id),
        second.map((item) => item.reference.block.id));
    expect(first.map((item) => item.reference.block.id),
        isNot(contains('cycle')));
    expect(first.map((item) => item.reference.block.id),
        isNot(contains('vault')));
  });

  test('S10 letter reuses diary; archive and shared-only hide it', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day + 30);
    expect(await savePersonalFutureLetter(store, day, 'Synthetic private text',
        accountAtOpen: store.activeAccountId), isTrue);
    final record = personalFutureLetters(store).single;
    expect(record.block.tags, contains(futureLetterTag));
    expect(record.block.text, 'Synthetic private text');
    expect(record.isAvailableOn(now), isFalse);
    expect(record.isAvailableOn(day), isTrue);
    expect(currentPersonalFutureLetter(store, record)?.block.id,
        record.block.id);

    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(personalFutureLetters(store), isEmpty);
    expect(currentPersonalFutureLetter(store, record), isNull);
    store.agendaContentFilter = AgendaContentFilter.all;

    final updated = record.block.copyWith(archived: true);
    await store.saveJournal(day, DayJournal(blocks: [updated]));
    expect(personalFutureLetters(store), isEmpty);
    expect(currentPersonalFutureLetter(store, record), isNull);
    store.dispose();
  });

  test('S10 stale A -> B -> A letter write is rejected', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final guard = Cap0160TagEditGuard(store);
    final oldEpoch = store.accountScopeEpoch;
    await store.activateCloudAccount('synthetic-account-B');
    await store.activateCloudAccount(null);
    expect(store.accountScopeEpoch, oldEpoch + 2);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day + 40);
    expect(await savePersonalFutureLetter(
      store, day, 'Never write from stale compose',
      accountAtOpen: null,
      scopeGuard: guard,
    ), isFalse);
    expect(personalFutureLetters(store), isEmpty);
    store.dispose();
  });

  testWidgets('S10 read dialog clears body when account changes',
      (tester) async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime.now().subtract(const Duration(days: 2));
    final block = DiaryBlock(
      id: 'synthetic-letter-previously-due',
      type: DiaryBlockType.note,
      createdAt: day,
      text: 'Visible only in this account until scope switch',
      tags: const [futureLetterTag],
    );
    await store.saveJournal(day, DayJournal(blocks: [block]));
    final record = personalFutureLetters(store).single;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => openPersonalFutureLetter(context, store, record),
        child: const Text('Open synthetic letter'),
      ))),
    ));
    await tester.tap(find.text('Open synthetic letter'));
    await tester.pumpAndSettle();
    expect(find.text('Visible only in this account until scope switch'),
        findsOneWidget);
    await store.activateCloudAccount('synthetic-account-B');
    await tester.pumpAndSettle();
    expect(find.text('Visible only in this account until scope switch'),
        findsNothing);
    expect(find.text('This letter is no longer available in this profile.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  test('S10 future letter display labels in all five locales', () {
    for (final lang in const ['it', 'en', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(lang);
      for (final key in const [
        'ready', 'waiting', 'unavailable', 'saveFailed', 'notice',
        'early', 'trash', 'date', 'create',
      ]) {
        expect(futureLetterLabel(strings, key).trim(), isNotEmpty);
      }
      expect(futureLetterTitle(strings).trim(), isNotEmpty);
    }
  });
}
