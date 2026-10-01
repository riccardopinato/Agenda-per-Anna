import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

enum PremiumCapability {
  cycleInsights,
  cycleAdvancedTracking,
  cycleCustomSymptoms,
  cyclePrivateReport,
}

enum PremiumStoreState {
  unconfigured,
  initializing,
  ready,
  error,
}

enum PremiumProductKind {
  monthly,
  lifetime,
  other,
}

enum PremiumPurchaseOutcome {
  success,
  cancelled,
  unavailable,
  unsupported,
  failed,
}

class PremiumStoreDiagnostics {
  final bool configured;
  final bool storeReleaseMode;
  final bool storeQaMode;
  final bool previewMode;
  final bool paidEntitlement;
  final String entitlementId;
  final String? currentOfferingIdentifier;
  final int productCount;
  final bool hasMonthly;
  final bool hasLifetime;
  final bool identityLinked;
  final bool canRestorePurchases;
  final String? lastError;
  final PremiumPurchaseOutcome? lastPurchaseOutcome;
  final String? lastPurchaseProductIdentifier;

  const PremiumStoreDiagnostics({
    required this.configured,
    required this.storeReleaseMode,
    required this.storeQaMode,
    required this.previewMode,
    required this.paidEntitlement,
    required this.entitlementId,
    required this.currentOfferingIdentifier,
    required this.productCount,
    required this.hasMonthly,
    required this.hasLifetime,
    required this.identityLinked,
    required this.canRestorePurchases,
    this.lastError,
    this.lastPurchaseOutcome,
    this.lastPurchaseProductIdentifier,
  });

  bool get catalogReady =>
      configured &&
      currentOfferingIdentifier != null &&
      hasMonthly &&
      hasLifetime;

  bool get purchaseQaReady =>
      catalogReady &&
      storeReleaseMode &&
      storeQaMode &&
      !previewMode;
}

class PremiumStoreProduct {
  final String packageIdentifier;
  final String productIdentifier;
  final PremiumProductKind kind;
  final String title;
  final String description;
  final String price;

  const PremiumStoreProduct({
    required this.packageIdentifier,
    required this.productIdentifier,
    required this.kind,
    required this.title,
    required this.description,
    required this.price,
  });
}

class PremiumEntitlementService extends ChangeNotifier {
  PremiumEntitlementService._();

