part of '../../main.dart';

class PlacesScreen extends StatefulWidget {
  final AgendaStore store;
  final bool startAdding;

  const PlacesScreen({
    super.key,
    required this.store,
    this.startAdding = false,
  });

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    if (widget.startAdding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_editPlace());
      });
    }
  }

  List<PlaceEntry> get _filtered {
    final q = query.trim().toLowerCase();
    final values = [...widget.store.places]
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    if (q.isEmpty) return values;
    return values.where((place) {
      final text = [
        place.name,
        place.category,
        place.address,
        place.note,
      ].join(' ').toLowerCase();
      return q.split(RegExp(r'\s+')).every(text.contains);
    }).toList();
  }

  Future<void> _editPlace([PlaceEntry? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final category = TextEditingController(text: existing?.category ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final note = TextEditingController(text: existing?.note ?? '');

    final result = await showDialog<PlaceEntry>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Nuovo luogo' : 'Modifica luogo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Es. Casa, Rifugio, Bar Centrale',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  hintText: 'Es. Casa, Montagna, Ristorante, Città',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo o zona',
                  hintText: 'Opzionale',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  hintText: 'Perché questo luogo è importante?',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final value = name.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(
                dialogContext,
                PlaceEntry(
                  id: existing?.id ?? const Uuid().v4(),
                  name: value,
                  category: category.text.trim(),
                  address: address.text.trim(),
                  note: note.text.trim(),
                  favorite: existing?.favorite ?? false,
                ),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    name.dispose();
    category.dispose();
    address.dispose();
    note.dispose();

    if (result == null) return;
    await widget.store.savePlace(result);
  }

  Future<void> _deletePlace(PlaceEntry place) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Eliminare “${place.name}”?'),
            content: const Text(
              'Il luogo verrà spostato nel Cestino. I ricordi collegati restano intatti e il collegamento viene conservato finché il luogo è recuperabile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sposta nel Cestino'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await widget.store.movePlaceToTrash(place.id);
  }

  Future<void> _openPlace(PlaceEntry place) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(
          store: widget.store,
          placeId: place.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'I miei luoghi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editPlace,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nuovo luogo'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.store.planningRevision,
          widget.store.journalRevision,
          widget.store.lifecycleRevision,
        ]),
        builder: (context, _) {
          final places = _filtered;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: SearchBar(
                  hintText: 'Cerca luoghi...',
                  leading: const Icon(Icons.search),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              Expanded(
                child: places.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'Salva i luoghi che hanno un significato per te e collegali ai ricordi del diario.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
                        itemCount: places.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          final memories =
                              widget.store.placeMemoryCount(place.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  place.favorite
                                      ? Icons.star
                                      : Icons.place_outlined,
                                ),
                              ),
                              title: Text(
                                place.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (place.category.isNotEmpty)
                                    place.category,
                                  if (place.address.isNotEmpty)
                                    place.address,
                                  '$memories ricordi',
                                ].join(' · '),
                              ),
                              onTap: () => _openPlace(place),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'favorite') {
                                    await widget.store.savePlace(
                                      place.copyWith(
                                        favorite: !place.favorite,
                                      ),
                                    );
                                  } else if (value == 'edit') {
                                    await _editPlace(place);
                                  } else if (value == 'delete') {
                                    await _deletePlace(place);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'favorite',
                                    child: Text(
                                      place.favorite
                                          ? 'Togli dai preferiti'
                                          : 'Aggiungi ai preferiti',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifica'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Elimina'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PlaceDetailScreen extends StatelessWidget {
  final AgendaStore store;
  final String placeId;

  const PlaceDetailScreen({
    super.key,
    required this.store,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        store.planningRevision,
        store.journalRevision,
      ]),
      builder: (context, _) {
        final place = store.placeById(placeId);
        if (place == null) {
          return const Scaffold(
            body: Center(child: Text('Luogo non disponibile.')),
          );
        }
        final memories = store.memoriesForPlace(place.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(place.name),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (place.category.isNotEmpty || place.address.isNotEmpty)
                Text(
                  [place.category, place.address]
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (place.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(place.note),
              ],
              const SizedBox(height: 20),
              Text(
                'Ricordi collegati · ${memories.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (memories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Nessun ricordo collegato. Apri un contenuto del diario e usa “Collega luoghi”.',
                  ),
                ),
              ...memories.map(
                (reference) => Card(
                  child: ListTile(
                    leading: Icon(
                      switch (reference.block.type) {
                        DiaryBlockType.note => Icons.sticky_note_2_outlined,
                        DiaryBlockType.photo => Icons.photo_outlined,
                        DiaryBlockType.sketch => Icons.draw_outlined,
                        DiaryBlockType.voice => Icons.mic_none_outlined,
                      },
                    ),
                    title: Text(store.memoryDisplayTitle(reference.block)),
                    subtitle: Text(
                      DateFormat('d MMMM yyyy', 'it_IT')
                          .format(reference.date),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlannerScreen(
                          store: store,
                          initialDate: reference.date,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
