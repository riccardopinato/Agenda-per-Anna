import 'dart:convert';

import 'ecosystem_contract.dart';
import 'ecosystem_contract_validator.dart';
import 'ecosystem_envelope.dart';
import 'ecosystem_models.dart';
import 'ecosystem_registry.dart';

const int ecosystemLocalTransportVersion =
    EcosystemContract.localTransportVersion;
const String ecosystemClipboardPrefix =
    EcosystemContract.clipboardPrefix;
const int ecosystemMaxLocalPayloadCharacters =
    EcosystemContract.maxLocalPayloadCharacters;

final class EcosystemTransferPackage {
  const EcosystemTransferPackage({
    this.transportVersion = ecosystemLocalTransportVersion,
    required this.targetApp,
    required this.envelope,
    required this.createdAtUtc,
  });

  final int transportVersion;
  final EcosystemAppId targetApp;
  final EcosystemEnvelope envelope;
  final DateTime createdAtUtc;

  Map<String, Object?> toJson() => {
        'transportVersion': transportVersion,
        'targetApp': targetApp.wireValue,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        'envelope': envelope.toJson(),
      };

  factory EcosystemTransferPackage.fromJson(
    Map<String, Object?> json,
  ) {
    try {
      final rawTransportVersion = json['transportVersion'];
      if (rawTransportVersion != null && rawTransportVersion is! num) {
        throw const FormatException(
          'Ecosystem transportVersion must be numeric.',
        );
      }
      final transportVersion =
          (rawTransportVersion as num?)?.toInt() ?? 1;
      if (transportVersion != ecosystemLocalTransportVersion) {
        throw FormatException(
          'Unsupported ecosystem local transport version: '
          '\$transportVersion',
        );
      }

      final targetAppRaw = json['targetApp'];
      if (targetAppRaw is! String || targetAppRaw.trim().isEmpty) {
        throw const FormatException(
          'Missing or invalid ecosystem targetApp.',
        );
      }

      final createdAtRaw = json['createdAtUtc'];
      if (createdAtRaw is! String || createdAtRaw.trim().isEmpty) {
        throw const FormatException(
          'Missing or invalid ecosystem createdAtUtc.',
        );
      }

      final envelopeRaw = json['envelope'];
      if (envelopeRaw is! Map) {
        throw const FormatException('Missing ecosystem envelope.');
      }

      final envelope = EcosystemEnvelope.fromJson(
        Map<String, Object?>.from(envelopeRaw),
      );
      EcosystemContractValidator.ensureValid(envelope);

      return EcosystemTransferPackage(
        transportVersion: transportVersion,
        targetApp: EcosystemAppId.fromWire(targetAppRaw),
        envelope: envelope,
        createdAtUtc: DateTime.parse(createdAtRaw).toUtc(),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'Invalid ecosystem transfer package: \$error',
      );
    }
  }
}

abstract final class EcosystemLocalTransportCodec {
  static String encode(EcosystemTransferPackage package) {
    EcosystemContractValidator.ensureValid(package.envelope);
    final json = jsonEncode(package.toJson());
    return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  }

  static EcosystemTransferPackage decode(String encoded) {
    final normalized = encoded.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Empty ecosystem transport payload.');
    }
    final padded = normalized.padRight(
      normalized.length + ((4 - normalized.length % 4) % 4),
      '=',
    );
    final json = utf8.decode(base64Url.decode(padded));
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException('Invalid ecosystem transport payload.');
    }
    return EcosystemTransferPackage.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  static Uri targetUri(EcosystemTransferPackage package) {
    final encoded = encode(package);
    if (encoded.length > ecosystemMaxLocalPayloadCharacters) {
      throw StateError('Ecosystem local payload exceeds URI limit.');
    }
    final target = EcosystemRegistry.definition(package.targetApp);
    return Uri(
      scheme: target.deepLinkScheme,
      host: 'ecosystem',
      path: '/import',
      queryParameters: {'payload': encoded},
    );
  }

  static EcosystemTransferPackage decodeTargetUri(Uri uri) {
    if (uri.host != 'ecosystem' || uri.path != '/import') {
      throw const FormatException('Unsupported ecosystem import URI.');
    }
    final payload = uri.queryParameters['payload'];
    if (payload == null || payload.trim().isEmpty) {
      throw const FormatException('Missing ecosystem import payload.');
    }
    final package = decode(payload);
    final expectedScheme =
        EcosystemRegistry.definition(package.targetApp).deepLinkScheme;
    if (uri.scheme != expectedScheme) {
      throw const FormatException('Ecosystem target scheme mismatch.');
    }
    return package;
  }

  static String clipboardText(EcosystemTransferPackage package) =>
      ecosystemClipboardPrefix + encode(package);

  static EcosystemTransferPackage decodeClipboardText(String value) {
    final normalized = value.trim();
    if (!normalized.startsWith(ecosystemClipboardPrefix)) {
      throw const FormatException(
        'Clipboard does not contain an ecosystem transfer.',
      );
    }
    return decode(normalized.substring(ecosystemClipboardPrefix.length));
  }
}
