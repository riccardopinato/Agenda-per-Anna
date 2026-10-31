part of '../main.dart';

List<String> normalizeOrganizationTags(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in values) {
    final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) continue;
    final key = value.toLowerCase();
    if (!seen.add(key)) continue;
    result.add(value);
    if (result.length >= 12) break;
  }
  return result;
}

/// UI copy for the Inbox-specific taxonomy, in all supported languages.
String inboxCategoryCopy(String code, String key) {
  final labels = switch (code) {
    'en' => {
      'heading': 'Your categories', 'all': 'All', 'manage': 'Manage',
      'create': 'New tag', 'rename': 'Rename category',
      'choose': 'Choose a note to categorize',
      'empty': 'Create an Inbox note first',
      'hint': 'Tags are saved on the selected note',
      'failed': 'Could not save the category',
    },
    'es' => {
      'heading': 'Tus categorías', 'all': 'Todas', 'manage': 'Gestionar',
      'create': 'Nueva etiqueta', 'rename': 'Renombrar categoría',
      'choose': 'Elige una nota para clasificar',
      'empty': 'Crea primero una nota en Inbox',
      'hint': 'Las etiquetas se guardan en la nota elegida',
      'failed': 'No se pudo guardar la categoría',
    },
    'fr' => {
      'heading': 'Vos catégories', 'all': 'Toutes', 'manage': 'Gérer',
      'create': 'Nouveau tag', 'rename': 'Renommer la catégorie',
      'choose': 'Choisissez une note à classer',
      'empty': 'Créez d’abord une note Inbox',
      'hint': 'Les tags sont enregistrés sur la note choisie',
      'failed': 'Impossible d’enregistrer la catégorie',
    },
    'pt' => {
      'heading': 'As tuas categorias', 'all': 'Todas', 'manage': 'Gerir',
      'create': 'Nova etiqueta', 'rename': 'Renomear categoria',
      'choose': 'Escolhe uma nota para categorizar',
      'empty': 'Cria primeiro uma nota na Inbox',
      'hint': 'As etiquetas são guardadas na nota escolhida',
      'failed': 'Não foi possível guardar a categoria',
    },
    _ => {
      'heading': 'Le tue categorie', 'all': 'Tutte', 'manage': 'Gestisci',
      'create': 'Nuovo tag', 'rename': 'Rinomina categoria',
      'choose': 'Scegli una nota da categorizzare',
      'empty': 'Crea prima una nota Inbox',
      'hint': 'I tag vengono salvati sulla nota scelta',
      'failed': 'Impossibile salvare la categoria',
    },
  };
  return labels[key] ?? key;
}

extension OrganizationAgendaStore on AgendaStore {
  List<InboxEntry> get activeInboxEntries =>
      inbox.where((entry) => !entry.archived).toList(growable: false);

  List<InboxEntry> get archivedInboxEntries =>
      inbox.where((entry) => entry.archived).toList(growable: false);

  List<String> get organizationTags {
    final tags = <String>[];
    for (final entry in inbox) {
      tags.addAll(entry.tags);
    }
    for (final journal in journals.values) {
      for (final block in journal.blocks) {
        tags.addAll(block.tags);
      }
    }
    final normalized = normalizeOrganizationTags(tags);
    normalized.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return normalized;
  }

