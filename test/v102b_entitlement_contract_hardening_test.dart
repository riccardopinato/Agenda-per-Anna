import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/premium_entitlement_service.dart';

void main() {
  test('Premium entitlement snapshot exposes explicit provenance', () {
    expect(
      PremiumEntitlementSource.values.map((value) => value.name),
      containsAll(<String>[
        'localDefault',
        'providerVerified',
        'qaOverride',
        'unknown',
      ]),
    );

    final service = PremiumEntitlementService.instance;
    service.setPaidEntitlementForTesting(true);
    final snapshot = service.entitlementSnapshot;

    expect(snapshot.hasAccess, isTrue);
    expect(snapshot.paidEntitlement, isTrue);
    expect(snapshot.source, PremiumEntitlementSource.providerVerified);
    expect(snapshot.isProviderBacked, isTrue);
    expect(snapshot.observedAt, isNotNull);

    service.setPaidEntitlementForTesting(false);
  });

  test('feature access uses the provider-agnostic snapshot boundary', () {
    final source =
        File('lib/premium_entitlement_service.dart').readAsStringSync();

    expect(source, contains('class PremiumEntitlementSnapshot'));
    expect(source, contains('PremiumEntitlementSnapshot get entitlementSnapshot'));
    expect(
      source,
      contains('entitlementSnapshot.hasAccess'),
    );
    expect(source, contains('PremiumEntitlementSource.qaOverride'));
    expect(source, contains('PremiumEntitlementSource.providerVerified'));
    expect(source, contains('_markEntitlementUnknownIfUnverified'));
  });

  test('RevenueCat remains one adapter instead of leaking into features', () {
    final premium =
        File('lib/premium_entitlement_service.dart').readAsStringSync();
    final cycle =
        File('lib/src/screens/cycle_tracker_screen.dart').readAsStringSync();
    final premiumScreen =
        File('lib/src/screens/premium_screen.dart').readAsStringSync();

    expect(premium, contains('package:purchases_flutter/purchases_flutter.dart'));
    expect(premium, contains('rc.Purchases.configure'));
    expect(cycle, contains('PremiumEntitlementService.instance'));
    expect(cycle, isNot(contains('purchases_flutter')));
    expect(cycle, isNot(contains('rc.Purchases')));
    expect(
      premiumScreen,
      contains('entitlementSource=\${d.entitlementSource.name}'),
    );
    expect(
      premiumScreen,
      contains('entitlementObservedAt=\${d.entitlementObservedAt'),
    );
  });

  test('v1.02-B keeps external Store proof fail-closed', () {
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();
    final doc =
        File('docs/V102_ENTITLEMENT_CONTRACT_HARDENING.md').readAsStringSync();

    expect(doc, contains('No direct Play Billing migration is introduced'));
    expect(doc, contains('RevenueCat CustomerInfo'));
    expect(doc, contains('They do not prove a real Google Play purchase or restore'));
    expect(
      roadmap,
      contains(
        '| v1.02-C | Google Play / RevenueCat Real QA | BLOCKED ON EXTERNAL DISTRIBUTION |',
      ),
    );
  });
}
