import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  DiaryBlockReference source(
    String id, DateTime day, {
    bool archived = false,
    DiaryBlockType type = DiaryBlockType.note,
  }) => DiaryBlockReference(
    date: day,
    block: DiaryBlock(
      id: id, type: type, createdAt: day,
      text: 'Record written by user', archived: archived,
    ),
  );

  test('CAP-0145 counts only saved active memories in last twelve months', () {
    final counts = annaRecordedMemoriesByDay([
      source('a', DateTime(2026, 11, 4)),
      source('b', DateTime(2026, 11, 4), type: DiaryBlockType.photo),
      source('a', DateTime(2026, 11, 4)), // duplicate ID ignored
      source('old', DateTime(2025, 11, 30)), // outside window
      source('archived', DateTime(2026, 10, 1), archived: true),
      source('within', DateTime(2025, 12, 1)),
      source('future', DateTime(2026, 12, 1)),
    ], endingMonth: DateTime(2026, 11));
    expect(counts['2026-11-04'], 2);
    expect(counts['2025-12-01'], 1);
    expect(counts.containsKey('2025-11-30'), false);
    expect(counts.containsKey('2026-10-01'), false);
    expect(counts.containsKey('2026-12-01'), false);
    expect(counts.containsKey('2026-11-05'), false);
  });

  test('CAP-0101 reports honest completion when tasks are known', () {
    AgendaItem task(String id, int day, {bool done = false}) =>
      AgendaItem(
        id: id, title: id, note: '', date: DateTime(2026, 11, day),
        type: ItemType.task, done: done,
      );
    final overview = WeeklyReviewSummary.fromItems([
      task('a', 2, done: true), task('b', 3),
      task('c', 4, done: true), task('overdue', 1),
    ], DateTime(2026, 11, 2));
    expect(overview.completedDatedThisWeek, 2);
    expect(overview.pendingDatedThisWeek, 1);
    expect(overview.overdueFromBefore, 1);
    expect(overview.completionPercentage, 66);
    expect(WeeklyReviewSummary.fromItems(
      const <AgendaItem>[], DateTime(2026, 11, 2)
    ).completionPercentage, isNull);
  });
}
