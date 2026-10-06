part of '../main.dart';

const String _backupRestoreTransactionKey = 'backup_restore_transaction_v1';

class _RestoreStagedAsset {
  final String canonicalAssetId;
  final String stagingAssetId;
  final String sha256Hex;

  const _RestoreStagedAsset({
    required this.canonicalAssetId,
    required this.stagingAssetId,
    required this.sha256Hex,
  });
}

class _SimulatedRestoreCrash implements Exception {
  final String phase;
  const _SimulatedRestoreCrash(this.phase);

  @override
  String toString() => 'Simulated restore crash at $phase';
}

/// One restore transaction spanning physical media and structured local state.
///
/// Invariants:
/// - incoming bytes first live only under the restore staging namespace;
/// - canonical media is promoted only after all staging bytes are readable;
/// - the LocalStateStore transaction commits the structured state and the
///   `structured_committed` marker atomically;
/// - recovery deletes promoted media only when the marker proves that the
///   structured commit never happened.
class _RestoreMediaStagingSession {
  final LocalStateStore prefs;
  final String transactionId;

  final Map<String, _RestoreStagedAsset> _entries =
      <String, _RestoreStagedAsset>{};
  final Set<String> _createdCanonicalIds = <String>{};
  String? _pendingCanonicalId;
  String _phase = 'staging';

  _RestoreMediaStagingSession(
    this.prefs, {
    String? transactionId,
  }) : transactionId = transactionId ?? const Uuid().v4();

  Future<void> begin() async {
    _phase = 'staging';
    await _persistMarker();
  }

  Future<String> stageContent(Uint8List bytes) async {
    final canonicalAssetId =
        MediaAssetStore.instance.contentAssetId(bytes);
    await stageNamed(canonicalAssetId, bytes);
    return canonicalAssetId;
  }

  Future<void> stageNamed(
    String canonicalAssetId,
    Uint8List bytes,
  ) async {
    if (canonicalAssetId.trim().isEmpty || bytes.isEmpty) {
      throw const FormatException('Media di ripristino non valido.');
    }

    final expectedHash = sha256.convert(bytes).toString();
    final existing = _entries[canonicalAssetId];
    if (existing != null) {
      if (existing.sha256Hex != expectedHash) {
        throw FormatException(
          'Collisione media nel ripristino: $canonicalAssetId',
        );
      }
      return;
    }

    final stagingAssetId = MediaAssetStore.instance.restoreStagingAssetId(
      transactionId,
      canonicalAssetId,
    );
    await MediaAssetStore.instance.putNamed(stagingAssetId, bytes);

    final staged = await MediaAssetStore.instance.read(stagingAssetId);
    if (staged == null ||
        staged.lengthInBytes != bytes.lengthInBytes ||
        sha256.convert(staged).toString() != expectedHash) {
      throw FormatException(
        'Staging media non integro: $canonicalAssetId',
      );
    }

    _entries[canonicalAssetId] = _RestoreStagedAsset(
      canonicalAssetId: canonicalAssetId,
      stagingAssetId: stagingAssetId,
      sha256Hex: expectedHash,
    );
    await _persistMarker();
  }

  Future<void> promoteAndVerify(
    Set<String> requiredCanonicalAssetIds,
  ) async {
    _phase = 'promoting';
    await _persistMarker();

    final entries = _entries.values.toList()
      ..sort(
        (a, b) =>
            a.canonicalAssetId.compareTo(b.canonicalAssetId),
      );

    for (final entry in entries) {
      final staged =
          await MediaAssetStore.instance.read(entry.stagingAssetId);
      if (staged == null ||
          sha256.convert(staged).toString() != entry.sha256Hex) {
        throw FormatException(
          'Media in staging non disponibile: '
          '${entry.canonicalAssetId}',
        );
      }

      final current =
          await MediaAssetStore.instance.read(entry.canonicalAssetId);
      if (current != null) {
        if (sha256.convert(current).toString() != entry.sha256Hex) {
          throw FormatException(
            'Asset locale con stesso ID ma contenuto diverso: '
            '${entry.canonicalAssetId}',
          );
        }
        continue;
      }

      // Persist pending intent BEFORE the physical write so crash recovery can
      // remove a canonical file even if the process dies between write and
      // the next marker update.
      _pendingCanonicalId = entry.canonicalAssetId;
      await _persistMarker();

      await MediaAssetStore.instance.putNamed(
        entry.canonicalAssetId,
        staged,
      );

      _createdCanonicalIds.add(entry.canonicalAssetId);
      _pendingCanonicalId = null;
      await _persistMarker();
    }

    for (final assetId in requiredCanonicalAssetIds) {
      final bytes = await MediaAssetStore.instance.read(assetId);
      if (bytes == null || bytes.isEmpty) {
        throw FormatException(
          'Reference media senza file integro: $assetId',
        );
      }
    }

    _phase = 'canonical_media_ready';
    await _persistMarker();
  }

