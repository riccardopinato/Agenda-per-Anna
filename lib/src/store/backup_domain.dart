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
        'templates': store.templates.map((e) => e.toJson()).toList(),
        'inbox': store.inbox.map((e) => e.toJson()).toList(),
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
      'templates': store.templates.map((e) => e.toJson()).toList(),
      'inbox': store.inbox.map((e) => e.toJson()).toList(),
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
      templateCount: (payload['templates'] as List? ?? const []).length,
      trashCount: (payload['trash'] as List? ?? const []).length,
    );
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
    buffer.writeln('MODELLI PERSONALI');
    buffer.writeln(
      '============================================================',
    );

    if (store.templates.isEmpty) {
      buffer.writeln('Nessun modello personale salvato.');
    } else {
      for (final template in store.sortedTemplates) {
        buffer.writeln(
          '- ${template.name} · ${template.kind.label} · ${template.summary}',
        );
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
