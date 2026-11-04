import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('CAP-0092 accepts plain task locally without changing source', () {
    const source = 'Comprare il pane';
    final draft = annaProposeTaskFromText(source,
        selectedDay: DateTime(2026, 11, 4),
        languageCode: 'it',
        now: DateTime(2026, 11, 4));
    expect(draft, isNotNull);
    expect(draft!.title, source);
    expect(draft.note, isEmpty);
    expect(draft.date, DateTime(2026, 11, 4));
    expect(draft.toEditorDraft().type, ItemType.task);
    expect(draft.toEditorDraft().done, isFalse);
  });

  test('CAP-0092 uses the existing parser for explicit dates and time', () {
    final draft = annaProposeTaskFromText('Dentista domani alle 10:30',
        selectedDay: DateTime(2026, 11, 4),
        languageCode: 'it',
        now: DateTime(2026, 11, 4));
    expect(draft, isNotNull);
    expect(draft!.date, DateTime(2026, 11, 5));
    expect(draft.time, const TimeOfDay(hour: 10, minute: 30));
    expect(annaProposeTaskFromText('Meeting 10:30 CET',
        selectedDay: DateTime(2026, 11, 4),
        languageCode: 'en', now: DateTime(2026, 11, 4)), isNull);
  });

  test('CAP-0093 converts only list lines and retains prose', () {
    const source = 'Spesa per sabato\n- latte\n- pane\n1. acqua';
    final result = annaProposeChecklistFromDiary(
        source, targetDay: DateTime(2026, 11, 4));
    expect(result, isNotNull);
    expect(result!.title, 'Spesa per sabato');
    expect(result.note, contains('Spesa per sabato'));
    expect(result.note, contains('☐ latte'));
    expect(result.note, contains('☐ pane'));
    expect(result.note, contains('☐ acqua'));
    expect(source, isNot(contains('☐')));
    expect(result.toEditorDraft().type, ItemType.task);
  });

  test('CAP-0093 refuses empty, too large or unsupported lists', () {
    expect(annaProposeChecklistFromDiary('Solo testo',
        targetDay: DateTime(2026, 11, 4)), isNull);
    expect(annaProposeChecklistFromDiary(List.filled(4001, 'z').join(),
        targetDay: DateTime(2026, 11, 4)), isNull);
    expect(annaProposeChecklistFromDiary(
        List.generate(21, (i) => '- voce $i').join('\n'),
        targetDay: DateTime(2026, 11, 4)), isNull);
  });

  test('CAP-0092 rejects invalid locales and blank input', () {
    expect(annaProposeTaskFromText(' ',
        selectedDay: DateTime(2026, 11, 4),
        languageCode: 'it', now: DateTime(2026, 11, 4)), isNull);
    expect(annaProposeTaskFromText('Compra latte',
        selectedDay: DateTime(2026, 11, 4),
        languageCode: 'de', now: DateTime(2026, 11, 4)), isNull);
  });
}
