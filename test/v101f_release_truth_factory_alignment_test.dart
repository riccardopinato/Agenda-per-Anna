import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.01 release truth is aligned across canonical docs', () {
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();
    final productBible = File('docs/PRODUCT_BIBLE.md').readAsStringSync();
    final readme = File('README.md').readAsStringSync();
    final v101 =
        File('docs/V101_PERSONALIZATION_SIMPLICITY.md').readAsStringSync();
    final evidence =
        File('docs/V101_RELEASE_TRUTH_EVIDENCE.md').readAsStringSync();

    expect(
      roadmap,
      contains(
        '| v1.01-E | Polish, Accessibility & Regression | Completed — 4/4 exact-head gates green |',
      ),
    );
    expect(
      roadmap,
      contains('| v1.01-F | Release Truth & Factory Alignment | Completed — documentation/evidence closure |'),
    );
    expect(
      roadmap,
      contains(
        'App-Factory-Core@47c47f49a7b46812e3bd6f1231c3524f2b52b826',
      ),
    );
    expect(roadmap, isNot(contains('|\\n| v1.00-D |')));

    // v1.01 closure evidence is historical; later product lines may advance
    // Product Bible.current without invalidating the v1.01 certification.
    expect(productBible, contains('Distribution identity:** 1.0.0-rc.1+110'));

    expect(readme, contains('**v1.01-E** is merged'));
    expect(readme, contains('**v1.01-F** aligns Product Bible'));

    expect(
      v101,
      contains('Status: **COMPLETED — A→E merged with exact-head 4/4 gates**'),
    );
    expect(
      v101,
      contains(
        '**v1.01-E** Polish, Accessibility & Regression — completed and merged after 4/4 exact-head gates.',
      ),
    );

    expect(evidence, contains('Development #1164 PASS'));
    expect(evidence, contains('AppLab #681 PASS'));
    expect(
      evidence,
      contains('c68273ff08d02dceeea9f8892db3f7644927cd87'),
    );
    expect(
      evidence,
      contains('8eba54222329742f076de1f31260915e6dad8437'),
    );
  });

  test('post-v1.01 roadmap stays fail-closed on external evidence', () {
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();
    final evidence =
        File('docs/V101_RELEASE_TRUTH_EVIDENCE.md').readAsStringSync();

    expect(
      roadmap,
      contains(
        '| v1.02-A | Native Physical Certification | SOFTWARE PREPARED — BLOCKED ON PHYSICAL EVIDENCE |',
      ),
    );
    expect(
      roadmap,
      contains(
        '| v1.02-C | Google Play / RevenueCat Real QA | SOFTWARE PREPARED — BLOCKED ON EXTERNAL DISTRIBUTION |',
      ),
    );
    expect(
      roadmap,
      contains(
        '| v1.03 | Cross-App Certification Refresh | SOFTWARE PREPARED — BLOCKED ON PAIRED PHYSICAL EVIDENCE |',
      ),
    );

    expect(evidence, contains('does **not** promote'));
    expect(evidence, contains('Store Ready'));
  });

  test('v1.01 closure does not invent a second product owner', () {
    final preferences = File('lib/src/domain_models.dart').readAsStringSync();
    final personalization =
        File('lib/src/screens/personalization_screen.dart').readAsStringSync();

    expect(preferences, contains('enum PersonalizationPreset'));
    expect(preferences, contains('enum AppModule'));
    expect(personalization, contains('store.applyPersonalizationPreset'));
    expect(personalization, contains('store.setModuleEnabled'));

    for (final forbidden in const <String>[
      'PersonalizationDatabase',
      'PersonalizationRepository',
      'PersonalizationSyncQueue',
      'ModuleVisibilityStore',
    ]) {
      expect(preferences, isNot(contains(forbidden)));
      expect(personalization, isNot(contains(forbidden)));
    }
  });
}
