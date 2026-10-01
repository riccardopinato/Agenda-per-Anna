part of '../main.dart';

const String lifeBridgeProtocolVersion = '1.0';
const String _lifeBridgeLinksPrefix = 'life_bridge_links_v1:';
const String _lifeBridgeHistoryPrefix = 'life_bridge_history_v1:';

enum LifeBridgeTransferMode { copy, link }

enum LifeBridgeLinkStatus { active, sourceUnavailable, unlinked }

class LifeBridgeSource {
  final String appId;
  final String objectId;
  final String? deepLink;
  final String? revision;

  const LifeBridgeSource({
    required this.appId,
    required this.objectId,
    this.deepLink,
    this.revision,
  });

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'objectId': objectId,
        if (deepLink != null && deepLink!.trim().isNotEmpty) 'deepLink': deepLink,
        if (revision != null && revision!.trim().isNotEmpty) 'revision': revision,
      };

  factory LifeBridgeSource.fromJson(Map<String, dynamic> json) {
    final appId = json['appId']?.toString().trim() ?? '';
    final objectId = json['objectId']?.toString().trim() ?? '';
    if (appId.isEmpty || objectId.isEmpty) {
      throw const FormatException('Life Bridge source is incomplete.');
    }
    return LifeBridgeSource(
      appId: appId,
      objectId: objectId,
      deepLink: _nullableTrimmed(json['deepLink']),
      revision: _nullableTrimmed(json['revision']),
    );
  }
}

class LifeBridgeLocation {
  final String name;
  final double? latitude;
  final double? longitude;

  const LifeBridgeLocation({
    required this.name,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  factory LifeBridgeLocation.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const FormatException('Life Bridge location requires a name.');
    }
    return LifeBridgeLocation(
      name: name,
      latitude: number(json['latitude']),
      longitude: number(json['longitude']),
    );
  }
}

class LifeBridgePayload {
  static const Set<String> annaSupportedObjectTypes = {
    'moment',
    'travel_memory',
    'journey',
    'photo',
    'place',
    'event',
  };

  final String protocolVersion;
  final String bridgeId;
  final LifeBridgeSource source;
  final String objectType;
  final LifeBridgeTransferMode transferMode;
  final String title;
  final String text;
  final DateTime occurredAt;
  final LifeBridgeLocation? location;
  final List<Map<String, dynamic>> media;
  final List<String> people;
  final List<String> tags;
  final Map<String, dynamic> extensions;
  final DateTime exportedAt;

  const LifeBridgePayload({
    this.protocolVersion = lifeBridgeProtocolVersion,
    required this.bridgeId,
    required this.source,
    required this.objectType,
    required this.transferMode,
    required this.title,
    required this.text,
    required this.occurredAt,
    this.location,
    this.media = const [],
    this.people = const [],
    this.tags = const [],
    this.extensions = const {},
    required this.exportedAt,
  });

  bool get supportedByAnna =>
      annaSupportedObjectTypes.contains(objectType.trim().toLowerCase());

