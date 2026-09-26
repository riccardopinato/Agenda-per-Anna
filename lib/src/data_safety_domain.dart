part of '../main.dart';

class DataSafetyReport {
  final int referencedMediaCount;
  final int storedMediaCount;
  final Set<String> missingMediaIds;
  final Set<String> corruptMediaIds;
  final Set<String> orphanMediaIds;
  final Set<String> unreadableStorageKeys;
  final int pendingCloudChanges;
  final int localSnapshotCount;

  const DataSafetyReport({
    required this.referencedMediaCount,
    required this.storedMediaCount,
    required this.missingMediaIds,
    required this.corruptMediaIds,
    required this.orphanMediaIds,
    required this.unreadableStorageKeys,
    required this.pendingCloudChanges,
    required this.localSnapshotCount,
  });

  bool get integrityHealthy =>
      missingMediaIds.isEmpty &&
      corruptMediaIds.isEmpty &&
      unreadableStorageKeys.isEmpty;

  bool get hasCleanupCandidates => orphanMediaIds.isNotEmpty;
  bool get hasPendingSync => pendingCloudChanges > 0;
}

extension AgendaStoreDataSafety on AgendaStore {
  Future<DataSafetyReport> auditDataSafety() async {
    final referenced = <String>{};
    _collectAssetIdsFromJson(_localDataPayload(), referenced);

    final storedAll = await MediaAssetStore.instance.listStoredAssetIds();
    final stored = storedAll
        .where((assetId) => !assetId.startsWith('remote_'))
        .toSet();

    final missing = <String>{};
    for (final assetId in referenced) {
      if (!stored.contains(assetId)) {
        missing.add(assetId);
        continue;
      }
      final bytes = await MediaAssetStore.instance.read(assetId);
      if (bytes == null &&
          !MediaAssetStore.instance.corruptAssetIds.contains(assetId)) {
        missing.add(assetId);
      }
    }

    final corrupt = MediaAssetStore.instance.corruptAssetIds
        .where(referenced.contains)
        .toSet();
    final orphan = stored.difference(referenced);

    return DataSafetyReport(
      referencedMediaCount: referenced.length,
      storedMediaCount: stored.length,
      missingMediaIds: Set<String>.unmodifiable(missing),
      corruptMediaIds: Set<String>.unmodifiable(corrupt),
      orphanMediaIds: Set<String>.unmodifiable(orphan),
      unreadableStorageKeys: unreadableStorageKeys,
      pendingCloudChanges: totalPendingCloudChanges,
      localSnapshotCount: localSnapshots.length,
    );
  }

  BackupSummary verifyBackupZip(Uint8List bytes) {
    // inspectBackupZip already performs manifest, data hash, media size/hash
    // and schema validation through the existing backup domain.
    return inspectBackupZip(bytes);
  }
}
