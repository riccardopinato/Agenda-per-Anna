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
    final byName = <String, String>{};
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
    if (updates.isEmpty) return 0;
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
