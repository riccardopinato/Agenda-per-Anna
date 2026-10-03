import 'ecosystem_envelope.dart';
import 'ecosystem_models.dart';

final class EcosystemContractValidation {
  const EcosystemContractValidation({
    required this.valid,
    this.reason,
  });

  final bool valid;
  final String? reason;
}

abstract final class EcosystemContractValidator {
  static EcosystemContractValidation validate(
    EcosystemEnvelope envelope,
  ) {
    if (envelope.schemaVersion != 1) {
      return const EcosystemContractValidation(
        valid: false,
        reason: 'unsupported_schema',
      );
    }
    if (envelope.privacyScope != EcosystemPrivacyScope.explicitShare) {
      return const EcosystemContractValidation(
        valid: false,
        reason: 'explicit_share_required',
      );
    }
    if (envelope.revision < 1 ||
        envelope.provenance.ownerRevision < 1) {
      return const EcosystemContractValidation(
        valid: false,
        reason: 'invalid_revision',
      );
    }

    final expectedBridgeId = EcosystemBridgeIdentity.forOwner(
      ownerApp: envelope.provenance.ownerApp,
      ownerEntityType: envelope.provenance.ownerEntityType,
      ownerEntityId: envelope.provenance.ownerEntityId,
    );
    if (envelope.bridgeId != expectedBridgeId) {
      return const EcosystemContractValidation(
        valid: false,
        reason: 'bridge_id_mismatch',
      );
    }

    if (envelope.transferMode == EcosystemTransferMode.link &&
        (envelope.provenance.canonicalDeepLink ?? '').trim().isEmpty) {
      return const EcosystemContractValidation(
        valid: false,
        reason: 'link_requires_canonical_deep_link',
      );
    }

    for (final media in envelope.media) {
      final handoff = media.handoff;
      if (handoff.kind == EcosystemMediaHandoffKind.shareToken &&
          (handoff.token ?? '').trim().isEmpty) {
        return const EcosystemContractValidation(
          valid: false,
          reason: 'share_token_missing',
        );
      }
      if (handoff.kind == EcosystemMediaHandoffKind.cloudObject &&
          (handoff.locator ?? '').trim().isEmpty) {
        return const EcosystemContractValidation(
          valid: false,
          reason: 'cloud_locator_missing',
        );
      }

      for (final value in <String?>[
        handoff.token,
        handoff.locator,
      ]) {
        if (_looksPrivateLocalReference(value)) {
          return const EcosystemContractValidation(
            valid: false,
            reason: 'private_media_reference_forbidden',
          );
        }
      }
    }

    if (envelope.fallback.plainText.trim().isEmpty &&
        (envelope.fallback.sourceDeepLink ?? '').trim().isEmpty &&
        (envelope.fallback.webUrl ?? '').trim().isEmpty) {
      return const EcosystemContractValidation(
        valid: false,
        reason: 'fallback_required',
      );
    }

    return const EcosystemContractValidation(valid: true);
  }

  static void ensureValid(EcosystemEnvelope envelope) {
    final result = validate(envelope);
    if (!result.valid) {
      throw StateError(
        'Invalid ecosystem contract: ${result.reason ?? 'unknown'}',
      );
    }
  }

  static bool _looksPrivateLocalReference(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized.startsWith('file://') ||
        normalized.startsWith('content://') ||
        normalized.startsWith('media://') ||
        normalized.startsWith('/data/') ||
        normalized.startsWith('/private/');
  }
}
