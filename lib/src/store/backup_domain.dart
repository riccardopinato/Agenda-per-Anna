part of '../../main.dart';

/// Pure-ish backup/export domain used by [AgendaStore].
///
/// It intentionally receives the store facade instead of owning persistence:
/// account scope, transactions, restore rollback and cloud reconciliation stay
/// orchestrated by AgendaStore, while serialization and validation live here.
class _AgendaBackupDomain {
  const _AgendaBackupDomain();

  Map<String, dynamic> localDataPayload(AgendaStore store) => {
        'items': store.items.map((e) => e.toJson()).toList(),
        'journals':
            store.journals.map((k, v) => MapEntry(k, v.toLocalJson())),
        'months': store.months.map((k, v) => MapEntry(k, v.toJson())),
        'weeks': store.weeks.map((k, v) => MapEntry(k, v.toJson())),
        'habits': store.habits.map((e) => e.toJson()).toList(),
        'birthdays': store.birthdays.map((e) => e.toJson()).toList(),
        'people': store.people.map((e) => e.toJson()).toList(),
        'inbox': store.inbox.map((e) => e.toJson()).toList(),
        'shopping': store.shoppingItems.map((e) => e.toJson()).toList(),
        'workoutSessions':
            store.workoutSessions.map((e) => e.toJson()).toList(),
        'workoutPlans': store.workoutPlans.map((e) => e.toJson()).toList(),
        'trash': store.trash.map((e) => e.toJson()).toList(),
        'preferences': store.preferences.toJson(),
      };

  Future<Map<String, dynamic>> portableBackupDataPayload(
    AgendaStore store,
  ) async {
    final portableJournals = <String, dynamic>{};
    for (final entry in store.journals.entries) {
      portableJournals[entry.key] =
          await store._portableJournalJson(entry.value);
    }
    final portableTrash = <Map<String, dynamic>>[];
    for (final entry in store.trash) {
      portableTrash.add(await store._portableTrashJson(entry));
    }
    return {
      'items': store.items.map((e) => e.toJson()).toList(),
      'journals': portableJournals,
      'months': store.months.map((k, v) => MapEntry(k, v.toJson())),
      'weeks': store.weeks.map((k, v) => MapEntry(k, v.toJson())),
      'habits': store.habits.map((e) => e.toJson()).toList(),
      'birthdays': store.birthdays.map((e) => e.toJson()).toList(),
      'people': store.people.map((e) => e.toJson()).toList(),
      'inbox': store.inbox.map((e) => e.toJson()).toList(),
      'shopping': store.shoppingItems.map((e) => e.toJson()).toList(),
      'workoutSessions':
          store.workoutSessions.map((e) => e.toJson()).toList(),
      'workoutPlans': store.workoutPlans.map((e) => e.toJson()).toList(),
      'trash': portableTrash,
      'preferences': store.preferences.toJson(),
    };
  }

