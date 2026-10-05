import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ecosystem/ecosystem_models.dart';
import 'ecosystem/ecosystem_registry.dart' as core;

enum EcosystemHubIntegrationStatus {
  active,
  certifiedCompatible,
  planned,
}

enum EcosystemAvailability {
  available,
  unavailable,
  unknown,
}

enum EcosystemLaunchOutcome {
  opened,
  unavailable,
  invalidUri,
}

class EcosystemHubAppDefinition {
  final String appId;
  final String displayName;
  final EcosystemHubIntegrationStatus integrationStatus;
  final String? contractLabel;
  final Set<String> protocolVersions;
  final Set<String> sends;
  final Set<String> receives;
  final String? probeUri;
  final String? launchUri;
  final String? fallbackUri;

  const EcosystemHubAppDefinition({
    required this.appId,
    required this.displayName,
    required this.integrationStatus,
    this.contractLabel,
    this.protocolVersions = const <String>{},
    this.sends = const <String>{},
    this.receives = const <String>{},
    this.probeUri,
    this.launchUri,
    this.fallbackUri,
  });
}

class EcosystemHubRegistry {
  EcosystemHubRegistry._();

  static EcosystemHubAppDefinition _coreApp(
    EcosystemAppId id, {
    required EcosystemHubIntegrationStatus integrationStatus,
    required String contractLabel,
    Set<String> protocolVersions = const <String>{},
    Set<String> sends = const <String>{},
    Set<String> receives = const <String>{},
    String? probeRoute,
  }) {
    final definition = core.EcosystemRegistry.definition(id);
    return EcosystemHubAppDefinition(
      appId: definition.id.wireValue,
      displayName: definition.displayName,
      integrationStatus: integrationStatus,
      contractLabel: contractLabel,
      protocolVersions: protocolVersions,
      sends: sends,
      receives: receives,
      probeUri: probeRoute == null
          ? null
          : '${definition.deepLinkScheme}://$probeRoute',
    );
  }

  static final List<EcosystemHubAppDefinition> apps = [
    _coreApp(
      EcosystemAppId.annasDiary,
      integrationStatus: EcosystemHubIntegrationStatus.active,
      contractLabel: 'Shared Ecosystem Core v1',
      protocolVersions: const {'1.0'},
      sends: const {'note', 'photo', 'moment', 'event'},
      receives: const {
        'moment',
        'travel_memory',
        'journey',
        'photo',
        'place',
        'event',
      },
    ),
    _coreApp(
      EcosystemAppId.wonderlog,
      integrationStatus: EcosystemHubIntegrationStatus.certifiedCompatible,
      contractLabel: 'E1 · Shared Ecosystem Core v1',
      protocolVersions: const {'1.0'},
      sends: const {'journey', 'travel_memory', 'photo', 'place'},
      receives: const {'note', 'photo'},
      // Android package-visibility probe only. Concrete opening uses the
      // canonical source object deep link already preserved by E1 provenance.
      probeRoute: 'journey',
    ),
    _coreApp(
      EcosystemAppId.notes,
      integrationStatus: EcosystemHubIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
    _coreApp(
      EcosystemAppId.trailpath,
      integrationStatus: EcosystemHubIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
    const EcosystemHubAppDefinition(
      appId: 'sleepmax',
      displayName: 'SleepMax',
      integrationStatus: EcosystemHubIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
    const EcosystemHubAppDefinition(
      appId: 'cashmate',
      displayName: 'CashMate',
      integrationStatus: EcosystemHubIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
  ];

  static EcosystemHubAppDefinition? byAppId(String appId) {
    final normalized = appId.trim().toLowerCase();
    for (final app in apps) {
      if (app.appId == normalized) return app;
    }
    return null;
  }

  static String displayNameFor(String appId) =>
      byAppId(appId)?.displayName ?? appId.trim();
}

typedef EcosystemCanLaunch = Future<bool> Function(Uri uri);
typedef EcosystemLaunch = Future<bool> Function(Uri uri);

class EcosystemLauncher {
  final EcosystemCanLaunch _canLaunch;
  final EcosystemLaunch _launch;

  EcosystemLauncher({
    EcosystemCanLaunch? canLaunch,
    EcosystemLaunch? launch,
  })  : _canLaunch = canLaunch ?? canLaunchUrl,
        _launch = launch ??
            ((uri) => launchUrl(
                  uri,
                  mode: LaunchMode.platformDefault,
                ));

  static final EcosystemLauncher instance = EcosystemLauncher();

  Future<EcosystemAvailability> availabilityFor(
    EcosystemHubAppDefinition app,
  ) async {
    final raw = app.probeUri?.trim() ?? '';
    if (raw.isEmpty || kIsWeb) return EcosystemAvailability.unknown;

    if (defaultTargetPlatform != TargetPlatform.android) {
      return EcosystemAvailability.unknown;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return EcosystemAvailability.unknown;

    try {
      return await _canLaunch(uri)
          ? EcosystemAvailability.available
          : EcosystemAvailability.unavailable;
    } catch (_) {
      return EcosystemAvailability.unknown;
    }
  }

  Future<EcosystemLaunchOutcome> openApp(
    EcosystemHubAppDefinition app,
  ) async {
    final primary = app.launchUri?.trim() ?? '';
    final fallback = app.fallbackUri?.trim() ?? '';

    if (primary.isNotEmpty) {
      final result = await openDeepLink(primary);
      if (result == EcosystemLaunchOutcome.opened) return result;
    }

    if (fallback.isNotEmpty) {
      return openDeepLink(fallback);
    }

    return EcosystemLaunchOutcome.unavailable;
  }

  Future<EcosystemLaunchOutcome> openDeepLink(String? rawUri) async {
    final raw = rawUri?.trim() ?? '';
    if (raw.isEmpty) return EcosystemLaunchOutcome.unavailable;

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      return EcosystemLaunchOutcome.invalidUri;
    }

    try {
      return await _launch(uri)
          ? EcosystemLaunchOutcome.opened
          : EcosystemLaunchOutcome.unavailable;
    } catch (_) {
      return EcosystemLaunchOutcome.unavailable;
    }
  }
}
