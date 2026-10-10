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
          'backup_local_media_missing:$assetId',
        );
      }
      mediaBytesTotal += bytes.lengthInBytes;
      if (mediaBytesTotal > BackupFileService.maxBackupMediaBytes) {
        throw const FormatException(
          'backup_too_many_media',
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

  Future<Uint8List> createOpenExportZip(AgendaStore store) async {
    final exportedAt = DateTime.now();
    final openData = Map<String, dynamic>.from(localDataPayload(store))
      ..remove('trash')
      ..remove('preferences');

    final referencedAssetIds = <String>{};
    store._collectAssetIdsFromJson(openData, referencedAssetIds);

    final files = <String, Uint8List>{};
    final mediaPaths = <String, String>{};
    final manifestFiles = <Map<String, dynamic>>[];
    var mediaBytesTotal = 0;

    final sortedIds = referencedAssetIds.toList()..sort();
    for (final assetId in sortedIds) {
      final bytes = await MediaAssetStore.instance.read(assetId);
      if (bytes == null || bytes.isEmpty) {
        throw FormatException(
          'open_export_local_media_missing:$assetId',
        );
      }
      mediaBytesTotal += bytes.lengthInBytes;
      if (mediaBytesTotal > BackupFileService.maxBackupMediaBytes) {
        throw const FormatException(
          'open_export_too_many_media',
        );
      }
      final extension = _openMediaExtension(bytes);
      final path = 'media/$assetId.$extension';
      files[path] = bytes;
      mediaPaths[assetId] = path;
      manifestFiles.add({
        'assetId': assetId,
        'path': path,
        'size': bytes.lengthInBytes,
        'sha256': sha256.convert(bytes).toString(),
      });
    }

    final sketchPaths = <String, String>{};
    for (final journalEntry in store.journals.entries) {
      for (final block in journalEntry.value.blocks) {
        if (block.type != DiaryBlockType.sketch || block.pages.isEmpty) {
          continue;
        }
        final safeId = _openFileToken(block.id);
        final path = 'sketches/$safeId.json';
        final json = const JsonEncoder.withIndent('  ').convert({
          'blockId': block.id,
          'createdAt': block.createdAt.toUtc().toIso8601String(),
          'pages': block.pages.map((page) => page.toJson()).toList(),
        });
        final bytes = Uint8List.fromList(utf8.encode(json));
        files[path] = bytes;
        sketchPaths[block.id] = path;
        manifestFiles.add({
          'blockId': block.id,
          'path': path,
          'size': bytes.lengthInBytes,
          'sha256': sha256.convert(bytes).toString(),
          'kind': 'sketch_json',
        });
      }
    }

    final dataDocument = {
      'format': 'annas_diary_open_export',
      'schemaVersion': 1,
      'appVersion': AgendaStore._appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'data': openData,
    };
    final dataJson =
        const JsonEncoder.withIndent('  ').convert(dataDocument);
    final markdown = _createOpenMarkdown(
      store,
      exportedAt: exportedAt,
      mediaPaths: mediaPaths,
      sketchPaths: sketchPaths,
    );

    final manifest = {
      'format': 'annas_diary_open_export_bundle',
      'bundleVersion': 1,
      'appVersion': AgendaStore._appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'readmeFile': 'README.md',
      'dataFile': 'data.json',
      'readmeSha256': sha256.convert(utf8.encode(markdown)).toString(),
      'dataSha256': sha256.convert(utf8.encode(dataJson)).toString(),
      'files': manifestFiles,
      'excludedScopes': const [
        'trash',
        'preferences',
        'private_vault',
        'cycle_tracker',
        'shared_passwords',
        'authentication_secrets',
      ],
    };

    return BackupFileService.instance.buildOpenExportZip(
      manifestJson: const JsonEncoder.withIndent('  ').convert(manifest),
      markdown: markdown,
      dataJson: dataJson,
      files: files,
    );
  }

  DecodedZipBackup decodeAndValidateBackupZip(
    AgendaStore store,
    Uint8List bytes,
  ) {
    final decoded = BackupFileService.instance.decodeZipBackup(bytes);

    final manifestValue = jsonDecode(decoded.manifestJson);
    if (manifestValue is! Map) {
      throw const FormatException('backup_manifest_invalid');
    }
    final manifest = Map<String, dynamic>.from(manifestValue);
    if (manifest['format'] != AgendaStore._backupBundleFormat ||
        manifest['bundleVersion'] != AgendaStore._backupBundleVersion) {
      throw const FormatException('backup_format_unsupported');
    }

    final expectedDataHash = manifest['dataSha256']?.toString() ?? '';
    final actualDataHash =
        sha256.convert(utf8.encode(decoded.dataJson)).toString();
    if (expectedDataHash.isEmpty || expectedDataHash != actualDataHash) {
      throw const FormatException('backup_data_hash_invalid');
    }

    final rawMedia = manifest['media'];
    if (rawMedia is! List) {
      throw const FormatException('backup_media_index_invalid');
    }

    final declaredIds = <String>{};
    for (final raw in rawMedia) {
      if (raw is! Map) {
        throw const FormatException('backup_media_index_invalid');
      }
      final entry = Map<String, dynamic>.from(raw);
      final assetId = entry['assetId']?.toString() ?? '';
      final expectedSize = entry['size'];
      final expectedHash = entry['sha256']?.toString() ?? '';
      if (assetId.isEmpty ||
          expectedSize is! int ||
          expectedHash.isEmpty ||
          !declaredIds.add(assetId)) {
        throw const FormatException('backup_media_index_invalid');
      }

      final mediaBytes = decoded.media[assetId];
      if (mediaBytes == null ||
          mediaBytes.lengthInBytes != expectedSize ||
          sha256.convert(mediaBytes).toString() != expectedHash) {
        throw FormatException(
          'backup_media_corrupt:$assetId',
        );
      }
    }

    if (decoded.media.keys.any((assetId) => !declaredIds.contains(assetId))) {
      throw const FormatException('backup_undeclared_media');
    }

    inspectBackup(decoded.dataJson);
    return decoded;
  }

  BackupSummary inspectBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('backup_invalid');
    }

    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != AgendaStore._backupFormat) {
      throw const FormatException(
        'backup_wrong_app',
      );
    }

    final schema = root['schemaVersion'];
    if (schema is! int ||
        schema > AgendaStore._backupSchemaVersion ||
        schema < 1) {
      throw const FormatException('backup_version_unsupported');
    }

    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('backup_data_unreadable');
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

  String _createOpenMarkdown(
    AgendaStore store, {
    required DateTime exportedAt,
    required Map<String, String> mediaPaths,
    required Map<String, String> sketchPaths,
  }) {
    final buffer = StringBuffer();
    final peopleById = {
      for (final person in store.people) person.id: person.name.trim(),
    };

    buffer.writeln('# Anna\'s Diary — Open Export');
    buffer.writeln();
    buffer.writeln(
      'Esportato il ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(exportedAt)}.',
    );
    buffer.writeln();
    buffer.writeln(
      'Questo archivio usa formati aperti: Markdown, JSON e file multimediali separati.',
    );
    buffer.writeln(
      'Il Cestino, le preferenze tecniche, il Private Vault, il Cycle Tracker, '
      'le password condivise e i segreti di autenticazione non sono inclusi.',
    );
    buffer.writeln();
    buffer.writeln('## Contenuto');
    buffer.writeln();
    buffer.writeln('- README.md: diario leggibile e indice principale');
    buffer.writeln('- data.json: dati privati ordinari strutturati');
    buffer.writeln('- media/: foto, audio e altri asset referenziati');
    buffer.writeln('- sketches/: rappresentazione JSON aperta dei disegni');
    buffer.writeln();

    buffer.writeln('## Diario');
    buffer.writeln();
    final journalEntries = store.journals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (journalEntries.isEmpty) {
      buffer.writeln('_Nessuna pagina di diario salvata._');
      buffer.writeln();
    } else {
      for (final entry in journalEntries) {
        final date = DateTime.tryParse(entry.key);
        final journal = entry.value;
        final dayLabel = date == null
            ? entry.key
            : DateFormat('d MMMM yyyy', 'it_IT').format(date);
        buffer.writeln('### $dayLabel');
        buffer.writeln();

        if (journal.mood != null) {
          buffer.writeln(
            '**Mood:** ${journal.mood!.emoji} ${journal.mood!.label}',
          );
          buffer.writeln();
        }
        if (journal.gratitude.isNotEmpty) {
          buffer.writeln('**Cose belle**');
          for (final value in journal.gratitude) {
            if (value.trim().isNotEmpty) {
              buffer.writeln('- ${_openMarkdownInline(value)}');
            }
          }
          buffer.writeln();
        }
        if (journal.beautiful.trim().isNotEmpty) {
          buffer.writeln('**Da ricordare**');
          buffer.writeln();
          buffer.writeln(journal.beautiful.trim());
          buffer.writeln();
        }
        if (journal.note.trim().isNotEmpty) {
          buffer.writeln('**Pensieri**');
          buffer.writeln();
          buffer.writeln(journal.note.trim());
          buffer.writeln();
        }

        final blocks = [...journal.blocks]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        for (final block in blocks) {
          final time = DateFormat('HH:mm').format(block.createdAt);
          final archived = block.archived ? ' · archiviato' : '';
          buffer.writeln(
            '#### $time · ${_openBlockLabel(block.type)}$archived',
          );
          buffer.writeln();

          if (block.text.trim().isNotEmpty) {
            buffer.writeln(block.text.trim());
            buffer.writeln();
          }

          if (block.type == DiaryBlockType.photo) {
            final mediaPath = mediaPaths[block.mediaAssetId];
            if (mediaPath != null) {
              final alt = block.text.trim().isEmpty
                  ? 'Foto'
                  : _openMarkdownInline(block.text.trim());
              buffer.writeln('![$alt]($mediaPath)');
              buffer.writeln();
            } else if (block.imageBase64.isNotEmpty) {
              buffer.writeln(
                '_Foto legacy incorporata nel record strutturato di data.json._',
              );
              buffer.writeln();
            }
          }

          if (block.type == DiaryBlockType.voice) {
            final mediaPath = mediaPaths[block.mediaAssetId];
            if (mediaPath != null) {
              buffer.writeln('[Apri registrazione audio]($mediaPath)');
              if (block.audioDurationMs > 0) {
                final seconds = (block.audioDurationMs / 1000).round();
                buffer.writeln('Durata: $seconds s');
              }
              buffer.writeln();
            } else if (block.audioBase64.isNotEmpty) {
              buffer.writeln(
                '_Audio legacy incorporato nel record strutturato di data.json._',
              );
              buffer.writeln();
            }
          }

          if (block.type == DiaryBlockType.sketch) {
            final sketchPath = sketchPaths[block.id];
            if (sketchPath != null) {
              buffer.writeln(
                '[Dati vettoriali del disegno]($sketchPath)',
              );
              buffer.writeln();
            }
            final sketchText = block.pages
                .expand((page) => page.textElements)
                .map((element) => element.text.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false);
            if (sketchText.isNotEmpty) {
              buffer.writeln('Testo nel disegno:');
              for (final value in sketchText) {
                buffer.writeln('- ${_openMarkdownInline(value)}');
              }
              buffer.writeln();
            }
          }

          if (block.tags.isNotEmpty) {
            buffer.writeln(
              '**Tag:** ${block.tags.map((tag) => '#${_openMarkdownInline(tag)}').join(' ')}',
            );
          }
          final people = block.personIds
              .map((id) => peopleById[id])
              .whereType<String>()
              .where((name) => name.isNotEmpty)
              .toList(growable: false);
          if (people.isNotEmpty) {
            buffer.writeln(
              '**Persone:** ${people.map(_openMarkdownInline).join(', ')}',
            );
          }
          if (block.places.isNotEmpty) {
            buffer.writeln(
              '**Luoghi:** ${block.places.map((place) => _openMarkdownInline(place.name)).join(', ')}',
            );
          }
          if (block.relatedBlockIds.isNotEmpty) {
            buffer.writeln(
              '**Ricordi collegati:** ${block.relatedBlockIds.map(_openMarkdownInline).join(', ')}',
            );
          }
          if (block.tags.isNotEmpty ||
              people.isNotEmpty ||
              block.places.isNotEmpty ||
              block.relatedBlockIds.isNotEmpty) {
            buffer.writeln();
          }
        }
      }
    }

    buffer.writeln('## Agenda');
    buffer.writeln();
    final items = [...store.items]
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        final aMinutes =
            a.start == null ? 9999 : a.start!.hour * 60 + a.start!.minute;
        final bMinutes =
            b.start == null ? 9999 : b.start!.hour * 60 + b.start!.minute;
        return aMinutes.compareTo(bMinutes);
      });
    if (items.isEmpty) {
      buffer.writeln('_Nessun impegno salvato._');
    } else {
      for (final item in items) {
        final date = DateFormat('yyyy-MM-dd', 'it_IT').format(item.date);
        final time =
            item.start == null ? '' : ' ${formatTime(item.start!)}';
        final done = item.done ? ' [completato]' : '';
        buffer.writeln(
          '- **$date$time** · ${_openMarkdownInline(item.title)}$done',
        );
        if (item.note.trim().isNotEmpty) {
          buffer.writeln(
            '  - ${_openMarkdownInline(item.note.trim())}',
          );
        }
      }
    }
    buffer.writeln();

    buffer.writeln('## Indice dati strutturati');
    buffer.writeln();
    buffer.writeln('- Persone: ${store.people.length}');
    buffer.writeln('- Compleanni: ${store.birthdays.length}');
    buffer.writeln('- Inbox: ${store.inbox.length}');
    buffer.writeln('- Lista della spesa: ${store.shoppingItems.length}');
    buffer.writeln(
      '- Sessioni di allenamento: ${store.workoutSessions.length}',
    );
    buffer.writeln(
      '- Schede di allenamento: ${store.workoutPlans.length}',
    );
    buffer.writeln('- Pagine settimanali: ${store.weeks.length}');
    buffer.writeln('- Pagine mensili: ${store.months.length}');
    buffer.writeln();
    buffer.writeln(
      'I record completi di queste sezioni sono disponibili in data.json.',
    );

    return buffer.toString();
  }

  String _openBlockLabel(DiaryBlockType type) => switch (type) {
        DiaryBlockType.note => 'Nota',
        DiaryBlockType.photo => 'Foto',
        DiaryBlockType.voice => 'Voce',
        DiaryBlockType.sketch => 'Disegno',
      };

  String _openMarkdownInline(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('|', '\\|')
      .trim();

  String _openMediaExtension(Uint8List bytes) {
    if (bytes.lengthInBytes >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'jpg';
    }
    if (bytes.lengthInBytes >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.lengthInBytes >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'webp';
    }
    if (bytes.lengthInBytes >= 6) {
      final signature =
          ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') {
        return 'gif';
      }
    }
    if (bytes.lengthInBytes >= 5 &&
        ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-') {
      return 'pdf';
    }
    if (bytes.lengthInBytes >= 12 &&
        ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp') {
      final brand =
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true).toLowerCase();
      if (brand.contains('m4a') || brand.contains('m4b')) {
        return 'm4a';
      }
      return 'mp4';
    }
    return 'bin';
  }

  String _openFileToken(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    if (normalized.isEmpty) {
      return sha256.convert(utf8.encode(value)).toString().substring(0, 24);
    }
    return normalized.length <= 96 ? normalized : normalized.substring(0, 96);
  }

  String createReadableExport(AgendaStore store) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('ANNA\'S DIARY');
    buffer.writeln(
      'Esportazione del ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(now)}',
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
            DateFormat('d MMMM yyyy', 'it_IT').format(item.date);
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
            '  Compleanno: ${DateFormat('d MMMM', 'it_IT').format(date)}',
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
        final dateText = DateFormat('d MMMM', 'it_IT').format(date);
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
              DateFormat('d MMMM yyyy', 'it_IT').format(session.date);
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
              : DateFormat('d MMMM yyyy', 'it_IT').format(date),
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
        _cap(DateFormat('MMMM yyyy', 'it_IT').format(DateTime(y, m))),
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
