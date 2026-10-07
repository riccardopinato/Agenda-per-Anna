import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.00-D AppLab includes Backup/Data trusted preflight', () {
    final journey =
        File('.maestro/applab-journey.json').readAsStringSync();
    final flow = File('.maestro/journey/backup.yaml').readAsStringSync();

    expect(journey, contains('"name": "backup"'));
    expect(journey, contains('.maestro/journey/backup.yaml'));
    expect(flow, contains('Crea backup completo|Create full backup'));
    expect(flow, contains('Ripristina da file|Restore from file'));
    expect(flow, contains('Esporta archivio aperto|Export open archive'));
    expect(flow, contains('Verifica integrità locale|Verify local integrity'));
  });

  test('v1.00-D sideload artifact records same-bytes identity', () {
    final workflow =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final tool =
        File('tool/create_physical_cert_manifest.py').readAsStringSync();

    for (final secret in const [
      'ANDROID_KEYSTORE_BASE64',
      'ANDROID_KEYSTORE_PASSWORD',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASSWORD',
    ]) {
      expect(workflow, contains(secret));
    }

    expect(workflow, contains('PHYSICAL_CERTIFICATION_MANIFEST.json'));
    expect(workflow, contains('--release-signing'));
    expect(workflow, contains('--signing-sha256'));
    expect(tool, contains('"artifactSha256"'));
    expect(tool, contains('"signingCertificateSha256"'));
    expect(tool, contains('"physicalVerification"'));
    expect(tool, contains('"status": "PENDING"'));
  });

  test('v1.00-D physical evidence validator fails closed then accepts full PASS',
      () async {
    final template = jsonDecode(
      File('docs/V100_D_PHYSICAL_EVIDENCE_TEMPLATE.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final pendingFile = File(
      '${Directory.systemTemp.path}/anna-v100d-pending.json',
    )..writeAsStringSync(jsonEncode(template));
    final pending = await Process.run(
      'python3',
      ['tool/validate_v100d_physical_evidence.py', pendingFile.path],
    );
    expect(pending.exitCode, isNot(0));

    final complete = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
    complete['commit'] = '0123456789abcdef0123456789abcdef01234567';
    complete['appVersion'] = '0.99.0+109';
    complete['artifactFile'] = 'Anna-Diary-arm64-release.apk';
    complete['artifactSha256'] = 'a' * 64;
    complete['signingCertificateSha256'] = 'b' * 64;
    complete['workflowRunId'] = '123456';

    final devices = complete['devices'] as List<dynamic>;
    (devices[0] as Map<String, dynamic>)
      ..['model'] = 'physical-device-a'
      ..['osVersion'] = 'Android 13';
    (devices[1] as Map<String, dynamic>)
      ..['model'] = 'physical-device-b'
      ..['osVersion'] = 'Android 14';

    final scenarios = complete['scenarios'] as List<dynamic>;
    for (final raw in scenarios) {
      final scenario = raw as Map<String, dynamic>;
      final id = scenario['id'] as String;
      scenario['status'] = 'PASS';
      scenario['expected'] = 'Expected behavior for $id';
      scenario['observed'] = 'Observed behavior for $id';
      scenario['deviceIds'] = id.startsWith('NOI-')
          ? ['device-a', 'device-b']
          : ['device-a'];
      scenario['evidenceRefs'] = <String>[];
    }

    final passFile = File(
      '${Directory.systemTemp.path}/anna-v100d-pass.json',
    )..writeAsStringSync(jsonEncode(complete));
    final passed = await Process.run(
      'python3',
      ['tool/validate_v100d_physical_evidence.py', passFile.path],
    );
    expect(
      passed.exitCode,
      0,
      reason: '${passed.stdout}\n${passed.stderr}',
    );
    expect(passed.stdout.toString(), contains('physical evidence: PASS'));

    try {
      pendingFile.deleteSync();
    } catch (_) {}
    try {
      passFile.deleteSync();
    } catch (_) {}
  });

  test('v1.00-D security docs keep physical evidence separate from backend',
      () {
    final doc =
        File('docs/V100_D_SECURITY_NATIVE_PHYSICAL.md').readAsStringSync();
    final security =
        File('docs/SECURITY_BASELINE.md').readAsStringSync();

    expect(doc, contains('LIVE BACKEND CONTRACT VERIFIED'));
    expect(doc, contains('BLOCKED ON PHYSICAL EVIDENCE'));
    expect(doc, contains('auth_leaked_password_protection'));
    expect(security, contains('20261001075952 shared_password_hardening_v086'));
    expect(
      security,
      contains('does **not** prove the two-device Flutter/Keystore client lifecycle'),
    );
  });
}
