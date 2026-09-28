part of '../main.dart';

class PlaceEntry {
  final String id;
  final String name;
  final String category;
  final String address;
  final String note;
  final bool favorite;

  const PlaceEntry({
    required this.id,
    required this.name,
    this.category = '',
    this.address = '',
    this.note = '',
    this.favorite = false,
  });

  PlaceEntry copyWith({
    String? name,
    String? category,
    String? address,
    String? note,
    bool? favorite,
  }) =>
      PlaceEntry(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        address: address ?? this.address,
        note: note ?? this.note,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'address': address,
        'note': note,
        'favorite': favorite,
      };

  factory PlaceEntry.fromJson(Map<String, dynamic> json) => PlaceEntry(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        address: json['address'] as String? ?? '',
        note: json['note'] as String? ?? '',
        favorite: json['favorite'] as bool? ?? false,
      );
}

extension AgendaStorePlaces on AgendaStore {
  PlaceEntry? placeById(String id) {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  PlaceEntry? trashedPlaceById(String id) {
    for (final entry in trash) {
      if (entry.kind != TrashEntityKind.place || entry.entityId != id) continue;
      try {
        return PlaceEntry.fromJson(entry.payload);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<PlaceEntry> placesForIds(Iterable<String> ids) {
    final wanted = ids.toSet();
    final result = places.where((place) => wanted.contains(place.id)).toList()
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return result;
  }

  List<DiaryBlockReference> memoriesForPlace(String placeId) =>
      memoryRecords(includeArchived: true)
          .where((reference) => reference.block.placeIds.contains(placeId))
          .toList();

  int placeMemoryCount(String placeId) => memoriesForPlace(placeId).length;

  DateTime? lastMemoryDateForPlace(String placeId) {
    final memories = memoriesForPlace(placeId);
    return memories.isEmpty ? null : memories.first.date;
  }

  Future<void> savePlace(PlaceEntry place) async {
    final name = place.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(place.name, 'name', 'Il nome è obbligatorio');
    }
    final normalized = place.copyWith(
      name: name,
      category: place.category.trim(),
      address: place.address.trim(),
      note: place.note.trim(),
    );
    final index = places.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      places.add(normalized);
    } else {
      places[index] = normalized;
    }
    await _persistEntityMutation(
      type: 'place',
      id: normalized.id,
      payload: normalized.toJson(),
    );
    _notifyPlanningChanged();
  }

  Future<void> tagDiaryBlockPlaces(
    DateTime date,
    String blockId,
    Iterable<String> placeIds,
  ) async {
    final key = AgendaStore.dateKey(date);
    final current = journals[key];
    if (current == null) return;
    final index = current.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return;

    final existingIds = current.blocks[index].placeIds.toSet();
    final validIds = <String>[];
    for (final raw in placeIds) {
      final id = raw.trim();
      if (id.isEmpty || validIds.contains(id)) continue;
      final isLive = places.any((place) => place.id == id);
      final isRecoverableExisting =
          existingIds.contains(id) && trashedPlaceById(id) != null;
      if (isLive || isRecoverableExisting) validIds.add(id);
    }

    final blocks = [...current.blocks];
    blocks[index] = blocks[index].copyWith(placeIds: validIds);
    await saveJournal(date, current.copyWith(blocks: blocks));
  }

  Future<void> _unlinkPurgedPlaces(Set<String> placeIds) async {
    if (placeIds.isEmpty) return;
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
        if (!block.placeIds.any(placeIds.contains)) return block;
        changed = true;
        return block.copyWith(
          placeIds: block.placeIds.where((id) => !placeIds.contains(id)).toList(),
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
        try {
          final block = DiaryBlock.fromJson(entry.payload);
          if (!block.placeIds.any(placeIds.contains)) continue;
          final updated = entry.copyWith(
            payload: block.copyWith(
              placeIds:
                  block.placeIds.where((id) => !placeIds.contains(id)).toList(),
            ).toLocalJson(),
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
            if (!block.placeIds.any(placeIds.contains)) return block;
            changed = true;
            return block.copyWith(
              placeIds:
                  block.placeIds.where((id) => !placeIds.contains(id)).toList(),
            );
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
      await _persistEntityMutations(mutations, createAutoSnapshot: false);
      _notifyJournalChanged();
    }
  }
}

Future<List<String>?> showPlacesPicker(
  BuildContext context,
  AgendaStore store, {
  Iterable<String> initialIds = const [],
}) async {
  final initial = initialIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  final selected = {...initial};
  final liveIds = store.places.map((place) => place.id).toSet();
  final recoverable = initial
      .where((id) => !liveIds.contains(id))
      .map(store.trashedPlaceById)
      .whereType<PlaceEntry>()
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return showModalBottomSheet<List<String>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final places = [...store.places]
          ..sort((a, b) {
            if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.place_outlined),
                  title: Text('Collega luoghi'),
                  subtitle: Text(
                    'I luoghi restano dati privati del diario.',
                  ),
                ),
                Expanded(
                  child: places.isEmpty && recoverable.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: Text(
                              'Non hai ancora salvato luoghi. Puoi crearli dalla Cattura veloce.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final place in recoverable)
                              CheckboxListTile(
                                value: selected.contains(place.id),
                                title: Text(place.name),
                                subtitle: const Text(
                                  'Nel Cestino · collegamento recuperabile',
                                ),
                                secondary: const Icon(
                                  Icons.restore_from_trash_outlined,
                                ),
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selected.add(place.id);
                                    } else {
                                      selected.remove(place.id);
                                    }
                                  });
                                },
                              ),
                            for (final place in places)
                              CheckboxListTile(
                                value: selected.contains(place.id),
                                title: Text(place.name),
                                subtitle: [
                                  place.category,
                                  place.address,
                                ].where((value) => value.trim().isNotEmpty).isEmpty
                                    ? null
                                    : Text(
                                        [place.category, place.address]
                                            .where(
                                              (value) =>
                                                  value.trim().isNotEmpty,
                                            )
                                            .join(' · '),
                                      ),
                                secondary: Icon(
                                  place.favorite
                                      ? Icons.star
                                      : Icons.place_outlined,
                                ),
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selected.add(place.id);
                                    } else {
                                      selected.remove(place.id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Annulla'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, selected.toList()),
                        child: const Text('Salva'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
