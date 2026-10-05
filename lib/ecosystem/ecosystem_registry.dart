import 'ecosystem_models.dart';

enum EcosystemCapability {
  receiveText,
  receivePhoto,
  receivePlace,
  receiveJourney,
  receiveRoute,
}

final class EcosystemAppDefinition {
  const EcosystemAppDefinition({
    required this.id,
    required this.displayName,
    required this.deepLinkScheme,
    required this.capabilities,
  });

  final EcosystemAppId id;
  final String displayName;
  final String deepLinkScheme;
  final Set<EcosystemCapability> capabilities;
}

abstract final class EcosystemRegistry {
  static const apps = <EcosystemAppDefinition>[
    EcosystemAppDefinition(
      id: EcosystemAppId.wonderlog,
      displayName: 'Wonderlog',
      deepLinkScheme: 'wonderlog',
      capabilities: {
        EcosystemCapability.receiveText,
        EcosystemCapability.receivePhoto,
        EcosystemCapability.receivePlace,
        EcosystemCapability.receiveJourney,
        EcosystemCapability.receiveRoute,
      },
    ),
    EcosystemAppDefinition(
      id: EcosystemAppId.annasDiary,
      displayName: "Anna's Diary",
      deepLinkScheme: 'annasdiary',
      capabilities: {
        EcosystemCapability.receiveText,
        EcosystemCapability.receivePhoto,
        EcosystemCapability.receivePlace,
        EcosystemCapability.receiveJourney,
      },
    ),
    EcosystemAppDefinition(
      id: EcosystemAppId.notes,
      displayName: 'Notes',
      deepLinkScheme: 'notesapp',
      capabilities: {
        EcosystemCapability.receiveText,
        EcosystemCapability.receivePhoto,
      },
    ),
    EcosystemAppDefinition(
      id: EcosystemAppId.trailpath,
      displayName: 'TrailPath',
      deepLinkScheme: 'trailpath',
      capabilities: {
        EcosystemCapability.receivePlace,
        EcosystemCapability.receiveRoute,
      },
    ),
  ];

  static EcosystemAppDefinition definition(EcosystemAppId id) =>
      apps.firstWhere((app) => app.id == id);
}
