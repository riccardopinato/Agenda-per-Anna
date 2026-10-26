import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.05-A5 defines bounded visual policies for canonical UX surfaces', () {
    final config = jsonDecode(
      File('.maestro/applab-visual.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final defaults = config['defaults'] as Map<String, dynamic>;
    final checkpoints = config['checkpoints'] as Map<String, dynamic>;

    expect(config['schema_version'], 1);
    expect(defaults['profile'], 'standard');
    expect(defaults['auto_mask_dynamic_views'], isTrue);

    for (final name in const [
      'calendar',
      'week',
      'today',
      'memories',
      'people',
      'more',
      'backup',
      'archive',
      'shared',
      'account',
      'trash',
      'functional-navigation',
      'personalization',
      'settings-hub',
    ]) {
      expect(checkpoints, contains(name));
    }

    for (final name in const [
      'more',
      'backup',
      'account',
      'personalization',
      'settings-hub',
    ]) {
      expect((checkpoints[name] as Map<String, dynamic>)['profile'], 'strict');
    }

    for (final name in const ['calendar', 'week', 'memories', 'archive']) {
      expect((checkpoints[name] as Map<String, dynamic>)['profile'], 'dynamic');
    }
  });

  test('v1.05-A5 baselines the category-first Settings Hub', () {
    final manifest = jsonDecode(
      File('.maestro/applab-journey.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final checkpoints = manifest['checkpoints'] as List<dynamic>;
    final settings = File(
      '.maestro/journey/settings-hub.yaml',
    ).readAsStringSync();

    expect(
      checkpoints.any(
        (entry) =>
            entry is Map<String, dynamic> &&
            entry['name'] == 'settings-hub' &&
            entry['flow'] == '.maestro/journey/settings-hub.yaml',
      ),
      isTrue,
    );

    for (final id in const [
      'more-settings',
      'settings-hub-personalization',
      'settings-hub-preferences-privacy',
      'settings-hub-premium',
      'settings-hub-account',
      'settings-hub-backup',
    ]) {
      expect(settings, contains("id: '$id'"));
    }
  });

  test('v1.05-A5 preserves the existing 10k-memory performance guard', () {
    final source = File(
      'test/v100_golden_core_cleanup_test.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        "test('long-history projections remain interactive at 10000 memories'",
      ),
    );
    expect(source, contains('const total = 10000'));
    expect(source, contains('final references = store.memoryReferences()'));
    expect(source, contains("store.personalSearch("));
    expect(source, contains('store.lifeArchiveEntries('));
    expect(source, contains('lessThan(const Duration(seconds: 10))'));
  });

  test('v1.05-A5 keeps physical performance evidence fail-closed', () {
    final docs = File(
      'docs/V105_A5_VISUAL_PERFORMANCE_BASELINES.md',
    ).readAsStringSync();

    expect(docs, contains('Physical performance remains a separate evidence lane'));
    expect(docs, contains('NOT VERIFIED'));
    expect(docs, isNot(contains('PHYSICAL PASS')));
  });
}
