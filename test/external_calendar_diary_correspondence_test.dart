import 'package:agenda_per_anna/external_calendar_service.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
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

  ExternalCalendarEvent event({
    String id = 'google-account:event:2026-10-18T17:30',
    String calendarId = 'google-account',
    String title = 'Dentist visit',
    DateTime? date,
    String? occurrenceKey,
  }) => ExternalCalendarEvent(
    id: id,
    sourceOccurrenceKey: occurrenceKey,
    calendarId: calendarId,
    calendarName: 'Personal Google calendar',
    title: title,
    description: 'Bring documents',
    location: 'Padova',
    start: date ?? DateTime(2026, 10, 18, 17, 30),
    end: DateTime(2026, 10, 18, 18, 30),
    allDay: false,
  );

  test('past-only external source never becomes a memory automatically', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final external = event();
    final report = externalCalendarDiaryCorrespondence(
      store, external, now: DateTime(2026, 11, 4),
    );
    expect(report.state, ExternalDiaryMatchState.unlinked);
    expect(report.canCapture, isTrue);
    expect(store.journal(external.date).blocks, isEmpty);

    expect(externalCalendarDiaryCorrespondence(
      store, external, now: DateTime(2026, 10, 18, 23),
    ).state, ExternalDiaryMatchState.unavailable);
    expect(canCaptureExternalCalendarMemory(
      event(title: '   '), DateTime(2026, 11, 4),
    ), isFalse);
  });

  test('possible duplicate stays in review, never merges or deletes', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final external = event();
    await store.saveJournal(external.date, DayJournal(blocks: [
      DiaryBlock(
        id: 'existing-diary',
        type: DiaryBlockType.note,
        createdAt: external.date,
        text: 'I went to the Dentist visit today',
      ),
    ]));
    final candidates = externalCalendarDiaryCandidates(store, external);
    expect(candidates.map((b) => b.id), contains('existing-diary'));
    final report = externalCalendarDiaryCorrespondence(
      store, external, now: DateTime(2026, 11, 4),
    );
    expect(report.state, ExternalDiaryMatchState.reviewCandidates);
    expect(report.candidateCount, 1);
    expect(store.journal(external.date).blocks.single.id, 'existing-diary');
  });

  test('confirmed diary save is idempotent and preserves unrelated blocks', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final external = event();
    await store.saveJournal(external.date, DayJournal(blocks: [
      DiaryBlock(
        id: 'unrelated',
        type: DiaryBlockType.note,
        createdAt: external.date,
        text: 'Unrelated private thought',
      ),
    ]));
    final originalEvents = List<AgendaItem>.from(store.items);
    expect(await saveExternalCalendarMemoryDraft(
      store, external, 'My memory', now: DateTime(2026, 11, 4),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    expect(await saveExternalCalendarMemoryDraft(
      store, external, 'My edited memory', now: DateTime(2026, 11, 4),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    final blocks = store.journal(external.date).blocks;
    expect(blocks.length, 2);
    expect(blocks.first.id, 'unrelated');
    expect(blocks.first.text, 'Unrelated private thought');
    expect(blocks.last.id, externalCalendarMemoryBlockId(external));
    expect(blocks.last.text, 'My edited memory');
    expect(store.items, originalEvents);
    expect(externalCalendarDiaryCorrespondence(
      store, external, now: DateTime(2026, 11, 4),
    ).state, ExternalDiaryMatchState.linked);
  });

  test('external occurrence identity is scoped to calendar and date', () {
    final first = event();
    final second = event(calendarId: 'another-calendar');
    final third = event(id: 'google-account:other-instance');
    expect(externalCalendarMemoryBlockId(first),
      isNot(externalCalendarMemoryBlockId(second)));
    expect(externalCalendarMemoryBlockId(first),
      isNot(externalCalendarMemoryBlockId(third)));
  });

  test('account mismatch, future events and empty text fail closed', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final external = event();
    expect(await saveExternalCalendarMemoryDraft(
      store, external, 'Private diary', now: DateTime(2026, 11, 4),
      expectedAccountId: 'different-account',
    ), isFalse);
    expect(await saveExternalCalendarMemoryDraft(
      store, external, 'Private diary', now: DateTime(2026, 10, 18),
      expectedAccountId: store.activeAccountId,
    ), isFalse);
    expect(await saveExternalCalendarMemoryDraft(
      store, external, '   ', now: DateTime(2026, 11, 4),
      expectedAccountId: store.activeAccountId,
    ), isFalse);
    expect(store.journal(external.date).blocks, isEmpty);
  });

  test('provider occurrence identity survives timezone display changes', () {
    final startMs = DateTime.utc(2026, 10, 18, 16, 30).millisecondsSinceEpoch;
    final native = ExternalCalendarEvent.fromPlatform({
      'calendarId': 'cal-1',
      'eventId': 'event-33',
      'calendarName': 'Google',
      'title': 'Flight',
      'startMs': startMs,
      'endMs': startMs + 3600000,
      'allDay': false,
    });
    expect(native.sourceOccurrenceKey, 'event-33:$startMs');
    final sameInstantDifferentDisplayId = ExternalCalendarEvent(
      id: 'cal-1:event-33:2026-10-18T18:30:00',
      sourceOccurrenceKey: native.sourceOccurrenceKey,
      calendarId: 'cal-1',
      calendarName: 'Google',
      title: 'Flight',
      description: '',
      location: '',
      start: DateTime(2026, 10, 18, 18, 30),
      end: DateTime(2026, 10, 18, 19, 30),
      allDay: false,
    );
    expect(externalCalendarMemoryBlockId(sameInstantDifferentDisplayId),
        externalCalendarMemoryBlockId(native));
  });

  test('civil-day shift edits original diary block rather than duplicating', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final original = event(occurrenceKey: 'event-33:1792331400000');
    expect(await saveExternalCalendarMemoryDraft(
      store, original, 'The original memory',
      now: DateTime(2026, 11, 4),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    final shifted = ExternalCalendarEvent(
      id: 'provider:rendered-in-new-timezone',
      sourceOccurrenceKey: original.sourceOccurrenceKey,
      calendarId: original.calendarId,
      calendarName: original.calendarName,
      title: original.title,
      description: original.description,
      location: original.location,
      start: DateTime(2026, 10, 19, 0, 30),
      end: DateTime(2026, 10, 19, 1, 30),
      allDay: false,
    );
    expect(externalCalendarDiaryCorrespondence(
      store, shifted, now: DateTime(2026, 11, 4),
    ).state, ExternalDiaryMatchState.linked);
    expect(await saveExternalCalendarMemoryDraft(
      store, shifted, 'Updated from shifted timezone',
      now: DateTime(2026, 11, 4),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    expect(store.journal(original.date).blocks.single.text,
        'Updated from shifted timezone');
    expect(store.journal(shifted.date).blocks, isEmpty);
  });

  test('draft is an editable proposal and strips B3 transport markers', () {
    final external = ExternalCalendarEvent(
      id: 'provider:one',
      calendarId: 'calendar',
      calendarName: 'Google',
      title: 'Appointment',
      description: 'Description [AnnaDiary:12345]',
      location: 'Padova',
      start: DateTime(2026, 10, 18, 15),
      end: DateTime(2026, 10, 18, 16),
      allDay: false,
    );
    final draft = externalCalendarMemoryDraftText(
      external, locale: 'en', sourceLabel: 'External calendar',
    );
    expect(draft, contains('Appointment'));
    expect(draft, contains('Padova'));
    expect(draft, contains('Description'));
    expect(draft, isNot(contains('AnnaDiary:')));
  });
}
