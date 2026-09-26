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
