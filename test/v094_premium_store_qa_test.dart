import 'dart:io';

import 'package:agenda_per_anna/premium_entitlement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Store QA readiness requires real catalog and QA build mode', () {
    const ready = PremiumStoreDiagnostics(
      configured: true,
      storeReleaseMode: true,
      storeQaMode: true,
      previewMode: false,
      paidEntitlement: false,
      entitlementId: 'premium',
      currentOfferingIdentifier: 'default',
      productCount: 2,
      hasMonthly: true,
      hasLifetime: true,
      identityLinked: false,
      canRestorePurchases: true,
    );

    expect(ready.catalogReady, isTrue);
    expect(ready.purchaseQaReady, isTrue);
    expect(ready.paidEntitlement, isFalse);

    const preview = PremiumStoreDiagnostics(
      configured: true,
      storeReleaseMode: true,
      storeQaMode: true,
      previewMode: true,
      paidEntitlement: false,
      entitlementId: 'premium',
      currentOfferingIdentifier: 'default',
      productCount: 2,
      hasMonthly: true,
      hasLifetime: true,
      identityLinked: false,
      canRestorePurchases: true,
    );
    expect(preview.purchaseQaReady, isFalse);

    const missingLifetime = PremiumStoreDiagnostics(
      configured: true,
      storeReleaseMode: true,
      storeQaMode: true,
      previewMode: false,
      paidEntitlement: false,
      entitlementId: 'premium',
      currentOfferingIdentifier: 'default',
      productCount: 1,
      hasMonthly: true,
      hasLifetime: false,
      identityLinked: false,
      canRestorePurchases: true,
    );
    expect(missingLifetime.catalogReady, isFalse);
    expect(missingLifetime.purchaseQaReady, isFalse);
  });

  test('Store QA never becomes an entitlement bypass', () {
    final service =
        File('lib/premium_entitlement_service.dart').readAsStringSync();

    expect(service, contains("'ANNA_STORE_QA'"));
    expect(
      service,
      contains('_paidEntitlement || previewMode'),
    );
    expect(
      service,
      isNot(contains('_paidEntitlement || _storeQa')),
    );
    expect(
      service,
      contains('premium_store_qa_requires_store_release'),
    );
  });

  test('production and Play QA workflows remain explicitly separated', () {
    final production =
        File('.github/workflows/build.yml').readAsStringSync();
    final qa =
        File('.github/workflows/premium-store-qa.yml').readAsStringSync();

    expect(production, contains('ANNA_STORE_QA: "false"'));
    expect(production, contains('--dart-define=ANNA_STORE_QA=false'));
    expect(production, isNot(contains('--dart-define=ANNA_STORE_QA=true')));

    expect(qa, contains('ANNA_STORE_QA: "true"'));
    expect(qa, contains('--dart-define=ANNA_STORE_QA=true'));
    expect(qa, contains('--dart-define=ANNA_PREMIUM_PREVIEW=false'));
    expect(qa, contains('flutter build appbundle'));
    expect(qa, contains('Google Play Internal Testing'));
    expect(qa, contains('Do not sideload for billing verification'));
  });

  test('QA diagnostics report excludes API key and raw app-user identity', () {
    final screen =
        File('lib/src/screens/premium_screen.dart').readAsStringSync();

    expect(screen, contains('PremiumStoreQaScreen'));
    expect(screen, contains('purchaseQaReady'));
    expect(screen, contains('identityLinked='));
    expect(screen, isNot(contains('REVENUECAT_ANDROID_API_KEY')));
    expect(screen, isNot(contains('identifiedAppUserId')));
  });

  test('release validator recognizes explicit QA mode without weakening gates', () {
    final validator =
        File('tool/validate_premium_release.py').readAsStringSync();

    expect(validator, contains('ANNA_STORE_RELEASE must be true'));
    expect(validator, contains('ANNA_PREMIUM_PREVIEW must be false'));
    expect(validator, contains('REVENUECAT_ANDROID_API_KEY is required'));
    expect(validator, contains('ANNA_STORE_QA'));
    expect(validator, contains('Premium store {mode} configuration validated.'));
  });
}
