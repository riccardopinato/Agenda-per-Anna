import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('legacy preferences preserve the complete existing experience', () {
    final legacy = AgendaPreferences.fromJson(const {});

    expect(legacy.personalizationPreset, PersonalizationPreset.complete);
    expect(legacy.enabledModules, completeAppModules);
    for (final module in AppModule.values) {
      expect(legacy.isModuleEnabled(module), isTrue);
    }
  });

  test('personalization presets are deterministic and reversible', () {
    const base = AgendaPreferences();

    final essential =
        base.applyPersonalizationPreset(PersonalizationPreset.essential);
    expect(essential.enabledModules, isEmpty);

    final life = essential.applyPersonalizationPreset(
      PersonalizationPreset.life,
    );
    expect(life.enabledModules, lifeAppModules);

    final complete = life.applyPersonalizationPreset(
      PersonalizationPreset.complete,
    );
    expect(complete.enabledModules, completeAppModules);
  });

  test('manual module changes become custom without deleting other choices', () {
    const base = AgendaPreferences();

    final hidden = base.withModuleEnabled(AppModule.workout, false);
    expect(hidden.personalizationPreset, PersonalizationPreset.custom);
    expect(hidden.isModuleEnabled(AppModule.workout), isFalse);
    expect(hidden.isModuleEnabled(AppModule.memories), isTrue);

    final restored = hidden.withModuleEnabled(AppModule.workout, true);
    expect(restored.isModuleEnabled(AppModule.workout), isTrue);
    expect(restored.enabledModules, completeAppModules);
  });

  test('Cycle Tracker visibility keeps its Vault dependency reachable', () {
    final cycleOnly = const AgendaPreferences(
      personalizationPreset: PersonalizationPreset.essential,
      enabledModules: {},
    ).withModuleEnabled(AppModule.cycleTracker, true);

    expect(cycleOnly.isModuleEnabled(AppModule.cycleTracker), isTrue);
    expect(cycleOnly.isModuleEnabled(AppModule.privateVault), isTrue);

    final withoutVault =
        cycleOnly.withModuleEnabled(AppModule.privateVault, false);
    expect(withoutVault.isModuleEnabled(AppModule.privateVault), isFalse);
    expect(withoutVault.isModuleEnabled(AppModule.cycleTracker), isFalse);
  });

  test('custom module preferences round-trip through JSON', () {
    final prefs = const AgendaPreferences()
        .withModuleEnabled(AppModule.shopping, false)
        .withModuleEnabled(AppModule.ecosystem, false);

    final restored = AgendaPreferences.fromJson(prefs.toJson());

    expect(restored.personalizationPreset, PersonalizationPreset.custom);
    expect(restored.isModuleEnabled(AppModule.shopping), isFalse);
    expect(restored.isModuleEnabled(AppModule.ecosystem), isFalse);
    expect(restored.isModuleEnabled(AppModule.memories), isTrue);
  });

  test('unknown future module names are ignored safely', () {
    final restored = AgendaPreferences.fromJson(const {
      'personalizationPreset': 'custom',
      'enabledModules': ['memories', 'future_module'],
    });

    expect(restored.personalizationPreset, PersonalizationPreset.custom);
    expect(restored.enabledModules, {AppModule.memories});
  });

  test('AgendaStore module changes never mutate domain data', () async {
    final store = AgendaStore();

    store.shoppingItems.add(
      ShoppingItem(
        id: 'keep-shopping',
        name: 'Latte',
        createdAt: DateTime(2026, 10, 14),
      ),
    );

    await store.setModuleEnabled(AppModule.shopping, false);

    expect(store.preferences.isModuleEnabled(AppModule.shopping), isFalse);
    expect(store.shoppingItems.single.id, 'keep-shopping');

    await store.setModuleEnabled(AppModule.shopping, true);
    expect(store.preferences.isModuleEnabled(AppModule.shopping), isTrue);
    expect(store.shoppingItems.single.id, 'keep-shopping');
  });

  test('backup restore preserves personalization while merge keeps target prefs',
      () async {
    final source = AgendaStore();
    await source.setModuleEnabled(AppModule.workout, false);
    final backup = await source.createBackupJson();

    final restored = AgendaStore();
    await restored.restoreBackup(backup, merge: false);
    expect(restored.preferences.isModuleEnabled(AppModule.workout), isFalse);

    final mergeTarget = AgendaStore();
    await mergeTarget.setModuleEnabled(AppModule.shopping, false);
    await mergeTarget.restoreBackup(backup, merge: true);

    expect(
      mergeTarget.preferences.isModuleEnabled(AppModule.shopping),
      isFalse,
    );
    expect(
      mergeTarget.preferences.isModuleEnabled(AppModule.workout),
      isTrue,
    );
  });
}