  static final PremiumEntitlementService instance =
      PremiumEntitlementService._();

  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_PREMIUM_ENTITLEMENT',
    defaultValue: 'premium',
  );

  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const String _webApiKey = String.fromEnvironment(
    'REVENUECAT_WEB_API_KEY',
  );

  static const bool _previewOverride = bool.fromEnvironment(
    'ANNA_PREMIUM_PREVIEW',
    defaultValue: false,
  );
  static const bool _storeRelease = bool.fromEnvironment(
    'ANNA_STORE_RELEASE',
    defaultValue: false,
  );
  static const bool _storeQa = bool.fromEnvironment(
    'ANNA_STORE_QA',
    defaultValue: false,
  );

  PremiumStoreState _state = PremiumStoreState.unconfigured;
  bool _sdkConfigured = false;
  bool _initializing = false;
  bool _listenerRegistered = false;
  bool _paidEntitlement = false;
  String? _identifiedAppUserId;
  String? _lastError;
  String? _currentOfferingIdentifier;
  PremiumPurchaseOutcome? _lastPurchaseOutcome;
  String? _lastPurchaseProductIdentifier;
  List<PremiumStoreProduct> _products = const [];
  final Map<String, rc.Package> _packagesByIdentifier = {};

  PremiumStoreState get state => _state;
  bool get configured => _sdkConfigured;
  bool get paidEntitlement => _paidEntitlement;
  bool get storeReleaseMode => _storeRelease;
  bool get storeQaMode => _storeQa;
  bool get previewMode =>
      !_paidEntitlement && !_storeRelease && (kDebugMode || _previewOverride);
  bool get hasPremiumAccess => _paidEntitlement || previewMode;
  bool get busy => _state == PremiumStoreState.initializing;
  bool get canRestorePurchases => _sdkConfigured && !kIsWeb;
  String? get lastError => _lastError;
  String? get identifiedAppUserId => _identifiedAppUserId;
  List<PremiumStoreProduct> get products =>
      List<PremiumStoreProduct>.unmodifiable(_products);

  PremiumStoreDiagnostics get diagnostics {
    final kinds = _products.map((product) => product.kind).toSet();
    return PremiumStoreDiagnostics(
      configured: _sdkConfigured,
      storeReleaseMode: _storeRelease,
      storeQaMode: _storeQa,
      previewMode: previewMode,
      paidEntitlement: _paidEntitlement,
      entitlementId: entitlementId,
      currentOfferingIdentifier: _currentOfferingIdentifier,
      productCount: _products.length,
      hasMonthly: kinds.contains(PremiumProductKind.monthly),
      hasLifetime: kinds.contains(PremiumProductKind.lifetime),
      identityLinked: _identifiedAppUserId != null,
      canRestorePurchases: canRestorePurchases,
      lastError: _lastError,
      lastPurchaseOutcome: _lastPurchaseOutcome,
      lastPurchaseProductIdentifier: _lastPurchaseProductIdentifier,
    );
  }

  bool allows(PremiumCapability capability) => hasPremiumAccess;

  String get _platformApiKey {
    if (kIsWeb) return _webApiKey.trim();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidApiKey.trim(),
      TargetPlatform.iOS => _iosApiKey.trim(),
      _ => '',
    };
  }

  Future<void> initialize({String? appUserId}) async {
    final normalizedId = _normalizeUserId(appUserId);
    if (_sdkConfigured) {
      await syncIdentity(normalizedId);
      await refresh();
      return;
    }
    if (_initializing) return;

    final apiKey = _platformApiKey;
    if (_storeQa && !_storeRelease) {
      _identifiedAppUserId = normalizedId;
      _state = PremiumStoreState.error;
      _lastError = 'premium_store_qa_requires_store_release';
      notifyListeners();
      return;
    }
    if (_storeRelease && _previewOverride) {
      _identifiedAppUserId = normalizedId;
      _state = PremiumStoreState.error;
      _lastError = 'premium_store_release_preview_enabled';
      notifyListeners();
      return;
    }
    if (_storeRelease && apiKey.isEmpty) {
      _identifiedAppUserId = normalizedId;
      _state = PremiumStoreState.error;
      _lastError = 'premium_store_release_missing_api_key';
      notifyListeners();
      return;
    }
    if (apiKey.isEmpty) {
      _identifiedAppUserId = normalizedId;
      _state = PremiumStoreState.unconfigured;
      _lastError = null;
      notifyListeners();
      return;
    }

    _initializing = true;
    _state = PremiumStoreState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      await rc.Purchases.setLogLevel(
        kDebugMode ? rc.LogLevel.debug : rc.LogLevel.warn,
      );
      final configuration = rc.PurchasesConfiguration(apiKey);
      if (normalizedId != null) {
        configuration.appUserID = normalizedId;
      }
      await rc.Purchases.configure(configuration);
      _sdkConfigured = true;
      _identifiedAppUserId = normalizedId;

      if (!_listenerRegistered) {
        rc.Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
        _listenerRegistered = true;
      }

      await refresh();
      _state = PremiumStoreState.ready;
    } catch (error) {
      _state = PremiumStoreState.error;
      _lastError = error.toString();
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> syncIdentity(String? appUserId) async {
    final normalizedId = _normalizeUserId(appUserId);
    if (!_sdkConfigured) {
      _identifiedAppUserId = normalizedId;
      return;
    }
    if (normalizedId == _identifiedAppUserId) return;

    _state = PremiumStoreState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      if (normalizedId == null) {
        if (_identifiedAppUserId != null) {
          final info = await rc.Purchases.logOut();
          _applyCustomerInfo(info);
        }
      } else {
        final result = await rc.Purchases.logIn(normalizedId);
        _applyCustomerInfo(result.customerInfo);
      }
      _identifiedAppUserId = normalizedId;
      await _refreshOfferings();
      _state = PremiumStoreState.ready;
    } catch (error) {
      _state = PremiumStoreState.error;
      _lastError = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!_sdkConfigured) return;

    _state = PremiumStoreState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      final info = await rc.Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
      await _refreshOfferings();
      _state = PremiumStoreState.ready;
    } catch (error) {
      _state = PremiumStoreState.error;
      _lastError = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<PremiumPurchaseOutcome> purchase(
    PremiumStoreProduct product,
  ) async {
    if (!_sdkConfigured) return PremiumPurchaseOutcome.unavailable;
    final package = _packagesByIdentifier[product.packageIdentifier];
    if (package == null) return PremiumPurchaseOutcome.unavailable;

    _state = PremiumStoreState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      final result = await rc.Purchases.purchase(
        rc.PurchaseParams.package(package),
      );
      _applyCustomerInfo(result.customerInfo);
      _state = PremiumStoreState.ready;
      final outcome = _paidEntitlement
          ? PremiumPurchaseOutcome.success
          : PremiumPurchaseOutcome.failed;
      _recordPurchaseOutcome(product, outcome);
      return outcome;
    } on PlatformException catch (error) {
      final code = rc.PurchasesErrorHelper.getErrorCode(error);
      _state = PremiumStoreState.ready;
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        _recordPurchaseOutcome(product, PremiumPurchaseOutcome.cancelled);
        return PremiumPurchaseOutcome.cancelled;
      }
      _lastError = error.message ?? error.toString();
      _recordPurchaseOutcome(product, PremiumPurchaseOutcome.failed);
      return PremiumPurchaseOutcome.failed;
    } catch (error) {
      _state = PremiumStoreState.error;
      _lastError = error.toString();
      _recordPurchaseOutcome(product, PremiumPurchaseOutcome.failed);
      return PremiumPurchaseOutcome.failed;
    } finally {
      notifyListeners();
    }
  }

  Future<PremiumPurchaseOutcome> restorePurchases() async {
    if (!_sdkConfigured) return PremiumPurchaseOutcome.unavailable;
    if (kIsWeb) return PremiumPurchaseOutcome.unsupported;

    _state = PremiumStoreState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      final info = await rc.Purchases.restorePurchases();
      _applyCustomerInfo(info);
      _state = PremiumStoreState.ready;
      return _paidEntitlement
          ? PremiumPurchaseOutcome.success
          : PremiumPurchaseOutcome.failed;
    } on PlatformException catch (error) {
      _state = PremiumStoreState.ready;
      _lastError = error.message ?? error.toString();
      return PremiumPurchaseOutcome.failed;
    } catch (error) {
      _state = PremiumStoreState.error;
      _lastError = error.toString();
      return PremiumPurchaseOutcome.failed;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _refreshOfferings() async {
    final offerings = await rc.Purchases.getOfferings();
    final offering = offerings.current;
    _packagesByIdentifier.clear();

    if (offering == null) {
      _currentOfferingIdentifier = null;
      _products = const [];
      return;
    }
    _currentOfferingIdentifier = offering.identifier;

    final products = <PremiumStoreProduct>[];
    for (final package in offering.availablePackages) {
      _packagesByIdentifier[package.identifier] = package;
      final kind = switch (package.packageType) {
        rc.PackageType.monthly => PremiumProductKind.monthly,
        rc.PackageType.lifetime => PremiumProductKind.lifetime,
        _ => PremiumProductKind.other,
      };
      products.add(
        PremiumStoreProduct(
          packageIdentifier: package.identifier,
          productIdentifier: package.storeProduct.identifier,
          kind: kind,
          title: package.storeProduct.title,
          description: package.storeProduct.description,
          price: package.storeProduct.priceString,
        ),
      );
    }

    products.sort((a, b) {
      int rank(PremiumProductKind value) => switch (value) {
            PremiumProductKind.monthly => 0,
            PremiumProductKind.lifetime => 1,
            PremiumProductKind.other => 2,
          };
      final byKind = rank(a.kind).compareTo(rank(b.kind));
      return byKind != 0 ? byKind : a.price.compareTo(b.price);
    });
    _products = List<PremiumStoreProduct>.unmodifiable(products);
  }

  void _recordPurchaseOutcome(
    PremiumStoreProduct product,
    PremiumPurchaseOutcome outcome,
  ) {
    _lastPurchaseProductIdentifier = product.productIdentifier;
    _lastPurchaseOutcome = outcome;
  }

  void _onCustomerInfoUpdated(rc.CustomerInfo info) {
    _applyCustomerInfo(info);
    notifyListeners();
  }

  void _applyCustomerInfo(rc.CustomerInfo info) {
    _paidEntitlement =
        info.entitlements.all[entitlementId]?.isActive == true;
  }

  String? _normalizeUserId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  @visibleForTesting
  void setPaidEntitlementForTesting(bool value) {
    if (_paidEntitlement == value) return;
    _paidEntitlement = value;
    notifyListeners();
  }
}
