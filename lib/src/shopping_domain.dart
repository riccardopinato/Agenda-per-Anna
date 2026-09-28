part of '../main.dart';

extension ShoppingAgendaStore on AgendaStore {
  List<ShoppingItem> get activeShoppingItems {
    final result = shoppingItems.where((item) => !item.done).toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.createdAt.compareTo(b.createdAt);
      });
    return result;
  }

  List<ShoppingItem> get purchasedShoppingItems {
    final result = shoppingItems.where((item) => item.done).toList()
      ..sort((a, b) {
        final aDate = a.lastPurchasedAt ?? a.createdAt;
        final bDate = b.lastPurchasedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    return result;
  }

  List<ShoppingItem> get frequentShoppingItems {
    final result = shoppingItems.where((item) => item.purchaseCount > 0).toList()
      ..sort((a, b) {
        final count = b.purchaseCount.compareTo(a.purchaseCount);
        if (count != 0) return count;
        final aDate = a.lastPurchasedAt ?? a.createdAt;
        final bDate = b.lastPurchasedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    return result;
  }

  ShoppingCategory inferShoppingCategory(String rawName) {
    final value = rawName.trim().toLowerCase();
    bool has(Iterable<String> words) => words.any(value.contains);

    if (has(const [
      'mela', 'mele', 'banana', 'banane', 'pera', 'pere', 'arancia',
      'limone', 'insalata', 'pomodor', 'zucchin', 'carot', 'patat',
      'cipoll', 'verdura', 'frutta', 'aglio', 'spinaci', 'funghi',
    ])) return ShoppingCategory.produce;

    if (has(const [
      'latte', 'yogurt', 'formaggio', 'mozzarella', 'burro', 'panna',
      'ricotta', 'uova',
    ])) return ShoppingCategory.dairy;

    if (has(const [
      'pane', 'panino', 'panini', 'focaccia', 'pizza', 'brioche',
      'cracker', 'grissini',
    ])) return ShoppingCategory.bakery;

    if (has(const [
      'acqua', 'vino', 'birra', 'succo', 'cola', 'bibita', 'caffè',
      'caffe', 'tè', 'the',
    ])) return ShoppingCategory.drinks;

    if (has(const ['surgel', 'gelato', 'ghiaccio', 'frozen'])) {
      return ShoppingCategory.frozen;
    }

    if (has(const [
      'detersiv', 'candeggina', 'spugna', 'carta casa', 'carta igien',
      'sacchi', 'sapone piatti', 'lavastoviglie', 'ammorbidente',
    ])) return ShoppingCategory.household;

    if (has(const [
      'shampoo', 'bagnoschiuma', 'dentifricio', 'deodorante',
      'crema', 'rasoio', 'assorbenti',
    ])) return ShoppingCategory.personalCare;

    if (has(const [
      'pasta', 'riso', 'farina', 'zucchero', 'sale', 'olio', 'aceto',
      'biscotti', 'cereali', 'tonno', 'legumi', 'passata', 'salsa',
      'cioccolato',
    ])) return ShoppingCategory.pantry;

    return ShoppingCategory.other;
  }

  int _nextShoppingOrder() {
    if (shoppingItems.isEmpty) return 0;
    return shoppingItems.map((item) => item.sortOrder).fold<int>(0, max) + 1;
  }

  Future<ShoppingItem?> addShoppingItem(
    String name, {
    String quantity = '',
    ShoppingCategory? category,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    final normalized = cleanName.toLowerCase();
    final existingIndex =
        shoppingItems.indexWhere((item) => item.normalizedName == normalized);

    if (existingIndex >= 0) {
      final existing = shoppingItems[existingIndex];
      final updated = existing.copyWith(
        name: cleanName,
        quantity: quantity.trim().isEmpty ? existing.quantity : quantity.trim(),
        category: category ?? existing.category,
        done: false,
        sortOrder: _nextShoppingOrder(),
      );
      shoppingItems[existingIndex] = updated;
      await _persistEntityMutation(
        type: 'shopping',
        id: updated.id,
        payload: updated.toJson(),
      );
      _notifyShoppingChanged();
      return updated;
    }

    final item = ShoppingItem(
      id: const Uuid().v4(),
      name: cleanName,
      quantity: quantity.trim(),
      category: category ?? inferShoppingCategory(cleanName),
      sortOrder: _nextShoppingOrder(),
      createdAt: DateTime.now(),
    );
    shoppingItems.add(item);
    await _persistEntityMutation(
      type: 'shopping',
      id: item.id,
      payload: item.toJson(),
    );
    _notifyShoppingChanged();
    return item;
  }

  Future<void> updateShoppingItem(
    ShoppingItem item, {
    String? name,
    String? quantity,
    ShoppingCategory? category,
  }) async {
    final index = shoppingItems.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    final cleanName = (name ?? item.name).trim();
    if (cleanName.isEmpty) return;
    final updated = item.copyWith(
      name: cleanName,
      quantity: quantity?.trim(),
      category: category,
    );
    shoppingItems[index] = updated;
    await _persistEntityMutation(
      type: 'shopping',
      id: updated.id,
      payload: updated.toJson(),
    );
    _notifyShoppingChanged();
  }

  Future<void> toggleShoppingItem(String id) async {
    final index = shoppingItems.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = shoppingItems[index];
    final completing = !current.done;
    final updated = current.copyWith(
      done: completing,
      purchaseCount:
          completing ? current.purchaseCount + 1 : current.purchaseCount,
      lastPurchasedAt: completing ? DateTime.now() : null,
      sortOrder: completing ? current.sortOrder : _nextShoppingOrder(),
    );
    shoppingItems[index] = updated;
    await _persistEntityMutation(
      type: 'shopping',
      id: updated.id,
      payload: updated.toJson(),
    );
    _notifyShoppingChanged();
  }

  Future<void> reorderShoppingItems(List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[];
    for (var index = 0; index < orderedIds.length; index++) {
      final itemIndex =
          shoppingItems.indexWhere((item) => item.id == orderedIds[index]);
      if (itemIndex < 0) continue;
      final current = shoppingItems[itemIndex];
      if (current.done || current.sortOrder == index) continue;
      final updated = current.copyWith(sortOrder: index);
      shoppingItems[itemIndex] = updated;
      mutations.add((
        type: 'shopping',
        id: updated.id,
        payload: updated.toJson(),
        deleted: false,
      ));
    }
    if (mutations.isEmpty) return;
    await _persistEntityMutations(mutations);
    _notifyShoppingChanged();
  }

  int _nextSharedShoppingOrder(String spaceId) {
    final entries = sharedShoppingItems(spaceId)
        .where((entry) => !entry.done)
        .toList(growable: false);
    if (entries.isEmpty) return 0;
    return entries.map((entry) => entry.shoppingOrder).fold<int>(0, max) + 1;
  }

  Future<SharedEntry?> addSharedShoppingItem(
    String spaceId,
    String name, {
    String quantity = '',
    ShoppingCategory? category,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    final normalized = cleanName.toLowerCase();
    SharedEntry? existing;
    for (final entry in sharedShoppingItems(spaceId)) {
      if (entry.title.trim().toLowerCase() == normalized) {
        existing = entry;
        break;
      }
    }

    final revision = DateTime.now().toUtc();
    final next = existing == null
        ? SharedEntry(
            id: const Uuid().v4(),
            type: SharedEntryType.shopping,
            title: cleanName,
            note: '',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            shoppingQuantity: quantity.trim(),
            shoppingCategory: category ?? inferShoppingCategory(cleanName),
            shoppingOrder: _nextSharedShoppingOrder(spaceId),
            shoppingPurchaseCount: 0,
          )
        : existing.copyWith(
            title: cleanName,
            done: false,
            shoppingQuantity: quantity.trim().isEmpty
                ? existing.shoppingQuantity
                : quantity.trim(),
            shoppingCategory: category ?? existing.shoppingCategory,
            shoppingOrder: _nextSharedShoppingOrder(spaceId),
          );

    await enqueueSharedUpsert(
      spaceId: spaceId,
      entry: next,
      updatedAt: revision,
    );
    _scheduleDeferredSharedCloudSync();
    return next;
  }

  Future<void> updateSharedShoppingItem(
    String spaceId,
    SharedEntry entry, {
    String? name,
    String? quantity,
    ShoppingCategory? category,
  }) async {
    if (entry.type != SharedEntryType.shopping) return;
    final cleanName = (name ?? entry.title).trim();
    if (cleanName.isEmpty) return;
    final revision = DateTime.now().toUtc();
    await enqueueSharedUpsert(
      spaceId: spaceId,
      entry: entry.copyWith(
        title: cleanName,
        shoppingQuantity: quantity?.trim(),
        shoppingCategory: category,
      ),
      updatedAt: revision,
    );
    _scheduleDeferredSharedCloudSync();
  }

  Future<void> toggleSharedShoppingItem(
    String spaceId,
    SharedEntry entry,
  ) async {
    if (entry.type != SharedEntryType.shopping) return;
    final completing = !entry.done;
    final revision = DateTime.now().toUtc();
    await enqueueSharedUpsert(
      spaceId: spaceId,
      entry: entry.copyWith(
        done: completing,
        shoppingPurchaseCount: completing
            ? entry.shoppingPurchaseCount + 1
            : entry.shoppingPurchaseCount,
        shoppingLastPurchasedAt:
            completing ? DateTime.now() : entry.shoppingLastPurchasedAt,
        shoppingOrder: completing
            ? entry.shoppingOrder
            : _nextSharedShoppingOrder(spaceId),
      ),
      updatedAt: revision,
    );
    _scheduleDeferredSharedCloudSync();
  }

  Future<void> reorderSharedShoppingItems(
    String spaceId,
    List<String> orderedIds,
  ) async {
    if (orderedIds.isEmpty) return;
    final entries = {
      for (final entry in sharedShoppingItems(spaceId)) entry.id: entry,
    };
    final revision = DateTime.now().toUtc();
    for (var index = 0; index < orderedIds.length; index++) {
      final entry = entries[orderedIds[index]];
      if (entry == null || entry.done || entry.shoppingOrder == index) {
        continue;
      }
      await enqueueSharedUpsert(
        spaceId: spaceId,
        entry: entry.copyWith(shoppingOrder: index),
        updatedAt: revision.add(Duration(microseconds: index)),
      );
    }
    _scheduleDeferredSharedCloudSync();
  }

  Future<void> deleteSharedShoppingItem(
    String spaceId,
    SharedEntry entry,
  ) async {
    if (entry.type != SharedEntryType.shopping) return;
    await enqueueSharedDelete(
      spaceId: spaceId,
      entityId: entry.id,
      updatedAt: DateTime.now().toUtc(),
    );
    _scheduleDeferredSharedCloudSync();
  }

  List<SharedEntry> sharedShoppingItems(String spaceId) {
    final result = sharedEntriesForSpace(spaceId)
        .where((entry) => entry.type == SharedEntryType.shopping)
        .toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        if (a.done) {
          final aDate = a.shoppingLastPurchasedAt ?? a.updatedAt ?? a.date;
          final bDate = b.shoppingLastPurchasedAt ?? b.updatedAt ?? b.date;
          return bDate.compareTo(aDate);
        }
        final order = a.shoppingOrder.compareTo(b.shoppingOrder);
        if (order != 0) return order;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return result;
  }
}
