import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('all five legacy palettes still have unchanged seed values', () {
    expect(AgendaPalette.values, [
      AgendaPalette.rose,
      AgendaPalette.lilac,
      AgendaPalette.sage,
      AgendaPalette.peach,
      AgendaPalette.sky,
    ]);
    expect(AgendaPalette.rose.seed.toARGB32(), 0xFFE98FAA);
    expect(AgendaPalette.lilac.seed.toARGB32(), 0xFF9A8ED0);
    expect(AgendaPalette.sage.seed.toARGB32(), 0xFF7FAF98);
    expect(AgendaPalette.peach.seed.toARGB32(), 0xFFE9A47D);
    expect(AgendaPalette.sky.seed.toARGB32(), 0xFF78A9D1);
  });

  test('existing JSON remains a legacy preset with delicate intensity', () {
    final older = AgendaPreferences.fromJson(const {
      'palette': 'sage',
      'themeMode': 'dark',
    });
    expect(older.useCustomPalette, isFalse);
    expect(older.colorIntensity, AgendaColorIntensity.delicate);
    expect(older.effectiveSeedColor.toARGB32(), 0xFF7FAF98);
  });

  test('custom seed and intensity survive JSON and copyWith', () {
    final prefs = const AgendaPreferences(
      palette: AgendaPalette.lilac,
      useCustomPalette: true,
      customColorValue: 0xFFAC58CC,
      colorIntensity: AgendaColorIntensity.expressive,
    ).copyWith(showDailyQuote: false);
    final restored = AgendaPreferences.fromJson(prefs.toJson());
    expect(restored.palette, AgendaPalette.lilac);
    expect(restored.useCustomPalette, isTrue);
    expect(restored.customColorValue, 0xFFAC58CC);
    expect(restored.colorIntensity, AgendaColorIntensity.expressive);
    expect(restored.effectiveSeedColor.toARGB32(), 0xFFAC58CC);
    expect(restored.copyWith(useCustomPalette: false).effectiveSeedColor.toARGB32(),
        0xFF9A8ED0);
  });

  test('corrupt custom color fails safely without changing legacy palette', () {
    final invalid = AgendaPreferences.fromJson(const {
      'palette': 'peach',
      'useCustomPalette': true,
      'customColorValue': -1,
      'colorIntensity': 'unknown',
    });
    expect(invalid.useCustomPalette, isFalse);
    expect(invalid.effectiveSeedColor.toARGB32(), 0xFFE9A47D);
    expect(invalid.colorIntensity, AgendaColorIntensity.delicate);
  });

  test('custom appearance survives canonical backup and restore', () async {
    final source = AgendaStore();
    await source.savePreferences(const AgendaPreferences(
      useCustomPalette: true,
      customColorValue: 0xFF3765C2,
      colorIntensity: AgendaColorIntensity.expressive,
    ));
    final backup = await source.createBackupJson();
    final target = AgendaStore();
    await target.restoreBackup(backup, merge: false);
    expect(target.preferences.useCustomPalette, isTrue);
    expect(target.preferences.customColorValue, 0xFF3765C2);
    expect(target.preferences.colorIntensity, AgendaColorIntensity.expressive);
    source.dispose();
    target.dispose();
  });

  test('sync uses the existing preferences owner for custom colors', () {
    final source = File('lib/src/agenda_store.dart').readAsStringSync();
    expect(source, contains('_cloudPreferencesPayload()'));
    expect(source, contains("payload['useCustomPalette']"));
    expect(source, contains("payload['customColorValue']"));
    expect(source, contains("payload['colorIntensity']"));
    expect(source, contains('preferences = preferences.copyWith('));
  });

  test('custom appearance editor does not persist on every drag', () {
    final source =
        File('lib/src/screens/appearance_colors.dart').readAsStringSync();
    expect(source, contains('onPanUpdate:'));
    expect(source, contains('onTapDown:'));
    expect(source, contains('hexController'));
    expect(source, contains("RegExp(r'^#?[0-9a-fA-F]{6}"));
    expect(source, contains('widget.store.savePreferences(current.copyWith('));
    expect(source, contains('Navigator.pop(context)'));
    expect(source, contains("ValueKey<String>('appearance-apply')"));
    expect(source, contains("ValueKey<String>('appearance-live-preview')"));
    expect(source.split('widget.store.savePreferences(').length, 2);
  });

  test('HSV channel adjustment supports keyboard and screen readers', () {
    final editor =
        File('lib/src/screens/appearance_colors.dart').readAsStringSync();
    final catalog = File('lib/src/localization_d3.dart').readAsStringSync();
    for (final channel in ['hue', 'saturation', 'brightness']) {
      expect(editor, contains("'appearance-$channel-slider'"));
    }
    expect(editor, contains('semanticFormatterCallback:'));
    expect(editor, contains('hsv.withSaturation(value)'));
    expect(editor, contains('hsv.withValue(value)'));
    expect(editor, contains('hsv.withHue(value)'));
    for (final key in [
      'appearanceHueSlider',
      'appearanceSaturationSlider',
      'appearanceBrightnessSlider',
    ]) {
      final line = catalog.split('\n').firstWhere(
            (line) => line.contains('"$key":'),
          );
      for (final language in ['en', 'it', 'es', 'fr', 'pt']) {
        expect(line, contains('"$language":'));
      }
    }
  });

  test('legacy cloud appearance keys are optional, not reset commands', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    for (final field in ['useCustomPalette', 'colorIntensity']) {
      expect(store, contains("payload.containsKey('$field')"));
    }
    expect(store, contains(': preferences.useCustomPalette'));
    expect(store, contains(': preferences.colorIntensity'));
  });

  test('settings and personalization link to the same editor', () {
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final personalize =
        File('lib/src/screens/personalization_screen.dart').readAsStringSync();
    expect(settings, contains('AppearanceColorsScreen('));
    expect(personalize, contains('AppearanceColorsScreen('));
    expect(settings, contains("'settings-appearance-colors'"));
    expect(personalize, contains("'personalization-appearance'"));
  });

  test('new labels exist for all five supported locales', () {
    final source = File('lib/src/localization_d3.dart').readAsStringSync();
    for (final key in [
      'appearanceColorsTitle',
      'appearanceHueSaturation',
      'appearanceHue',
      'appearanceSaturationValue',
      'appearanceHex',
      'appearanceDelicate',
      'appearanceExpressive',
      'appearanceApply',
    ]) {
      final line = source.split('\n').firstWhere(
        (line) => line.contains('"$key":'),
      );
      for (final locale in ['en', 'it', 'es', 'fr', 'pt']) {
        expect(line, contains('"$locale":'));
      }
    }
  });

  testWidgets('editor opens with six presets and cancels without save',
      (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(MaterialApp(
      home: AppearanceColorsScreen(store: store),
    ));
    await tester.pumpAndSettle();
    for (final palette in AgendaPalette.values) {
      expect(find.byKey(ValueKey('appearance-preset-${palette.name}')),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey<String>('appearance-custom')),
        findsOneWidget);
    // The three accessible sliders lengthen the scrollable editor; the
    // HEX input is lazily built only after it enters the viewport.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('appearance-hex')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('appearance-hex')),
        findsOneWidget);
    expect(store.preferences.useCustomPalette, isFalse);
    store.dispose();
  });
}
