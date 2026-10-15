import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generic Release Reality binds exact artifact and release identity',
      () async {
    final temp = Directory.systemTemp.createTempSync('anna-release-reality-');
    addTearDown(() {
      try {
        temp.deleteSync(recursive: true);
      } catch (_) {}
    });

    final artifact = File('${temp.path}/candidate.aab')
      ..writeAsBytesSync(utf8.encode('exact-release-bytes'));
    final output = File('${temp.path}/release-reality.json');

    final result = await Process.run('python3', [
      'tool/create_release_reality.py',
      '--artifact',
      artifact.path,
      '--output',
      output.path,
      '--project',
      "Anna's Diary",
      '--repository',
      'riccardopinato/Agenda-per-Anna',
      '--source-ref',
      'main',
      '--source-sha',
      '0123456789abcdef0123456789abcdef01234567',
      '--version',
      '1.0.0-rc.1',
      '--build-number',
      '110',
      '--variant',
      'store-qa',
      '--package-id',
      'com.riccardopinato.agenda_per_anna',
      '--signing-sha256',
      'a' * 64,
      '--workflow-run-id',
      '123456',
      '--distribution-channel',
      'google-play-internal-testing-candidate',
      '--validation-level',
      'ARTIFACT_BUILT',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final record =
        jsonDecode(output.readAsStringSync()) as Map<String, dynamic>;

    expect(record['evidenceType'], 'release_reality');
    expect(record['project'], "Anna's Diary");
    expect(record['sourceRef'], 'main');
    expect(record['sourceSha'], hasLength(40));
    expect(record['packageId'], 'com.riccardopinato.agenda_per_anna');
    expect(record['artifactName'], 'candidate.aab');
    expect(record['artifactSha256'], hasLength(64));
    expect(record['signingFingerprint'], 'A' * 64);
    expect(record['validationLevel'], 'ARTIFACT_BUILT');
    expect(record['validatedAt'], isNotEmpty);
  });

  test('physical and Store QA candidates emit Release Reality evidence', () {
    final physical =
        File('tool/create_physical_cert_manifest.py').readAsStringSync();
    final sideload =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final storeQa =
        File('.github/workflows/premium-store-qa.yml').readAsStringSync();

    expect(physical, contains('build_release_reality_record'));
    expect(physical, contains('"releaseReality": release_reality'));
    expect(physical, contains('"validationLevel"'));
    expect(sideload, contains('--source-ref "$GITHUB_REF_NAME"'));
    expect(sideload, contains('--validation-level "ARTIFACT_BUILT"'));

    expect(storeQa, contains('tool/create_release_reality.py'));
    expect(storeQa, contains('STORE_QA_RELEASE_REALITY.json'));
    expect(
      storeQa,
      contains(
        '--distribution-channel "google-play-internal-testing-candidate"',
      ),
    );
    expect(storeQa, contains('--validation-level "ARTIFACT_BUILT"'));
  });

  test('candidate records never claim physical or distribution verification',
      () {
    final physical =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final storeQa =
        File('.github/workflows/premium-store-qa.yml').readAsStringSync();

    expect(physical, contains('--validation-level "ARTIFACT_BUILT"'));
    expect(storeQa, contains('--validation-level "ARTIFACT_BUILT"'));
    expect(physical, isNot(contains('--validation-level "PHYSICAL_DEVICE_VERIFIED"')));
    expect(storeQa, isNot(contains('--validation-level "DISTRIBUTION_VERIFIED"')));
    expect(storeQa, isNot(contains('--validation-level "STORE_READY"')));
  });
}
