import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('shared entry round-trip preserves calendar data', () {
    final original = SharedEntry(
      id: 'shared-1',
      type: SharedEntryType.appointment,
      title: 'Cena insieme',
      note: 'Prenotazione alle 20',
      date: DateTime(2026, 9, 21),
      start: const TimeOfDay(hour: 20, minute: 0),
      end: const TimeOfDay(hour: 22, minute: 0),
    );

    final restored = SharedEntry.fromJson(
      original.toJson(),
      updatedBy: 'user-2',
    );

    expect(restored.id, original.id);
    expect(restored.type, SharedEntryType.appointment);
    expect(restored.title, 'Cena insieme');
    expect(restored.start?.hour, 20);
    expect(restored.end?.hour, 22);
    expect(restored.updatedBy, 'user-2');
  });

  test('shared task preserves completion state', () {
    final task = SharedEntry(
      id: 'task-1',
      type: SharedEntryType.task,
      title: 'Comprare i biglietti',
      note: '',
      date: DateTime(2026, 9, 22),
      done: true,
    );

    final restored = SharedEntry.fromJson(task.toJson());

    expect(restored.type, SharedEntryType.task);
    expect(restored.done, isTrue);
  });

  test('shared note has no time after serialization', () {
    final note = SharedEntry(
      id: 'note-1',
      type: SharedEntryType.note,
      title: 'Idea weekend',
      note: 'Valle Aurina',
      date: DateTime(2026, 9, 23),
    );

    final restored = SharedEntry.fromJson(note.toJson());

    expect(restored.type, SharedEntryType.note);
    expect(restored.start, isNull);
    expect(restored.end, isNull);
  });
}