  /// Inbox-only category names (never mix in private diary categories).
  /// A new category becomes persistent when attached to a canonical note.
  List<String> get inboxCategoryTags {
    final byName = <String, String>{
      for (final category in preferences.inboxCategoryCatalog)
        category.toLowerCase(): category,
    };
    for (final entry in inbox) {
      for (final tag in entry.tags) {
        final name = tag.trim();
        if (name.isEmpty) continue;
        byName.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    return byName.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// A category can exist before any note uses it. It follows canonical
  /// account-scoped preferences, including normal backup and sync.
  Future<void> createInboxCategory(String name) async {
    final value = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty || value.length > 48) {
      throw ArgumentError.value(name, 'name', 'Invalid category name');
    }
    final existing = inboxCategoryTags;
    if (existing.any((tag) => tag.toLowerCase() == value.toLowerCase())) {
      return;
    }
    final updated = normalizeInboxCategoryCatalog([
      ...preferences.inboxCategoryCatalog,
      value,
    ]);
    if (updated.length == preferences.inboxCategoryCatalog.length) {
      throw StateError('Inbox category catalogue full');
    }
    await savePreferences(preferences.copyWith(inboxCategoryCatalog: updated));
    _notifyInboxChanged();
  }

  /// Empty categories can be removed without detaching tags from notes.
  Future<void> removeUnusedInboxCategory(String name) async {
    final key = name.trim().toLowerCase();
    if (inbox.any((entry) =>
        entry.tags.any((tag) => tag.trim().toLowerCase() == key))) {
      throw StateError('Category still used by Inbox notes');
    }
    final updated = preferences.inboxCategoryCatalog
        .where((tag) => tag.toLowerCase() != key).toList();
    await savePreferences(preferences.copyWith(inboxCategoryCatalog: updated));
    _notifyInboxChanged();
  }

  /// Live Inbox records using the same category, case-insensitively.
  List<InboxEntry> inboxEntriesInCategory(
    String category, {
    bool includeArchived = false,
  }) {
    final key = category.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final entries = inbox.where((entry) =>
      (includeArchived || !entry.archived) &&
      entry.tags.any((tag) => tag.trim().toLowerCase() == key),
    ).toList();
    entries.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return entries;
  }

  Future<void> toggleInboxArchived(String id) async {
    final index = inbox.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    inbox[index] = inbox[index].copyWith(
      archived: !inbox[index].archived,
    );
    await _persistEntityMutation(
      type: 'inbox',
      id: inbox[index].id,
      payload: inbox[index].toJson(),
    );
    _notifyInboxChanged();
  }

  Future<void> setInboxTags(String id, Iterable<String> tags) async {
    final index = inbox.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    inbox[index] = inbox[index].copyWith(
      tags: normalizeOrganizationTags(tags),
    );
    await _persistEntityMutation(
      type: 'inbox',
      id: inbox[index].id,
      payload: inbox[index].toJson(),
    );
    _notifyInboxChanged();
  }

  /// Rename a tag in ALL Inbox records, including archived records.
  /// Persist the batch first; only then update the in-memory projection.
  Future<int> renameInboxTag(String oldName, String newName) async {
    final from = normalizeOrganizationTags([oldName]);
    final to = normalizeOrganizationTags([newName]);
    if (from.isEmpty || to.isEmpty) return 0;
    final oldKey = from.single.toLowerCase();
    final target = to.single;
    final updates = <({int index, InboxEntry entry})>[];
    for (var i = 0; i < inbox.length; i++) {
      final entry = inbox[i];
      if (!entry.tags.any((tag) => tag.toLowerCase() == oldKey)) continue;
      final next = entry.copyWith(
        tags: normalizeOrganizationTags(entry.tags.map(
          (tag) => tag.toLowerCase() == oldKey ? target : tag,
        )),
      );
      if (listEquals(next.tags, entry.tags)) continue;
      updates.add((index: i, entry: next));
    }
    final catalog = preferences.inboxCategoryCatalog;
    final newCatalog = normalizeInboxCategoryCatalog([
      for (final name in catalog)
        name.toLowerCase() == oldKey ? target : name,
    ]);
    if (updates.isEmpty && listEquals(catalog, newCatalog)) return 0;
    if (updates.isNotEmpty) {
      await _persistEntityMutations(
      updates.map((update) => (
        type: 'inbox',
        id: update.entry.id,
        payload: update.entry.toJson(),
        deleted: false,
      )).toList(),
    );
      for (final update in updates) {
        inbox[update.index] = update.entry;
      }
    }
    if (!listEquals(catalog, newCatalog)) {
      await savePreferences(
        preferences.copyWith(inboxCategoryCatalog: newCatalog),
      );
    }
    _notifyInboxChanged();
    return updates.length;
  }

  Future<void> updateDiaryOrganization(
    DateTime date,
    String blockId, {
    bool? pinned,
    bool? archived,
    Iterable<String>? tags,
  }) async {
    final current = journal(date);
    final index = current.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return;

    final blocks = [...current.blocks];
    final block = blocks[index];
    blocks[index] = block.copyWith(
      pinned: pinned,
      archived: archived,
      tags: tags == null ? null : normalizeOrganizationTags(tags),
    );
    await saveJournal(date, current.copyWith(blocks: blocks));
  }

  Future<void> toggleDiaryPinned(DateTime date, String blockId) async {
    final block = journal(date).blocks.cast<DiaryBlock?>().firstWhere(
          (candidate) => candidate?.id == blockId,
          orElse: () => null,
        );
    if (block == null) return;
    await updateDiaryOrganization(
      date,
      blockId,
      pinned: !block.pinned,
    );
  }

  Future<void> toggleDiaryArchived(DateTime date, String blockId) async {
    final block = journal(date).blocks.cast<DiaryBlock?>().firstWhere(
          (candidate) => candidate?.id == blockId,
          orElse: () => null,
        );
    if (block == null) return;
    await updateDiaryOrganization(
      date,
      blockId,
      archived: !block.archived,
    );
  }

  Future<void> setDiaryTags(
    DateTime date,
    String blockId,
    Iterable<String> tags,
  ) =>
      updateDiaryOrganization(
        date,
        blockId,
        tags: tags,
      );
}
