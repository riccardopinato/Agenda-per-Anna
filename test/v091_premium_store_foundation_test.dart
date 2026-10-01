import 'dart:io';

import 'package:agenda_per_anna/premium_entitlement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium capabilities stay centralized behind one entitlement', () {
    final premium = PremiumEntitlementService.instance;

    premium.setPaidEntitlementForTesting(false);
    expect(premium.previewMode, isTrue);
    expect(premium.hasPremiumAccess, isTrue);
    expect(
      PremiumCapability.values.every(premium.allows),
      isTrue,
    );

    premium.setPaidEntitlementForTesting(true);
    expect(premium.paidEntitlement, isTrue);
    expect(premium.previewMode, isFalse);
    expect(premium.hasPremiumAccess, isTrue);

    premium.setPaidEntitlementForTesting(false);
  });

  test('RevenueCat configuration is build-time and never hardcodes a user', () {
    final source =
        File('lib/premium_entitlement_service.dart').readAsStringSync();

    expect(source, contains('REVENUECAT_ANDROID_API_KEY'));
    expect(source, contains('REVENUECAT_IOS_API_KEY'));
    expect(source, contains('REVENUECAT_WEB_API_KEY'));
    expect(source, contains("defaultValue: 'premium'"));
    expect(source, contains('configuration.appUserID = normalizedId'));
    expect(source, contains('Purchases.logIn(normalizedId)'));
    expect(source, isNot(contains('@')));
  });

  test('custom paywall is cross-platform and RevenueCat UI is not required', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final screen =
        File('lib/src/screens/premium_screen.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(pubspec, contains('purchases_flutter:'));
    expect(pubspec, isNot(contains('purchases_ui_flutter:')));
    expect(screen, contains('PremiumStoreProduct'));
    expect(screen, contains('premiumWebRestoreUnsupported'));
    expect(main, contains("part 'src/screens/premium_screen.dart';"));
    expect(
      main,
      contains('PremiumEntitlementService.instance.initialize'),
    );
    expect(
      main,
      contains('CloudSyncService.instance.userId'),
    );
  });

  test('Android generated manifest preserves Play Billing permission', () {
    final platformScript =
        File('tool/prepare_android_platform.py').readAsStringSync();

    expect(
      platformScript,
      contains('com.android.vending.BILLING'),
    );
    expect(
      platformScript,
      contains('RevenueCat billing manifest permission'),
    );
  });

  test('Premium never becomes a second source for intimate data', () {
    final premium =
        File('lib/premium_entitlement_service.dart').readAsStringSync();

    expect(premium, isNot(contains('PrivateVaultService')));
    expect(premium, isNot(contains('CycleTrackerState')));
    expect(premium, isNot(contains('DiaryBlock')));
    expect(premium, isNot(contains('AgendaStore')));
    expect(premium, isNot(contains('email')));
  });
}
