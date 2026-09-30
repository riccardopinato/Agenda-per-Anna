import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stable Android signing bootstrap contract stays intact', () {
    final bootstrap =
        File('tool/setup_release_signing_windows.ps1').readAsStringSync();
    final doctor =
        File('.github/workflows/signing-doctor.yml').readAsStringSync();
    final sideload =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final release =
        File('.github/workflows/build.yml').readAsStringSync();
    final gitignore = File('.gitignore').readAsStringSync();

    const requiredSecrets = <String>[
      'ANDROID_KEYSTORE_BASE64',
      'ANDROID_KEYSTORE_PASSWORD',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASSWORD',
    ];

    for (final name in requiredSecrets) {
      expect(bootstrap, contains(name));
      expect(doctor, contains(name));
      expect(sideload, contains(name));
      expect(release, contains(name));
    }

    expect(bootstrap, contains('annas-diary-release'));
    expect(bootstrap, contains('SIGNING-RECOVERY.json'));
    expect(bootstrap, contains('gh secret set'));
    expect(bootstrap, contains('gh workflow run signing-doctor.yml'));
    expect(bootstrap, contains('gh workflow run sideload-arm64.yml'));
    expect(bootstrap, contains('Riutilizzo la keystore release stabile esistente'));

    expect(doctor, contains('Decode and verify stable keystore'));
    expect(doctor, contains('keytool -list'));
    expect(sideload, contains('Require stable Android signing configuration'));
    expect(release, contains('Require stable Android signing configuration'));

    expect(gitignore, contains('.signing/'));
    expect(gitignore, contains('*.jks'));
    expect(gitignore, contains('SIGNING-RECOVERY.json'));
  });
}
