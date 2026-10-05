import 'ecosystem_envelope.dart';
import 'ecosystem_models.dart';
import 'ecosystem_registry.dart';

abstract final class EcosystemTransferPlanner {
  static EcosystemCapability requiredCapability(
    EcosystemEntityType entityType,
  ) =>
      switch (entityType) {
        EcosystemEntityType.journey => EcosystemCapability.receiveJourney,
        EcosystemEntityType.memory ||
        EcosystemEntityType.note ||
        EcosystemEntityType.generic =>
          EcosystemCapability.receiveText,
        EcosystemEntityType.place => EcosystemCapability.receivePlace,
        EcosystemEntityType.route => EcosystemCapability.receiveRoute,
        EcosystemEntityType.photo => EcosystemCapability.receivePhoto,
      };

  static bool canSend(
    EcosystemEnvelope envelope,
    EcosystemAppId target,
  ) {
    final definition = EcosystemRegistry.definition(target);
    final capability = requiredCapability(envelope.sourceEntityType);

    if (!definition.capabilities.contains(capability)) {
      return false;
    }

    if (envelope.media.isNotEmpty &&
        !definition.capabilities.contains(EcosystemCapability.receivePhoto) &&
        envelope.sourceEntityType != EcosystemEntityType.journey) {
      return false;
    }

    return envelope.privacyScope == EcosystemPrivacyScope.explicitShare;
  }
}
