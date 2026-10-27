import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

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

  test('v1.05-B2 derives one bounded annual review from canonical data', () async {
    final store = AgendaStore();
    await store.load();

    await store.saveJournal(
      DateTime(2026, 1, 10),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'jan-note',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 1, 10, 12),
            text: 'January memory',
            places: const [DiaryPlaceReference(name: 'Padova')],
          ),
        ],
      ),
    );
    await store.saveJournal(
      DateTime(2026, 2, 14),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'feb-photo',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2026, 2, 14, 12),
            text: 'February memory',
            imageBase64: 'portable-test-image',
            places: const [DiaryPlaceReference(name: 'Padova')],
          ),
        ],
      ),
    );
    await store.saveJournal(
      DateTime(2026, 3, 1),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'archived',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 3, 1, 12),
            text: 'Archived',
            archived: true,
          ),
        ],
      ),
    );

    final review = store.yearReviewSnapshot(2026);

    expect(review.memoryCount, 2);
    expect(review.activeMonths, 2);
    expect(review.months, hasLength(12));
    expect(review.months[0].memoryCount, 1);
    expect(review.months[1].memoryCount, 1);
    expect(review.highlights.map((entry) => entry.block.id), contains('feb-photo'));
    expect(review.highlights.map((entry) => entry.block.id), isNot(contains('archived')));
    expect(review.places.single.label, 'Padova');
    expect(review.places.single.count, 2);

    store.dispose();
  });

  test('v1.05-B2 replaces legacy YearScreen counters without a new store', () {
    final domain = File('lib/src/year_review_domain.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(domain, contains('lifeArchiveEntries('));
    expect(domain, contains('memoryReferences()'));
    expect(domain, contains('class YearReviewSnapshot'));
    expect(planner, contains("identifier: 'year-review-surface'"));
    expect(planner, contains('yearReviewSnapshot('));

    for (final forbidden in const [
      'YearDatabase',
      'YearRepository',
      'year_review_db',
      'yearReviewStore',
      'persistYearReview',
    ]) {
      expect(domain, isNot(contains(forbidden)));
      expect(planner, isNot(contains(forbidden)));
    }
  });

  test('v1.05-B2 labels cover every supported language', () {
    for (final code in const ['en', 'it', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(code);
      expect(strings.v105YearReview, isNotEmpty);
      expect(strings.v105YearReviewSubtitle, isNotEmpty);
      expect(strings.v105Highlights, isNotEmpty);
      expect(strings.v105RecurringPeople, isNotEmpty);
      expect(strings.v105RecurringPlaces, isNotEmpty);
      expect(strings.v105ActiveMonths, isNotEmpty);
      expect(strings.v105LifeMoments, isNotEmpty);
      expect(strings.v105MemoriesCount(2), isNotEmpty);
      expect(strings.v105LifeCount(3), isNotEmpty);
    }
  });

  test('v1.05-B2 trusted journey opens the annual surface', () {
    final flow = File('.maestro/journey/calendar.yaml').readAsStringSync();
    expect(flow, contains("id: 'calendar-open-year-overview'"));
    expect(flow, contains("id: 'year-review-surface'"));
  });
}
