import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.05-A4 remains closed while the v1.05 line advances', () {
    final bible = File('docs/PRODUCT_BIBLE.md').readAsStringSync();
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();

    expect(bible, contains('Current product line:** v1.05'));
    expect(
      roadmap,
      contains(
        '| v1.05-A4 | Capture / More / Settings / Motion Polish | Completed — PR #119 merged after 4/4 exact-head gates |',
      ),
    );
    expect(
      roadmap,
      contains(
        'App-Factory-Core@b5573840caaf0e92bd7719b7471d49a8e34995c1',
      ),
    );
    expect(roadmap, contains('(Master v26.8, Golden Index v23, resolved 29 Oct 2026).'));
  });

  test('v1.05-A4 keeps one canonical capture path behind progressive disclosure', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();

    expect(capture, contains('Future<void> showUnifiedCapture('));
    expect(capture, contains('var showAllActions = false'));
    expect(capture, contains("'captureMoreActions'"));
    expect(capture, contains('AnimatedSize('));
    expect(capture, contains('AnnaDesignTokens.motionStandard'));

    for (final action in const <String>[
      '_UnifiedCaptureAction.text',
      '_UnifiedCaptureAction.photo',
      '_UnifiedCaptureAction.task',
      '_UnifiedCaptureAction.voice',
      '_UnifiedCaptureAction.inbox',
      '_UnifiedCaptureAction.event',
      '_UnifiedCaptureAction.birthday',
      '_UnifiedCaptureAction.person',
    ]) {
      expect(capture, contains(action));
    }

    expect(capture, contains('_saveUnifiedCaptureText('));
    expect(capture, contains('_saveUnifiedCaptureVoice('));
    expect(capture, contains('_saveUnifiedCapturePhoto('));
    expect(capture, contains('openUnifiedItemComposer('));
  });

  test('v1.05-A4 uses shared reduced-motion-aware visual and feedback primitives', () {
    final theme = File('lib/src/theme_semantics.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();

    expect(theme, contains('abstract final class AnnaFeedback'));
    expect(theme, contains('HapticFeedback.selectionClick()'));
    expect(theme, contains('HapticFeedback.lightImpact()'));
    expect(theme, contains('static bool animationsEnabled(BuildContext context)'));
    expect(capture, contains('AnnaDesignTokens.animationsEnabled(context)'));
    expect(capture, contains('AnnaFeedback.selection()'));
    expect(capture, contains('AnnaFeedback.success()'));
  });

  test('v1.05-A4 More has explicit hierarchy and no duplicate AppBar search', () {
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();

    expect(more, contains("strings.d3('moreQuickAccess')"));
    expect(more, contains("strings.d3('moreYourSpace')"));
    expect(more, contains("strings.d3('moreDataAndApp')"));
    expect(more, isNot(contains("ValueKey<String>('more-search-action')")));

    for (final id in const <String>[
      'more-search',
      'more-inbox',
      'more-explore',
      'more-personalize',
      'more-archive',
      'more-backup',
      'more-cloud',
      'more-settings',
    ]) {
      expect(more, contains("id: '$id'"));
    }
  });

  test('v1.05-A4 Settings opens a category-first hub without new state ownership', () {
    final main = File('lib/main.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final hub = File('lib/src/screens/settings_hub.dart').readAsStringSync();

    expect(main, contains("part 'src/screens/settings_hub.dart';"));
    expect(more, contains('SettingsHubScreen(store: store)'));

    for (final id in const <String>[
      'settings-hub-personalization',
      'settings-hub-preferences-privacy',
      'settings-hub-premium',
      'settings-hub-account',
      'settings-hub-backup',
    ]) {
      expect(hub, contains("id: '$id'"));
    }

    expect(hub, contains('PremiumEntitlementService.instance'));
    expect(hub, contains('AnimatedBuilder('));
    expect(hub, contains('SettingsScreen(store: store)'));
    expect(hub, contains('PersonalizationScreen(store: store)'));
    expect(hub, contains('CloudAccountScreen(store: store)'));
    expect(hub, contains('BackupScreen(store: store)'));
    expect(hub, isNot(contains('SharedPreferences')));
    expect(hub, isNot(contains('LocalStateStore')));
  });

  test('v1.05-A4 five-language labels are complete', () {
    final localization = File('lib/src/localization_d3.dart').readAsStringSync();

    for (final key in const <String>[
      'captureMoreActions',
      'captureFewerActions',
      'moreQuickAccess',
      'moreYourSpace',
      'moreDataAndApp',
      'settingsHubIntro',
      'settingsPreferencesPrivacy',
      'settingsPreferencesPrivacySubtitle',
    ]) {
      expect(localization, contains('"$key"'));
    }
  });
}
