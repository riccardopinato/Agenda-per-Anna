part of '../../main.dart';

Future<List<String>?> showPeoplePicker(
  BuildContext context,
  AgendaStore store, {
  Iterable<String> initialIds = const [],
}) async {
  if (store.people.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nessuna persona salvata'),
        content: const Text(
          'Aggiungi prima una persona da “Persone importanti”, poi potrai collegarla ai ricordi.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return null;
  }

  final selected = initialIds.where(
    (id) => store.people.any((person) => person.id == id),
  ).toSet();
  final searchController = TextEditingController();

  final result = await showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final query = searchController.text.trim().toLowerCase();
        final candidates = [...store.people]
          ..sort((a, b) {
            if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
        final visible = candidates.where((person) {
          if (query.isEmpty) return true;
          return [
            person.name,
            person.relationship,
            person.note,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

        return AlertDialog(
          title: const Text('Persone nel ricordo'),
          content: SizedBox(
            width: 430,
            height: 390,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Cerca una persona...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text('Nessuna persona trovata.'))
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final person = visible[index];
                            return CheckboxListTile(
                              value: selected.contains(person.id),
                              title: Text(person.name),
                              subtitle: person.relationship.trim().isEmpty
                                  ? null
                                  : Text(person.relationship),
                              secondary: Icon(
                                person.favorite
                                    ? Icons.star
                                    : Icons.person_outline,
                              ),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selected.add(person.id);
                                  } else {
                                    selected.remove(person.id);
                                  }
                                });
                              },
                            );
                          },
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
              onPressed: () =>
                  Navigator.pop(dialogContext, selected.toList()),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    ),
  );

  searchController.dispose();
  return result;
}

class PeopleScreen extends StatefulWidget {
  final AgendaStore store;
  final bool startAdding;

  const PeopleScreen({
    super.key,
    required this.store,
    this.startAdding = false,
  });

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.startAdding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _edit();
      });
    }
  }

  Future<void> _edit([PersonEntry? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final relationshipController =
        TextEditingController(text: existing?.relationship ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    String? birthdayId = existing?.birthdayId;
    var favorite = existing?.favorite ?? false;
    final birthdays = [...widget.store.birthdays]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final result = await showDialog<PersonEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nuova persona' : 'Modifica persona'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: existing == null,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: relationshipController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Relazione',
                      hintText: 'Es. amica, sorella, collega...',
                      prefixIcon: Icon(Icons.favorite_border),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: birthdayId,
                    decoration: const InputDecoration(
                      labelText: 'Compleanno collegato',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Nessun compleanno'),
                      ),
                      ...birthdays.map(
                        (birthday) => DropdownMenuItem<String>(
                          value: birthday.id,
                          child: Text(
                            '${birthday.name} · '
                            '${DateFormat('d MMMM', 'it_IT').format(DateTime(2000, birthday.month, birthday.day))}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(
                        () => birthdayId =
                            value == null || value.isEmpty ? null : value,
                      );
                    },
                  ),
                  if (birthdays.isEmpty) ...[
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Puoi aggiungere i compleanni dalla schermata dedicata.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nota personale',
                      hintText: 'Dettagli che vuoi ricordare...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: favorite,
                    title: const Text('Persona importante'),
                    subtitle: const Text(
                      'Mostrala per prima nell’elenco.',
                    ),
                    secondary: const Icon(Icons.star_outline),
                    onChanged: (value) =>
                        setDialogState(() => favorite = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  PersonEntry(
                    id: existing?.id ?? const Uuid().v4(),
                    name: name,
                    relationship: relationshipController.text.trim(),
                    note: noteController.text.trim(),
                    birthdayId: birthdayId,
                    favorite: favorite,
                  ),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    relationshipController.dispose();
    noteController.dispose();

    if (result == null) return;
    await widget.store.savePerson(result);
  }

  Future<void> _delete(PersonEntry person) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Spostare nel Cestino?'),
            content: Text(
              '${person.name} verrà rimossa dall’elenco, ma i collegamenti ai ricordi resteranno pronti per un eventuale ripristino.',
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
    await widget.store.movePersonToTrash(person.id);
  }

  Future<void> _openMemories(PersonEntry person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryMemoriesScreen(
          store: widget.store,
          personId: person.id,
          personName: person.name,
        ),
      ),
    );
  }

  Widget _personCard(PersonEntry person) {
    final birthday = widget.store.birthdayForPerson(person);
    final memoryCount = widget.store.personMemoryCount(person.id);
    final lastMemory = widget.store.lastMemoryDateForPerson(person.id);

    final details = <String>[
      if (person.relationship.trim().isNotEmpty) person.relationship.trim(),
      if (birthday != null)
        'Compleanno: ${DateFormat('d MMMM', 'it_IT').format(DateTime(2000, birthday.month, birthday.day))}',
      '$memoryCount ${memoryCount == 1 ? 'ricordo' : 'ricordi'} collegati',
      if (lastMemory != null)
        'Ultimo: ${DateFormat('d MMM yyyy', 'it_IT').format(lastMemory)}',
    ];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(person.favorite ? Icons.star : Icons.person_outline),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.join(' · ')),
            if (person.note.trim().isNotEmpty)
              Text(
                person.note.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: person.note.trim().isNotEmpty,
        onTap: () => _edit(person),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'memories') _openMemories(person);
            if (value == 'edit') _edit(person);
            if (value == 'delete') _delete(person);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'memories',
              child: Text('Vedi ricordi collegati'),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text('Modifica'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Sposta nel Cestino'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Persone importanti',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Compleanni',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BirthdaysScreen(store: widget.store),
              ),
            ),
            icon: const Icon(Icons.cake_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Persona'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.store.planningRevision,
          widget.store.journalRevision,
        ]),
        builder: (context, _) {
          final people = [...widget.store.people]
            ..sort((a, b) {
              if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

          if (people.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 52),
                      const SizedBox(height: 14),
                      const Text(
                        'Le persone che contano',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Salva solo nome, relazione, una nota e l’eventuale compleanno. Poi collega queste persone ai ricordi del diario.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Aggiungi persona'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _personCard(people[index]),
          );
        },
      ),
    );
  }
}
