import 'ecosystem_contract.dart';
import 'ecosystem_models.dart';

abstract final class EcosystemBridgeIdentity {
  static String forOwner({
    required EcosystemAppId ownerApp,
    required EcosystemEntityType ownerEntityType,
    required String ownerEntityId,
  }) =>
      'ecosystem:v1:${ownerApp.wireValue}:'
      '${ownerEntityType.name}:$ownerEntityId';
}

final class EcosystemEnvelope {
  EcosystemEnvelope({
    this.schemaVersion = EcosystemContract.schemaVersion,
    String? bridgeId,
    required this.sourceApp,
    required this.sourceEntityType,
    required this.sourceEntityId,
    required this.createdAtUtc,
    this.title,
    this.text,
    this.tags = const [],
    this.people = const [],
    this.places = const [],
    this.media = const [],
    this.sourceDeepLink,
    this.privacyScope = EcosystemPrivacyScope.explicitShare,
    this.transferMode = EcosystemTransferMode.copy,
    this.revision = 1,
    EcosystemProvenance? provenance,
    EcosystemFallback? fallback,
  })  : provenance = provenance ??
            EcosystemProvenance(
              ownerApp: sourceApp,
              ownerEntityType: sourceEntityType,
              ownerEntityId: sourceEntityId,
              ownerRevision: revision,
              canonicalDeepLink: sourceDeepLink,
            ),
        bridgeId = bridgeId ??
            EcosystemBridgeIdentity.forOwner(
              ownerApp: provenance?.ownerApp ?? sourceApp,
              ownerEntityType:
                  provenance?.ownerEntityType ?? sourceEntityType,
              ownerEntityId: provenance?.ownerEntityId ?? sourceEntityId,
            ),
        fallback = fallback ??
            EcosystemFallback(
              plainText: _defaultFallbackText(title, text),
              sourceDeepLink: sourceDeepLink,
            );

  final int schemaVersion;
  final String bridgeId;
  final EcosystemAppId sourceApp;
  final EcosystemEntityType sourceEntityType;
  final String sourceEntityId;
  final DateTime createdAtUtc;
  final String? title;
  final String? text;
  final List<String> tags;
  final List<String> people;
  final List<EcosystemPlace> places;
  final List<EcosystemMediaReference> media;
  final String? sourceDeepLink;
  final EcosystemPrivacyScope privacyScope;
  final EcosystemTransferMode transferMode;
  final int revision;
  final EcosystemProvenance provenance;
  final EcosystemFallback fallback;

  String get idempotencyKey =>
      '$bridgeId:$revision:${transferMode.name}';

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'bridgeId': bridgeId,
        'sourceApp': sourceApp.wireValue,
        'sourceEntityType': sourceEntityType.name,
        'sourceEntityId': sourceEntityId,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        'title': title,
        'text': text,
        'tags': tags,
        'people': people,
        'places': places.map((item) => item.toJson()).toList(),
        'media': media.map((item) => item.toJson()).toList(),
        'sourceDeepLink': sourceDeepLink,
        'privacyScope': privacyScope.name,
        'transferMode': transferMode.name,
        'revision': revision,
        'provenance': provenance.toJson(),
        'fallback': fallback.toJson(),
      };

  factory EcosystemEnvelope.fromJson(Map<String, Object?> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion != EcosystemContract.schemaVersion) {
      throw FormatException(
        'Unsupported EcosystemEnvelope schema version: $schemaVersion',
      );
    }

    final sourceApp =
        EcosystemAppId.fromWire(json['sourceApp']! as String);
    final sourceEntityType = EcosystemEntityType.values.byName(
      json['sourceEntityType']! as String,
    );
    final sourceEntityId = json['sourceEntityId']! as String;
    final revision = (json['revision'] as num?)?.toInt() ?? 1;
    final sourceDeepLink = json['sourceDeepLink'] as String?;

    final provenanceJson = json['provenance'];
    final provenance = provenanceJson is Map
        ? EcosystemProvenance.fromJson(
            Map<String, Object?>.from(provenanceJson),
          )
        : EcosystemProvenance(
            ownerApp: sourceApp,
            ownerEntityType: sourceEntityType,
            ownerEntityId: sourceEntityId,
            ownerRevision: revision,
            canonicalDeepLink: sourceDeepLink,
          );

    final title = json['title'] as String?;
    final text = json['text'] as String?;
    final fallbackJson = json['fallback'];
    final fallback = fallbackJson is Map
        ? EcosystemFallback.fromJson(
            Map<String, Object?>.from(fallbackJson),
          )
        : EcosystemFallback(
            plainText: _defaultFallbackText(title, text),
            sourceDeepLink: sourceDeepLink,
          );

    return EcosystemEnvelope(
      schemaVersion: schemaVersion,
      bridgeId: json['bridgeId'] as String? ??
          EcosystemBridgeIdentity.forOwner(
            ownerApp: provenance.ownerApp,
            ownerEntityType: provenance.ownerEntityType,
            ownerEntityId: provenance.ownerEntityId,
          ),
      sourceApp: sourceApp,
      sourceEntityType: sourceEntityType,
      sourceEntityId: sourceEntityId,
      createdAtUtc: DateTime.parse(json['createdAtUtc']! as String).toUtc(),
      title: title,
      text: text,
      tags: List<String>.unmodifiable(
        (json['tags'] as List<Object?>? ?? const []).whereType<String>(),
      ),
      people: List<String>.unmodifiable(
        (json['people'] as List<Object?>? ?? const []).whereType<String>(),
      ),
      places: List<EcosystemPlace>.unmodifiable(
        (json['places'] as List<Object?>? ?? const []).map(
          (item) => EcosystemPlace.fromJson(
            Map<String, Object?>.from(item! as Map),
          ),
        ),
      ),
      media: List<EcosystemMediaReference>.unmodifiable(
        (json['media'] as List<Object?>? ?? const []).map(
          (item) => EcosystemMediaReference.fromJson(
            Map<String, Object?>.from(item! as Map),
          ),
        ),
      ),
      sourceDeepLink: sourceDeepLink,
      privacyScope: EcosystemPrivacyScope.values.byName(
        json['privacyScope'] as String? ?? 'explicitShare',
      ),
      transferMode: EcosystemTransferMode.values.byName(
        json['transferMode'] as String? ?? 'copy',
      ),
      revision: revision,
      provenance: provenance,
      fallback: fallback,
    );
  }

  static String _defaultFallbackText(String? title, String? text) {
    final values = <String>[
      if ((title ?? '').trim().isNotEmpty) title!.trim(),
      if ((text ?? '').trim().isNotEmpty) text!.trim(),
    ];
    return values.join('\n\n');
  }
}
