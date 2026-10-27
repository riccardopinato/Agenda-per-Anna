part of '../main.dart';

enum MemoryLifeThreadKind { person, place, tag }

DiaryBlockType? _memoryCollectionTypeFromName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final value in DiaryBlockType.values) {
    if (value.name == name) return value;
  }
  return null;
}

class MemoryCollectionDefinition {
  final String id;
  final String name;
  final String? personId;
  final String? place;
  final String? tag;
  final DiaryBlockType? type;
  final int? year;

  const MemoryCollectionDefinition({
    required this.id,
    required this.name,
    this.personId,
    this.place,
    this.tag,
    this.type,
    this.year,
  });

  bool get hasFilter =>
      (personId?.trim().isNotEmpty ?? false) ||
      (place?.trim().isNotEmpty ?? false) ||
      (tag?.trim().isNotEmpty ?? false) ||
      type != null ||
      year != null;

  bool matches(DiaryBlockReference reference) {
    final block = reference.block;
    if (personId != null &&
        personId!.isNotEmpty &&
        !block.personIds.contains(personId)) {
      return false;
    }
    if (place != null && place!.trim().isNotEmpty) {
      final wanted = place!.trim().toLowerCase();
      if (!block.places.any((candidate) => candidate.normalizedName == wanted)) {
        return false;
      }
    }
    if (tag != null && tag!.trim().isNotEmpty) {
      final wanted = tag!.trim().toLowerCase();
      if (!block.tags.any((candidate) => candidate.trim().toLowerCase() == wanted)) {
        return false;
      }
    }
    if (type != null && block.type != type) return false;
    if (year != null && reference.date.year != year) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'personId': personId,
        'place': place,
        'tag': tag,
        'type': type?.name,
        'year': year,
      };

  factory MemoryCollectionDefinition.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString();
    return MemoryCollectionDefinition(
      id: (json['id']?.toString() ?? '').trim(),
      name: (json['name']?.toString() ?? '').trim(),
      personId: (json['personId']?.toString().trim().isEmpty ?? true)
          ? null
          : json['personId'].toString().trim(),
      place: (json['place']?.toString().trim().isEmpty ?? true)
          ? null
          : json['place'].toString().trim(),
      tag: (json['tag']?.toString().trim().isEmpty ?? true)
          ? null
          : json['tag'].toString().trim(),
      type: _memoryCollectionTypeFromName(rawType),
      year: (json['year'] as num?)?.toInt(),
    );
  }
}

class MemoryLifeThread {
  final MemoryLifeThreadKind kind;
  final String id;
  final String label;
  final List<DiaryBlockReference> memories;

  const MemoryLifeThread({
    required this.kind,
    required this.id,
    required this.label,
    required this.memories,
  });

  int get count => memories.length;
  DiaryBlockReference get latest => memories.first;
}

extension AgendaStoreMemoryCollections on AgendaStore {
  List<DiaryBlockReference> memoryCollectionReferences(
    MemoryCollectionDefinition definition,
  ) =>
      memoryReferences()
          .where(definition.matches)
          .toList(growable: false);

