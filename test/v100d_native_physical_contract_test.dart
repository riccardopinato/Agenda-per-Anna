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
    expect(workflow, contains('mkdir -p "$(dirname "$CERT_DER")"'));
    expect(tool, contains('"artifactSha256"'));
    expect(tool, contains('"signingCertificateSha256"'));
    expect(tool, contains('"physicalVerification"'));
    expect(tool, contains('"status": "PENDING"'));
  });

  test(
      'v1.00-D physical evidence is bound to candidate bytes, identity, roles and unique scenarios',
      () async {
    final temp = Directory.systemTemp.createTempSync('anna-v100d-');
    addTearDown(() {
      try {
        temp.deleteSync(recursive: true);
      } catch (_) {}
    });

    final artifact = File('${temp.path}/Anna-Diary-arm64-release.apk')
      ..writeAsBytesSync(utf8.encode('signed-candidate-fixture'));
    final manifestFile =
        File('${temp.path}/PHYSICAL_CERTIFICATION_MANIFEST.json');

    final created = await Process.run(
      'python3',
      [
        'tool/create_physical_cert_manifest.py',
        '--artifact',
        artifact.path,
        '--output',
        manifestFile.path,
        '--repository',
        'riccardopinato/Agenda-per-Anna',
        '--commit',
        '0123456789abcdef0123456789abcdef01234567',
        '--version',
        '0.99.0+109',
        '--variant',
        'arm64-v8a release physical fixture',
        '--signing-sha256',
        'b' * 64,
        '--workflow-run-id',
        '123456',
        '--channel',
        'direct-sideload',
      ],
    );
    expect(
      created.exitCode,
      0,
      reason: '${created.stdout}\n${created.stderr}',
    );

    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final template = jsonDecode(
      File('docs/V100_D_PHYSICAL_EVIDENCE_TEMPLATE.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    Map<String, dynamic> candidateEvidence() {
      final complete = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
      for (final key in const [
        'repository',
        'commit',
        'appVersion',
        'artifactFile',
        'artifactSha256',
        'signingCertificateSha256',
        'workflowRunId',
        'channel',
      ]) {
        complete[key] = manifest[key];
      }

      final devices = complete['devices'] as List<dynamic>;
      (devices[0] as Map<String, dynamic>)
        ..['model'] = 'physical-device-a'
        ..['osVersion'] = 'Android 13'
        ..['accountRole'] = 'owner';
      (devices[1] as Map<String, dynamic>)
        ..['model'] = 'physical-device-b'
        ..['osVersion'] = 'Android 14'
        ..['accountRole'] = 'member';

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
      return complete;
    }

    Future<ProcessResult> validate(
      Map<String, dynamic> evidence,
      String name,
    ) async {
      final evidenceFile = File('${temp.path}/$name.json')
        ..writeAsStringSync(jsonEncode(evidence));
      return Process.run(
        'python3',
        [
          'tool/validate_v100d_physical_evidence.py',
          evidenceFile.path,
          '--manifest',
          manifestFile.path,
          '--artifact',
          artifact.path,
        ],
      );
    }

    final pending = candidateEvidence();
    (pending['scenarios'] as List<dynamic>).first['status'] = 'PENDING';
    expect((await validate(pending, 'pending')).exitCode, isNot(0));

    final nullCommit = candidateEvidence()..['commit'] = null;
    expect((await validate(nullCommit, 'null-commit')).exitCode, isNot(0));

    final wrongDigest = candidateEvidence()..['artifactSha256'] = 'a' * 64;
    expect((await validate(wrongDigest, 'wrong-digest')).exitCode, isNot(0));

    final duplicateScenario = candidateEvidence();
    final scenarios = duplicateScenario['scenarios'] as List<dynamic>;
    scenarios.add(jsonDecode(jsonEncode(scenarios.first)));
    expect(
      (await validate(duplicateScenario, 'duplicate-scenario')).exitCode,
      isNot(0),
    );

    final wrongRoles = candidateEvidence();
    final devices = wrongRoles['devices'] as List<dynamic>;
    (devices[1] as Map<String, dynamic>)['accountRole'] = 'owner';
    expect((await validate(wrongRoles, 'wrong-roles')).exitCode, isNot(0));

    final passed = await validate(candidateEvidence(), 'pass');
    expect(
      passed.exitCode,
      0,
      reason: '${passed.stdout}\n${passed.stderr}',
    );
    expect(passed.stdout.toString(), contains('physical evidence: PASS'));
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
      contains(
        'does **not** prove the two-device Flutter/Keystore client lifecycle',
      ),
    );
  });
}
