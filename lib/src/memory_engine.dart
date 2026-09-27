part of '../main.dart';

/// Derived, read-only memory layer.
///
/// DiaryBlock inside DayJournal remains the only canonical private-memory
/// storage. This engine centralizes timeline, relationship, "on this day",
/// connections and grouping projections without introducing another database.
class MemoryEngineSnapshot {
  final DateTime anchor;
  final List<DiaryBlockReference> records;
  final List<DiaryBlockReference> onThisDay;

  const MemoryEngineSnapshot({
    required this.anchor,
    required this.records,
    required this.onThisDay,
  });

  int get count => records.length;

  DateTime? get firstMemoryDate =>
      records.isEmpty ? null : records.last.date;

  DateTime? get lastMemoryDate =>
      records.isEmpty ? null : records.first.date;

  int countType(DiaryBlockType type) =>
      records.where((record) => record.block.type == type).length;

  int get distinctDays =>
      records.map((record) => AgendaStore.dateKey(record.date)).toSet().length;
}

extension AgendaStoreMemoryEngine on AgendaStore {
  List<DiaryBlockReference> memoryRecords({
    bool includeArchived = false,
    String? personId,
  }) {
    final result = <DiaryBlockReference>[];
    for (final entry in journals.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      for (final block in entry.value.blocks) {
        if (!includeArchived && block.archived) continue;
        if (personId != null && !block.personIds.contains(personId)) continue;
        result.add(DiaryBlockReference(date: date, block: block));
      }
    }

    result.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      return b.block.createdAt.compareTo(a.block.createdAt);
    });
    return result;
  }

  DiaryBlockReference? memoryRecordById(
    String blockId, {
    bool includeArchived = true,
  }) {
    for (final reference in memoryRecords(
      includeArchived: includeArchived,
    )) {
      if (reference.block.id == blockId) return reference;
    }
    return null;
  }

  List<DiaryBlockReference> memoriesOnThisDay(
    DateTime day, {
    String? personId,
  }) {
    final result = memoryRecords(
      includeArchived: false,
      personId: personId,
    ).where((reference) {
      final date = reference.date;
      return date.year < day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();

    result.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      return b.block.createdAt.compareTo(a.block.createdAt);
    });
    return result;
  }

  List<DiaryBlockReference> relatedMemoryRecords(DiaryBlock block) {
    final wanted = block.relatedBlockIds.toSet();
    if (wanted.isEmpty) return const [];
    return memoryRecords(includeArchived: true)
        .where((reference) => wanted.contains(reference.block.id))
        .toList();
  }

  List<DiaryBlockReference> memoryBacklinks(String targetBlockId) {
    return memoryRecords(includeArchived: true)
        .where(
          (reference) =>
              reference.block.id != targetBlockId &&
              reference.block.relatedBlockIds.contains(targetBlockId),
        )
        .toList();
  }

  String memoryDisplayTitle(DiaryBlock block) {
    final text = block.text.trim();
    if (text.isNotEmpty) {
      final firstLine = text.split('\n').first.trim();
      if (firstLine.length <= 64) return firstLine;
      return '${firstLine.substring(0, 61)}…';
    }
    return switch (block.type) {
      DiaryBlockType.note => 'Nota del diario',
      DiaryBlockType.photo => 'Foto del diario',
      DiaryBlockType.sketch => 'Sketch del diario',
      DiaryBlockType.voice => 'Nota vocale',
    };
  }

  Map<String, List<DiaryBlockReference>> memoriesByDay(
    Iterable<DiaryBlockReference> records,
  ) {
    final result = <String, List<DiaryBlockReference>>{};
    for (final record in records) {
      result
          .putIfAbsent(AgendaStore.dateKey(record.date), () => [])
          .add(record);
    }
    return result;
  }

  Map<String, List<DiaryBlockReference>> memoriesByMonth(
    Iterable<DiaryBlockReference> records,
  ) {
    final result = <String, List<DiaryBlockReference>>{};
    for (final record in records) {
      final key =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(record);
    }
    return result;
  }

  Map<int, List<DiaryBlockReference>> memoriesByYear(
    Iterable<DiaryBlockReference> records,
  ) {
    final result = <int, List<DiaryBlockReference>>{};
    for (final record in records) {
      result.putIfAbsent(record.date.year, () => []).add(record);
    }
    return result;
  }

  MemoryEngineSnapshot memoryEngineSnapshot({
    DateTime? anchor,
    bool includeArchived = false,
    String? personId,
  }) {
    final day = anchor ?? DateTime.now();
    return MemoryEngineSnapshot(
      anchor: DateTime(day.year, day.month, day.day),
      records: memoryRecords(
        includeArchived: includeArchived,
        personId: personId,
      ),
      onThisDay: memoriesOnThisDay(
        day,
        personId: personId,
      ),
    );
  }
}