  List<MemoryLifeThread> _memoryLifeThreads({int? limit}) {
    final references = memoryReferences();
    final buckets = <String, List<DiaryBlockReference>>{};
    final metadata = <String, ({MemoryLifeThreadKind kind, String label})>{};

    void add(
      MemoryLifeThreadKind kind,
      String id,
      String label,
      DiaryBlockReference reference,
    ) {
      final normalizedId = id.trim().toLowerCase();
      final normalizedLabel = label.trim();
      if (normalizedId.isEmpty || normalizedLabel.isEmpty) return;
      final key = '${kind.name}:$normalizedId';
      final bucket = buckets.putIfAbsent(key, () => <DiaryBlockReference>[]);
      if (bucket.any((candidate) => candidate.block.id == reference.block.id)) {
        return;
      }
      bucket.add(reference);
      metadata.putIfAbsent(
        key,
        () => (kind: kind, label: normalizedLabel),
      );
    }

    for (final reference in references) {
      for (final personId in reference.block.personIds.toSet()) {
        final matches = people.where((person) => person.id == personId);
        if (matches.isEmpty) continue;
        add(
          MemoryLifeThreadKind.person,
          personId,
          matches.first.name,
          reference,
        );
      }
      for (final place in reference.block.places) {
        add(
          MemoryLifeThreadKind.place,
          place.normalizedName,
          place.name,
          reference,
        );
      }
      for (final tag in reference.block.tags) {
        add(
          MemoryLifeThreadKind.tag,
          tag,
          tag.startsWith('#') ? tag : '#$tag',
          reference,
        );
      }
    }

    final threads = <MemoryLifeThread>[];
    for (final entry in buckets.entries) {
      if (entry.value.length < 2) continue;
      final sorted = [...entry.value]
        ..sort((a, b) {
          final date = b.date.compareTo(a.date);
          if (date != 0) return date;
          return b.block.createdAt.compareTo(a.block.createdAt);
        });
      final info = metadata[entry.key]!;
      threads.add(
        MemoryLifeThread(
          kind: info.kind,
          id: entry.key,
          label: info.label,
          memories: List.unmodifiable(sorted),
        ),
      );
    }
    threads.sort((a, b) {
      final count = b.count.compareTo(a.count);
      if (count != 0) return count;
      final recent = b.latest.date.compareTo(a.latest.date);
      if (recent != 0) return recent;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    final visible = limit == null ? threads : threads.take(limit);
    return List.unmodifiable(visible);
  }

  List<MemoryLifeThread> memoryLifeThreads() =>
      _memoryLifeThreads(limit: 24);

  MemoryLifeThread? memoryLifeThreadById(String id) {
    final wanted = id.trim();
    if (wanted.isEmpty) return null;
    for (final thread in _memoryLifeThreads()) {
      if (thread.id == wanted) return thread;
    }
    return null;
  }

  Future<void> saveMemoryCollection(
    MemoryCollectionDefinition definition,
  ) async {
    final normalized = MemoryCollectionDefinition(
      id: definition.id.trim().isEmpty ? const Uuid().v4() : definition.id.trim(),
      name: definition.name.trim(),
      personId: definition.personId?.trim(),
      place: definition.place?.trim(),
      tag: definition.tag?.trim(),
      type: definition.type,
      year: definition.year,
    );
    if (normalized.name.isEmpty) {
      throw const FormatException('memory_collection_name_required');
    }
    if (!normalized.hasFilter) {
      throw const FormatException('memory_collection_filter_required');
    }

    final next = [...preferences.memoryCollections];
    final index = next.indexWhere((entry) => entry.id == normalized.id);
    if (index < 0) {
      if (next.length >= 24) {
        throw const FormatException('memory_collection_limit_reached');
      }
      next.add(normalized);
    } else {
      next[index] = normalized;
    }
    await savePreferences(
      preferences.copyWith(memoryCollections: List.unmodifiable(next)),
    );
  }

  Future<void> deleteMemoryCollection(String id) async {
    final next = preferences.memoryCollections
        .where((entry) => entry.id != id)
        .toList(growable: false);
    await savePreferences(
      preferences.copyWith(memoryCollections: next),
    );
  }
}

extension AnnaStringsV105B3 on AnnaStrings {
  String get v105Collections => _pick(
        en: 'Collections',
        it: 'Collezioni',
        es: 'Colecciones',
        fr: 'Collections',
        pt: 'Coleções',
      );

  String get v105LifeThreads => _pick(
        en: 'Life Threads',
        it: 'Fili della vita',
        es: 'Hilos de vida',
        fr: 'Fils de vie',
        pt: 'Fios da vida',
      );

  String get v105CollectionsIntro => _pick(
        en: 'Save filters, not copies. Results always come from your current diary.',
        it: 'Salva filtri, non copie. I risultati arrivano sempre dal diario corrente.',
        es: 'Guarda filtros, no copias. Los resultados siempre vienen del diario actual.',
        fr: 'Enregistre des filtres, pas des copies. Les résultats viennent toujours du journal actuel.',
        pt: 'Guarda filtros, não cópias. Os resultados vêm sempre do diário atual.',
      );

  String get v105LifeThreadsIntro => _pick(
        en: 'Recurring people, places and tags become derived stories automatically.',
        it: 'Persone, luoghi e tag ricorrenti diventano automaticamente storie derivate.',
        es: 'Personas, lugares y etiquetas recurrentes se convierten automáticamente en historias derivadas.',
        fr: 'Les personnes, lieux et tags récurrents deviennent automatiquement des histoires dérivées.',
        pt: 'Pessoas, lugares e etiquetas recorrentes tornam-se automaticamente histórias derivadas.',
      );

  String get v105NewCollection => _pick(
        en: 'New collection',
        it: 'Nuova collezione',
        es: 'Nueva colección',
        fr: 'Nouvelle collection',
        pt: 'Nova coleção',
      );

  String get v105CollectionName => _pick(
        en: 'Collection name',
        it: 'Nome collezione',
        es: 'Nombre de la colección',
        fr: 'Nom de la collection',
        pt: 'Nome da coleção',
      );

  String get v105AnyPerson => _pick(
        en: 'Any person',
        it: 'Qualsiasi persona',
        es: 'Cualquier persona',
        fr: 'Toute personne',
        pt: 'Qualquer pessoa',
      );

  String get v105AnyPlace => _pick(
        en: 'Any place',
        it: 'Qualsiasi luogo',
        es: 'Cualquier lugar',
        fr: 'Tout lieu',
        pt: 'Qualquer lugar',
      );

  String get v105AnyType => _pick(
        en: 'Any type',
        it: 'Qualsiasi tipo',
        es: 'Cualquier tipo',
        fr: 'Tout type',
        pt: 'Qualquer tipo',
      );

  String get v105OptionalTag => _pick(
        en: 'Tag (optional)',
        it: 'Tag (opzionale)',
        es: 'Etiqueta (opcional)',
        fr: 'Tag (facultatif)',
        pt: 'Etiqueta (opcional)',
      );

  String get v105OptionalYear => _pick(
        en: 'Year (optional)',
        it: 'Anno (opzionale)',
        es: 'Año (opcional)',
        fr: 'Année (facultatif)',
        pt: 'Ano (opcional)',
      );

  String get v105ChooseFilter => _pick(
        en: 'Choose at least one filter.',
        it: 'Scegli almeno un filtro.',
        es: 'Elige al menos un filtro.',
        fr: 'Choisis au moins un filtre.',
        pt: 'Escolhe pelo menos um filtro.',
      );

  String get v105InvalidYear => _pick(
        en: 'Enter a valid whole year.',
        it: 'Inserisci un anno intero valido.',
        es: 'Introduce un año entero válido.',
        fr: 'Saisis une année entière valide.',
        pt: 'Introduz um ano inteiro válido.',
      );

  String get v105NoCollections => _pick(
        en: 'No saved collections yet.',
        it: 'Nessuna collezione salvata.',
        es: 'Aún no hay colecciones guardadas.',
        fr: 'Aucune collection enregistrée.',
        pt: 'Ainda não há coleções guardadas.',
      );

  String get v105NoThreads => _pick(
        en: 'Life Threads appear when a person, place or tag returns in at least two memories.',
        it: 'I Fili della vita compaiono quando una persona, un luogo o un tag ricorre in almeno due ricordi.',
        es: 'Los Hilos de vida aparecen cuando una persona, lugar o etiqueta vuelve en al menos dos recuerdos.',
        fr: 'Les Fils de vie apparaissent quand une personne, un lieu ou un tag revient dans au moins deux souvenirs.',
        pt: 'Os Fios da vida aparecem quando uma pessoa, lugar ou etiqueta regressa em pelo menos duas memórias.',
      );

  String v105MemoryCount(int count) => _pick(
        en: '$count memories',
        it: '$count ricordi',
        es: '$count recuerdos',
        fr: '$count souvenirs',
        pt: '$count memórias',
      );
}
