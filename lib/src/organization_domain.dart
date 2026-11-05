part of '../main.dart';

/// Canonical-equivalent tag key for Latin alphabets used by IT/EN/ES/FR/PT.
/// Retains diacritics: café and cafe are distinct, while café and cafe\u0301
/// compare identically. This is a bounded Latin NFD mapping, not a general
/// transliterator or an external dependency.
const _latinOrganizationDecomposition = <int, String>{
  0xe0: 'a\u0300',
  0xe1: 'a\u0301',
  0xe2: 'a\u0302',
  0xe3: 'a\u0303',
  0xe4: 'a\u0308',
  0xe5: 'a\u030a',
  0xe7: 'c\u0327',
  0xe8: 'e\u0300',
  0xe9: 'e\u0301',
  0xea: 'e\u0302',
  0xeb: 'e\u0308',
  0xec: 'i\u0300',
  0xed: 'i\u0301',
  0xee: 'i\u0302',
  0xef: 'i\u0308',
  0xf1: 'n\u0303',
  0xf2: 'o\u0300',
  0xf3: 'o\u0301',
  0xf4: 'o\u0302',
  0xf5: 'o\u0303',
  0xf6: 'o\u0308',
  0xf9: 'u\u0300',
  0xfa: 'u\u0301',
  0xfb: 'u\u0302',
  0xfc: 'u\u0308',
  0xfd: 'y\u0301',
  0xff: 'y\u0308',
  0x101: 'a\u0304',
  0x103: 'a\u0306',
  0x105: 'a\u0328',
  0x107: 'c\u0301',
  0x109: 'c\u0302',
  0x10b: 'c\u0307',
  0x10d: 'c\u030c',
  0x10f: 'd\u030c',
  0x113: 'e\u0304',
  0x115: 'e\u0306',
  0x117: 'e\u0307',
  0x119: 'e\u0328',
  0x11b: 'e\u030c',
  0x11d: 'g\u0302',
  0x11f: 'g\u0306',
  0x121: 'g\u0307',
  0x123: 'g\u0327',
  0x125: 'h\u0302',
  0x129: 'i\u0303',
  0x12b: 'i\u0304',
  0x12d: 'i\u0306',
  0x12f: 'i\u0328',
  0x135: 'j\u0302',
  0x137: 'k\u0327',
  0x13a: 'l\u0301',
  0x13c: 'l\u0327',
  0x13e: 'l\u030c',
  0x144: 'n\u0301',
  0x146: 'n\u0327',
  0x148: 'n\u030c',
  0x14d: 'o\u0304',
  0x14f: 'o\u0306',
  0x151: 'o\u030b',
  0x155: 'r\u0301',
  0x157: 'r\u0327',
  0x159: 'r\u030c',
  0x15b: 's\u0301',
  0x15d: 's\u0302',
  0x15f: 's\u0327',
  0x161: 's\u030c',
  0x163: 't\u0327',
  0x165: 't\u030c',
  0x169: 'u\u0303',
  0x16b: 'u\u0304',
  0x16d: 'u\u0306',
  0x16f: 'u\u030a',
  0x171: 'u\u030b',
  0x173: 'u\u0328',
  0x175: 'w\u0302',
  0x177: 'y\u0302',
  0x17a: 'z\u0301',
  0x17c: 'z\u0307',
  0x17e: 'z\u030c',
  0x1a1: 'o\u031b',
  0x1b0: 'u\u031b',
  0x1ce: 'a\u030c',
  0x1d0: 'i\u030c',
  0x1d2: 'o\u030c',
  0x1d4: 'u\u030c',
  0x1d6: 'u\u0308\u0304',
  0x1d8: 'u\u0308\u0301',
  0x1da: 'u\u0308\u030c',
  0x1dc: 'u\u0308\u0300',
  0x1df: 'a\u0308\u0304',
  0x1e1: 'a\u0307\u0304',
  0x1e3: '\u00e6\u0304',
  0x1e7: 'g\u030c',
  0x1e9: 'k\u030c',
  0x1eb: 'o\u0328',
  0x1ed: 'o\u0328\u0304',
  0x1ef: '\u0292\u030c',
  0x1f0: 'j\u030c',
  0x1f5: 'g\u0301',
  0x1f9: 'n\u0300',
  0x1fb: 'a\u030a\u0301',
  0x1fd: '\u00e6\u0301',
  0x1ff: '\u00f8\u0301',
  0x201: 'a\u030f',
  0x203: 'a\u0311',
  0x205: 'e\u030f',
  0x207: 'e\u0311',
  0x209: 'i\u030f',
  0x20b: 'i\u0311',
  0x20d: 'o\u030f',
  0x20f: 'o\u0311',
  0x211: 'r\u030f',
  0x213: 'r\u0311',
  0x215: 'u\u030f',
  0x217: 'u\u0311',
  0x219: 's\u0326',
  0x21b: 't\u0326',
  0x21f: 'h\u030c',
  0x227: 'a\u0307',
  0x229: 'e\u0327',
  0x22b: 'o\u0308\u0304',
  0x22d: 'o\u0303\u0304',
  0x22f: 'o\u0307',
  0x231: 'o\u0307\u0304',
  0x233: 'y\u0304',
};

String organizationTagComparisonKey(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  final key = StringBuffer();
  for (final rune in cleaned.runes) {
    key.write(
      _latinOrganizationDecomposition[rune] ?? String.fromCharCode(rune),
    );
  }
  return key.toString();
}

List<String> normalizeOrganizationTags(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in values) {
    final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) continue;
    final key = organizationTagComparisonKey(value);
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

  Future<void> setInboxTags(String id, Iterable<String> tags, {
    Cap0160TagEditGuard? scopeGuard,
  }) async {
    if (scopeGuard != null && !scopeGuard.isCurrent) {
      throw const Cap0160ScopeChanged();
    }
    final index = inbox.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    final previous = inbox[index];
    final updated = previous.copyWith(tags: normalizeOrganizationTags(tags));
    inbox[index] = updated;
    void rollbackRejectedTag() {
      // Another Inbox capture may insert at index zero while the serial
      // writer waits. Restore by the exact optimistic object identity, never
      // by the stale index captured before the asynchronous gap.
      final currentIndex = inbox.indexWhere(
        (candidate) => identical(candidate, updated),
      );
      if (currentIndex >= 0) {
        inbox[currentIndex] = previous;
        _notifyInboxChanged();
      }
    }
    try {
      await _persistEntityMutation(
        type: 'inbox',
        id: updated.id,
        payload: updated.toJson(),
        scopeGuard: scopeGuard,
        onScopeRejected: rollbackRejectedTag,
      );
    } catch (_) {
      rollbackRejectedTag();
      rethrow;
    }
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
    Cap0160TagEditGuard? scopeGuard,
  }) async {
    if (scopeGuard != null && !scopeGuard.isCurrent) {
      throw const Cap0160ScopeChanged();
    }
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
    await saveJournal(date, current.copyWith(blocks: blocks),
        scopeGuard: scopeGuard);
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
    Iterable<String> tags, {
    Cap0160TagEditGuard? scopeGuard,
  }) =>
      updateDiaryOrganization(
        date,
        blockId,
        tags: tags,
        scopeGuard: scopeGuard,
      );
}