  int get protocolMajor =>
      int.tryParse(protocolVersion.split('.').first.trim()) ?? -1;

  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'bridgeId': bridgeId,
        'source': source.toJson(),
        'objectType': objectType,
        'transferMode': transferMode.name,
        'title': title,
        'text': text,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (location != null) 'location': location!.toJson(),
        'media': media,
        'people': people,
        'tags': tags,
        if (extensions.isNotEmpty) 'extensions': extensions,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory LifeBridgePayload.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Life Bridge payload must be a JSON object.');
    }
    return LifeBridgePayload.fromJson(Map<String, dynamic>.from(decoded));
  }

  factory LifeBridgePayload.fromJson(Map<String, dynamic> json) {
    final protocolVersion =
        json['protocolVersion']?.toString().trim() ?? lifeBridgeProtocolVersion;
    final major = int.tryParse(protocolVersion.split('.').first.trim());
    if (major != 1) {
      throw FormatException(
        'Unsupported Life Bridge protocol major: $protocolVersion',
      );
    }

    final bridgeId = json['bridgeId']?.toString().trim() ?? '';
    if (bridgeId.isEmpty) {
      throw const FormatException('Life Bridge payload requires bridgeId.');
    }

    final rawSource = json['source'];
    if (rawSource is! Map) {
      throw const FormatException('Life Bridge payload requires source.');
    }

    final objectType = json['objectType']?.toString().trim().toLowerCase() ?? '';
    if (objectType.isEmpty) {
      throw const FormatException('Life Bridge payload requires objectType.');
    }

    final transferWire =
        json['transferMode']?.toString().trim().toLowerCase() ?? 'copy';
    final transferMode = switch (transferWire) {
      'copy' => LifeBridgeTransferMode.copy,
      'link' => LifeBridgeTransferMode.link,
      _ => throw FormatException(
          'Unsupported Life Bridge transferMode: $transferWire',
        ),
    };

    final occurredAt =
        DateTime.tryParse(json['occurredAt']?.toString() ?? '')?.toLocal();
    if (occurredAt == null) {
      throw const FormatException('Life Bridge payload requires occurredAt.');
    }

    final exportedAt =
        DateTime.tryParse(json['exportedAt']?.toString() ?? '')?.toUtc();
    if (exportedAt == null) {
      throw const FormatException('Life Bridge payload requires exportedAt.');
    }

    LifeBridgeLocation? location;
    final rawLocation = json['location'];
    if (rawLocation is Map) {
      location =
          LifeBridgeLocation.fromJson(Map<String, dynamic>.from(rawLocation));
    }

    final media = <Map<String, dynamic>>[];
    for (final item in (json['media'] as List? ?? const [])) {
      if (item is Map) {
        media.add(Map<String, dynamic>.from(item));
      }
    }

    final people = _normalizedStringList(json['people']);
    final tags = _normalizedStringList(json['tags']);
    final rawExtensions = json['extensions'];
    final extensions = rawExtensions is Map
        ? Map<String, dynamic>.from(rawExtensions)
        : <String, dynamic>{};

    return LifeBridgePayload(
      protocolVersion: protocolVersion,
      bridgeId: bridgeId,
      source: LifeBridgeSource.fromJson(
        Map<String, dynamic>.from(rawSource),
      ),
      objectType: objectType,
      transferMode: transferMode,
      title: json['title']?.toString().trim() ?? '',
      text: json['text']?.toString().trim() ?? '',
      occurredAt: occurredAt,
      location: location,
      media: List.unmodifiable(media),
      people: List.unmodifiable(people),
      tags: List.unmodifiable(tags),
      extensions: Map.unmodifiable(extensions),
      exportedAt: exportedAt,
    );
  }
}

class LifeBridgeImportRecord {
  final String id;
  final String bridgeId;
  final String sourceAppId;
  final String objectType;
  final LifeBridgeTransferMode transferMode;
  final String destinationType;
  final String destinationId;
  final DateTime importedAt;

