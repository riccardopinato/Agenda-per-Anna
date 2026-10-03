enum EcosystemAppId {
  wonderlog('wonderlog'),
  annasDiary('annas_diary'),
  notes('notes'),
  trailpath('trailpath');

  const EcosystemAppId(this.wireValue);
  final String wireValue;

  static EcosystemAppId fromWire(String value) => values.firstWhere(
        (item) => item.wireValue == value,
      );
}

enum EcosystemEntityType {
  journey,
  memory,
  note,
  place,
  route,
  photo,
  generic,
}

enum EcosystemPrivacyScope {
  private,
  explicitShare,
}

enum EcosystemTransferMode {
  copy,
  link,
}

enum EcosystemMediaHandoffKind {
  omitted,
  shareToken,
  cloudObject,
}

final class EcosystemPlace {
  const EcosystemPlace({
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String name;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory EcosystemPlace.fromJson(Map<String, Object?> json) =>
      EcosystemPlace(
        name: json['name']! as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

final class EcosystemProvenance {
  const EcosystemProvenance({
    required this.ownerApp,
    required this.ownerEntityType,
    required this.ownerEntityId,
    required this.ownerRevision,
    this.canonicalDeepLink,
    this.parentBridgeId,
  });

  final EcosystemAppId ownerApp;
  final EcosystemEntityType ownerEntityType;
  final String ownerEntityId;
  final int ownerRevision;
  final String? canonicalDeepLink;
  final String? parentBridgeId;

  Map<String, Object?> toJson() => {
        'ownerApp': ownerApp.wireValue,
        'ownerEntityType': ownerEntityType.name,
        'ownerEntityId': ownerEntityId,
        'ownerRevision': ownerRevision,
        if (canonicalDeepLink != null)
          'canonicalDeepLink': canonicalDeepLink,
        if (parentBridgeId != null) 'parentBridgeId': parentBridgeId,
      };

  factory EcosystemProvenance.fromJson(Map<String, Object?> json) =>
      EcosystemProvenance(
        ownerApp: EcosystemAppId.fromWire(json['ownerApp']! as String),
        ownerEntityType: EcosystemEntityType.values.byName(
          json['ownerEntityType']! as String,
        ),
        ownerEntityId: json['ownerEntityId']! as String,
        ownerRevision: (json['ownerRevision'] as num?)?.toInt() ?? 1,
        canonicalDeepLink: json['canonicalDeepLink'] as String?,
        parentBridgeId: json['parentBridgeId'] as String?,
      );
}

final class EcosystemFallback {
  const EcosystemFallback({
    required this.plainText,
    this.sourceDeepLink,
    this.webUrl,
  });

  final String plainText;
  final String? sourceDeepLink;
  final String? webUrl;

  Map<String, Object?> toJson() => {
        'plainText': plainText,
        if (sourceDeepLink != null) 'sourceDeepLink': sourceDeepLink,
        if (webUrl != null) 'webUrl': webUrl,
      };

  factory EcosystemFallback.fromJson(Map<String, Object?> json) =>
      EcosystemFallback(
        plainText: json['plainText'] as String? ?? '',
        sourceDeepLink: json['sourceDeepLink'] as String?,
        webUrl: json['webUrl'] as String?,
      );
}

final class EcosystemMediaHandoff {
  const EcosystemMediaHandoff({
    required this.kind,
    this.token,
    this.locator,
    this.expiresAtUtc,
    this.reason,
  });

  final EcosystemMediaHandoffKind kind;
  final String? token;
  final String? locator;
  final DateTime? expiresAtUtc;
  final String? reason;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (token != null) 'token': token,
        if (locator != null) 'locator': locator,
        if (expiresAtUtc != null)
          'expiresAtUtc': expiresAtUtc!.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      };

  factory EcosystemMediaHandoff.fromJson(Map<String, Object?> json) =>
      EcosystemMediaHandoff(
        kind: EcosystemMediaHandoffKind.values.byName(
          json['kind'] as String? ?? 'omitted',
        ),
        token: json['token'] as String?,
        locator: json['locator'] as String?,
        expiresAtUtc: json['expiresAtUtc'] == null
            ? null
            : DateTime.parse(json['expiresAtUtc']! as String).toUtc(),
        reason: json['reason'] as String?,
      );
}

final class EcosystemMediaReference {
  const EcosystemMediaReference({
    required this.id,
    required this.kind,
    this.mimeType,
    this.fileName,
    this.byteSize,
    this.handoff = const EcosystemMediaHandoff(
      kind: EcosystemMediaHandoffKind.omitted,
      reason: 'binary_handoff_not_enabled',
    ),
  });

  final String id;
  final String kind;
  final String? mimeType;
  final String? fileName;
  final int? byteSize;
  final EcosystemMediaHandoff handoff;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind,
        if (mimeType != null) 'mimeType': mimeType,
        if (fileName != null) 'fileName': fileName,
        if (byteSize != null) 'byteSize': byteSize,
        'handoff': handoff.toJson(),
      };

  factory EcosystemMediaReference.fromJson(Map<String, Object?> json) {
    final kind = json['kind'] as String? ?? 'media';
    final fileName = json['fileName'] as String?;
    final handoffJson = json['handoff'];

    return EcosystemMediaReference(
      id: json['id'] as String? ??
          'legacy:$kind:${fileName ?? 'media'}',
      kind: kind,
      mimeType: json['mimeType'] as String?,
      fileName: fileName,
      byteSize: (json['byteSize'] as num?)?.toInt(),
      handoff: handoffJson is Map
          ? EcosystemMediaHandoff.fromJson(
              Map<String, Object?>.from(handoffJson),
            )
          : const EcosystemMediaHandoff(
              kind: EcosystemMediaHandoffKind.omitted,
              reason: 'legacy_local_reference_removed',
            ),
    );
  }
}
