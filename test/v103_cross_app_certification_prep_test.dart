import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.03 pair template remains fail-closed until paired execution', () {
    final template = jsonDecode(
      File('docs/V103_WONDERLOG_PAIR_SESSION_TEMPLATE.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(template['schema_version'], 1);
    expect((template['protocol'] as Map<String, dynamic>)['name'],
        'Shared Ecosystem Core');
    expect(
      (template['transport'] as Map<String, dynamic>)['requires_installed_apps'],
      isTrue,
    );

    final scenarios = (template['scenarios'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final kinds = scenarios.map((row) => row['kind']).toSet();

    expect(
      kinds,
      containsAll(<String>{
        'COPY',
        'LINK',
        'IDEMPOTENCY',
        'PROVENANCE',
        'OWNERSHIP',
        'FAIL_CLOSED',
        'DEEP_LINK_HANDOFF',
      }),
    );
    expect(
      scenarios.every((row) => row['result'] == 'NOT_VERIFIED'),
      isTrue,
    );

    final physical =
        template['physical_evidence'] as Map<String, dynamic>;
    expect(physical['physical'], isTrue);
    expect(physical['result'], 'BLOCKED');
    expect(physical['evidence_refs'], isEmpty);
  });

  test('v1.03 documentation does not promote historical v0.96 evidence', () {
    final doc =
        File('docs/V103_CROSS_APP_CERTIFICATION_REFRESH.md').readAsStringSync();
    final provenance =
        File('docs/REUSE_PROVENANCE.txt').readAsStringSync();

    expect(provenance, contains('physical Wonderlog <-> Anna round trip: PASS'));
    expect(doc, contains('Historical PASS != new-process PASS'));
    expect(doc, contains('BLOCKED ON PAIRED PHYSICAL EVIDENCE'));
    expect(
      doc,
      contains(
        'riccardopinato/AppLab@02f25d75b990055521869d75781e93893a6b6cdf',
      ),
    );
  });

  test('v1.03 reuses Shared Ecosystem Core instead of creating a protocol', () {
    final contract =
        File('lib/ecosystem/ecosystem_contract.dart').readAsStringSync();
    final bridge = File('lib/src/life_bridge.dart').readAsStringSync();
    final doc =
        File('docs/V103_CROSS_APP_CERTIFICATION_REFRESH.md').readAsStringSync();

    expect(contract, contains('Shared Ecosystem Core'));
    expect(bridge, contains('lifeBridgeProtocolVersion'));
    expect(doc, contains('does not:'));
    expect(doc, contains('create another bridge protocol'));
  });
}
