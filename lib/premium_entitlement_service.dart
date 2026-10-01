import 'package:flutter/foundation.dart';

enum PremiumCapability {
  cycleInsights,
  cycleAdvancedTracking,
  cycleCustomSymptoms,
  cyclePrivateReport,
}

class PremiumEntitlementService extends ChangeNotifier {
  PremiumEntitlementService._();

  static final PremiumEntitlementService instance =
      PremiumEntitlementService._();

  static const bool _previewEnabled = bool.fromEnvironment(
    'ANNA_PREMIUM_PREVIEW',
    defaultValue: true,
  );

  bool _paidEntitlement = false;

  bool get paidEntitlement => _paidEntitlement;
  bool get previewMode => _previewEnabled && !_paidEntitlement;
  bool get hasPremiumAccess => _paidEntitlement || _previewEnabled;

  bool allows(PremiumCapability capability) => hasPremiumAccess;

  /// Temporary bridge until the app-wide purchase provider is introduced.
  ///
  /// v0.89 keeps the entitlement decision centralized so RevenueCat or
  /// another provider can replace this source without scattering paywall
  /// checks through product screens.
  @visibleForTesting
  void setPaidEntitlementForTesting(bool value) {
    if (_paidEntitlement == value) return;
    _paidEntitlement = value;
    notifyListeners();
  }
}
