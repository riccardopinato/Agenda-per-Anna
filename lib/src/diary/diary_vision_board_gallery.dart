part of '../../main.dart';

/// S11-D: all copy is original. No remote assets or separate gallery database.
String visionBoardGalleryText(AnnaStrings strings, String key) {
  const labels = <String, List<String>>{
    'title': ['My Vision Boards', 'Le mie Vision Board', 'Mis Vision Boards',
      'Mes Vision Boards', 'As minhas Vision Boards'],
    'description': ['Private boards made from your memories and dreams',
      'Collage privati per ricordi e desideri',
      'Collages privados de recuerdos y sueños',
      'Collages privés pour souvenirs et rêves',
      'Colagens privadas de memórias e sonhos'],
    'empty': ['No Vision Boards yet. Create one from your private diary.',
      'Nessuna Vision Board. Creane una dal diario personale.',
      'Todavía no hay Vision Boards. Crea una en tu diario privado.',
      'Aucune Vision Board. Créez-en une dans votre journal privé.',
      'Ainda não há Vision Boards. Crie uma no seu diário privado.'],
    'hidden': ['Personal boards are unavailable in this view.',
      'Le Vision Board private non sono disponibili in questa vista.',
      'Los tableros privados no están disponibles en esta vista.',
      'Les tableaux privés sont indisponibles dans cette vue.',
      'Os quadros privados não estão disponíveis nesta vista.'],
    'edit': ['Edit board', 'Modifica', 'Editar', 'Modifier', 'Editar'],
    'links': ['Link memories', 'Collega ricordi', 'Vincular recuerdos',
      'Lier des souvenirs', 'Associar memórias'],
    'linked': ['Linked memories', 'Ricordi collegati', 'Recuerdos vinculados',
      'Souvenirs liés', 'Memórias associadas'],
    'trash': ['Move to Trash', 'Sposta nel Cestino', 'Mover a la papelera',
      'Mettre à la corbeille', 'Mover para o lixo'],
    'deleteQuestion': ['Move this Vision Board to Trash?',
      'Spostare questa Vision Board nel Cestino?',
      '¿Mover esta Vision Board a la papelera?',
      'Mettre cette Vision Board à la corbeille ?',
      'Mover esta Vision Board para o lixo?'],
    'deleteDetail': ['You can restore it from the existing Trash.',
      'Potrai ripristinarla dal Cestino esistente.',
      'Podrás restaurarla desde la papelera.',
      'Vous pourrez la restaurer depuis la corbeille.',
      'Pode restaurá-la a partir do lixo.'],
    'saveFailed': ['Could not save. The board may have changed.',
      'Impossibile salvare. La Vision Board potrebbe essere cambiata.',
      'No se pudo guardar. El tablero puede haber cambiado.',
      'Enregistrement impossible. Le tableau a peut-être changé.',
      'Não foi possível guardar. O quadro pode ter sido alterado.'],
  };
  final index = switch (strings.languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
  };
  return labels[key]![index];
}

abstract final class VisionBoardMemories {
  static bool get isSourceSupported => true;

  static DiaryBlockReference? current(
    AgendaStore store,
    DiaryBlockReference reference,
  ) {
    if (!store.entryScopeReady ||
        store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return null;
    }
    final journal = store.journal(reference.date);
    for (final block in journal.blocks) {
      if (identical(block, reference.block) &&
          block.id == reference.block.id &&
          block.isPersonalVisionBoard && !block.archived) {
        return DiaryBlockReference(date: reference.date, block: block);
      }
    }
    return null;
  }

  /// Linked IDs resolve from the current canonical private journal. Deleted,
  /// archived or otherwise unavailable blocks are never exposed by a stale UI.
  static List<DiaryBlockReference> linked(
    AgendaStore store, DiaryBlockReference board,
  ) {
    final active = current(store, board);
    if (active == null) return const <DiaryBlockReference>[];
    final wanted = active.block.relatedBlockIds.toSet();
    if (wanted.isEmpty) return const <DiaryBlockReference>[];
    return store.memoryReferences().where((ref) =>
      ref.block.id != active.block.id && wanted.contains(ref.block.id),
    ).take(12).toList(growable: false);
  }

  /// Independent of the generic connections setter, which has no scope-epoch
  /// guard. The same canonical journal writer is used, not a new store.
  static Future<bool> saveLinks(
    AgendaStore store,
    DiaryBlockReference board,
    Iterable<String> ids, {
    required Cap0160TagEditGuard scopeGuard,
  }) async {
    if (!scopeGuard.isCurrent || current(store, board) == null) return false;
    final valid = store.memoryReferences()
        .map((ref) => ref.block.id).toSet()
      ..remove(board.block.id);
    final normalized = <String>[];
    for (final raw in ids) {
      final id = raw.trim();
      if (id.isEmpty || !valid.contains(id) || normalized.contains(id)) {
        continue;
      }
      normalized.add(id);
      if (normalized.length >= 12) break;
    }
    if (!scopeGuard.isCurrent) return false;
    final existing = store.journal(board.date);
    final index = existing.blocks.indexWhere(
      (block) => identical(block, board.block),
    );
    if (index < 0) return false;
    final updated = [...existing.blocks];
    updated[index] = board.block.copyWith(relatedBlockIds: normalized);
    try {
      await store.saveJournal(board.date,
        existing.copyWith(blocks: updated), scopeGuard: scopeGuard);
      return scopeGuard.isCurrent;
    } on Cap0160ScopeChanged {
      return false;
    }
  }

