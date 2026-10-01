import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Premium preview is fail-closed for release builds', () {
    final source =
        File('lib/premium_entitlement_service.dart').readAsStringSync();

    expect(source, contains("'ANNA_PREMIUM_PREVIEW'"));
    expect(source, contains('defaultValue: false'));
    expect(source, contains("'ANNA_STORE_RELEASE'"));
    expect(source, contains('premium_store_release_preview_enabled'));
    expect(source, contains('premium_store_release_missing_api_key'));
    expect(
      source,
      contains(
        '!_paidEntitlement && !_storeRelease && '
        '(kDebugMode || _previewOverride)',
      ),
    );
  });

  test('store release workflow requires real Premium configuration', () {
    final workflow =
        File('.github/workflows/build.yml').readAsStringSync();
    final validator =
        File('tool/validate_premium_release.py').readAsStringSync();

    expect(workflow, contains('Require Premium store configuration'));
    expect(workflow, contains(r'${{ secrets.REVENUECAT_ANDROID_API_KEY }}'));
    expect(workflow, contains('--dart-define=ANNA_STORE_RELEASE=true'));
    expect(workflow, contains('--dart-define=ANNA_PREMIUM_PREVIEW=false'));
    expect(
      workflow,
      contains('--dart-define=REVENUECAT_PREMIUM_ENTITLEMENT=premium'),
    );
    expect(
      workflow,
      contains('--dart-define=REVENUECAT_ANDROID_API_KEY='),
    );

    expect(validator, contains('REVENUECAT_ANDROID_API_KEY is required.'));
    expect(validator, contains('ANNA_STORE_RELEASE must be true'));
    expect(validator, contains('ANNA_PREMIUM_PREVIEW must be false'));
    expect(validator, contains("'premium' entitlement"));
  });

  test('QA distribution channels opt into preview explicitly', () {
    final pages =
        File('.github/workflows/deploy-pages.yml').readAsStringSync();
    final sideload =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final applab =
        File('.github/workflows/applab.yml').readAsStringSync();

    for (final source in [pages, sideload, applab]) {
      expect(source, contains('ANNA_STORE_RELEASE=false'));
      expect(source, contains('ANNA_PREMIUM_PREVIEW=true'));
    }

    expect(pages, contains('Build web preview'));
    expect(
      sideload,
      isNot(contains('REVENUECAT_ANDROID_API_KEY')),
    );
    expect(
      applab,
      isNot(contains('REVENUECAT_ANDROID_API_KEY')),
    );
  });

  test('production and preview build contracts cannot silently converge', () {
    final release =
        File('.github/workflows/build.yml').readAsStringSync();
    final previewSources = [
      File('.github/workflows/deploy-pages.yml').readAsStringSync(),
      File('.github/workflows/sideload-arm64.yml').readAsStringSync(),
      File('.github/workflows/applab.yml').readAsStringSync(),
    ].join('\n');

    expect(release, contains('ANNA_STORE_RELEASE=true'));
    expect(release, contains('ANNA_PREMIUM_PREVIEW=false'));
    expect(previewSources, isNot(contains('ANNA_STORE_RELEASE=true')));
    expect(previewSources, isNot(contains('ANNA_PREMIUM_PREVIEW=false')));
  });
}
