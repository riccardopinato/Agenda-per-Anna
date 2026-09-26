import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('Diary 2.0 presets are deterministic and non-AI', () {
    expect(diaryTemplatePresets.map((preset) => preset.id).toSet().length,
        diaryTemplatePresets.length);
    expect(
      diaryTemplatePresets.map((preset) => preset.id),
      containsAll([
        'morning',
        'evening',
        'gratitude',
        'travel',
        'special_day',
        'reflection',
      ]),
    );
    expect(
      diaryTemplatePresets.every((preset) => preset.seedText.trim().isNotEmpty),
      isTrue,
    );
  });

  test('applying a template reuses ordinary journal persistence', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 3);
    final preset =
        diaryTemplatePresets.firstWhere((value) => value.id == 'travel');

    final created = await store.applyDiaryTemplate(
      day,
      preset,
      createdAt: DateTime(2026, 10, 3, 9),
    );

    expect(created.type, DiaryBlockType.note);
    expect(created.tags, contains('viaggio'));
    expect(store.journal(day).blocks.single.id, created.id);
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    final restored = reloaded.journal(day).blocks.single;
    expect(restored.id, created.id);
    expect(restored.text, contains('Diario di viaggio'));
    expect(restored.tags, contains('viaggio'));
    reloaded.dispose();
  });

  test('template application never overwrites existing diary content', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 4);
    await store.saveJournal(
      day,
      DayJournal(
        beautiful: 'Una giornata importante',
        blocks: [
          DiaryBlock(
            id: 'existing',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 4, 8),
            text: 'Già presente',
          ),
        ],
      ),
    );

    await store.applyDiaryTemplate(
      day,
      diaryTemplatePresets.first,
      createdAt: DateTime(2026, 10, 4, 9),
    );

    final journal = store.journal(day);
    expect(journal.beautiful, 'Una giornata importante');
    expect(journal.blocks, hasLength(2));
    expect(journal.blocks.first.id, 'existing');
    store.dispose();
  });
}
