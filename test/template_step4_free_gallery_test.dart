import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('Step4 free diary catalog has original editable templates in five locales',
      () {
    for (final language in const <AppLanguage>[
      AppLanguage.italian,
      AppLanguage.english,
      AppLanguage.spanish,
      AppLanguage.french,
      AppLanguage.portuguese,
    ]) {
      final strings = AnnaStrings.forPreference(language);
      final presets = diaryTemplatePresetsFor(strings);
      expect(presets, hasLength(6));
      expect(presets.map((preset) => preset.id).toSet(), hasLength(6));
      for (final preset in presets) {
        expect(preset.title.trim(), isNotEmpty);
        expect(preset.seedText.trim(), isNotEmpty);
      }
      for (final key in const <String>[
        'templateCatalogFree',
        'templateCatalogPreview',
        'templateCatalogPrivacy',
        'templateCatalogBack',
        'templateCatalogUse',
      ]) {
        final value = strings.d3(key);
        expect(value.trim(), isNotEmpty);
        expect(value, isNot(key), reason: '${language.name}: $key');
      }
    }
  });

  test('Step4 preview returns a preset, never writes directly to the store', () {
    final source = File('lib/src/diary/diary_templates.dart').readAsStringSync();
    final previewStart = source.indexOf('_previewFreeDiaryTemplate(');
    final pickerStart = source.indexOf('Future<DiaryTemplatePreset?> showDiaryTemplatePicker(');
    expect(previewStart, greaterThan(0));
    expect(pickerStart, greaterThan(previewStart));

    final preview = source.substring(previewStart, pickerStart);
    expect(preview, contains('showDialog<DiaryTemplatePreset>'));
    expect(preview, contains('SelectableText(preset.seedText)'));
    expect(preview, contains('Navigator.pop(dialogContext, preset)'));
    expect(preview, isNot(contains('saveJournal(')));
    expect(preview, isNot(contains('startDailyRitual(')));

    final picker = source.substring(pickerStart);
    expect(picker, contains('if (selected != null && sheetContext.mounted)'));
    expect(picker, contains('Navigator.pop(sheetContext, selected)'));
  });
}
