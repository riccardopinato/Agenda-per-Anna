import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  DiaryBlockReference note(
    String id,
    String text,
    DateTime date, {
    bool archived = false,
    String? place,
    String? person,
  }) => DiaryBlockReference(
    date: date,
    block: DiaryBlock(
      id: id,
      type: DiaryBlockType.note,
      createdAt: date,
      text: text,
      archived: archived,
      personIds: person == null ? [] : [person],
      places: place == null ? [] : [DiaryPlaceReference(name: place)],
    ),
  );

  test('CAP-0151 quotes are exact source substrings and preserve negation',
      () {
    final notes = [
      note('a', 'Non voglio dimenticare la passeggiata. '
          'Al tramonto abbiamo visto i colli insieme.',
          DateTime(2026, 11, 5)),
      note('b', 'Il lavoro è stato impegnativo ma ho finito tutto.',
          DateTime(2026, 11, 4)),
    ];
    final report = memoryExtractiveReport(notes);
    expect(report.eligibleNotes, 2);
    expect(report.quotes, isNotEmpty);
    for (final quote in report.quotes) {
      expect(quote.text, quote.source.block.text.substring(
          quote.start, quote.end));
    }
    expect(report.quotes.any((q) => q.text.contains('Non voglio')), isTrue);
    expect(memoryExtractiveReport(notes).quotes.map((q) => q.text).toList(),
        report.quotes.map((q) => q.text).toList());
  });

  test('private archive, date, place and person filters do not leak', () {
    final refs = [
      note('a', 'Ricordiamo una bella cena fatta insieme.',
          DateTime(2026, 11, 5), place: 'Monselice', person: 'p1'),
      note('b', 'Al mare ci siamo divertiti in estate.',
          DateTime(2026, 10, 1), place: 'Padova'),
      note('c', 'Questa storia archiviata è riservata.',
          DateTime(2026, 11, 5), archived: true,
          place: 'Monselice', person: 'p1'),
    ];
    final report = memoryExtractiveReport(refs,
      fromInclusive: DateTime(2026, 11, 4),
      toExclusive: DateTime(2026, 11, 6),
      personId: 'p1', placeKey: 'monselice');
    expect(report.eligibleNotes, 1);
    expect(report.quotes.single.source.block.id, 'a');
    expect(memoryExtractiveReport(refs, personId: 'unknown').quotes, isEmpty);
    expect(memoryExtractiveReport(refs, placeKey: 'unknown').quotes, isEmpty);
    expect(memoryExtractiveReport(refs, maxQuotes: 0).quotes, isEmpty);
  });

  test('bounded 200-note scan discloses partial coverage', () {
    final refs = List.generate(205, (i) => note('id-$i',
      'Questa è la nota numero $i con un dettaglio personale.',
      DateTime(2026, 11, 5)));
    final report = memoryExtractiveReport(refs);
    expect(report.eligibleNotes, 205);
    expect(report.scannedNotes, 200);
    expect(report.partial, isTrue);
    expect(report.quotes.length, lessThanOrEqualTo(4));
  });

  test('five locales and canonical private-only source contracts', () {
    for (final code in ['it', 'en', 'es', 'fr', 'pt']) {
      for (final key in ['title','intro','week','month','place',
          'person','source','limited','empty']) {
        expect(memoryExtractiveCopy(code, key), isNotEmpty);
      }
    }
    final engine = File('lib/src/memory_extractive_summary.dart')
        .readAsStringSync();
    final ui = File('lib/src/screens/memory_extractive_summary_screen.dart')
        .readAsStringSync();
    final memories = File('lib/src/diary/diary_memories.dart')
        .readAsStringSync();
    expect(engine, contains('raw.substring(start, end)'));
    expect(engine, contains('block.archived'));
    expect(engine, isNot(contains('CloudSyncService')));
    expect(ui, contains('widget.store.memoryReferences('));
    expect(ui, contains('widget.store.entryScopeReady'));
    expect(ui, contains('MemoryExtractiveSummaryScreen('));
    expect(memories, contains(
        "key: const ValueKey('cap0151-memory-extractive-summary')"));
  });
}
