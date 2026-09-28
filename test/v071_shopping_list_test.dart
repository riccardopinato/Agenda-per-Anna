import 'dart:io';

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

  test('shopping categories are deterministic and item JSON is compatible', () {
    final store = AgendaStore();
    expect(store.inferShoppingCategory('Latte'), ShoppingCategory.dairy);
    expect(store.inferShoppingCategory('Pane'), ShoppingCategory.bakery);
    expect(store.inferShoppingCategory('Mele'), ShoppingCategory.produce);
    expect(store.inferShoppingCategory('Detersivo piatti'),
        ShoppingCategory.household);

    final legacy = ShoppingItem.fromJson({
      'id': 'legacy-shopping',
      'name': 'Qualcosa',
      'createdAt': DateTime(2026, 9, 28).toIso8601String(),
    });
    expect(legacy.quantity, isEmpty);
    expect(legacy.category, ShoppingCategory.other);
    expect(legacy.done, isFalse);
    expect(legacy.purchaseCount, 0);
    store.dispose();
  });

  test('private shopping persists, reorders and learns frequent items',
      () async {
    final first = AgendaStore();
    await first.load();

    final milk = await first.addShoppingItem('Latte', quantity: '2');
    final bread = await first.addShoppingItem('Pane');
    expect(milk, isNotNull);
    expect(bread, isNotNull);
    expect(first.activeShoppingItems.map((item) => item.name), ['Latte', 'Pane']);

    await first.reorderShoppingItems([bread!.id, milk!.id]);
    expect(first.activeShoppingItems.map((item) => item.name), ['Pane', 'Latte']);

    await first.toggleShoppingItem(milk.id);
    expect(first.purchasedShoppingItems.single.name, 'Latte');
    expect(first.purchasedShoppingItems.single.purchaseCount, 1);
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.activeShoppingItems.single.name, 'Pane');
    expect(second.purchasedShoppingItems.single.name, 'Latte');
    expect(second.frequentShoppingItems.single.purchaseCount, 1);

    await second.addShoppingItem('  Latte  ');
    expect(second.activeShoppingItems.map((item) => item.name), contains('Latte'));
    expect(
      second.shoppingItems.where((item) => item.normalizedName == 'latte'),
      hasLength(1),
    );
    second.dispose();
  });

  test('private shopping uses Trash and restores losslessly', () async {
    final store = AgendaStore();
    await store.load();
    final item = await store.addShoppingItem(
      'Yogurt',
      quantity: '4',
      category: ShoppingCategory.dairy,
    );
    expect(item, isNotNull);

    expect(await store.moveShoppingItemToTrash(item!.id), isTrue);
    expect(store.shoppingItems, isEmpty);
    final trashed = store.trash.single;
    expect(trashed.kind, TrashEntityKind.shoppingItem);
    expect(trashed.payload['quantity'], '4');

    expect(await store.restoreTrashEntry(trashed.id), isTrue);
    expect(store.shoppingItems.single.name, 'Yogurt');
    expect(store.shoppingItems.single.quantity, '4');
    expect(store.shoppingItems.single.category, ShoppingCategory.dairy);
    store.dispose();
  });

  test('shopping survives existing backup restore pipeline', () async {
    final source = AgendaStore();
    await source.load();
    await source.addShoppingItem(
      'Mele',
      quantity: '1 kg',
      category: ShoppingCategory.produce,
    );
    final backup = await source.createBackupJson();
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final restored = AgendaStore();
    await restored.load();
    await restored.restoreBackup(backup, merge: false);
    expect(restored.shoppingItems.single.name, 'Mele');
    expect(restored.shoppingItems.single.quantity, '1 kg');
    expect(restored.shoppingItems.single.category, ShoppingCategory.produce);
    restored.dispose();
  });

  test('shopping remains isolated across account profiles', () async {
    final store = AgendaStore();
    await store.load();

    await store.activateCloudAccount('shopping-a');
    await store.addShoppingItem('Articolo A');

    await store.activateCloudAccount('shopping-b');
    expect(store.shoppingItems, isEmpty);
    await store.addShoppingItem('Articolo B');

    await store.activateCloudAccount('shopping-a');
    expect(store.shoppingItems.map((item) => item.name), ['Articolo A']);
    store.dispose();
  });

  test('Noi shopping reuses SharedEntry payload and pending queue', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('shopping-shared-user');

    final added = await store.addSharedShoppingItem(
      'space-shopping',
      'Pasta',
      quantity: '2 pacchi',
      category: ShoppingCategory.pantry,
    );
    expect(added, isNotNull);

    final cached = store.sharedShoppingItems('space-shopping').single;
    expect(cached.type, SharedEntryType.shopping);
    expect(cached.shoppingQuantity, '2 pacchi');
    expect(cached.shoppingCategory, ShoppingCategory.pantry);

    final roundTrip = SharedEntry.fromJson(cached.toJson());
    expect(roundTrip.type, SharedEntryType.shopping);
    expect(roundTrip.shoppingQuantity, '2 pacchi');

    final pending =
        await store.loadSharedPendingOperations('space-shopping');
    expect(pending.any((operation) => operation.entityId == cached.id), isTrue);

    await store.toggleSharedShoppingItem('space-shopping', cached);
    final checked = store.sharedShoppingItems('space-shopping').single;
    expect(checked.done, isTrue);
    expect(checked.shoppingPurchaseCount, 1);
    store.dispose();
  });

  test('v0.71 keeps one private and one existing shared sync path', () {
    final storeSource = File('lib/src/agenda_store.dart').readAsStringSync();
    final shoppingSource =
        File('lib/src/shopping_domain.dart').readAsStringSync();
    final sharedSource =
        File('lib/src/screens/shared_space.dart').readAsStringSync();
    final migrations = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .join('\n')
        .toLowerCase();

    expect(storeSource, contains("static const _shoppingKey = 'shopping_v1'"));
    expect(shoppingSource, contains("type: 'shopping'"));
    expect(shoppingSource, contains('enqueueSharedUpsert('));
    expect(shoppingSource, contains('enqueueSharedDelete('));
    expect(sharedSource, contains('ShoppingListScreen('));
    expect(migrations, isNot(contains('create table shopping')));
    expect(migrations, isNot(contains('create table public.shopping')));
  });

  test('v0.71 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.71.0');
    expect(pubspec, contains('version: 0.71.0+81'));
  });
}
