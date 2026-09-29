part of '../main.dart';

enum LifeArchiveKind { diary, agenda, workout, inbox }

extension LifeArchiveKindUi on LifeArchiveKind {
  String get label => switch (this) {
        LifeArchiveKind.diary => 'Diario',
        LifeArchiveKind.agenda => 'Agenda',
        LifeArchiveKind.workout => 'Allenamenti',
        LifeArchiveKind.inbox => 'Inbox',
      };

  IconData get icon => switch (this) {
        LifeArchiveKind.diary => Icons.auto_stories_outlined,
        LifeArchiveKind.agenda => Icons.event_outlined,
        LifeArchiveKind.workout => Icons.sports_outlined,
        LifeArchiveKind.inbox => Icons.inbox_outlined,
      };
}

class LifeArchiveEntry {
  final String id;
  final LifeArchiveKind kind;
  final DateTime date;
  final String title;
  final String subtitle;
  final String searchableText;
  final bool archived;
  final AgendaItem? agendaItem;
  final DiaryBlockReference? diaryReference;
  final WorkoutSession? workoutSession;
  final InboxEntry? inboxEntry;

  const LifeArchiveEntry({
    required this.id,
    required this.kind,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.searchableText,
    this.archived = false,
    this.agendaItem,
    this.diaryReference,
    this.workoutSession,
    this.inboxEntry,
  });
}

extension AgendaStoreLifeArchive on AgendaStore {
  List<LifeArchiveEntry> lifeArchiveEntries({
    DateTime? through,
    String query = '',
    LifeArchiveKind? kind,
  }) {
    final anchor = through ?? DateTime.now();
    final end = DateTime(anchor.year, anchor.month, anchor.day, 23, 59, 59, 999);
    final result = <LifeArchiveEntry>[];

    for (final reference in memoryReferences(includeArchived: true)) {
      if (reference.date.isAfter(end)) continue;
      final block = reference.block;
      final peopleText = peopleForIds(block.personIds)
          .map((person) => '${person.name} ${person.relationship}')
          .join(' ');
      final placesText = block.places.map((place) => place.name).join(' ');
      final tagsText = block.tags.join(' ');
      final sketchText = block.pages
          .expand((page) => page.textElements)
          .map((element) => element.text)
          .join(' ');
      final typeLabel = switch (block.type) {
        DiaryBlockType.note => 'Nota',
        DiaryBlockType.sketch => 'Sketch',
        DiaryBlockType.photo => 'Foto',
        DiaryBlockType.voice => 'Nota vocale',
      };
      result.add(
        LifeArchiveEntry(
          id: 'diary:${block.id}',
          kind: LifeArchiveKind.diary,
          date: block.createdAt,
          title: diaryBlockDisplayTitle(block),
          subtitle: [
            typeLabel,
            if (block.archived) 'Archiviato',
            if (block.places.isNotEmpty)
              block.places.map((place) => place.name).take(2).join(', '),
          ].join(' · '),
          searchableText: [
            block.text,
            sketchText,
            peopleText,
            placesText,
            tagsText,
            typeLabel,
          ].join(' '),
          archived: block.archived,
          diaryReference: reference,
        ),
      );
    }

    for (final item in items) {
      if (item.date.isAfter(end)) continue;
      final timedDate = item.start == null
          ? item.date
          : DateTime(
              item.date.year,
              item.date.month,
              item.date.day,
              item.start!.hour,
              item.start!.minute,
            );
      final typeLabel =
          item.type == ItemType.task ? 'Attività' : 'Appuntamento';
      result.add(
        LifeArchiveEntry(
          id: 'agenda:${item.id}',
          kind: LifeArchiveKind.agenda,
          date: timedDate,
          title: item.title.trim().isEmpty ? typeLabel : item.title.trim(),
          subtitle: [
            typeLabel,
            item.category.label,
            if (item.done) 'Completato',
          ].join(' · '),
          searchableText: [
            item.title,
            item.note,
            typeLabel,
            item.category.label,
          ].join(' '),
          agendaItem: item,
        ),
      );
    }

    for (final session in workoutSessions) {
      if (session.date.isAfter(end)) continue;
      result.add(
        LifeArchiveEntry(
          id: 'workout:${session.id}',
          kind: LifeArchiveKind.workout,
          date: session.date,
          title: session.title.trim().isEmpty
              ? session.sport.label
              : session.title.trim(),
          subtitle: [
            session.sport.label,
            if (session.distanceKm != null && session.distanceKm! > 0)
              '${session.distanceKm!.toStringAsFixed(session.distanceKm! % 1 == 0 ? 0 : 1)} km',
            if (session.durationSeconds > 0)
              '${(session.durationSeconds / 60).round()} min',
          ].join(' · '),
          searchableText: [
            session.title,
            session.note,
            session.planName,
            session.sport.label,
            ...session.exercises.map((exercise) => exercise.name),
          ].join(' '),
          workoutSession: session,
        ),
      );
    }

    for (final entry in archivedInboxEntries) {
      if (entry.createdAt.isAfter(end)) continue;
      result.add(
        LifeArchiveEntry(
          id: 'inbox:${entry.id}',
          kind: LifeArchiveKind.inbox,
          date: entry.createdAt,
          title: entry.text,
          subtitle: [
            'Inbox archiviata',
            if (entry.tags.isNotEmpty)
              entry.tags.map((tag) => '#$tag').take(3).join(' '),
          ].join(' · '),
          searchableText: [entry.text, ...entry.tags].join(' '),
          archived: true,
          inboxEntry: entry,
        ),
      );
    }

    final normalizedKind = kind;
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    result.removeWhere((entry) {
      if (normalizedKind != null && entry.kind != normalizedKind) return true;
      if (tokens.isEmpty) return false;
      final haystack = [
        entry.title,
        entry.subtitle,
        entry.searchableText,
        '${entry.date.day} ${entry.date.month} ${entry.date.year}',
        '${entry.date.year}',
      ].join(' ').toLowerCase();
      return !tokens.every(haystack.contains);
    });

    result.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      return a.id.compareTo(b.id);
    });
    return result;
  }
}
