part of '../main.dart';

class PersonEntry {
  final String id;
  final String name;
  final String relationship;
  final String note;
  final String? birthdayId;
  final bool favorite;

  const PersonEntry({
    required this.id,
    required this.name,
    this.relationship = '',
    this.note = '',
    this.birthdayId,
    this.favorite = false,
  });

  PersonEntry copyWith({
    String? name,
    String? relationship,
    String? note,
    String? birthdayId,
    bool? favorite,
    bool clearBirthday = false,
  }) =>
      PersonEntry(
        id: id,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        note: note ?? this.note,
        birthdayId: clearBirthday ? null : (birthdayId ?? this.birthdayId),
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'note': note,
        'birthdayId': birthdayId,
        'favorite': favorite,
      };

  factory PersonEntry.fromJson(Map<String, dynamic> json) => PersonEntry(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '',
        note: json['note'] as String? ?? '',
        birthdayId: (json['birthdayId'] as String?)?.trim().isEmpty == true
            ? null
            : json['birthdayId'] as String?,
        favorite: json['favorite'] as bool? ?? false,
      );
}

class PersonMemoryReference {
  final DateTime date;
  final DiaryBlock block;

  const PersonMemoryReference({
    required this.date,
    required this.block,
  });
}

extension AgendaStorePeople on AgendaStore {
  PersonEntry? personById(String id) {
    for (final person in people) {
      if (person.id == id) return person;
    }
    return null;
  }

  BirthdayEntry? birthdayForPerson(PersonEntry person) {
    final birthdayId = person.birthdayId;
    if (birthdayId == null || birthdayId.isEmpty) return null;
    for (final birthday in birthdays) {
      if (birthday.id == birthdayId) return birthday;
    }
    return null;
  }

  List<PersonEntry> peopleForIds(Iterable<String> ids) {
    final wanted = ids.toSet();
    final result = people.where((person) => wanted.contains(person.id)).toList()
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return result;
  }

  List<PersonMemoryReference> memoriesForPerson(String personId) {
    final result = <PersonMemoryReference>[];
    for (final entry in journals.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      for (final block in entry.value.blocks) {
        if (block.personIds.contains(personId)) {
          result.add(PersonMemoryReference(date: date, block: block));
        }
      }
    }
    result.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      return b.block.createdAt.compareTo(a.block.createdAt);
    });
    return result;
  }

  int personMemoryCount(String personId) =>
      memoriesForPerson(personId).length;

  DateTime? lastMemoryDateForPerson(String personId) {
    final memories = memoriesForPerson(personId);
    return memories.isEmpty ? null : memories.first.date;
  }

  Future<void> savePerson(PersonEntry person) async {
    final normalizedName = person.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(person.name, 'name', 'Il nome è obbligatorio');
    }

    final linkedBirthday = person.birthdayId;
    final birthdayExists = linkedBirthday != null &&
        birthdays.any((birthday) => birthday.id == linkedBirthday);
    final normalized = person.copyWith(
      name: normalizedName,
      relationship: person.relationship.trim(),
      note: person.note.trim(),
      clearBirthday: linkedBirthday != null && !birthdayExists,
    );

    final index = people.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      people.add(normalized);
    } else {
      people[index] = normalized;
    }

    await _persistEntityMutation(
      type: 'person',
      id: normalized.id,
      payload: normalized.toJson(),
    );
    _notifyPlanningChanged();
  }

  Future<void> tagDiaryBlockPeople(
    DateTime date,
    String blockId,
    Iterable<String> personIds,
  ) async {
    final key = AgendaStore.dateKey(date);
    final current = journals[key];
    if (current == null) return;
    final index = current.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return;

    final validIds = <String>[];
    for (final id in personIds) {
      if (validIds.contains(id)) continue;
      if (people.any((person) => person.id == id)) validIds.add(id);
    }

    final blocks = [...current.blocks];
    blocks[index] = blocks[index].copyWith(personIds: validIds);
    await saveJournal(date, current.copyWith(blocks: blocks));
  }

  Future<void> _unlinkPurgedPeople(Set<String> personIds) async {
    if (personIds.isEmpty) return;
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
        if (!block.personIds.any(personIds.contains)) return block;
        changed = true;
        return block.copyWith(
          personIds:
              block.personIds.where((id) => !personIds.contains(id)).toList(),
        );
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
        final block = DiaryBlock.fromJson(entry.payload);
        if (!block.personIds.any(personIds.contains)) continue;
        final updatedBlock = block.copyWith(
          personIds:
              block.personIds.where((id) => !personIds.contains(id)).toList(),
        );
        final updatedEntry = entry.copyWith(payload: updatedBlock.toLocalJson());
        trash[i] = updatedEntry;
        mutations.add((
          type: 'trash',
          id: updatedEntry.id,
          payload: updatedEntry.toJson(),
          deleted: false,
        ));
      } else if (entry.kind == TrashEntityKind.journal) {
        final journal = DayJournal.fromJson(entry.payload);
        var changed = false;
        final blocks = journal.blocks.map((block) {
          if (!block.personIds.any(personIds.contains)) return block;
          changed = true;
          return block.copyWith(
            personIds:
                block.personIds.where((id) => !personIds.contains(id)).toList(),
          );
        }).toList();
        if (!changed) continue;
        final updatedEntry = entry.copyWith(
          payload: journal.copyWith(blocks: blocks).toLocalJson(),
        );
        trash[i] = updatedEntry;
        mutations.add((
          type: 'trash',
          id: updatedEntry.id,
          payload: updatedEntry.toJson(),
          deleted: false,
        ));
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

  Future<void> _unlinkPurgedBirthdays(Set<String> birthdayIds) async {
    if (birthdayIds.isEmpty) return;
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[];

    for (var i = 0; i < people.length; i++) {
      final person = people[i];
      if (person.birthdayId == null ||
          !birthdayIds.contains(person.birthdayId)) {
        continue;
      }
      final updated = person.copyWith(clearBirthday: true);
      people[i] = updated;
      mutations.add((
        type: 'person',
        id: updated.id,
        payload: updated.toJson(),
        deleted: false,
      ));
    }

    for (var i = 0; i < trash.length; i++) {
      final entry = trash[i];
      if (entry.kind != TrashEntityKind.person) continue;
      final person = PersonEntry.fromJson(entry.payload);
      if (person.birthdayId == null ||
          !birthdayIds.contains(person.birthdayId)) {
        continue;
      }
      final updatedEntry = entry.copyWith(
        payload: person.copyWith(clearBirthday: true).toJson(),
      );
      trash[i] = updatedEntry;
      mutations.add((
        type: 'trash',
        id: updatedEntry.id,
        payload: updatedEntry.toJson(),
        deleted: false,
      ));
    }

    if (mutations.isNotEmpty) {
      await _persistEntityMutations(
        mutations,
        createAutoSnapshot: false,
      );
      _notifyPlanningChanged();
    }
  }
}
