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
      throw const FormatException('restore_media_invalid');
    }

    final expectedHash = sha256.convert(bytes).toString();
    final existing = _entries[canonicalAssetId];
    if (existing != null) {
      if (existing.sha256Hex != expectedHash) {
        throw FormatException(
          'restore_media_collision:$canonicalAssetId',
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

  Future<Uint8List?> readIncoming(String canonicalAssetId) async {
    final stagedEntry = _entries[canonicalAssetId];
    if (stagedEntry == null) {
      return MediaAssetStore.instance.read(canonicalAssetId);
    }

    final staged =
        await MediaAssetStore.instance.read(stagedEntry.stagingAssetId);
    if (staged == null ||
        sha256.convert(staged).toString() != stagedEntry.sha256Hex) {
      throw FormatException(
        'Media in staging non disponibile: $canonicalAssetId',
      );
    }
    return staged;
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
    // Structured data is already committed before finish() is called.
    // Cleanup failure must not be surfaced as a failed restore: keep the
    // committed marker so startup recovery can retry staging cleanup.
    if (kDebugMode &&
        AgendaStore.restoreFailurePhaseForTesting ==
            'cleanup_after_structured_commit') {
      return;
    }

    var cleanupComplete = true;
    for (final entry in _entries.values) {
      try {
        await MediaAssetStore.instance.delete(entry.stagingAssetId);
      } catch (_) {
        cleanupComplete = false;
      }
    }

    try {
      await MediaAssetStore.instance.clearRestoreStaging();
    } catch (_) {
      cleanupComplete = false;
    }

    if (!cleanupComplete) return;

    try {
      await prefs.remove(_backupRestoreTransactionKey);
    } catch (_) {
      // Leaving a structured_committed marker is safe. Startup recovery will
      // retry marker cleanup without deleting canonical media.
    }
  }

  Future<void> rollbackIfUncommitted() async {
    final raw = prefs.getString(_backupRestoreTransactionKey);
    final phase = _readPhase(raw) ?? _phase;

    if (phase != 'structured_committed') {
      final ids = <String>{
        ..._createdCanonicalIds,
        if (_pendingCanonicalId != null) _pendingCanonicalId!,
        ..._readCreatedCanonicalIds(raw),
      };
      final markerPending = _readPendingCanonicalId(raw);
      if (markerPending != null) ids.add(markerPending);
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
  final markerRecovered =
      prefs.recoveredKeys.contains(_backupRestoreTransactionKey);

  if (raw == null) {
    // No active transaction can legitimately own staging without a marker.
    // This also cleans staging left behind by a lost/unreadable marker.
    await MediaAssetStore.instance.clearRestoreStaging();
    if (prefs.corruptKeys.contains(_backupRestoreTransactionKey)) {
      await prefs.remove(_backupRestoreTransactionKey);
    }
    return;
  }

  // If LocalStateStore had to recover the marker from previousValue, its
  // visible phase may be stale (for example canonical_media_ready after a
  // structured commit). Preserve canonical files conservatively; reference-
  // aware GC after normal state load can remove genuine orphans safely.
  if (!markerRecovered) {
    final phase = _RestoreMediaStagingSession._readPhase(raw);
    if (phase != 'structured_committed') {
      final ids = <String>{
        ..._RestoreMediaStagingSession._readCreatedCanonicalIds(raw),
      };
      final pending =
          _RestoreMediaStagingSession._readPendingCanonicalId(raw);
      if (pending != null) ids.add(pending);
      for (final assetId in ids) {
        await MediaAssetStore.instance.delete(assetId);
      }
    }
  }

  // Staging is never a canonical reference after startup recovery.
  await MediaAssetStore.instance.clearRestoreStaging();
  await prefs.remove(_backupRestoreTransactionKey);
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
