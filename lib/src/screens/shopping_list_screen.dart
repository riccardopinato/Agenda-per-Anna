part of '../../main.dart';

class ShoppingListScreen extends StatefulWidget {
  final AgendaStore store;
  final SharedSpace? sharedSpace;

  const ShoppingListScreen({
    super.key,
    required this.store,
    this.sharedSpace,
  });

  bool get shared => sharedSpace != null;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  bool purchased = false;
  bool adding = false;

  String? get _spaceId => widget.sharedSpace?.id;

  @override
  void initState() {
    super.initState();
    if (widget.shared) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshShared());
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _refreshShared() async {
    if (!widget.shared || !CloudSyncService.instance.signedIn) return;
    try {
      await widget.store.refreshSharedAgendaCache(pullRemote: true);
    } catch (_) {
      // The cached list remains usable offline.
    }
  }

  List<ShoppingItem> get _privateItems =>
      purchased ? widget.store.purchasedShoppingItems : widget.store.activeShoppingItems;

  List<SharedEntry> get _sharedItems {
    final spaceId = _spaceId;
    if (spaceId == null) return const [];
    return widget.store
        .sharedShoppingItems(spaceId)
        .where((entry) => entry.done == purchased)
        .toList(growable: false);
  }

  Future<void> _add() async {
    final name = nameController.text.trim();
    if (name.isEmpty || adding) return;
    setState(() => adding = true);
    try {
      if (widget.shared) {
        await widget.store.addSharedShoppingItem(
          _spaceId!,
          name,
          quantity: quantityController.text,
        );
      } else {
        await widget.store.addShoppingItem(
          name,
          quantity: quantityController.text,
        );
      }
      nameController.clear();
      quantityController.clear();
      if (mounted) setState(() => purchased = false);
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  Future<_ShoppingEditValue?> _showEditor({
    required String name,
    required String quantity,
    required ShoppingCategory category,
  }) async {
    final strings = AnnaStrings.of(context);
    final nameController = TextEditingController(text: name);
    final quantityController = TextEditingController(text: quantity);
    var selectedCategory = category;
    final result = await showDialog<_ShoppingEditValue>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(strings.editShoppingItem),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: strings.item,
                      prefixIcon: Icon(Icons.shopping_basket_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: strings.optionalQuantity,
                      hintText: strings.optionalQuantityHint,
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ShoppingCategory>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: strings.category,
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: ShoppingCategory.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(strings.shoppingCategoryLabel(category)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLocal(() => selectedCategory = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                final cleanName = nameController.text.trim();
                if (cleanName.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  _ShoppingEditValue(
                    name: cleanName,
                    quantity: quantityController.text.trim(),
                    category: selectedCategory,
                  ),
                );
              },
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    quantityController.dispose();
    return result;
  }

  Future<void> _editPrivate(ShoppingItem item) async {
    final value = await _showEditor(
      name: item.name,
      quantity: item.quantity,
      category: item.category,
    );
    if (value == null) return;
    await widget.store.updateShoppingItem(
      item,
      name: value.name,
      quantity: value.quantity,
      category: value.category,
    );
  }

  Future<void> _editShared(SharedEntry entry) async {
    final value = await _showEditor(
      name: entry.title,
      quantity: entry.shoppingQuantity,
      category: entry.shoppingCategory,
    );
    if (value == null) return;
    await widget.store.updateSharedShoppingItem(
      _spaceId!,
      entry,
      name: value.name,
      quantity: value.quantity,
      category: value.category,
    );
  }

  Future<void> _deletePrivate(ShoppingItem item) async {
    final removed = await widget.store.moveShoppingItemToTrash(item.id);
    if (!mounted || !removed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AnnaStrings.of(context).shoppingItemMovedToTrash)),
    );
  }

  Future<void> _deleteShared(SharedEntry entry) async {
    final strings = AnnaStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.deleteSharedShoppingQuestion),
            content: Text(
              strings.sharedShoppingDeleteDescription(entry.title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.deleteForEveryone),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await widget.store.deleteSharedShoppingItem(_spaceId!, entry);
  }

  Future<void> _togglePrivate(ShoppingItem item) =>
      widget.store.toggleShoppingItem(item.id);

  Future<void> _toggleShared(SharedEntry entry) =>
      widget.store.toggleSharedShoppingItem(_spaceId!, entry);

  Future<void> _reorderPrivate(int oldIndex, int newIndex) async {
    final list = widget.store.activeShoppingItems;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await widget.store.reorderShoppingItems(
      list.map((value) => value.id).toList(growable: false),
    );
  }

  Future<void> _reorderShared(int oldIndex, int newIndex) async {
    final list = _sharedItems;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await widget.store.reorderSharedShoppingItems(
      _spaceId!,
      list.map((value) => value.id).toList(growable: false),
    );
  }

  Future<void> _openSharedList() async {
    final strings = AnnaStrings.of(context);
    if (widget.store.sharedAgendaSpaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.sharedSpaceRequired),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<SharedSpace>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          children: [
            ListTile(
              title: Text(
                strings.sharedShopping,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(strings.sharedShoppingSelectDescription),
            ),
            ...widget.store.sharedAgendaSpaces.map(
              (space) => ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.favorite_outline),
                ),
                title: Text(space.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, space),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListScreen(
          store: widget.store,
          sharedSpace: selected,
        ),
      ),
    );
  }

  List<ShoppingItem> get _frequentPrivate =>
      widget.store.frequentShoppingItems.take(8).toList(growable: false);

  List<SharedEntry> get _frequentShared {
    final spaceId = _spaceId;
    if (spaceId == null) return const [];
    final list = widget.store
        .sharedShoppingItems(spaceId)
        .where((entry) => entry.shoppingPurchaseCount > 0)
        .toList()
      ..sort(
        (a, b) =>
            b.shoppingPurchaseCount.compareTo(a.shoppingPurchaseCount),
      );
    return list.take(8).toList(growable: false);
  }

  Widget _frequentChips(BuildContext context) {
    if (widget.shared) {
      final items = _frequentShared;
      if (items.isEmpty) return const SizedBox.shrink();
      return _FrequentShoppingSection(
        labels: items.map((item) => item.title).toList(growable: false),
        onTap: (index) => widget.store.addSharedShoppingItem(
          _spaceId!,
          items[index].title,
          quantity: items[index].shoppingQuantity,
          category: items[index].shoppingCategory,
        ),
      );
    }

    final items = _frequentPrivate;
    if (items.isEmpty) return const SizedBox.shrink();
    return _FrequentShoppingSection(
      labels: items.map((item) => item.name).toList(growable: false),
      onTap: (index) => widget.store.addShoppingItem(
        items[index].name,
        quantity: items[index].quantity,
        category: items[index].category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final listenable = widget.shared
        ? widget.store.sharedRevision
        : widget.store.shoppingRevision;

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final count = widget.shared
            ? widget.store
                .sharedShoppingItems(_spaceId!)
                .where((entry) => !entry.done)
                .length
            : widget.store.activeShoppingItems.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.shared
                  ? strings.sharedShoppingFor(widget.sharedSpace!.name)
                  : strings.shoppingList,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (!widget.shared)
                IconButton(
                  tooltip: strings.sharedShopping,
                  onPressed: _openSharedList,
                  icon: const Icon(Icons.favorite_outline),
                ),
              if (widget.shared)
                IconButton(
                  tooltip: strings.refresh,
                  onPressed: _refreshShared,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: _ShoppingQuickAddCard(
                    nameController: nameController,
                    quantityController: quantityController,
                    adding: adding,
                    onAdd: _add,
                    shared: widget.shared,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _frequentChips(context),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment<bool>(
                              value: false,
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: Text(strings.toBuy),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(strings.purchased),
                            ),
                          ],
                          selected: {purchased},
                          onSelectionChanged: (value) =>
                              setState(() => purchased = value.first),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        avatar: const Icon(Icons.format_list_numbered, size: 17),
                        label: Text('$count'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: widget.shared
                      ? _buildSharedList()
                      : _buildPrivateList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivateList() {
    final items = _privateItems;
    if (items.isEmpty) {
      return _ShoppingEmptyState(purchased: purchased, shared: false);
    }
    if (!purchased) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        onReorderItem: _reorderPrivate,
        itemBuilder: (context, index) {
          final item = items[index];
          return _PrivateShoppingTile(
            key: ValueKey(item.id),
            item: item,
            onToggle: () => _togglePrivate(item),
            onEdit: () => _editPrivate(item),
            onDelete: () => _deletePrivate(item),
            reorderIndex: index,
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _PrivateShoppingTile(
          key: ValueKey(item.id),
          item: item,
          onToggle: () => _togglePrivate(item),
          onEdit: () => _editPrivate(item),
          onDelete: () => _deletePrivate(item),
        );
      },
    );
  }

  Widget _buildSharedList() {
    final items = _sharedItems;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshShared,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 360,
              child: _ShoppingEmptyState(
                purchased: purchased,
                shared: true,
              ),
            ),
          ],
        ),
      );
    }

    if (!purchased) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        onReorderItem: _reorderShared,
        itemBuilder: (context, index) {
          final entry = items[index];
          return _SharedShoppingTile(
            key: ValueKey(entry.id),
            entry: entry,
            onToggle: () => _toggleShared(entry),
            onEdit: () => _editShared(entry),
            onDelete: () => _deleteShared(entry),
            reorderIndex: index,
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshShared,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final entry = items[index];
          return _SharedShoppingTile(
            key: ValueKey(entry.id),
            entry: entry,
            onToggle: () => _toggleShared(entry),
            onEdit: () => _editShared(entry),
            onDelete: () => _deleteShared(entry),
          );
        },
      ),
    );
  }
}

