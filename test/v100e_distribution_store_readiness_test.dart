import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.00-E uses canonical 1.0 release-candidate metadata', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = File('lib/app_version.dart').readAsStringSync();

    expect(pubspec, contains('version: 1.0.0-rc.1+110'));
    expect(version, contains("appReleaseVersion = '1.0.0-rc.1'"));
    expect(version, contains('appReleaseBuildNumber = 110'));
  });

  test('v1.00-E pins current Play Android submission requirements', () {
    final android =
        File('tool/prepare_android_platform.py').readAsStringSync();
    final release =
        File('.github/workflows/build.yml').readAsStringSync();
    final storeQa =
        File('.github/workflows/premium-store-qa.yml').readAsStringSync();

    expect(android, contains('compileSdk = 36'));
    expect(android, contains('targetSdk = 36'));
    expect(android, contains('android:launchMode="singleTop"'));
    expect(android, contains('Android Gradle Plugin >= 8.5.1'));

    expect(release, contains('zipalign'));
    expect(release, contains('-c -P 16 -v 4'));
    expect(release, contains('manifest target-sdk'));
    expect(release, contains('Expected targetSdk 36'));
    expect(release, contains('flutter build appbundle'));
    expect(release, contains('--dart-define=ANNA_STORE_RELEASE=true'));
    expect(release, contains('--dart-define=ANNA_PREMIUM_PREVIEW=false'));

    expect(storeQa, contains('compileSdk = 36'));
    expect(storeQa, contains('targetSdk = 36'));
    expect(storeQa, contains('ANNA_STORE_QA=true'));
    expect(storeQa, contains('ANNA_PREMIUM_PREVIEW=false'));
    expect(storeQa, contains('workflow_dispatch:'));
    expect(storeQa, isNot(contains('\n  push:')));
    expect(storeQa, contains('REVENUECAT_ANDROID_API_KEY'));
    expect(storeQa, contains('Premium Store QA is not configured'));
  });

  test('v1.00-E publishes policy and account-deletion surfaces', () {
    final deploy =
        File('.github/workflows/deploy-pages.yml').readAsStringSync();
    final privacy = File('legal/privacy.html').readAsStringSync();
    final deletion = File('legal/delete-account.html').readAsStringSync();
    final appShell = File('lib/src/app_shell.dart').readAsStringSync();
    final dataSafety =
        File('docs/PLAY_STORE_DATA_SAFETY.md').readAsStringSync();

    expect(deploy, contains('legal/delete-account.html'));
    expect(privacy, contains('delete-account.html'));
    expect(privacy, contains('RevenueCat'));
    expect(privacy, contains('Supabase'));
    expect(privacy, contains('Firebase'));
    expect(privacy, contains("non è un dispositivo medico"));
    expect(privacy, contains('identificatore tecnico anonimo'));
    expect(privacy, contains('inizializzarsi'));
    expect(deletion, contains('./?account=delete'));
    expect(appShell, contains("queryParameters['account'] == 'delete'"));
    expect(appShell, contains('CloudAccountScreen(store: store)'));

    final cloud =
        File('lib/cloud_sync_service.dart').readAsStringSync();
    final account =
        File('lib/src/screens/cloud_account.dart').readAsStringSync();
    expect(cloud, contains('returnToAccountDeletion'));
    expect(cloud, contains("queryParameters: const {'account': 'delete'}"));
    expect(account, contains("queryParameters['account'] == 'delete'"));

    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final localization =
        File('lib/src/localization_v100.dart').readAsStringSync();
    expect(settings, contains('strings.v100PrivacyPolicy'));
    expect(settings, contains('privacy.html'));
    expect(localization, contains('v100PrivacyPolicyDescription'));

    expect(dataSafety, contains('Account & sync -> Delete account and data'));
    expect(dataSafety, contains('## Health apps declaration'));
    expect(dataSafety, contains('Period Tracking'));
    expect(dataSafety, contains('Activity and Fitness'));
    expect(dataSafety, contains('anonymous technical app-user/install identifier'));
    expect(dataSafety, contains('current app does not implement general product analytics'));
  });

  test('v1.00-E keeps external proof honest', () {
    final doc =
        File('docs/V100_E_DISTRIBUTION_STORE_READINESS.md').readAsStringSync();

    expect(doc, contains('Google Play Internal Testing'));
    expect(doc, contains('CI can prove build/configuration readiness'));
    expect(doc, contains('D7 remains blocked'));
    expect(doc, contains('STORE READY'));
    expect(doc, contains('Supabase Free plan'));
    expect(doc, contains('Google Play Health apps policy'));
    expect(doc, contains('Supabase OAuth redirect for Web account deletion'));
    expect(doc, contains('manual and fail-closed'));
  });
}
