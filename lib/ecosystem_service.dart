import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum EcosystemIntegrationStatus {
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

class EcosystemAppDefinition {
  final String appId;
  final String displayName;
  final EcosystemIntegrationStatus integrationStatus;
  final String? contractLabel;
  final Set<String> protocolVersions;
  final Set<String> sends;
  final Set<String> receives;
  final String? probeUri;
  final String? launchUri;
  final String? fallbackUri;

  const EcosystemAppDefinition({
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

class EcosystemRegistry {
  EcosystemRegistry._();

  static const List<EcosystemAppDefinition> apps = [
    EcosystemAppDefinition(
      appId: 'annas_diary',
      displayName: "Anna's Diary",
      integrationStatus: EcosystemIntegrationStatus.active,
      contractLabel: 'Shared Ecosystem Core v1',
      protocolVersions: {'1.0'},
      sends: {'note', 'photo', 'moment', 'event'},
      receives: {
        'moment',
        'travel_memory',
        'journey',
        'photo',
        'place',
        'event',
      },
    ),
    EcosystemAppDefinition(
      appId: 'wonderlog',
      displayName: 'Wonderlog',
      integrationStatus: EcosystemIntegrationStatus.certifiedCompatible,
      contractLabel: 'E1 · Shared Ecosystem Core v1',
      protocolVersions: {'1.0'},
      sends: {'journey', 'travel_memory', 'photo', 'place'},
      receives: {'note', 'photo'},
      // Used only as an Android package-visibility/install probe.
      // Opening a concrete Wonderlog object uses the canonical source deep link
      // stored in bridge provenance/history rather than inventing a root route.
      probeUri: 'wonderlog://journey',
    ),
    EcosystemAppDefinition(
      appId: 'notes',
      displayName: 'Notes',
      integrationStatus: EcosystemIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
    EcosystemAppDefinition(
      appId: 'trailpath',
      displayName: 'TrailPath',
      integrationStatus: EcosystemIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
    EcosystemAppDefinition(
      appId: 'sleepmax',
      displayName: 'SleepMax',
      integrationStatus: EcosystemIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
    EcosystemAppDefinition(
      appId: 'cashmate',
      displayName: 'CashMate',
      integrationStatus: EcosystemIntegrationStatus.planned,
      contractLabel: 'Shared Ecosystem Core v1 planned',
    ),
  ];

  static EcosystemAppDefinition? byAppId(String appId) {
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
    EcosystemAppDefinition app,
  ) async {
    final raw = app.probeUri?.trim() ?? '';
    if (raw.isEmpty || kIsWeb) return EcosystemAvailability.unknown;

    // Android is the only platform where v0.97 declares an explicit package
    // visibility query. Other platforms stay honest/unknown until their native
    // install-detection contract is implemented and verified.
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
    EcosystemAppDefinition app,
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
