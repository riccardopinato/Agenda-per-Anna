part of '../main.dart';

enum PersonalSearchKind { agenda, diary, person, place, birthday, inbox, month }

extension PersonalSearchKindUi on PersonalSearchKind {
  String get label => switch (this) {
        PersonalSearchKind.agenda => 'Agenda',
        PersonalSearchKind.diary => 'Diario',
        PersonalSearchKind.person => 'Persone',
        PersonalSearchKind.place => 'Luoghi',
        PersonalSearchKind.birthday => 'Compleanni',
        PersonalSearchKind.inbox => 'Inbox',
        PersonalSearchKind.month => 'Mesi',
      };

  IconData get icon => switch (this) {
        PersonalSearchKind.agenda => Icons.event_outlined,
        PersonalSearchKind.diary => Icons.auto_stories_outlined,
        PersonalSearchKind.person => Icons.person_outline,
        PersonalSearchKind.place => Icons.place_outlined,
        PersonalSearchKind.birthday => Icons.cake_outlined,
        PersonalSearchKind.inbox => Icons.inbox_outlined,
        PersonalSearchKind.month => Icons.calendar_month_outlined,
      };
}

class DiaryBlockReference {
  final DateTime date;
  final DiaryBlock block;

  const DiaryBlockReference({
    required this.date,
    required this.block,
  });
}

enum MemoryRecallFacetKind { person, place }

class MemoryRecallFacet {
  final MemoryRecallFacetKind kind;
  final String id;
  final String label;
  final int count;

  const MemoryRecallFacet({
    required this.kind,
    required this.id,
    required this.label,
    required this.count,
  });
}

class MemoryRecallSnapshot {
  final DateTime anchor;
  final List<DiaryBlockReference> onThisDay;
  final List<DiaryBlockReference> sameMonthPastYears;
  final List<DiaryBlockReference> yearHighlights;
  final List<MemoryRecallFacet> people;
  final List<MemoryRecallFacet> places;

  const MemoryRecallSnapshot({
    required this.anchor,
    required this.onThisDay,
    required this.sameMonthPastYears,
    required this.yearHighlights,
    required this.people,
    required this.places,
  });

  bool get isEmpty => yearHighlights.isEmpty;
  int get historicalYears => yearHighlights.length;
}

class PersonalSearchHit {
  final PersonalSearchKind kind;
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final AgendaItem? agendaItem;
  final String? diaryBlockId;
  final String? personId;
  final String? placeName;
  final String? birthdayId;
  final String? inboxId;

  const PersonalSearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    this.agendaItem,
    this.diaryBlockId,
    this.personId,
    this.placeName,
    this.birthdayId,
    this.inboxId,
  });
}

