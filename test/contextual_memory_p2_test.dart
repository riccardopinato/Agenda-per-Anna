import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiaryBlockReference make(
    String id,
    DateTime date, {
    List<String> people = const [],
    List<DiaryPlaceReference> places = const [],
    List<String> tags = const [],
    bool archived = false,
  }) {
    return DiaryBlockReference(
      date: date,
      block: DiaryBlock(
        id: id,
        type: DiaryBlockType.note,
        createdAt: date,
        personIds: people,
        places: places,
        tags: tags,
        archived: archived,
      ),
    );
  }

  final anchor = DateTime(2026, 11, 5);

  test('anniversary, saved person and place are explicit source reasons', () {
    final picks = ContextualMemorySelector.choose(
      today: anchor,
      authorizedPrivateMemories: [
        make('same-day', DateTime(2025, 11, 5)),
        make('linked-person', DateTime(2026, 10, 1), people: ['p1']),
        make('linked-place', DateTime(2026, 10, 1),
            places: [const DiaryPlaceReference(name: 'Roma')]),
      ],
    );
    expect(picks.length, 2);
    expect(picks[0].reference.block.id, 'same-day');
    expect(picks[0].reason, 'anniversary');
    expect(picks[1].reason, 'person');
  });

  test('archived, unknown, future, explicitly sensitive and excluded never surface', () {
    final picks = ContextualMemorySelector.choose(
      today: anchor,
      excludedIds: {'excluded'},
      authorizedPrivateMemories: [
        make('archived', DateTime(2025, 11, 5), archived: true),
        make('future', DateTime(2026, 11, 6), people: ['person']),
        make('no-link', DateTime(2026, 10, 1)),
        make('health', DateTime(2025, 11, 5), tags: ['salute']),
        make('cycle', DateTime(2025, 11, 5), tags: ['Ciclo']),
        make('credentials', DateTime(2025, 11, 5), tags: ['password']),
        make('excluded', DateTime(2025, 11, 5)),
      ],
    );
    expect(picks, isEmpty);
  });

  test('deterministic 2-per-day maximum with source ID deduplication', () {
    final same = make('same', DateTime(2025, 11, 5));
    final many = <DiaryBlockReference>[
      same, same,
      for (var i = 0; i < 10; i++)
        make('place-$i', DateTime(2025, 10, i + 1),
            places: [const DiaryPlaceReference(name: 'Cortina')]),
    ];
    final first = ContextualMemorySelector.choose(
      today: anchor, authorizedPrivateMemories: many, limit: 200);
    final second = ContextualMemorySelector.choose(
      today: anchor, authorizedPrivateMemories: many.reversed);
    expect(first.length, 2);
    expect(first.map((x) => x.reference.block.id).toSet().length, 2);
    expect(first.map((x) => x.reference.block.id).toList(),
        second.map((x) => x.reference.block.id).toList());
  });

  test('private opt-in, bounded snooze and reset are source-controlled', () {
    final source = File('lib/src/diary/diary_contextual_memory.dart')
        .readAsStringSync();
    expect(source, contains('bool _enabled = false;'));
    expect(source, contains('DateTime(now.year, now.month, now.day + 7)'));
    expect(source, contains('AgendaContentFilter.sharedOnly'));
    expect(source, contains("key: const ValueKey('contextual-memory-optin')"));
    expect(source, contains("key: const ValueKey('contextual-memory-snooze')"));
    expect(source, contains("key: const ValueKey('contextual-memory-reset-excluded')"));
    expect(source, contains('_digestFor(String id)'));
    expect(source, contains('maxPicks = limit.clamp(0, 2)'));
    expect(source, contains("prefs.setInt('${key}_selected_day', today)"));
    expect(source, contains("prefs.setStringList("));
    expect(source, contains("'${key}_selected_hashes'"));
    expect(source, contains('_dailySelectedDay == today'));
    expect(source, contains('while (_excluded.length > 500)'), isFalse);
    expect(source, contains('_snoozedThrough > today'));
    expect(source, isNot(contains('onThisDayPushNotification')));
  });
}
