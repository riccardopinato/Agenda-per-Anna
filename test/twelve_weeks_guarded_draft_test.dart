import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
  });

  const plan = TwelveWeeksDraftPlan(
    week: 1,
    title: 'Le mie dodici settimane',
    chapterTitle: 'Da dove partire',
    prompt: 'Quale passo voglio provare?',
    intention: 'Camminare ogni sera',
  );

  test('Draft validation happens before any canonical write', () {
    expect(plan.prepareText(), contains('## Settimana 1'));
    expect(plan.prepareText(), contains('Camminare ogni sera'));
    expect(
      () => const TwelveWeeksDraftPlan(
        week: 13,
        title: 'A',
        chapterTitle: 'B',
        prompt: 'C',
      ).prepareText(),
      throwsFormatException,
    );
  });

  test('No confirmation, wrong request ID or shared-only scope = no write',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final guard = Cap0160TagEditGuard(store);
    final date = DateTime(2026, 11, 10);
    expect(
      await TwelveWeeksDraftWriter.saveConfirmed(
        store, date, plan, userConfirmed: false,
        requestId: 'request-1234', scopeGuard: guard,
      ),
      isNull,
    );
    expect(
      await TwelveWeeksDraftWriter.saveConfirmed(
        store, date, plan, userConfirmed: true,
        requestId: '!', scopeGuard: guard,
      ),
      isNull,
    );
    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(
      await TwelveWeeksDraftWriter.saveConfirmed(
        store, date, plan, userConfirmed: true,
        requestId: 'request-1234', scopeGuard: guard,
      ),
      isNull,
    );
    expect(store.journal(date).blocks, isEmpty);
    store.dispose();
  });

  test('One guarded insert preserves existing content; retry is idempotent',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final date = DateTime(2026, 11, 10);
    await store.saveJournal(
      date,
      const DayJournal(beautiful: 'Originale intatto'),
    );
    final guard = Cap0160TagEditGuard(store);
    final first = await TwelveWeeksDraftWriter.saveConfirmed(
      store, date, plan, userConfirmed: true,
      requestId: 'request-1234', scopeGuard: guard,
    );
    expect(first, isNotNull);
    expect(store.journal(date).beautiful, 'Originale intatto');
    final second = await TwelveWeeksDraftWriter.saveConfirmed(
      store, date, plan, userConfirmed: true,
      requestId: 'request-1234', scopeGuard: guard,
    );
    expect(second?.id, first?.id);
    expect(store.journal(date).blocks, hasLength(1));
    final otherDay = DateTime(2026, 11, 11);
    final wrongDayReplay = await TwelveWeeksDraftWriter.saveConfirmed(
      store, otherDay, plan, userConfirmed: true,
      requestId: 'request-1234', scopeGuard: guard,
    );
    expect(wrongDayReplay, isNull);
    expect(store.journal(otherDay).blocks, isEmpty);
    expect(store.journal(date).blocks, hasLength(1));

    final userEdit = first!.copyWith(text: 'Testo modificato manualmente');
    await store.saveJournal(
      date,
      store.journal(date).copyWith(blocks: [userEdit]),
    );
    final replay = await TwelveWeeksDraftWriter.saveConfirmed(
      store, date, plan, userConfirmed: true,
      requestId: 'request-1234', scopeGuard: guard,
    );
    expect(replay, isNull);
    expect(store.journal(date).blocks.single.text,
        'Testo modificato manualmente');
    store.dispose();

    final loaded = AgendaStore();
    await loaded.load();
    expect(loaded.journal(date).beautiful, 'Originale intatto');
    expect(loaded.journal(date).blocks, hasLength(1));
    loaded.dispose();
  });
}