extension SearchConnectionsAgendaStore on AgendaStore {
  List<DiaryBlockReference> allDiaryBlockReferences({
    bool includeArchived = false,
  }) {
    final result = <DiaryBlockReference>[];
    for (final entry in journals.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      for (final block in entry.value.blocks) {
        if (!includeArchived && block.archived) continue;
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

  List<DiaryBlockReference> memoryReferences({
    bool includeArchived = false,
    String? personId,
  }) {
    return allDiaryBlockReferences(includeArchived: includeArchived)
        .where(
          (reference) =>
              personId == null || reference.block.personIds.contains(personId),
        )
        .toList(growable: false);
  }

  List<DiaryBlockReference> memoryReferencesOnThisDay(
    DateTime day, {
    String? personId,
  }) {
    return memoryReferences(personId: personId)
        .where(
          (reference) =>
              reference.date.year < day.year &&
              reference.date.month == day.month &&
              reference.date.day == day.day,
        )
        .toList(growable: false);
  }

  MemoryRecallSnapshot memoryRecallSnapshot(
    DateTime anchor, {
    String? personId,
    Iterable<DiaryBlockReference>? references,
  }) {
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final historical = (references ??
            memoryReferences(
              personId: personId,
            ))
        .where(
          (reference) =>
              !reference.block.archived &&
              reference.date.isBefore(anchorDay) &&
              (personId == null ||
                  reference.block.personIds.contains(personId)),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final dateOrder = b.date.compareTo(a.date);
        if (dateOrder != 0) return dateOrder;
        return b.block.createdAt.compareTo(a.block.createdAt);
      });

    final onThisDay = historical
        .where(
          (reference) =>
              reference.date.month == anchorDay.month &&
              reference.date.day == anchorDay.day,
        )
        .toList(growable: false);

    final sameMonthPastYears = historical
        .where(
          (reference) =>
              reference.date.month == anchorDay.month &&
              reference.date.day != anchorDay.day,
        )
        .toList(growable: false);

    final highlightByYear = <int, DiaryBlockReference>{};
    for (final reference in historical) {
      final current = highlightByYear[reference.date.year];
      if (current == null ||
          (current.block.type != DiaryBlockType.photo &&
              reference.block.type == DiaryBlockType.photo)) {
        highlightByYear[reference.date.year] = reference;
      }
    }
    final highlightYears = highlightByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final yearHighlights = highlightYears
        .map((year) => highlightByYear[year]!)
        .toList(growable: false);

    final personCounts = <String, int>{};
    final placeCounts = <String, int>{};
    final placeLabels = <String, String>{};

    for (final reference in historical) {
      for (final id in reference.block.personIds.toSet()) {
        if (!people.any((person) => person.id == id)) continue;
        personCounts[id] = (personCounts[id] ?? 0) + 1;
      }

      final seenPlaces = <String>{};
      for (final place in reference.block.places) {
        final label = place.name.trim();
        final key = place.normalizedName;
        if (label.isEmpty || key.isEmpty || !seenPlaces.add(key)) continue;
        placeLabels.putIfAbsent(key, () => label);
        placeCounts[key] = (placeCounts[key] ?? 0) + 1;
      }
    }

    final recurringPeople = personCounts.entries
        .map((entry) {
          final person = people.firstWhere((person) => person.id == entry.key);
          return MemoryRecallFacet(
            kind: MemoryRecallFacetKind.person,
            id: entry.key,
            label: person.name,
            count: entry.value,
          );
        })
        .toList(growable: false)
      ..sort((a, b) {
        final countOrder = b.count.compareTo(a.count);
        if (countOrder != 0) return countOrder;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    final recurringPlaces = placeCounts.entries
        .map(
          (entry) => MemoryRecallFacet(
            kind: MemoryRecallFacetKind.place,
            id: entry.key,
            label: placeLabels[entry.key] ?? entry.key,
            count: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final countOrder = b.count.compareTo(a.count);
        if (countOrder != 0) return countOrder;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    return MemoryRecallSnapshot(
      anchor: anchorDay,
      onThisDay: onThisDay,
      sameMonthPastYears: sameMonthPastYears,
      yearHighlights: yearHighlights,
      people: recurringPeople,
      places: recurringPlaces,
    );
  }

  List<String> get diaryPlaceNames {
    final labels = <String, String>{};
    for (final reference in memoryReferences(includeArchived: true)) {
      for (final place in reference.block.places) {
        final name = place.name.trim();
        if (name.isEmpty) continue;
        labels.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    final result = labels.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  List<DiaryBlockReference> memoriesForPlace(
    String placeName, {
    bool includeArchived = false,
  }) {
    final wanted = placeName.trim().toLowerCase();
    if (wanted.isEmpty) return const [];
    return memoryReferences(includeArchived: includeArchived)
        .where(
          (reference) => reference.block.places.any(
            (place) => place.normalizedName == wanted,
          ),
        )
        .toList(growable: false);
  }

  Future<void> setDiaryBlockPlaces(
    DateTime date,
    String blockId,
    Iterable<DiaryPlaceReference> places,
  ) async {
    final key = AgendaStore.dateKey(date);
    final current = journals[key];
    if (current == null) return;
    final index = current.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return;

    final normalized = <DiaryPlaceReference>[];
    final seen = <String>{};
    for (final raw in places) {
      final name = raw.name.trim();
      final normalizedName = name.toLowerCase();
      if (name.isEmpty || !seen.add(normalizedName)) continue;

      final lat = raw.latitude;
      final lon = raw.longitude;
      final validCoordinates = lat != null &&
          lon != null &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180;
      normalized.add(
        DiaryPlaceReference(
          name: name,
          latitude: validCoordinates ? lat : null,
          longitude: validCoordinates ? lon : null,
        ),
      );
      if (normalized.length >= 6) break;
    }

    final blocks = [...current.blocks];
    blocks[index] = blocks[index].copyWith(places: normalized);
    await saveJournal(date, current.copyWith(blocks: blocks));
  }

  DiaryBlockReference? diaryBlockReferenceById(
    String blockId, {
    bool includeArchived = true,
  }) {
    for (final reference
        in allDiaryBlockReferences(includeArchived: includeArchived)) {
      if (reference.block.id == blockId) return reference;
    }
    return null;
  }

  String diaryBlockDisplayTitle(DiaryBlock block) {
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

  List<DiaryBlockReference> relatedDiaryBlocks(DiaryBlock block) {
    final wanted = block.relatedBlockIds.toSet();
    if (wanted.isEmpty) return const [];
    return allDiaryBlockReferences(includeArchived: true)
        .where((reference) => wanted.contains(reference.block.id))
        .toList();
  }

  List<DiaryBlockReference> backlinksForDiaryBlock(String targetBlockId) {
    return allDiaryBlockReferences(includeArchived: true)
        .where(
          (reference) =>
              reference.block.id != targetBlockId &&
              reference.block.relatedBlockIds.contains(targetBlockId),
        )
        .toList();
  }

  Future<void> setDiaryBlockConnections(
    DateTime date,
    String blockId,
    Iterable<String> targetIds,
  ) async {
    final key = AgendaStore.dateKey(date);
    final current = journals[key];
    if (current == null) return;
    final index = current.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return;

    final validIds = allDiaryBlockReferences(includeArchived: true)
        .map((reference) => reference.block.id)
        .toSet()
      ..remove(blockId);

    final normalized = <String>[];
    for (final raw in targetIds) {
      final id = raw.trim();
      if (id.isEmpty || !validIds.contains(id) || normalized.contains(id)) {
        continue;
      }
      normalized.add(id);
      if (normalized.length >= 12) break;
    }

    final blocks = [...current.blocks];
    blocks[index] = blocks[index].copyWith(relatedBlockIds: normalized);
    await saveJournal(date, current.copyWith(blocks: blocks));
  }

  bool _hasLiveOrRecoverableDiaryBlockId(String blockId) {
    if (allDiaryBlockReferences(includeArchived: true)
        .any((reference) => reference.block.id == blockId)) {
      return true;
    }
    for (final entry in trash) {
      try {
        if (entry.kind == TrashEntityKind.diaryBlock) {
          if (DiaryBlock.fromJson(entry.payload).id == blockId) return true;
        } else if (entry.kind == TrashEntityKind.journal) {
          if (DayJournal.fromJson(entry.payload)
              .blocks
              .any((block) => block.id == blockId)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> _unlinkPurgedDiaryBlockConnections(
    Set<String> blockIds,
  ) async {
    if (blockIds.isEmpty) return;
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[];

    for (final entry in journals.entries.toList()) {
      var changed = false;
      final blocks = entry.value.blocks.map((block) {
        final nextIds =
            block.relatedBlockIds.where((id) => !blockIds.contains(id)).toList();
        if (nextIds.length == block.relatedBlockIds.length) return block;
        changed = true;
        return block.copyWith(relatedBlockIds: nextIds);
      }).toList();
      if (!changed) continue;
      final updated = entry.value.copyWith(blocks: blocks);
      journals[entry.key] = updated;
      mutations.add((
        type: 'journal',
        id: entry.key,
        payload: updated.toLocalJson(),
        deleted: false,
      ));
    }

    for (var i = 0; i < trash.length; i++) {
      final entry = trash[i];
      if (entry.kind == TrashEntityKind.diaryBlock) {
        try {
          final block = DiaryBlock.fromJson(entry.payload);
          final nextIds = block.relatedBlockIds
              .where((id) => !blockIds.contains(id))
              .toList();
          if (nextIds.length == block.relatedBlockIds.length) continue;
          final updated = entry.copyWith(
            payload: block.copyWith(relatedBlockIds: nextIds).toLocalJson(),
          );
          trash[i] = updated;
          mutations.add((
            type: 'trash',
            id: updated.id,
            payload: updated.toJson(),
            deleted: false,
          ));
        } catch (_) {}
      } else if (entry.kind == TrashEntityKind.journal) {
        try {
          final journal = DayJournal.fromJson(entry.payload);
          var changed = false;
          final blocks = journal.blocks.map((block) {
            final nextIds = block.relatedBlockIds
                .where((id) => !blockIds.contains(id))
                .toList();
            if (nextIds.length == block.relatedBlockIds.length) return block;
            changed = true;
            return block.copyWith(relatedBlockIds: nextIds);
          }).toList();
          if (!changed) continue;
          final updated = entry.copyWith(
            payload: journal.copyWith(blocks: blocks).toLocalJson(),
          );
          trash[i] = updated;
          mutations.add((
            type: 'trash',
            id: updated.id,
            payload: updated.toJson(),
            deleted: false,
          ));
        } catch (_) {}
      }
    }

    if (mutations.isNotEmpty) {
      await _persistEntityMutations(
        mutations,
        createAutoSnapshot: false,
      );
      _notifyJournalChanged();
    }
  }

  bool _matchesPersonalSearch(String query, Iterable<String> values) {
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return false;
    final haystack = values.join(' ').toLowerCase();
    return tokens.every(haystack.contains);
  }

  List<PersonalSearchHit> personalSearch(
    String query, {
    Set<PersonalSearchKind>? kinds,
    bool includeArchived = false,
    String languageCode = 'it',
  }) {
    final strings = AnnaStrings(languageCode);
    final locale = AnnaStrings.resolveLocale(Locale(languageCode)).languageCode;
    final enabled = kinds == null || kinds.isEmpty
        ? PersonalSearchKind.values.toSet()
        : kinds;
    if (query.trim().isEmpty) return const [];

    final hits = <PersonalSearchHit>[];

    if (enabled.contains(PersonalSearchKind.agenda)) {
      for (final item in items) {
        if (!_matchesPersonalSearch(query, [
          item.title,
          item.note,
          item.category.label,
          item.type.name,
          DateFormat('d MMMM yyyy', locale).format(item.date),
          if (item.isRecurring) item.recurrenceRule.label,
        ])) {
          continue;
        }
        hits.add(
          PersonalSearchHit(
            kind: PersonalSearchKind.agenda,
            id: item.id,
            title: item.title,
            subtitle:
                '${DateFormat('d MMMM yyyy', locale).format(item.date)} · ${item.category.label}',
            date: item.date,
            agendaItem: item,
          ),
        );
      }
    }

    if (enabled.contains(PersonalSearchKind.diary)) {
      for (final entry in journals.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date == null) continue;
        final journal = entry.value;
        if (_matchesPersonalSearch(query, [
          journal.beautiful,
          journal.note,
          ...journal.gratitude,
          journal.mood?.label ?? '',
          DateFormat('d MMMM yyyy', locale).format(date),
        ])) {
          hits.add(
            PersonalSearchHit(
              kind: PersonalSearchKind.diary,
              id: 'journal:${AgendaStore.dateKey(date)}',
              title: journal.beautiful.trim().isEmpty
                  ? 'Diario del ${DateFormat('d MMMM', locale).format(date)}'
                  : journal.beautiful.trim(),
              subtitle:
                  '${strings.v100Day} · ${DateFormat('d MMMM yyyy', locale).format(date)}',
              date: date,
            ),
          );
        }

        for (final block in journal.blocks) {
          if (!includeArchived && block.archived) continue;
          final linkedPeople = peopleForIds(block.personIds);
          final sketchText = block.pages
              .expand((page) => page.textElements)
              .map((element) => element.text);
          if (!_matchesPersonalSearch(query, [
            block.text,
            block.ocrText,
            ...block.tags,
            ...linkedPeople.map((person) => person.name),
            ...linkedPeople.map((person) => person.relationship),
            ...block.places.map((place) => place.name),
            ...sketchText,
            DateFormat('d MMMM yyyy', locale).format(date),
            switch (block.type) {
              DiaryBlockType.note => 'nota testo diario',
              DiaryBlockType.photo => 'foto immagine ricordo',
              DiaryBlockType.sketch => 'sketch disegno',
              DiaryBlockType.voice => 'voce audio registrazione',
            },
          ])) {
            continue;
          }
          hits.add(
            PersonalSearchHit(
              kind: PersonalSearchKind.diary,
              id: 'block:${block.id}',
              title: diaryBlockDisplayTitle(block),
              subtitle: [
                switch (block.type) {
                  DiaryBlockType.note => strings.v100Note,
                  DiaryBlockType.photo => strings.v100Photo,
                  DiaryBlockType.sketch => strings.v100Sketch,
                  DiaryBlockType.voice => strings.v100VoiceNote,
                },
                DateFormat('d MMMM yyyy', locale).format(date),
                if (block.type == DiaryBlockType.photo &&
                    block.ocrText.trim().isNotEmpty)
                  strings.v100PhotoText,
                if (block.tags.isNotEmpty)
                  block.tags.map((tag) => '#$tag').join(' '),
                if (block.places.isNotEmpty)
                  block.places.map((place) => '📍 ${place.name}').join(' · '),
              ].join(' · '),
              date: date,
              diaryBlockId: block.id,
            ),
          );
        }
      }
    }

    if (enabled.contains(PersonalSearchKind.person)) {
      for (final person in people) {
        final birthday = birthdayForPerson(person);
        if (!_matchesPersonalSearch(query, [
          person.name,
          person.relationship,
          person.note,
          birthday?.name ?? '',
          birthday?.note ?? '',
          if (person.anniversaryDate != null)
            DateFormat('d MMMM yyyy', locale)
                .format(person.anniversaryDate!),
        ])) {
          continue;
        }
        final lastMemory = lastMemoryDateForPerson(person.id);
        hits.add(
          PersonalSearchHit(
            kind: PersonalSearchKind.person,
            id: person.id,
            title: person.name,
            subtitle: [
              if (person.relationship.trim().isNotEmpty)
                person.relationship.trim(),
              '${personMemoryCount(person.id)} ricordi',
            ].join(' · '),
            date: lastMemory ?? DateTime.fromMillisecondsSinceEpoch(0),
            personId: person.id,
          ),
        );
      }
    }

    if (enabled.contains(PersonalSearchKind.place)) {
      final latestByPlace = <String, DiaryBlockReference>{};
      final labels = <String, String>{};
      for (final reference
          in memoryReferences(includeArchived: includeArchived)) {
        for (final place in reference.block.places) {
          final label = place.name.trim();
          if (label.isEmpty ||
              !_matchesPersonalSearch(query, [
                label,
                if (place.latitude != null) place.latitude.toString(),
                if (place.longitude != null) place.longitude.toString(),
              ])) {
            continue;
          }
          final key = label.toLowerCase();
          labels.putIfAbsent(key, () => label);
          latestByPlace.putIfAbsent(key, () => reference);
        }
      }
      for (final entry in latestByPlace.entries) {
        final reference = entry.value;
        hits.add(
          PersonalSearchHit(
            kind: PersonalSearchKind.place,
            id: 'place:${entry.key}',
            title: labels[entry.key]!,
            subtitle:
                '${strings.v100SearchKind(PersonalSearchKind.place)} · ${DateFormat('d MMMM yyyy', locale).format(reference.date)}',
            date: reference.date,
            diaryBlockId: reference.block.id,
            placeName: labels[entry.key],
          ),
        );
      }
    }

    if (enabled.contains(PersonalSearchKind.birthday)) {
      final now = DateTime.now();
      for (final birthday in birthdays) {
        if (!_matchesPersonalSearch(query, [
          birthday.name,
          birthday.note,
          DateFormat('d MMMM', locale)
              .format(DateTime(2000, birthday.month, birthday.day)),
          if (birthday.year != null) birthday.year.toString(),
        ])) {
          continue;
        }
        var occurrence = birthdayOccurrence(birthday, now.year);
        if (occurrence.date.isBefore(DateTime(now.year, now.month, now.day))) {
          occurrence = birthdayOccurrence(birthday, now.year + 1);
        }
        hits.add(
          PersonalSearchHit(
            kind: PersonalSearchKind.birthday,
            id: birthday.id,
            title: birthday.name,
            subtitle:
                '${strings.v100SearchKind(PersonalSearchKind.birthday)} · ${DateFormat('d MMMM', locale).format(occurrence.date)}',
            date: occurrence.date,
            birthdayId: birthday.id,
          ),
        );
      }
    }

    if (enabled.contains(PersonalSearchKind.inbox)) {
      for (final entry in inbox) {
        if (!includeArchived && entry.archived) continue;
        if (!_matchesPersonalSearch(query, [
          entry.text,
          ...entry.tags,
          DateFormat('d MMMM yyyy', locale).format(entry.createdAt),
        ])) {
          continue;
        }
        hits.add(
          PersonalSearchHit(
            kind: PersonalSearchKind.inbox,
            id: entry.id,
            title: entry.text,
            subtitle: [
              'Inbox',
              DateFormat('d MMM yyyy', locale).format(entry.createdAt),
              if (entry.tags.isNotEmpty)
                entry.tags.map((tag) => '#$tag').join(' '),
            ].join(' · '),
            date: entry.createdAt,
            inboxId: entry.id,
          ),
        );
      }
    }

    if (enabled.contains(PersonalSearchKind.month)) {
      for (final entry in months.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 2) continue;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) continue;
        final data = entry.value;
        if (!_matchesPersonalSearch(query, [
          data.intention,
          ...data.goals,
          ...data.books,
          ...data.films,
          ...data.hobbies,
          ...data.wishes,
          ...data.ideas,
          data.monthWord,
          data.selfCare,
          data.bestMoment,
          data.lesson,
          data.challenge,
          data.nextMonth,
          data.reflection,
          DateFormat('MMMM yyyy', locale).format(DateTime(year, month)),
        ])) {
          continue;
        }
        final date = DateTime(year, month);
        hits.add(
          PersonalSearchHit(
            kind: PersonalSearchKind.month,
            id: entry.key,
            title: _cap(DateFormat('MMMM yyyy', locale).format(date)),
            subtitle: data.intention.trim().isEmpty
                ? strings.v100MonthPage
                : data.intention.trim(),
            date: date,
          ),
        );
      }
    }

    hits.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return hits;
  }
}

Future<List<String>?> showDiaryConnectionsPicker(
  BuildContext context,
  AgendaStore store, {
  required DiaryBlock source,
}) async {
  final candidates = store
      .allDiaryBlockReferences()
      .where((reference) => reference.block.id != source.id)
      .toList();
  final selected = source.relatedBlockIds
      .where(
        (id) => candidates.any((reference) => reference.block.id == id),
      )
      .toSet();

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Collega ricordi',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                subtitle: Text(
                  candidates.isEmpty
                      ? 'Non ci sono ancora altri ricordi da collegare.'
                      : 'Seleziona fino a 12 ricordi. I collegamenti inversi vengono mostrati automaticamente.',
                ),
              ),
              Expanded(
                child: candidates.isEmpty
                    ? const Center(child: Text('Nessun altro ricordo.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final reference = candidates[index];
                          final block = reference.block;
                          final checked = selected.contains(block.id);
                          final disabled = !checked && selected.length >= 12;
                          return CheckboxListTile(
                            value: checked,
                            onChanged: disabled
                                ? null
                                : (value) => setSheetState(() {
                                      if (value == true) {
                                        selected.add(block.id);
                                      } else {
                                        selected.remove(block.id);
                                      }
                                    }),
                            secondary: Icon(
                              switch (block.type) {
                                DiaryBlockType.note =>
                                  Icons.sticky_note_2_outlined,
                                DiaryBlockType.photo => Icons.photo_outlined,
                                DiaryBlockType.sketch => Icons.draw_outlined,
                                DiaryBlockType.voice => Icons.mic_none_outlined,
                              },
                            ),
                            title: Text(
                              store.diaryBlockDisplayTitle(block),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              DateFormat('d MMMM yyyy', 'it_IT')
                                  .format(reference.date),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          selected.toList(growable: false),
                        ),
                        child: Text('Salva (${selected.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PersonalSearchConnectionsScreen extends StatefulWidget {
  final AgendaStore store;

  const PersonalSearchConnectionsScreen({
    super.key,
    required this.store,
  });

  @override
  State<PersonalSearchConnectionsScreen> createState() =>
      _PersonalSearchConnectionsScreenState();
}

class _PersonalSearchConnectionsScreenState
    extends State<PersonalSearchConnectionsScreen> {
  String query = '';
  final Set<PersonalSearchKind> selectedKinds = {};
  bool includeArchived = false;
  bool ocrIndexing = false;
  int lastOcrIndexed = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_indexPhotoText());
  }

  Future<void> _indexPhotoText() async {
    if (ocrIndexing) return;
    if (mounted) setState(() => ocrIndexing = true);
    var total = 0;
    try {
      for (var pass = 0; pass < 3; pass++) {
        final indexed = await widget.store.ensurePhotoOcrIndexed(
          maxPerPass: 12,
        );
        total += indexed;
        if (indexed == 0) break;
      }
    } finally {
      if (mounted) {
        setState(() {
          ocrIndexing = false;
          lastOcrIndexed = total;
        });
      }
    }
  }

  Future<void> _openHit(PersonalSearchHit hit) async {
    switch (hit.kind) {
      case PersonalSearchKind.agenda:
        await openItemEditor(
          context,
          widget.store,
          hit.date,
          existing: hit.agendaItem,
        );
        return;
      case PersonalSearchKind.diary:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlannerScreen(
              store: widget.store,
              initialDate: hit.date,
            ),
          ),
        );
        return;
      case PersonalSearchKind.person:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PeopleScreen(store: widget.store),
          ),
        );
        return;
      case PersonalSearchKind.place:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlannerScreen(
              store: widget.store,
              initialDate: hit.date,
            ),
          ),
        );
        return;
      case PersonalSearchKind.birthday:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BirthdaysScreen(store: widget.store),
          ),
        );
        return;
      case PersonalSearchKind.inbox:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InboxScreen(store: widget.store),
          ),
        );
        return;
      case PersonalSearchKind.month:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonthScreen(
              store: widget.store,
              initialMonth: hit.date,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final hits = widget.store.personalSearch(
      query,
      kinds: selectedKinds,
      includeArchived: includeArchived,
      languageCode: strings.languageCode,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.v100SearchConnectTitle,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: ocrIndexing
                ? strings.v100SearchPhotoIndexing
                : strings.v100SearchRefreshPhotoText,
            onPressed: ocrIndexing ? null : _indexPhotoText,
            icon: ocrIndexing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.text_snippet_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ocrIndexing)
            const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: strings.v100SearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    selected: selectedKinds.isEmpty,
                    label: Text(strings.all),
                    onSelected: (_) => setState(selectedKinds.clear),
                  ),
                ),
                ...PersonalSearchKind.values.map(
                  (kind) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: FilterChip(
                      selected: selectedKinds.contains(kind),
                      avatar: Icon(kind.icon, size: 16),
                      label: Text(strings.v100SearchKind(kind)),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          selectedKinds.add(kind);
                        } else {
                          selectedKinds.remove(kind);
                        }
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: FilterChip(
                    selected: includeArchived,
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text(strings.archive),
                    onSelected: (value) =>
                        setState(() => includeArchived = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: query.trim().isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        strings.v100SearchPrompt,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : hits.isEmpty
                    ? Center(child: Text(strings.v100NoResults))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
                        itemCount: hits.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final hit = hits[index];
                          return Card(
                            child: ListTile(
                              leading:
                                  CircleAvatar(child: Icon(hit.kind.icon)),
                              title: Text(
                                hit.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                hit.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openHit(hit),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