  Future<String> createBackupJson(AgendaStore store) async {
    final document = {
      'format': AgendaStore._backupFormat,
      'schemaVersion': AgendaStore._backupSchemaVersion,
      'appVersion': AgendaStore._appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': await portableBackupDataPayload(store),
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  Future<Uint8List> createBackupZip(AgendaStore store) async {
    final exportedAt = DateTime.now();
    final localData = localDataPayload(store);
    final referencedAssetIds = <String>{};
    store._collectAssetIdsFromJson(localData, referencedAssetIds);

    final media = <String, Uint8List>{};
    final manifestMedia = <Map<String, dynamic>>[];
    var mediaBytesTotal = 0;

    final sortedIds = referencedAssetIds.toList()..sort();
    for (final assetId in sortedIds) {
      final bytes = await MediaAssetStore.instance.read(assetId);
      if (bytes == null || bytes.isEmpty) {
        throw FormatException(
          'Media locale mancante nel backup: $assetId',
        );
      }
      mediaBytesTotal += bytes.lengthInBytes;
      if (mediaBytesTotal > BackupFileService.maxBackupMediaBytes) {
        throw const FormatException(
          'Il backup contiene troppi media per essere creato in sicurezza in memoria.',
        );
      }
      media[assetId] = bytes;
      manifestMedia.add({
        'assetId': assetId,
        'path': 'media/$assetId.bin',
        'size': bytes.lengthInBytes,
        'sha256': sha256.convert(bytes).toString(),
      });
    }

    final dataDocument = {
      'format': AgendaStore._backupFormat,
      'schemaVersion': AgendaStore._backupSchemaVersion,
      'appVersion': AgendaStore._appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'data': localData,
    };
    final dataJson =
        const JsonEncoder.withIndent('  ').convert(dataDocument);

    final manifest = {
      'format': AgendaStore._backupBundleFormat,
      'bundleVersion': AgendaStore._backupBundleVersion,
      'appVersion': AgendaStore._appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'dataFile': 'data.json',
      'mediaCount': manifestMedia.length,
      'media': manifestMedia,
      'dataSha256': sha256.convert(utf8.encode(dataJson)).toString(),
    };

    return BackupFileService.instance.buildZipBackup(
      manifestJson: const JsonEncoder.withIndent('  ').convert(manifest),
      dataJson: dataJson,
      media: media,
    );
  }

  DecodedZipBackup decodeAndValidateBackupZip(
    AgendaStore store,
    Uint8List bytes,
  ) {
    final decoded = BackupFileService.instance.decodeZipBackup(bytes);

    final manifestValue = jsonDecode(decoded.manifestJson);
    if (manifestValue is! Map) {
      throw const FormatException('Manifest backup non valido.');
    }
    final manifest = Map<String, dynamic>.from(manifestValue);
    if (manifest['format'] != AgendaStore._backupBundleFormat ||
        manifest['bundleVersion'] != AgendaStore._backupBundleVersion) {
      throw const FormatException('Formato ZIP del backup non supportato.');
    }

    final expectedDataHash = manifest['dataSha256']?.toString() ?? '';
    final actualDataHash =
        sha256.convert(utf8.encode(decoded.dataJson)).toString();
    if (expectedDataHash.isEmpty || expectedDataHash != actualDataHash) {
      throw const FormatException('Il file dati del backup non è integro.');
    }

    final rawMedia = manifest['media'];
    if (rawMedia is! List) {
      throw const FormatException('Indice media del backup non valido.');
    }

    final declaredIds = <String>{};
    for (final raw in rawMedia) {
      if (raw is! Map) {
        throw const FormatException('Indice media del backup non valido.');
      }
      final entry = Map<String, dynamic>.from(raw);
      final assetId = entry['assetId']?.toString() ?? '';
      final expectedSize = entry['size'];
      final expectedHash = entry['sha256']?.toString() ?? '';
      if (assetId.isEmpty ||
          expectedSize is! int ||
          expectedHash.isEmpty ||
          !declaredIds.add(assetId)) {
        throw const FormatException('Indice media del backup non valido.');
      }

      final mediaBytes = decoded.media[assetId];
      if (mediaBytes == null ||
          mediaBytes.lengthInBytes != expectedSize ||
          sha256.convert(mediaBytes).toString() != expectedHash) {
        throw FormatException(
          'Media del backup danneggiato o mancante: $assetId',
        );
      }
    }

    if (decoded.media.keys.any((assetId) => !declaredIds.contains(assetId))) {
      throw const FormatException('Il backup contiene media non dichiarati.');
    }

    inspectBackup(decoded.dataJson);
    return decoded;
  }

  BackupSummary inspectBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Il file non contiene un backup valido.');
    }

    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != AgendaStore._backupFormat) {
      throw const FormatException(
        'Questo file non appartiene ad Anna\'s Diary.',
      );
    }