  const LifeBridgeImportRecord({
    required this.id,
    required this.bridgeId,
    required this.sourceAppId,
    required this.objectType,
    required this.transferMode,
    required this.destinationType,
    required this.destinationId,
    required this.importedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bridgeId': bridgeId,
        'sourceAppId': sourceAppId,
        'objectType': objectType,
        'transferMode': transferMode.name,
        'destinationType': destinationType,
        'destinationId': destinationId,
        'importedAt': importedAt.toUtc().toIso8601String(),
      };

  factory LifeBridgeImportRecord.fromJson(Map<String, dynamic> json) {
    final mode = json['transferMode']?.toString() == 'link'
        ? LifeBridgeTransferMode.link
        : LifeBridgeTransferMode.copy;
    return LifeBridgeImportRecord(
      id: json['id']?.toString() ?? const Uuid().v4(),
      bridgeId: json['bridgeId']?.toString() ?? '',
      sourceAppId: json['sourceAppId']?.toString() ?? '',
      objectType: json['objectType']?.toString() ?? '',
      transferMode: mode,
      destinationType: json['destinationType']?.toString() ?? '',
      destinationId: json['destinationId']?.toString() ?? '',
      importedAt:
          DateTime.tryParse(json['importedAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

class LifeBridgeLinkRecord {
  final String id;
  final LifeBridgeSource source;
  final String localObjectType;
  final String localObjectId;
  final LifeBridgeLinkStatus status;
  final Map<String, dynamic> cachedPayload;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LifeBridgeLinkRecord({
    required this.id,
    required this.source,
    required this.localObjectType,
    required this.localObjectId,
    required this.status,
    required this.cachedPayload,
    required this.createdAt,
    required this.updatedAt,
  });

  LifeBridgeLinkRecord copyWith({
    LifeBridgeLinkStatus? status,
    Map<String, dynamic>? cachedPayload,
    DateTime? updatedAt,
  }) =>
      LifeBridgeLinkRecord(
        id: id,
        source: source,
        localObjectType: localObjectType,
        localObjectId: localObjectId,
        status: status ?? this.status,
        cachedPayload: cachedPayload ?? this.cachedPayload,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.toJson(),
        'localObjectType': localObjectType,
        'localObjectId': localObjectId,
        'status': status.name,
        'cachedPayload': cachedPayload,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory LifeBridgeLinkRecord.fromJson(Map<String, dynamic> json) {
    final rawSource = json['source'];
    final rawPayload = json['cachedPayload'];
    return LifeBridgeLinkRecord(
      id: json['id']?.toString() ?? const Uuid().v4(),
      source: LifeBridgeSource.fromJson(
        rawSource is Map
            ? Map<String, dynamic>.from(rawSource)
            : <String, dynamic>{},
      ),
      localObjectType: json['localObjectType']?.toString() ?? '',
      localObjectId: json['localObjectId']?.toString() ?? '',
      status: LifeBridgeLinkStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => LifeBridgeLinkStatus.active,
      ),
      cachedPayload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : <String, dynamic>{},
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

class LifeBridgeState {
  final List<LifeBridgeLinkRecord> links;
  final List<LifeBridgeImportRecord> history;

  const LifeBridgeState({
    this.links = const [],
    this.history = const [],
  });

  List<LifeBridgeLinkRecord> get activeLinks => links
      .where((link) => link.status != LifeBridgeLinkStatus.unlinked)
      .toList(growable: false);
}

enum LifeBridgeImportOutcome { imported, duplicate, unsupported }

class LifeBridgeImportResult {
  final LifeBridgeImportOutcome outcome;
  final String? destinationType;
  final String? destinationId;
  final LifeBridgeImportRecord? record;

  const LifeBridgeImportResult({
    required this.outcome,
    this.destinationType,
    this.destinationId,
    this.record,
  });
}

String? _nullableTrimmed(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _normalizedStringList(dynamic raw) {
  final values = <String>[];
  final seen = <String>{};
  for (final value in (raw as List? ?? const [])) {
    final text = value.toString().trim();
    if (text.isEmpty) continue;
    final key = text.toLowerCase();
    if (seen.add(key)) values.add(text);
  }
  return values;
}

String _lifeBridgeScopeKey(AgendaStore store, String prefix) =>
    '$prefix${store._entityScopeToken(store.activeAccountId)}';

String _lifeBridgeNoteText(LifeBridgePayload payload) {
  final pieces = <String>[];
  if (payload.title.trim().isNotEmpty) pieces.add(payload.title.trim());
  if (payload.text.trim().isNotEmpty &&
      payload.text.trim() != payload.title.trim()) {
    pieces.add(payload.text.trim());
  }
  if (payload.location != null &&
      payload.location!.name.trim().isNotEmpty &&
      !pieces.any(
        (piece) =>
            piece.toLowerCase().contains(payload.location!.name.toLowerCase()),
      )) {
    pieces.add('📍 ${payload.location!.name}');
  }
  return pieces.join('\n\n').trim();
}

extension LifeBridgeAgendaStore on AgendaStore {
  Future<LifeBridgeState> loadLifeBridgeState() async {
    final prefs = await _localState();
    final linksKey = _lifeBridgeScopeKey(this, _lifeBridgeLinksPrefix);
    final historyKey = _lifeBridgeScopeKey(this, _lifeBridgeHistoryPrefix);

    final links = <LifeBridgeLinkRecord>[];
    final rawLinks = prefs.getString(linksKey);
    if (rawLinks != null) {
      try {
        final decoded = jsonDecode(rawLinks);
        for (final item in (decoded as List? ?? const [])) {
          if (item is! Map) continue;
          try {
            links.add(
              LifeBridgeLinkRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (_) {}
        }
      } catch (_) {}
    }

    final history = <LifeBridgeImportRecord>[];
    final rawHistory = prefs.getString(historyKey);
    if (rawHistory != null) {
      try {
        final decoded = jsonDecode(rawHistory);
        for (final item in (decoded as List? ?? const [])) {
          if (item is! Map) continue;
          try {
            final record = LifeBridgeImportRecord.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (record.bridgeId.isNotEmpty) history.add(record);
          } catch (_) {}
        }
      } catch (_) {}
    }

    links.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    history.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return LifeBridgeState(
      links: List.unmodifiable(links),
      history: List.unmodifiable(history),
    );
  }

  Future<void> _persistLifeBridgeState(LifeBridgeState state) async {
    final prefs = await _localState();
    final linksKey = _lifeBridgeScopeKey(this, _lifeBridgeLinksPrefix);
    final historyKey = _lifeBridgeScopeKey(this, _lifeBridgeHistoryPrefix);
    await prefs.writeBatch({
      linksKey: jsonEncode(state.links.map((item) => item.toJson()).toList()),
      historyKey:
          jsonEncode(state.history.map((item) => item.toJson()).toList()),
    });
  }

  Future<LifeBridgeImportResult> importLifeBridgePayload(
    LifeBridgePayload payload,
  ) async {
    if (payload.protocolMajor != 1 || !payload.supportedByAnna) {
      return const LifeBridgeImportResult(
        outcome: LifeBridgeImportOutcome.unsupported,
      );
    }

    final state = await loadLifeBridgeState();
    for (final existing in state.history) {
      if (existing.bridgeId == payload.bridgeId) {
        return LifeBridgeImportResult(
          outcome: LifeBridgeImportOutcome.duplicate,
          destinationType: existing.destinationType,
          destinationId: existing.destinationId,
          record: existing,
        );
      }
    }

    final destination = await _materializeLifeBridgePayload(payload);
    final now = DateTime.now();
    final record = LifeBridgeImportRecord(
      id: const Uuid().v4(),
      bridgeId: payload.bridgeId,
      sourceAppId: payload.source.appId,
      objectType: payload.objectType,
      transferMode: payload.transferMode,
      destinationType: destination.$1,
      destinationId: destination.$2,
      importedAt: now,
    );

    final nextLinks = [...state.links];
    if (payload.transferMode == LifeBridgeTransferMode.link) {
      nextLinks.insert(
        0,
        LifeBridgeLinkRecord(
          id: const Uuid().v4(),
          source: payload.source,
          localObjectType: destination.$1,
          localObjectId: destination.$2,
          status: LifeBridgeLinkStatus.active,
          cachedPayload: payload.toJson(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final nextHistory = [record, ...state.history];
    await _persistLifeBridgeState(
      LifeBridgeState(
        links: nextLinks,
        history: nextHistory,
      ),
    );

    return LifeBridgeImportResult(
      outcome: LifeBridgeImportOutcome.imported,
      destinationType: destination.$1,
      destinationId: destination.$2,
      record: record,
    );
  }

  Future<(String, String)> _materializeLifeBridgePayload(
    LifeBridgePayload payload,
  ) async {
    if (payload.objectType == 'event') {
      final occurred = payload.occurredAt.toLocal();
      final date = DateTime(occurred.year, occurred.month, occurred.day);
      final title = payload.title.trim().isEmpty
          ? payload.text.trim()
          : payload.title.trim();
      final item = AgendaItem(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Life Bridge' : title,
        note: _lifeBridgeNoteText(payload),
        date: date,
        type: ItemType.appointment,
        category: AgendaCategory.personal,
        start: TimeOfDay(hour: occurred.hour, minute: occurred.minute),
      );
      await upsert(item);
      return ('agenda_item', item.id);
    }

    final occurred = payload.occurredAt.toLocal();
    final day = DateTime(occurred.year, occurred.month, occurred.day);
    final current = journal(day);

    final matchedPersonIds = <String>[];
    for (final name in payload.people) {
      final normalized = name.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      for (final person in people) {
        if (person.name.trim().toLowerCase() == normalized) {
          if (!matchedPersonIds.contains(person.id)) {
            matchedPersonIds.add(person.id);
          }
          break;
        }
      }
    }

    final places = <DiaryPlaceReference>[];
    if (payload.location != null) {
      places.add(
        DiaryPlaceReference(
          name: payload.location!.name,
          latitude: payload.location!.latitude,
          longitude: payload.location!.longitude,
        ),
      );
    }

    final tags = <String>{
      ...payload.tags,
      'life-bridge',
      'source:${payload.source.appId}',
      'type:${payload.objectType}',
    }.where((tag) => tag.trim().isNotEmpty).toList(growable: false);

    final block = DiaryBlock(
      id: const Uuid().v4(),
      type: DiaryBlockType.note,
      createdAt: occurred,
      text: _lifeBridgeNoteText(payload),
      tags: tags,
      personIds: matchedPersonIds,
      places: places,
    );

    await saveJournal(
      day,
      current.copyWith(blocks: [...current.blocks, block]),
    );
    return ('diary_block', block.id);
  }

  LifeBridgePayload exportLifeBridgeDiaryBlock(
    DiaryBlock block, {
    LifeBridgeTransferMode transferMode = LifeBridgeTransferMode.copy,
  }) {
    final peopleNames = <String>[];
    for (final personId in block.personIds) {
      for (final person in people) {
        if (person.id == personId) {
          peopleNames.add(person.name);
          break;
        }
      }
    }

    final place = block.places.isEmpty
        ? null
        : LifeBridgeLocation(
            name: block.places.first.name,
            latitude: block.places.first.latitude,
            longitude: block.places.first.longitude,
          );

    final objectType =
        block.type == DiaryBlockType.photo ? 'photo' : 'moment';
    final mediaOmitted = block.hasPhotoMedia ||
        block.hasVoiceMedia ||
        block.type == DiaryBlockType.sketch;

    return LifeBridgePayload(
      bridgeId: const Uuid().v4(),
      source: LifeBridgeSource(
        appId: 'annas_diary',
        objectId: block.id,
        revision: block.createdAt.toUtc().toIso8601String(),
      ),
      objectType: objectType,
      transferMode: transferMode,
      title: _lifeBridgeTitleFromText(block.text),
      text: block.text,
      occurredAt: block.createdAt,
      location: place,
      people: peopleNames,
      tags: block.tags,
      extensions: mediaOmitted
          ? const {
              'annas_diary': {
                'mediaTransfer': 'omitted',
                'reason': 'explicit_binary_transfer_not_supported_in_v1',
              },
            }
          : const {},
      exportedAt: DateTime.now().toUtc(),
    );
  }

  LifeBridgePayload exportLifeBridgeAgendaItem(
    AgendaItem item, {
    LifeBridgeTransferMode transferMode = LifeBridgeTransferMode.copy,
  }) {
    final occurredAt = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      item.start?.hour ?? 0,
      item.start?.minute ?? 0,
    );

    return LifeBridgePayload(
      bridgeId: const Uuid().v4(),
      source: LifeBridgeSource(
        appId: 'annas_diary',
        objectId: item.id,
        revision: occurredAt.toUtc().toIso8601String(),
      ),
      objectType: 'event',
      transferMode: transferMode,
      title: item.title,
      text: item.note,
      occurredAt: occurredAt,
      tags: ['agenda', item.category.name],
      exportedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> markLifeBridgeSourceUnavailable(String linkId) async {
    final state = await loadLifeBridgeState();
    final now = DateTime.now();
    final next = state.links
        .map(
          (link) => link.id == linkId
              ? link.copyWith(
                  status: LifeBridgeLinkStatus.sourceUnavailable,
                  updatedAt: now,
                )
              : link,
        )
        .toList(growable: false);
    await _persistLifeBridgeState(
      LifeBridgeState(links: next, history: state.history),
    );
  }

  Future<void> unlinkLifeBridge(String linkId) async {
    final state = await loadLifeBridgeState();
    final now = DateTime.now();
    final next = state.links
        .map(
          (link) => link.id == linkId
              ? link.copyWith(
                  status: LifeBridgeLinkStatus.unlinked,
                  updatedAt: now,
                )
              : link,
        )
        .toList(growable: false);
    await _persistLifeBridgeState(
      LifeBridgeState(links: next, history: state.history),
    );
  }

  Future<void> convertLifeBridgeLinkToCopy(String linkId) async {
    await unlinkLifeBridge(linkId);
  }
}

String _lifeBridgeTitleFromText(String text) {
  final first = text
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => 'Memory');
  return first.length <= 80 ? first : '${first.substring(0, 77)}...';
}

extension LifeBridgeStrings on AnnaStrings {
  String get lifeEcosystemTitle => _pick(
        en: 'Life Ecosystem',
        it: 'Ecosistema vita',
        es: 'Ecosistema de vida',
        fr: 'Écosystème de vie',
        pt: 'Ecossistema de vida',
      );

  String get lifeEcosystemSubtitle => _pick(
        en: 'Connect memories and events without merging app databases.',
        it: 'Collega ricordi ed eventi senza fondere i database delle app.',
        es: 'Conecta recuerdos y eventos sin fusionar las bases de datos.',
        fr: 'Relie souvenirs et événements sans fusionner les bases de données.',
        pt: 'Liga memórias e eventos sem fundir as bases de dados.',
      );

  String get lifeBridgeImportHint => _pick(
        en: 'Paste JSON exported by a compatible app. Anna stores a canonical local copy or a linked snapshot according to the payload.',
        it: 'Incolla il JSON esportato da un’app compatibile. Anna salva una copia locale canonica o una snapshot collegata in base al payload.',
        es: 'Pega el JSON exportado por una app compatible. Anna guarda una copia local canónica o una instantánea enlazada según el payload.',
        fr: 'Colle le JSON exporté par une app compatible. Anna conserve une copie locale canonique ou un instantané lié selon le payload.',
        pt: 'Cola o JSON exportado por uma app compatível. Anna guarda uma cópia local canónica ou um snapshot ligado conforme o payload.',
      );

  String get lifeBridgePaste => _pick(
        en: 'Paste from clipboard',
        it: 'Incolla dagli appunti',
        es: 'Pegar desde el portapapeles',
        fr: 'Coller depuis le presse-papiers',
        pt: 'Colar da área de transferência',
      );

  String get lifeBridgeLinks => _pick(
        en: 'Linked items',
        it: 'Elementi collegati',
        es: 'Elementos enlazados',
        fr: 'Éléments liés',
        pt: 'Itens ligados',
      );

  String get lifeBridgeHistory => _pick(
        en: 'Import history',
        it: 'Cronologia importazioni',
        es: 'Historial de importaciones',
        fr: 'Historique des imports',
        pt: 'Histórico de importações',
      );

  String get lifeBridgeNoLinks => _pick(
        en: 'No linked items yet.',
        it: 'Nessun elemento collegato.',
        es: 'Aún no hay elementos enlazados.',
        fr: 'Aucun élément lié pour le moment.',
        pt: 'Ainda não existem itens ligados.',
      );

  String get lifeBridgeNoHistory => _pick(
        en: 'No imports yet.',
        it: 'Nessuna importazione.',
        es: 'Aún no hay importaciones.',
        fr: 'Aucun import pour le moment.',
        pt: 'Ainda não existem importações.',
      );

  String get lifeBridgeUnsupported => _pick(
        en: 'This Life Bridge payload is not supported by Anna v0.95.',
        it: 'Questo payload Life Bridge non è supportato da Anna v0.95.',
        es: 'Este payload Life Bridge no es compatible con Anna v0.95.',
        fr: 'Ce payload Life Bridge n’est pas pris en charge par Anna v0.95.',
        pt: 'Este payload Life Bridge não é suportado pela Anna v0.95.',
      );

  String get lifeBridgeInvalid => _pick(
        en: 'Invalid Life Bridge payload.',
        it: 'Payload Life Bridge non valido.',
        es: 'Payload Life Bridge no válido.',
        fr: 'Payload Life Bridge invalide.',
        pt: 'Payload Life Bridge inválido.',
      );

  String get lifeBridgeImported => _pick(
        en: 'Imported into Anna’s canonical data.',
        it: 'Importato nei dati canonici di Anna.',
        es: 'Importado a los datos canónicos de Anna.',
        fr: 'Importé dans les données canoniques d’Anna.',
        pt: 'Importado para os dados canónicos da Anna.',
      );

  String get lifeBridgeDuplicate => _pick(
        en: 'This bridge item was already imported.',
        it: 'Questo elemento Bridge era già stato importato.',
        es: 'Este elemento Bridge ya se había importado.',
        fr: 'Cet élément Bridge avait déjà été importé.',
        pt: 'Este item Bridge já tinha sido importado.',
      );

  String get lifeBridgeMarkUnavailable => _pick(
        en: 'Mark source unavailable',
        it: 'Segna sorgente non disponibile',
        es: 'Marcar origen no disponible',
        fr: 'Marquer la source indisponible',
        pt: 'Marcar origem indisponível',
      );

  String get lifeBridgeConvertCopy => _pick(
        en: 'Keep as independent copy',
        it: 'Mantieni come copia indipendente',
        es: 'Mantener como copia independiente',
        fr: 'Conserver comme copie indépendante',
        pt: 'Manter como cópia independente',
      );

  String get lifeBridgeUnlink => _pick(
        en: 'Unlink',
        it: 'Scollega',
        es: 'Desvincular',
        fr: 'Dissocier',
        pt: 'Desligar',
      );

  String get lifeBridgeSourceUnavailable => _pick(
        en: 'source unavailable',
        it: 'sorgente non disponibile',
        es: 'origen no disponible',
        fr: 'source indisponible',
        pt: 'origem indisponível',
      );
}

class LifeEcosystemScreen extends StatefulWidget {
  final AgendaStore store;

  const LifeEcosystemScreen({
    super.key,
    required this.store,
  });

  @override
  State<LifeEcosystemScreen> createState() => _LifeEcosystemScreenState();
}

class _LifeEcosystemScreenState extends State<LifeEcosystemScreen> {
  LifeBridgeState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final state = await widget.store.loadLifeBridgeState();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _importFromClipboard() async {
    final strings = AnnaStrings.of(context);
    final data = await Clipboard.getData('text/plain');
    final raw = data?.text?.trim() ?? '';
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.lifeBridgeInvalid)),
      );
      return;
    }

    try {
      final payload = LifeBridgePayload.decode(raw);
      final result = await widget.store.importLifeBridgePayload(payload);
      if (!mounted) return;
      final message = switch (result.outcome) {
        LifeBridgeImportOutcome.imported => strings.lifeBridgeImported,
        LifeBridgeImportOutcome.duplicate => strings.lifeBridgeDuplicate,
        LifeBridgeImportOutcome.unsupported => strings.lifeBridgeUnsupported,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.lifeBridgeInvalid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final state = _state ?? const LifeBridgeState();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.lifeEcosystemTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hub_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Life Bridge v1',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(strings.lifeEcosystemSubtitle),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _importFromClipboard,
                          icon: const Icon(Icons.content_paste_go_outlined),
                          label: Text(strings.lifeBridgePaste),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.lifeBridgeImportHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _LifeBridgeAppCard(
                  icon: Icons.auto_stories_outlined,
                  title: 'Anna\'s Diary',
                  subtitle: 'Life Bridge v1 · reference implementation',
                  active: true,
                ),
                const SizedBox(height: 10),
                const _LifeBridgeAppCard(
                  icon: Icons.travel_explore_outlined,
                  title: 'Wonderlog',
                  subtitle: 'First external integration target · adapter not implemented yet',
                  active: false,
                ),
                const SizedBox(height: 10),
                const _LifeBridgeAppCard(
                  icon: Icons.bedtime_outlined,
                  title: 'SleepMax',
                  subtitle: 'Life Bridge adapter not implemented yet',
                  active: false,
                ),
                const SizedBox(height: 10),
                const _LifeBridgeAppCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'CashMate',
                  subtitle: 'Life Bridge adapter not implemented yet',
                  active: false,
                ),
                const SizedBox(height: 24),
                Text(
                  strings.lifeBridgeLinks,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (state.activeLinks.isEmpty)
                  Text(strings.lifeBridgeNoLinks)
                else
                  ...state.activeLinks.map(
                    (link) => _LifeBridgeLinkTile(
                      link: link,
                      onUnavailable: () async {
                        await widget.store
                            .markLifeBridgeSourceUnavailable(link.id);
                        await _reload();
                      },
                      onConvertCopy: () async {
                        await widget.store
                            .convertLifeBridgeLinkToCopy(link.id);
                        await _reload();
                      },
                      onUnlink: () async {
                        await widget.store.unlinkLifeBridge(link.id);
                        await _reload();
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  strings.lifeBridgeHistory,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (state.history.isEmpty)
                  Text(strings.lifeBridgeNoHistory)
                else
                  ...state.history.take(30).map(
                        (record) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            record.transferMode == LifeBridgeTransferMode.link
                                ? Icons.link_outlined
                                : Icons.copy_all_outlined,
                          ),
                          title: Text(
                            '${record.sourceAppId} · ${record.objectType}',
                          ),
                          subtitle: Text(
                            '${record.destinationType} · '
                            '${DateFormat.yMd(AnnaStrings.intlLocale(context)).add_Hm().format(record.importedAt)}',
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

class _LifeBridgeAppCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;

  const _LifeBridgeAppCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          active ? Icons.check_circle_outline : Icons.schedule_outlined,
          color: active ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}

class _LifeBridgeLinkTile extends StatelessWidget {
  final LifeBridgeLinkRecord link;
  final Future<void> Function() onUnavailable;
  final Future<void> Function() onConvertCopy;
  final Future<void> Function() onUnlink;

  const _LifeBridgeLinkTile({
    required this.link,
    required this.onUnavailable,
    required this.onConvertCopy,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final payload = link.cachedPayload;
    final title = payload['title']?.toString().trim();
    final objectType = payload['objectType']?.toString() ?? link.localObjectType;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        link.status == LifeBridgeLinkStatus.sourceUnavailable
            ? Icons.link_off_outlined
            : Icons.link_outlined,
      ),
      title: Text(
        title == null || title.isEmpty
            ? '${link.source.appId} · $objectType'
            : title,
      ),
      subtitle: Text(
        link.status == LifeBridgeLinkStatus.sourceUnavailable
            ? '${link.source.appId} · ${strings.lifeBridgeSourceUnavailable}'
            : '${link.source.appId} · $objectType',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'unavailable') {
            unawaited(onUnavailable());
          } else if (value == 'copy') {
            unawaited(onConvertCopy());
          } else if (value == 'unlink') {
            unawaited(onUnlink());
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'unavailable',
            child: Text(strings.lifeBridgeMarkUnavailable),
          ),
          PopupMenuItem(
            value: 'copy',
            child: Text(strings.lifeBridgeConvertCopy),
          ),
          PopupMenuItem(
            value: 'unlink',
            child: Text(strings.lifeBridgeUnlink),
          ),
        ],
      ),
    );
  }
}