  String structuredCommittedMarkerJson() {
    _phase = 'structured_committed';
    return _markerJson();
  }

  Future<void> finish() async {
    for (final entry in _entries.values) {
      await MediaAssetStore.instance.delete(entry.stagingAssetId);
    }
    // Also clears any orphan staging key left by an interrupted stage write
    // that happened before the marker could be updated.
    await MediaAssetStore.instance.clearRestoreStaging();
    await prefs.remove(_backupRestoreTransactionKey);
  }

  Future<void> rollbackIfUncommitted() async {
    final raw = prefs.getString(_backupRestoreTransactionKey);
    final phase = _readPhase(raw) ?? _phase;

    if (phase != 'structured_committed') {
      final ids = <String>{
        ..._createdCanonicalIds,
        if (_pendingCanonicalId != null) _pendingCanonicalId!,
        ..._readCreatedCanonicalIds(raw),
        if (_readPendingCanonicalId(raw) case final pending?)
          pending,
      };
      for (final assetId in ids) {
        await MediaAssetStore.instance.delete(assetId);
      }
    }

    for (final entry in _entries.values) {
      await MediaAssetStore.instance.delete(entry.stagingAssetId);
    }
    await MediaAssetStore.instance.clearRestoreStaging();
    await prefs.remove(_backupRestoreTransactionKey);
  }

  Future<void> _persistMarker() =>
      prefs.setString(_backupRestoreTransactionKey, _markerJson());

  String _markerJson() => jsonEncode({
        'version': 1,
        'transactionId': transactionId,
        'phase': _phase,
        'createdCanonicalIds':
            _createdCanonicalIds.toList()..sort(),
        'pendingCanonicalId': _pendingCanonicalId,
        'stagedCanonicalIds': _entries.keys.toList()..sort(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

  static String? _readPhase(String? raw) {
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      return value['phase']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Set<String> _readCreatedCanonicalIds(String? raw) {
    if (raw == null) return const <String>{};
    try {
      final value = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      return (value['createdCanonicalIds'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  static String? _readPendingCanonicalId(String? raw) {
    if (raw == null) return null;
    try {
      final value = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      final id = value['pendingCanonicalId']?.toString().trim() ?? '';
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }
}

Future<void> _recoverInterruptedBackupRestore(
  LocalStateStore prefs,
) async {
  final raw = prefs.getString(_backupRestoreTransactionKey);
  if (raw != null) {
    final phase = _RestoreMediaStagingSession._readPhase(raw);
    if (phase != 'structured_committed') {
      final ids = <String>{
        ..._RestoreMediaStagingSession._readCreatedCanonicalIds(raw),
        if (_RestoreMediaStagingSession._readPendingCanonicalId(raw)
            case final pending?)
          pending,
      };
      for (final assetId in ids) {
        await MediaAssetStore.instance.delete(assetId);
      }
    }
  }

  // Safe for both known and malformed/missing markers: staging assets are
  // never canonical references. Any promoted orphan that cannot be recovered
  // from a damaged marker is later handled by reference-aware media GC.
  await MediaAssetStore.instance.clearRestoreStaging();
  if (raw != null) {
    await prefs.remove(_backupRestoreTransactionKey);
  }
}

void _injectRestoreFailureForTesting(
  String phase, {
  bool simulateCrash = false,
}) {
  if (!kDebugMode ||
      AgendaStore.restoreFailurePhaseForTesting != phase) {
    return;
  }
  if (simulateCrash) {
    throw _SimulatedRestoreCrash(phase);
  }
  throw StateError('Injected restore failure at $phase');
}
