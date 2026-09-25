part of '../../main.dart';

class TrashScreen extends StatelessWidget {
  final AgendaStore store;

  const TrashScreen({
    super.key,
    required this.store,
  });

  Future<void> _restore(BuildContext context, TrashEntry entry) async {
    final conflict = store.trashRestoreConflictReason(entry);
    if (conflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(conflict)),
      );
      return;
    }

    final restored = await store.restoreTrashEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? '“${entry.title}” ripristinato.'
              : 'Impossibile ripristinare “${entry.title}”. Il contenuto è rimasto nel Cestino.',
        ),
      ),
    );
  }

  Future<void> _purge(BuildContext context, TrashEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare definitivamente?'),
            content: Text(
              '“${entry.title}” verrà rimosso dal Cestino. '
              'Prima dell’operazione verrà creato un punto di ripristino locale.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina definitivamente'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await store.purgeTrashEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Elemento eliminato definitivamente.')),
    );
  }

  Future<void> _empty(BuildContext context) async {
    final count = store.trash.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Svuotare il Cestino?'),
            content: Text(
              '$count elementi verranno eliminati definitivamente. '
              'Anna’s Diary creerà prima un punto di ripristino locale.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Svuota'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final removed = await store.emptyTrash();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$removed elementi rimossi dal Cestino.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.lifecycleRevision,
      builder: (context, _) {
        final entries = [...store.trash]
          ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Cestino',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (entries.isNotEmpty)
                TextButton(
                  onPressed: () => _empty(context),
                  child: const Text('Svuota'),
                ),
            ],
          ),
          body: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 52),
                        SizedBox(height: 12),
                        Text(
                          'Il Cestino è vuoto.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Gli elementi eliminati in modo reversibile compariranno qui.',
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
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${entry.kind.label} · eliminato '
                          '${DateFormat('d MMM yyyy, HH:mm', 'it_IT').format(entry.deletedAt)}',
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Azioni Cestino',
                          onSelected: (value) {
                            if (value == 'restore') {
                              _restore(context, entry);
                            } else if (value == 'purge') {
                              _purge(context, entry);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'restore',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.restore),
                                title: Text('Ripristina'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'purge',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_forever_outlined),
                                title: Text('Elimina definitivamente'),
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
