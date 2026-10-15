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
      List<String>.filled(64, 'a').join(),
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
    expect(record['signingFingerprint'], List<String>.filled(64, 'A').join());
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
    expect(sideload, contains('--source-ref "\$GITHUB_REF_NAME"'));
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

  test('Store QA validator requires exact AAB and real scenario evidence',
      () async {
    final temp = Directory.systemTemp.createTempSync('anna-store-qa-');
    addTearDown(() {
      try {
        temp.deleteSync(recursive: true);
      } catch (_) {}
    });

    final artifact = File('${temp.path}/candidate.aab')
      ..writeAsBytesSync(utf8.encode('store-qa-exact-bytes'));
    final realityFile = File('${temp.path}/STORE_QA_RELEASE_REALITY.json');

    final created = await Process.run('python3', [
      'tool/create_release_reality.py',
      '--artifact',
      artifact.path,
      '--output',
      realityFile.path,
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
      'release obfuscated Premium Store QA AAB',
      '--package-id',
      'com.riccardopinato.agenda_per_anna',
      '--signing-sha256',
      List<String>.filled(64, 'b').join(),
      '--workflow-run-id',
      '654321',
      '--distribution-channel',
      'google-play-internal-testing-candidate',
      '--validation-level',
      'ARTIFACT_BUILT',
    ]);
    expect(created.exitCode, 0, reason: '${created.stdout}\n${created.stderr}');

    final reality =
        jsonDecode(realityFile.readAsStringSync()) as Map<String, dynamic>;
    final template = jsonDecode(
      File('docs/V102_STORE_QA_EVIDENCE_TEMPLATE.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    Map<String, dynamic> completeEvidence() {
      final evidence =
          jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
      for (final key in const <String>[
        'repository',
        'sourceSha',
        'version',
        'buildNumber',
        'packageId',
        'artifactName',
        'artifactSha256',
        'signingFingerprint',
        'workflowRun',
        'distributionChannel',
      ]) {
        evidence[key] = reality[key];
      }
      evidence['status'] = 'PASS';
      evidence['testerRef'] = 'license-tester-a';
      final scenarios = evidence['scenarios'] as List<dynamic>;
      for (final raw in scenarios) {
        final scenario = raw as Map<String, dynamic>;
        final id = scenario['id'] as String;
        scenario['status'] = 'PASS';
        scenario['expected'] = 'Expected Store behavior for $id';
        scenario['observed'] = 'Observed Store behavior for $id';
        scenario['evidenceRefs'] = <String>['evidence/$id.txt'];
      }
      return evidence;
    }

    Future<ProcessResult> validate(
      Map<String, dynamic> evidence,
      String name,
    ) async {
      final file = File('${temp.path}/$name.json')
        ..writeAsStringSync(jsonEncode(evidence));
      return Process.run('python3', [
        'tool/validate_v102_store_qa_evidence.py',
        file.path,
        '--release-reality',
        realityFile.path,
        '--artifact',
        artifact.path,
      ]);
    }

    final pending = completeEvidence()..['status'] = 'PENDING';
    expect((await validate(pending, 'pending')).exitCode, isNot(0));

    final wrongArtifact = completeEvidence()
      ..['artifactSha256'] = List<String>.filled(64, 'c').join();
    expect((await validate(wrongArtifact, 'wrong-artifact')).exitCode, isNot(0));

    final passed = await validate(completeEvidence(), 'pass');
    expect(
      passed.exitCode,
      0,
      reason: '${passed.stdout}\n${passed.stderr}',
    );
    expect(
      passed.stdout.toString(),
      contains('Store QA evidence: PASS'),
    );
  });

}