    final schema = root['schemaVersion'];
    if (schema is! int ||
        schema > AgendaStore._backupSchemaVersion ||
        schema < 1) {
      throw const FormatException('Versione del backup non supportata.');
    }

    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('Il backup non contiene dati leggibili.');
    }

    final payload = Map<String, dynamic>.from(data);
    final exportedAt =
        DateTime.tryParse(root['exportedAt'] as String? ?? '') ??
            DateTime.now();

    return BackupSummary(
      exportedAt: exportedAt,
      itemCount: (payload['items'] as List? ?? const []).length,
      journalCount: (payload['journals'] as Map? ?? const {}).length,
      monthCount: (payload['months'] as Map? ?? const {}).length,
      weekCount: (payload['weeks'] as Map? ?? const {}).length,
      habitCount: (payload['habits'] as List? ?? const []).length,
      birthdayCount: (payload['birthdays'] as List? ?? const []).length,
      personCount: (payload['people'] as List? ?? const []).length,
      trashCount: (payload['trash'] as List? ?? const []).length,
    );
  }

  Future<Uint8List> createOpenLifeArchive(AgendaStore store) async {
    final exportedAt = DateTime.now();
    final raw = localDataPayload(store);
    final openData = <String, dynamic>{
      'items': raw['items'],
      'journals': raw['journals'],
      'months': raw['months'],
      'weeks': raw['weeks'],
      'habits': raw['habits'],
      'birthdays': raw['birthdays'],
      'people': raw['people'],
      'inbox': raw['inbox'],
      'shopping': raw['shopping'],
      'workoutSessions': raw['workoutSessions'],
      'workoutPlans': raw['workoutPlans'],
    };

    final referencedAssetIds = <String>{};
    store._collectAssetIdsFromJson(openData, referencedAssetIds);

    final files = <String, Uint8List>{};
    final mediaIndex = <Map<String, dynamic>>[];
    final mediaPaths = <String, String>{};

    for (final assetId in referencedAssetIds.toList()..sort()) {
      final bytes = await MediaAssetStore.instance.read(assetId);
      if (bytes == null || bytes.isEmpty) continue;
      final extension = _openArchiveMediaExtension(bytes);
      final path = 'media/$assetId.$extension';
      mediaPaths[assetId] = path;
      files[path] = bytes;
      mediaIndex.add({
        'assetId': assetId,
        'path': path,
        'size': bytes.lengthInBytes,
        'sha256': sha256.convert(bytes).toString(),
      });
    }

    final archiveDocument = {
      'format': 'annas_diary_open_life_archive',
      'version': 1,
      'appVersion': AgendaStore._appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'restoreBackup': false,
      'data': openData,
      'media': mediaIndex,
    };

    final intro = StringBuffer()
      ..writeln('ANNA\'S DIARY — OPEN LIFE ARCHIVE')
      ..writeln()
      ..writeln('Questa cartella ZIP è pensata per essere letta e riutilizzata')
      ..writeln('anche senza Anna\'s Diary. Non è un backup di ripristino.')
      ..writeln()
      ..writeln('This ZIP is designed to remain readable and reusable outside')
      ..writeln('Anna\'s Diary. It is not a restore backup.')
      ..writeln()
      ..writeln('Contenuti / Contents:')
      ..writeln('- life.txt: esportazione leggibile')
      ..writeln('- life.json: dati strutturati aperti')
      ..writeln('- years/: capitoli annuali Markdown')
      ..writeln('- media/: media originali disponibili')
      ..writeln()
      ..writeln('Esportato / Exported: ${exportedAt.toIso8601String()}');

    files['README.txt'] = Uint8List.fromList(utf8.encode(intro.toString()));
    files['life.txt'] = Uint8List.fromList(
      utf8.encode(createReadableExport(store)),
    );
    files['life.json'] = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(archiveDocument)),
    );

    final byYear = <int, List<DiaryBlockReference>>{};
    for (final reference
        in store.allDiaryBlockReferences(includeArchived: true)) {
      byYear.putIfAbsent(reference.date.year, () => []).add(reference);
    }

    final years = byYear.keys.toList()..sort();
    for (final year in years) {
      final records = byYear[year]!
        ..sort((a, b) {
          final dateOrder = a.date.compareTo(b.date);
          if (dateOrder != 0) return dateOrder;
          return a.block.createdAt.compareTo(b.block.createdAt);
        });
      final chapter = _openArchiveYearMarkdown(
        store,
        year,
        records,
        mediaPaths,
      );
      files['years/$year.md'] =
          Uint8List.fromList(utf8.encode(chapter));
    }

    return BackupFileService.instance.buildPortableArchive(files: files);
  }

  String _openArchiveMediaExtension(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'webp';
    }
    if (bytes.length >= 8 &&
        ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp') {
      return 'm4a';
    }
    if (bytes.length >= 4 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'OggS') {
      return 'ogg';
    }
    if (bytes.length >= 3 &&
        ascii.decode(bytes.sublist(0, 3), allowInvalid: true) == 'ID3') {
      return 'mp3';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return 'webm';
    }
    return 'bin';
  }

  String _openArchiveYearMarkdown(
    AgendaStore store,
    int year,
    List<DiaryBlockReference> records,
    Map<String, String> mediaPaths,
  ) {
    final buffer = StringBuffer()
      ..writeln('# $year')
      ..writeln()
      ..writeln('Anna\'s Diary — Open Life Archive')
      ..writeln();

    String? lastDay;
    for (final record in records) {
      final dayKey = AgendaStore.dateKey(record.date);
      if (dayKey != lastDay) {
        lastDay = dayKey;
        buffer
          ..writeln()
          ..writeln(
            '## ${DateFormat('d MMMM yyyy').format(record.date)}',
          )
          ..writeln();
      }

      final block = record.block;
      final typeLabel = switch (block.type) {
        DiaryBlockType.note => 'Nota / Note',
        DiaryBlockType.sketch => 'Sketch',
        DiaryBlockType.photo => 'Foto / Photo',
        DiaryBlockType.voice => 'Voce / Voice',
      };
      buffer.writeln(
        '### $typeLabel · ${DateFormat('HH:mm').format(block.createdAt)}'
        '${block.archived ? ' · archived' : ''}',
      );

      final text = block.text.trim();
      if (text.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln(text);
      }

      final sketchText = block.pages
          .expand((page) => page.textElements)
          .map((element) => element.text.trim())
          .where((value) => value.isNotEmpty)
          .join(' · ');
      if (sketchText.isNotEmpty) {
        buffer.writeln('- Sketch text: $sketchText');
      }

      final people = store.peopleForIds(block.personIds)
          .map((person) => person.name)
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false);
      if (people.isNotEmpty) {
        buffer.writeln('- People: ${people.join(', ')}');
      }
      if (block.places.isNotEmpty) {
        buffer.writeln(
          '- Places: ${block.places.map((place) => place.name).join(', ')}',
        );
      }
      if (block.tags.isNotEmpty) {
        buffer.writeln('- Tags: ${block.tags.join(', ')}');
      }
      if (block.mediaAssetId.isNotEmpty &&
          mediaPaths[block.mediaAssetId] case final path?) {
        buffer.writeln('- Media: ../$path');
      }
      if (block.mediaThumbnailAssetId.isNotEmpty &&
          mediaPaths[block.mediaThumbnailAssetId] case final path?) {
        buffer.writeln('- Thumbnail: ../$path');
      }
      buffer.writeln();
    }

    if (records.isEmpty) {
      buffer.writeln('_Nessun contenuto di diario / No diary content._');
    }
    return buffer.toString();
  }

  String createReadableExport(AgendaStore store) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('ANNA\'S DIARY');
    buffer.writeln(
      'Esportazione del ${DateFormat('d MMMM yyyy, HH:mm').format(now)}',
    );
    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('IMPEGNI E ATTIVITÀ');
    buffer.writeln(
      '============================================================',
    );

    final sortedItems = [...store.items]..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        final am =
            a.start == null ? 9999 : a.start!.hour * 60 + a.start!.minute;
        final bm =
            b.start == null ? 9999 : b.start!.hour * 60 + b.start!.minute;
        return am.compareTo(bm);
      });

    if (sortedItems.isEmpty) {
      buffer.writeln('Nessun impegno salvato.');
    } else {
      for (final item in sortedItems) {
        final date =
            DateFormat('d MMMM yyyy').format(item.date);
        final time =
            item.start == null ? '' : ' · ${formatTime(item.start!)}';
        buffer.writeln('- $date$time · ${item.title}');
        buffer.writeln('  Categoria: ${item.category.label}');
        if (item.note.trim().isNotEmpty) {
          buffer.writeln('  Note: ${item.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('PERSONE IMPORTANTI');
    buffer.writeln(
      '============================================================',
    );

    if (store.people.isEmpty) {
      buffer.writeln('Nessuna persona salvata.');
    } else {
      final people = [...store.people]
        ..sort((a, b) {
          if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      for (final person in people) {
        final relationship = person.relationship.trim().isEmpty
            ? ''
            : ' · ${person.relationship.trim()}';
        buffer.writeln('- ${person.name}$relationship');
        final birthday = store.birthdayForPerson(person);
        if (birthday != null) {
          final date = DateTime(2000, birthday.month, birthday.day);
          buffer.writeln(
            '  Compleanno: ${DateFormat('d MMMM').format(date)}',
          );
        }
        final memories = store.personMemoryCount(person.id);
        if (memories > 0) {
          buffer.writeln('  Ricordi collegati: $memories');
        }
        if (person.note.trim().isNotEmpty) {
          buffer.writeln('  Note: ${person.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('COMPLEANNI');
    buffer.writeln(
      '============================================================',
    );

    if (store.birthdays.isEmpty) {
      buffer.writeln('Nessun compleanno salvato.');
    } else {
      final birthdays = [...store.birthdays]
        ..sort((a, b) {
          final month = a.month.compareTo(b.month);
          if (month != 0) return month;
          final day = a.day.compareTo(b.day);
          if (day != 0) return day;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      for (final birthday in birthdays) {
        final date = DateTime(2000, birthday.month, birthday.day);
        final dateText = DateFormat('d MMMM').format(date);
        final yearText =
            birthday.year == null ? '' : ' ${birthday.year}';
        buffer.writeln('- $dateText$yearText · ${birthday.name}');
        if (birthday.note.trim().isNotEmpty) {
          buffer.writeln('  Note: ${birthday.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('LISTA DELLA SPESA');
    buffer.writeln(
      '============================================================',
    );

    if (store.shoppingItems.isEmpty) {
      buffer.writeln('Nessun articolo salvato.');
    } else {
      final shopping = [...store.shoppingItems]
        ..sort((a, b) {
          if (a.done != b.done) return a.done ? 1 : -1;
          final category = a.category.index.compareTo(b.category.index);
          if (category != 0) return category;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      for (final item in shopping) {
        final mark = item.done ? '✓' : '•';
        final quantity =
            item.quantity.trim().isEmpty ? '' : ' · ${item.quantity.trim()}';
        buffer.writeln(
          '$mark ${item.name}$quantity · ${item.category.label}',
        );
      }
    }

    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('ALLENAMENTO');
    buffer.writeln(
      '============================================================',
    );

    if (store.workoutSessions.isEmpty && store.workoutPlans.isEmpty) {
      buffer.writeln('Nessun allenamento o scheda salvata.');
    } else {
      final sessions = [...store.workoutHistory];
      if (sessions.isNotEmpty) {
        buffer.writeln('Sessioni:');
        for (final session in sessions) {
          final date =
              DateFormat('d MMMM yyyy').format(session.date);
          final parts = <String>[
            session.sport.label,
            if (session.distanceKm != null)
              '${session.distanceKm!.toStringAsFixed(
                    session.distanceKm! % 1 == 0 ? 0 : 2,
                  )} km',
            if (session.durationSeconds > 0)
              store.formatWorkoutDuration(session.durationSeconds),
            if (store.workoutPerformanceLabel(session) case final value?)
              value,
          ];
          buffer.writeln('- $date · ${session.title}');
          buffer.writeln('  ${parts.join(' · ')}');
          if (session.note.trim().isNotEmpty) {
            buffer.writeln('  Note: ${session.note.trim()}');
          }
        }
      }

      if (store.workoutPlans.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Schede:');
        for (final plan in store.workoutPlansSorted) {
          buffer.writeln(
            '- ${plan.name} · ${plan.sport.label} · '
            '${plan.exercises.length} esercizi',
          );
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('DIARIO');
    buffer.writeln(
      '============================================================',
    );

    final journalEntries = store.journals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (journalEntries.isEmpty) {
      buffer.writeln('Nessuna pagina di diario salvata.');
    } else {
      for (final entry in journalEntries) {
        final date = DateTime.tryParse(entry.key);
        final journal = entry.value;
        buffer.writeln();
        buffer.writeln(
          date == null
              ? entry.key
              : DateFormat('d MMMM yyyy').format(date),
        );
        if (journal.mood != null) {
          buffer.writeln(
            'Mood: ${journal.mood!.emoji} ${journal.mood!.label}',
          );
        }
        if (journal.gratitude.isNotEmpty) {
          buffer.writeln('Cose belle:');
          for (final value in journal.gratitude) {
            buffer.writeln('  • $value');
          }
        }
        if (journal.beautiful.trim().isNotEmpty) {
          buffer.writeln('Da ricordare: ${journal.beautiful.trim()}');
        }
        if (journal.note.trim().isNotEmpty) {
          buffer.writeln('Pensieri: ${journal.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln('PAGINE MENSILI');
    buffer.writeln(
      '============================================================',
    );

    final monthEntries = store.months.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in monthEntries) {
      final parts = entry.key.split('-');
      if (parts.length != 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      final data = entry.value;
      buffer.writeln();
      buffer.writeln(
        _cap(DateFormat('MMMM yyyy').format(DateTime(y, m))),
      );
      if (data.monthWord.isNotEmpty) {
        buffer.writeln('Parola del mese: ${data.monthWord}');
      }
      if (data.intention.isNotEmpty) {
        buffer.writeln('Intenzione: ${data.intention}');
      }
      if (data.goals.isNotEmpty) {
        buffer.writeln('Obiettivi: ${data.goals.join(' · ')}');
      }
      if (data.books.isNotEmpty) {
        buffer.writeln('Libri: ${data.books.join(' · ')}');
      }
      if (data.films.isNotEmpty) {
        buffer.writeln('Film e serie: ${data.films.join(' · ')}');
      }
      if (data.wishes.isNotEmpty) {
        buffer.writeln('Desideri: ${data.wishes.join(' · ')}');
      }
      if (data.bestMoment.isNotEmpty) {
        buffer.writeln('Momento più bello: ${data.bestMoment}');
      }
      if (data.reflection.isNotEmpty) {
        buffer.writeln('Riflessione: ${data.reflection}');
      }
    }

    return buffer.toString();
  }
}
