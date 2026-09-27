part of '../main.dart';

enum LifeMomentKind { memory, agenda, birthday }

extension LifeMomentKindUi on LifeMomentKind {
  String get label => switch (this) {
        LifeMomentKind.memory => 'Ricordi',
        LifeMomentKind.agenda => 'Agenda',
        LifeMomentKind.birthday => 'Compleanni',
      };

  IconData get icon => switch (this) {
        LifeMomentKind.memory => Icons.auto_awesome_outlined,
        LifeMomentKind.agenda => Icons.event_note_outlined,
        LifeMomentKind.birthday => Icons.cake_outlined,
      };
}

/// A read-only cross-domain reference.
///
/// It deliberately owns no serialized payload. Canonical data remains in
/// AgendaItem, DiaryBlock/DayJournal and BirthdayEntry.
class LifeMomentReference {
  final String id;
  final LifeMomentKind kind;
  final DateTime dateTime;
  final String title;
  final String subtitle;
  final String sourceId;
  final String? diaryBlockId;
  final String? agendaItemId;
  final String? birthdayId;
  final List<String> personIds;
  final List<String> placeIds;

  const LifeMomentReference({
    required this.id,
    required this.kind,
    required this.dateTime,
    required this.title,
    required this.subtitle,
    required this.sourceId,
    this.diaryBlockId,
    this.agendaItemId,
    this.birthdayId,
    this.personIds = const [],
    this.placeIds = const [],
  });

  DateTime get day => DateTime(dateTime.year, dateTime.month, dateTime.day);
}

