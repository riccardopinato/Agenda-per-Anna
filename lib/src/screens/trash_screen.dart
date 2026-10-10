part of '../../main.dart';

class TrashScreen extends StatelessWidget {
  final AgendaStore store;

  const TrashScreen({
    super.key,
    required this.store,
  });

  String _displayTitle(BuildContext context, TrashEntry entry) {
    final strings = AnnaStrings.of(context);
    final locale = AnnaStrings.intlLocale(context);

    switch (entry.kind) {
      case TrashEntityKind.diaryBlock:
        try {
          final block = DiaryBlock.fromJson(entry.payload);
          if (block.text.trim().isNotEmpty) return block.text.trim();
          return switch (block.type) {
            DiaryBlockType.note => strings.d3('trashDiaryNote'),
            DiaryBlockType.photo => strings.d3('trashDiaryPhoto'),
            DiaryBlockType.sketch => strings.d3('trashDiarySketch'),
            DiaryBlockType.voice => strings.d3('trashDiaryVoice'),
          };
        } catch (_) {
          break;
        }
      case TrashEntityKind.journal:
        final date = DateTime.tryParse(entry.entityId);
        if (date != null) {
          return strings.d3Format(
            'trashJournalTitle',
            {'date': DateFormat('d MMMM yyyy', locale).format(date)},
          );
        }
      case TrashEntityKind.month:
        final parts = entry.entityId.split('-');
        if (parts.length >= 2) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          if (year != null && month != null) {
            return _cap(DateFormat('MMMM yyyy', locale).format(DateTime(year, month)));
          }
        }
      case TrashEntityKind.week:
        final date = DateTime.tryParse(entry.entityId);
        if (date != null) {
          return strings.d3Format(
            'trashWeekTitle',
            {'date': DateFormat('d MMMM yyyy', locale).format(date)},
          );
        }
      default:
        break;
    }

    final title = entry.title.trim();
    if (title.isEmpty || title == 'Elemento eliminato') {
      return strings.trashKindLabel(entry.kind);
    }
    return title;
  }

  Future<void> _restore(BuildContext context, TrashEntry entry) async {
    final strings = AnnaStrings.of(context);
    final conflict = store.trashRestoreConflictReason(entry);
    if (conflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.trashConflict(conflict))),
      );
      return;
    }

    final displayTitle = _displayTitle(context, entry);
    final restored = await store.restoreTrashEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? strings.restoredFromTrash(displayTitle)
              : strings.restoreFailedTrash(displayTitle),
        ),
      ),
    );
  }

  Future<void> _purge(BuildContext context, TrashEntry entry) async {
    final strings = AnnaStrings.of(context);
    final displayTitle = _displayTitle(context, entry);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.deletePermanentlyQuestion),
            content: Text(
              strings.purgeTrashDescription(displayTitle),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.deletePermanently),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await store.purgeTrashEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.itemDeletedPermanently)),
    );
  }

  Future<void> _empty(BuildContext context) async {
    final strings = AnnaStrings.of(context);
    final count = store.trash.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.emptyTrashQuestion),
            content: Text(
              strings.emptyTrashDescription(count),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.emptyTrash),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final removed = await store.emptyTrash();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.removedFromTrash(removed))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.lifecycleRevision,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final entries = [...store.trash]
          ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.trash,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (entries.isNotEmpty)
                TextButton(
                  onPressed: () => _empty(context),
                  child: Text(strings.emptyTrash),
                ),
            ],
          ),
          body: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline, size: 52),
                        const SizedBox(height: 12),
                        Text(
                          strings.trashEmpty,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.trashEmptyDescription,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(entry.kind.icon)),
                        title: Text(
                          _displayTitle(context, entry),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          strings.trashEntrySubtitle(
                            strings.trashKindLabel(entry.kind),
                            DateFormat('d MMM yyyy, HH:mm', AnnaStrings.intlLocale(context)).format(entry.deletedAt),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: strings.trashActions,
                          onSelected: (value) {
                            if (value == 'restore') {
                              _restore(context, entry);
                            } else if (value == 'purge') {
                              _purge(context, entry);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'restore',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.restore),
                                title: Text(strings.restore),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'purge',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.delete_forever_outlined),
                                title: Text(strings.deletePermanently),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