  /// Reuse canonical Trash. Caller must check scope again after confirmation.
  /// No deleting media directly: Trash references must keep them recoverable.
  static Future<bool> moveToTrash(
    AgendaStore store, DiaryBlockReference board, {
    required Cap0160TagEditGuard scopeGuard,
  }) async {
    if (!scopeGuard.isCurrent || current(store, board) == null) return false;
    return store.moveDiaryBlockToTrash(board.date, board.block.id);
  }
}

class VisionBoardGalleryScreen extends StatefulWidget {
  const VisionBoardGalleryScreen({super.key, required this.store});
  final AgendaStore store;

  @override
  State<VisionBoardGalleryScreen> createState() =>
      _VisionBoardGalleryScreenState();
}

class _VisionBoardGalleryScreenState extends State<VisionBoardGalleryScreen> {
  bool _busy = false;

  void _notice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(visionBoardGalleryText(
        AnnaStrings.of(context), 'saveFailed')),
    ));
  }

  Future<void> _edit(DiaryBlockReference ref) async {
    if (_busy) return;
    final guard = Cap0160TagEditGuard(widget.store);
    if (!guard.isCurrent || VisionBoardMemories.current(widget.store, ref) == null) {
      return;
    }
    await Navigator.push<List<DiarySketchPage>>(
      context, MaterialPageRoute(
        builder: (_) => DiarySketchbookScreen(
          initialPages: ref.block.pages,
          visionBoardMode: true,
          onSavePages: (pages) => saveExistingPrivateVisionBoard(
            widget.store, ref.date, ref.block, pages, scopeGuard: guard,
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _links(DiaryBlockReference ref) async {
    if (_busy) return;
    final guard = Cap0160TagEditGuard(widget.store);
    if (!guard.isCurrent || VisionBoardMemories.current(widget.store, ref) == null) {
      return;
    }
    final selected = await showDiaryConnectionsPicker(
      context, widget.store, source: ref.block,
    );
    if (selected == null || !mounted) return;
    setState(() => _busy = true);
    final ok = await VisionBoardMemories.saveLinks(
      widget.store, ref, selected, scopeGuard: guard,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _notice();
  }

  Future<void> _trash(DiaryBlockReference ref) async {
    if (_busy) return;
    final guard = Cap0160TagEditGuard(widget.store);
    if (!guard.isCurrent || VisionBoardMemories.current(widget.store, ref) == null) {
      return;
    }
    final strings = AnnaStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(visionBoardGalleryText(strings, 'deleteQuestion')),
        content: Text(visionBoardGalleryText(strings, 'deleteDetail')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(visionBoardGalleryText(strings, 'trash')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await VisionBoardMemories.moveToTrash(
      widget.store, ref, scopeGuard: guard,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _notice();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(visionBoardGalleryText(strings, 'title')),
      ),
      body: AnimatedBuilder(
        animation: widget.store.journalRevision,
        builder: (context, _) {
          if (!widget.store.entryScopeReady ||
              widget.store.agendaContentFilter ==
                  AgendaContentFilter.sharedOnly) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(visionBoardGalleryText(strings, 'hidden')),
            ));
          }
          final boards = VisionBoardFoundation.personalBoards(widget.store);
          if (boards.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(visionBoardGalleryText(strings, 'empty'),
                textAlign: TextAlign.center),
            ));
          }
          return ListView.builder(
            key: const ValueKey('vision-board-gallery-list'),
            padding: const EdgeInsets.all(16),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final ref = boards[index];
              final linked = VisionBoardMemories.linked(widget.store, ref);
              final title = widget.store.diaryBlockDisplayTitle(
                ref.block, strings: strings);
              return Card(
                key: ValueKey('vision-board-${ref.block.id}'),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Semantics(
                        button: true,
                        label: title,
                        child: InkWell(
                          onTap: _busy ? null : () => _edit(ref),
                          child: DiarySketchPagePreview(
                            page: ref.block.pages.isEmpty
                                ? DiarySketchPage(id: ref.block.id)
                                : ref.block.pages.first,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(title, maxLines: 2),
                      subtitle: Text(DateFormat('d MMM yyyy',
                        AnnaStrings.intlLocale(context)).format(ref.date)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _edit(ref),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(visionBoardGalleryText(strings, 'edit')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _links(ref),
                            icon: const Icon(Icons.link_outlined),
                            label: Text(visionBoardGalleryText(strings, 'links')),
                          ),
                          TextButton.icon(
                            onPressed: _busy ? null : () => _trash(ref),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(visionBoardGalleryText(strings, 'trash')),
                          ),
                        ],
                      ),
                    ),
                    if (linked.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          visionBoardGalleryText(strings, 'linked'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      ...linked.map((memory) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.auto_stories_outlined),
                        title: Text(widget.store.diaryBlockDisplayTitle(
                          memory.block, strings: strings)),
                        onTap: _busy ? null : () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlannerScreen(
                              store: widget.store, initialDate: memory.date,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
