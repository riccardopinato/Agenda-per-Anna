import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.05-A0 owns one canonical visual token foundation', () {
    final source = File('lib/src/theme_semantics.dart').readAsStringSync();

    expect(source, contains('abstract final class AnnaDesignTokens'));
    expect(source, contains('static const double spaceMd = 16'));
    expect(source, contains('static const double radiusLg = 24'));
    expect(
      source,
      contains('static const Duration motionStandard = Duration(milliseconds: 180)'),
    );
    expect(source, contains('static bool animationsEnabled(BuildContext context)'));
    expect(source, contains('media?.disableAnimations'));
    expect(source, contains('media?.accessibleNavigation'));
    expect(source, contains('enum AnnaVisualDomain'));
  });

  test('accent surfaces are brightness-aware instead of always blending white', () {
    final source = File('lib/src/theme_semantics.dart').readAsStringSync();

    expect(source, contains('scheme.brightness == Brightness.dark'));
    expect(source, contains('scheme.surfaceContainerHigh'));
    expect(source, contains('scheme.surfaceContainerLowest'));
    expect(
      source,
      isNot(contains(
        'final start = Color.lerp(scheme.primary, Colors.white, 0.78)!',
      )),
    );
  });

  test('shared Material chrome consumes the design foundation', () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final widgets = File('lib/src/widgets_editors.dart').readAsStringSync();

    expect(shell, contains('scaffoldBackgroundColor: scheme.surface'));
    expect(shell, contains('bottomSheetTheme: BottomSheetThemeData'));
    expect(shell, contains('filledButtonTheme: FilledButtonThemeData'));
    expect(shell, contains('AnnaDesignTokens.animationsEnabled(context)'));
    expect(widgets, contains('final AnnaVisualDomain? domain'));
    expect(widgets, contains('AnnaDesignTokens.radiusLg'));
    expect(widgets, contains('AnnaDesignTokens.spaceMd'));
  });

  test('design foundation does not introduce persistence or AI infrastructure', () {
    final source = File('lib/src/theme_semantics.dart').readAsStringSync();

    for (final forbidden in <String>[
      'SharedPreferences',
      'Sembast',
      'Supabase',
      'OpenAI',
      'embedding',
      'database',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}