class _ShoppingEditValue {
  final String name;
  final String quantity;
  final ShoppingCategory category;

  const _ShoppingEditValue({
    required this.name,
    required this.quantity,
    required this.category,
  });
}

class _ShoppingQuickAddCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final bool adding;
  final bool shared;
  final VoidCallback onAdd;

  const _ShoppingQuickAddCard({
    required this.nameController,
    required this.quantityController,
    required this.adding,
    required this.shared,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Material(
      color: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  shared ? Icons.favorite_outline : Icons.shopping_cart_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shared
                        ? strings.sharedListQuickAdd
                        : strings.quickAddShopping,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => onAdd(),
                    decoration: InputDecoration(
                      labelText: strings.whatDoYouNeed,
                      hintText: strings.shoppingItemHint,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: quantityController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onAdd(),
                    decoration: InputDecoration(
                      labelText: strings.quantity,
                      hintText: strings.quantityHint,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: strings.add,
                  onPressed: adding ? null : onAdd,
                  icon: adding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentShoppingSection extends StatelessWidget {
  final List<String> labels;
  final ValueChanged<int> onTap;

  const _FrequentShoppingSection({
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            strings.frequent,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (var index = 0; index < labels.length; index++)
            ActionChip(
              avatar: const Icon(Icons.replay_outlined, size: 17),
              label: Text(labels[index]),
              onPressed: () => onTap(index),
            ),
        ],
      ),
    );
  }
}

class _PrivateShoppingTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? reorderIndex;

  const _PrivateShoppingTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    return _ShoppingTileShell(
      name: item.name,
      quantity: item.quantity,
      category: item.category,
      done: item.done,
      purchaseCount: item.purchaseCount,
      onToggle: onToggle,
      onEdit: onEdit,
      onDelete: onDelete,
      reorderIndex: reorderIndex,
    );
  }
}

class _SharedShoppingTile extends StatelessWidget {
  final SharedEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? reorderIndex;

  const _SharedShoppingTile({
    super.key,
    required this.entry,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    return _ShoppingTileShell(
      name: entry.title,
      quantity: entry.shoppingQuantity,
      category: entry.shoppingCategory,
      done: entry.done,
      purchaseCount: entry.shoppingPurchaseCount,
      onToggle: onToggle,
      onEdit: onEdit,
      onDelete: onDelete,
      reorderIndex: reorderIndex,
      shared: true,
    );
  }
}

class _ShoppingTileShell extends StatelessWidget {
  final String name;
  final String quantity;
  final ShoppingCategory category;
  final bool done;
  final int purchaseCount;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? reorderIndex;
  final bool shared;

  const _ShoppingTileShell({
    required this.name,
    required this.quantity,
    required this.category,
    required this.done,
    required this.purchaseCount,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.reorderIndex,
    this.shared = false,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(
        leading: Checkbox(
          value: done,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          [
            if (quantity.trim().isNotEmpty) quantity.trim(),
            strings.shoppingCategoryLabel(category),
            if (shared) 'Noi ♡',
            if (purchaseCount > 1) strings.purchasedTimes(purchaseCount),
          ].join(' · '),
        ),
        onTap: onEdit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reorderIndex != null)
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(strings.edit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(strings.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingEmptyState extends StatelessWidget {
  final bool purchased;
  final bool shared;

  const _ShoppingEmptyState({
    required this.purchased,
    required this.shared,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              purchased
                  ? Icons.check_circle_outline
                  : Icons.shopping_cart_outlined,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              purchased
                  ? strings.noRecentPurchases
                  : strings.shoppingListEmpty,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              purchased
                  ? strings.purchasedItemsHere
                  : shared
                      ? strings.sharedShoppingEmpty
                      : strings.privateShoppingEmpty,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
