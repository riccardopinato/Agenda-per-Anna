import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('CAP-0120 manual author alt text legacy and backup roundtrip', () {
    final day = DateTime(2026, 11, 4);
    final original = DiaryBlock(
      id:'pic', type: DiaryBlockType.photo, createdAt:day,
      text:'A moment', mediaAssetId:'asset-1',
    );
    final legacy = DiaryBlock.fromJson(original.toJson()
        ..remove('altText'));
    expect(legacy.altText, isEmpty);
    final described = original.copyWith(altText: 'Una foto del lago');
    expect(DiaryBlock.fromJson(described.toJson()).altText,
        'Una foto del lago');
    expect(DiaryBlock.fromJson(described.toLocalJson()).altText,
        'Una foto del lago');
    expect(described.mediaAssetId, original.mediaAssetId);
    expect(described.text, original.text);
    expect(original.altText, isEmpty);
    final emojiDescription = List<String>.filled(300, '🌻').join();
    final combinedDescription = List<String>.filled(300, 'e\u0301').join();
    expect(DiaryBlock.fromJson(original.copyWith(
      altText: emojiDescription,
    ).toJson()).altText, emojiDescription);
    expect(DiaryBlock.fromJson(original.copyWith(
      altText: combinedDescription,
    ).toLocalJson()).altText, combinedDescription);
    expect(DiaryBlock.fromJson(original.copyWith(
      altText: List<String>.filled(501, 'a').join(),
    ).toJson()).altText, isEmpty);
  });

  test('CAP-0147 Today order defaults, normalizes, and persists', () {
    const old = AgendaPreferences();
    expect(old.todayCardOrder, ['review','realistic']);
    expect(AgendaPreferences.fromJson(
        const {'displayName':'A'}).todayCardOrder,
        ['review','realistic']);
    final reversed = old.copyWith(todayCardOrder: ['realistic','review']);
    final restored = AgendaPreferences.fromJson(reversed.toJson());
    expect(restored.todayCardOrder, ['realistic','review']);
    expect(restored.displayName, old.displayName);
    expect(annaNormalizeTodayCardOrder(
        ['unknown','realistic','realistic','review']),
        ['realistic','review']);
    expect(annaNormalizeTodayCardOrder(['unexpected']), ['review','realistic']);
  });

  test('CAP-0147 state cannot own or erase module data', () {
    const original = AgendaPreferences(
      displayName: 'Anna',
      enabledModules: {AppModule.memories, AppModule.shopping},
    );
    final updated = original.copyWith(todayCardOrder: ['realistic','review']);
    expect(updated.enabledModules, original.enabledModules);
    expect(updated.displayName, 'Anna');
    expect(updated.todayCardOrder, ['realistic','review']);
  });
}