extension AgendaStoreLifeTimeline on AgendaStore {
  DateTime _agendaLifeMomentDateTime(AgendaItem item) => DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
        item.start?.hour ?? 12,
        item.start?.minute ?? 0,
      );

  DateTime _memoryLifeMomentDateTime(DiaryBlockReference reference) => DateTime(
        reference.date.year,
        reference.date.month,
        reference.date.day,
        reference.block.createdAt.hour,
        reference.block.createdAt.minute,
        reference.block.createdAt.second,
      );

  String _memoryLifeMomentSubtitle(DiaryBlock block) {
    final context = <String>[
      switch (block.type) {
        DiaryBlockType.note => 'Nota',
        DiaryBlockType.photo => 'Foto',
        DiaryBlockType.sketch => 'Sketch',
        DiaryBlockType.voice => 'Voce',
      },
      ...peopleForIds(block.personIds).map((person) => person.name),
      ...placesForIds(block.placeIds).map((place) => place.name),
    ];
    return context.where((value) => value.trim().isNotEmpty).join(' · ');
  }

  List<LifeMomentReference> lifeMoments({
    bool includeArchivedMemories = false,
    bool includeCompletedAgenda = true,
    bool includeBirthdays = true,
    DateTime? from,
    DateTime? to,
    Set<LifeMomentKind>? kinds,
    DateTime? birthdayAnchor,
  }) {
    final enabled = kinds ?? LifeMomentKind.values.toSet();
    final moments = <LifeMomentReference>[];

    bool inRange(DateTime value) {
      if (from != null && value.isBefore(from)) return false;
      if (to != null && value.isAfter(to)) return false;
      return true;
    }

    if (enabled.contains(LifeMomentKind.memory)) {
      for (final reference in memoryRecords(
        includeArchived: includeArchivedMemories,
      )) {
        final dateTime = _memoryLifeMomentDateTime(reference);
        if (!inRange(dateTime)) continue;
        moments.add(
          LifeMomentReference(
            id: 'memory:${reference.block.id}',
            kind: LifeMomentKind.memory,
            dateTime: dateTime,
            title: memoryDisplayTitle(reference.block),
            subtitle: _memoryLifeMomentSubtitle(reference.block),
            sourceId: reference.block.id,
            diaryBlockId: reference.block.id,
            personIds: List.unmodifiable(reference.block.personIds),
            placeIds: List.unmodifiable(reference.block.placeIds),
          ),
        );
      }
    }

    if (enabled.contains(LifeMomentKind.agenda)) {
      for (final item in items) {
        if (!includeCompletedAgenda && item.done) continue;
        final dateTime = _agendaLifeMomentDateTime(item);
        if (!inRange(dateTime)) continue;
        moments.add(
          LifeMomentReference(
            id: 'agenda:${item.id}',
            kind: LifeMomentKind.agenda,
            dateTime: dateTime,
            title: item.title.trim().isEmpty ? 'Impegno' : item.title.trim(),
            subtitle: [
              item.type == ItemType.task ? 'Attività' : 'Appuntamento',
              item.category.label,
              if (item.done) 'Completato',
            ].join(' · '),
            sourceId: item.id,
            agendaItemId: item.id,
          ),
        );
      }
    }

    if (includeBirthdays && enabled.contains(LifeMomentKind.birthday)) {
      final anchor = birthdayAnchor ?? DateTime.now();
      for (final birthday in birthdays) {
        final occurrence = birthdayOccurrence(birthday, anchor.year);
        final occurrenceDateTime = DateTime(
          occurrence.date.year,
          occurrence.date.month,
          occurrence.date.day,
          9,
        );
        if (inRange(occurrenceDateTime)) {
          moments.add(
            LifeMomentReference(
              id: 'birthday:${birthday.id}:${anchor.year}',
              kind: LifeMomentKind.birthday,
              dateTime: occurrenceDateTime,
              title: birthday.name,
              subtitle: occurrence.age == null
                  ? 'Compleanno'
                  : 'Compleanno · ${occurrence.age} anni',
              sourceId: birthday.id,
              birthdayId: birthday.id,
            ),
          );
        }

        // A known birth year is a genuine historical life event. Keep it
        // distinct from the recurring current-year birthday occurrence.
        final birthYear = birthday.year;
        if (birthYear != null && birthYear != anchor.year) {
          final birthOccurrence = birthdayOccurrence(birthday, birthYear);
          final birthDateTime = DateTime(
            birthOccurrence.date.year,
            birthOccurrence.date.month,
            birthOccurrence.date.day,
            9,
          );
          if (inRange(birthDateTime)) {
            moments.add(
              LifeMomentReference(
                id: 'birthday:${birthday.id}:birth',
                kind: LifeMomentKind.birthday,
                dateTime: birthDateTime,
                title: birthday.name,
                subtitle: 'Nascita',
                sourceId: birthday.id,
                birthdayId: birthday.id,
              ),
            );
          }
        }
      }
    }

    moments.sort((a, b) {
      final byDate = b.dateTime.compareTo(a.dateTime);
      if (byDate != 0) return byDate;
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      return a.id.compareTo(b.id);
    });
    return moments;
  }

  Map<String, List<LifeMomentReference>> lifeMomentsByDay(
    Iterable<LifeMomentReference> moments,
  ) {
    final result = <String, List<LifeMomentReference>>{};
    for (final moment in moments) {
      result
          .putIfAbsent(AgendaStore.dateKey(moment.day), () => [])
          .add(moment);
    }
    return result;
  }

  Map<int, List<LifeMomentReference>> lifeMomentsByYear(
    Iterable<LifeMomentReference> moments,
  ) {
    final result = <int, List<LifeMomentReference>>{};
    for (final moment in moments) {
      result.putIfAbsent(moment.dateTime.year, () => []).add(moment);
    }
    return result;
  }

  bool lifeMomentMatches(
    LifeMomentReference moment,
    String rawQuery,
  ) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final personText = peopleForIds(moment.personIds)
        .map((person) => '${person.name} ${person.relationship}')
        .join(' ');
    final placeText = placesForIds(moment.placeIds)
        .map((place) => '${place.name} ${place.category} ${place.address}')
        .join(' ');
    final searchable = [
      moment.title,
      moment.subtitle,
      personText,
      placeText,
      moment.kind.label,
      DateFormat('d MMMM yyyy', 'it_IT').format(moment.dateTime),
      DateFormat('MMMM yyyy', 'it_IT').format(moment.dateTime),
      '${moment.dateTime.year}',
    ].join(' ').toLowerCase();
    return query
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .every(searchable.contains);
  }
}
