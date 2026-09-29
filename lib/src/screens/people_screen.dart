part of '../../main.dart';

Future<List<String>?> showPeoplePicker(
  BuildContext context,
  AgendaStore store, {
  Iterable<String> initialIds = const [],
}) async {
  final strings = AnnaStrings.of(context);
  if (store.people.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.noPeopleSaved),
        content: Text(strings.addPersonBeforeLink),
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

  final selected = initialIds.toSet();
  final recoverable = initialIds
      .map(store.trashedPersonById)
      .whereType<PersonEntry>()
      .toList();
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
          title: Text(strings.peopleInMemory),
          content: SizedBox(
            width: 430,
            height: 390,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: strings.searchPersonHint,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: visible.isEmpty && recoverable.isEmpty
                      ? Center(child: Text(strings.noPersonFound))
                      : ListView(
                          children: [
                            for (final person in recoverable)
                              CheckboxListTile(
                                value: selected.contains(person.id),
                                title: Text(person.name),
                                subtitle: Text(strings.recoverableTrashLink),
                                secondary:
                                    const Icon(Icons.restore_from_trash_outlined),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selected.add(person.id);
                                    } else {
                                      selected.remove(person.id);
                                    }
                                  });
                                },
                              ),
                            for (final person in visible)
                              CheckboxListTile(
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
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, selected.toList()),
              child: Text(strings.save),
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
    final strings = AnnaStrings.of(context);
    final nameController = TextEditingController(text: existing?.name ?? '');
    final relationshipController =
        TextEditingController(text: existing?.relationship ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    String? birthdayId = existing?.birthdayId;
    DateTime? anniversaryDate = existing?.anniversaryDate;
    var favorite = existing?.favorite ?? false;
    final birthdays = [...widget.store.birthdays]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final liveBirthdayIds = birthdays.map((birthday) => birthday.id).toSet();
    final recoverableBirthday = birthdayId == null ||
            liveBirthdayIds.contains(birthdayId)
        ? null
        : widget.store.trashedBirthdayById(birthdayId);
    final unavailableBirthdayId = birthdayId != null &&
            !liveBirthdayIds.contains(birthdayId) &&
            recoverableBirthday == null
        ? birthdayId
        : null;

    final result = await showDialog<PersonEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? strings.newPerson : strings.editPerson),
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
                    decoration: InputDecoration(
                      labelText: '${strings.name} *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: relationshipController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: strings.relationship,
                      hintText: strings.relationshipHint,
                      prefixIcon: Icon(Icons.favorite_border),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: birthdayId,
                    decoration: InputDecoration(
                      labelText: strings.linkedBirthday,
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(strings.noBirthday),
                      ),
                      if (recoverableBirthday != null)
                        DropdownMenuItem<String>(
                          value: recoverableBirthday.id,
                          child: Text(
                            '${recoverableBirthday.name} · nel Cestino',
                          ),
                        ),
                      if (unavailableBirthdayId != null)
                        DropdownMenuItem<String>(
                          value: unavailableBirthdayId,
                          child: Text(strings.birthdayUnavailable),
                        ),
                      ...birthdays.map(
                        (birthday) => DropdownMenuItem<String>(
                          value: birthday.id,
                          child: Text(
                            '${birthday.name} · '
                            '${DateFormat('d MMMM', AnnaStrings.intlLocale(context)).format(DateTime(2000, birthday.month, birthday.day))}',
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.addBirthdaysFromDedicatedScreen,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite_outline),
                    title: Text(strings.anniversaryImportantDate),
                    subtitle: Text(
                      anniversaryDate == null
                          ? strings.noDate
                          : DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context))
                              .format(anniversaryDate!),
                    ),
                    trailing: anniversaryDate == null
                        ? null
                        : IconButton(
                            tooltip: strings.removeDate,
                            onPressed: () =>
                                setDialogState(() => anniversaryDate = null),
                            icon: const Icon(Icons.close),
                          ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: anniversaryDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => anniversaryDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: strings.personalNote,
                      hintText: strings.personalNoteHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: favorite,
                    title: Text(strings.importantPerson),
                    subtitle: Text(strings.showFirstInList),
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
              child: Text(strings.cancel),
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
                    anniversaryDate: anniversaryDate,
                    favorite: favorite,
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
    relationshipController.dispose();
    noteController.dispose();

    if (result == null) return;
    await widget.store.savePerson(result);
  }

  Future<void> _delete(PersonEntry person) async {
    final strings = AnnaStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.moveToTrashQuestion),
            content: Text(
              strings.personTrashDescription(person.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.moveToTrash),
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


  Future<void> _openRelationshipOverview(PersonEntry person) async {
    final strings = AnnaStrings.of(context);
    final snapshot = widget.store.relationshipSnapshot(person);
    final anniversary = person.anniversaryDate;
    final firstMemory = snapshot.firstMemoryDate;
    final lastMemory = snapshot.lastMemoryDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Icon(
                        person.favorite ? Icons.star : Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          if (person.relationship.trim().isNotEmpty)
                            Text(person.relationship.trim()),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: Text(
                        strings.memoriesCount(snapshot.memoryCount),
                      ),
                    ),
                    if (snapshot.birthday != null)
                      Chip(
                        avatar: const Icon(Icons.cake_outlined, size: 18),
                        label: Text(
                          DateFormat('d MMMM', AnnaStrings.intlLocale(context)).format(
                            DateTime(
                              2000,
                              snapshot.birthday!.month,
                              snapshot.birthday!.day,
                            ),
                          ),
                        ),
                      ),
                    if (anniversary != null)
                      Chip(
                        avatar:
                            const Icon(Icons.favorite_outline, size: 18),
                        label: Text(
                          strings.sinceDate(DateFormat('d MMM yyyy', AnnaStrings.intlLocale(context)).format(anniversary)),
                        ),
                      ),
                  ],
                ),
                if (snapshot.nextAnniversary != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat_outlined),
                    title: Text(strings.nextAnniversary),
                    subtitle: Text(
                      DateFormat('EEEE d MMMM yyyy', AnnaStrings.intlLocale(context))
                          .format(snapshot.nextAnniversary!),
                    ),
                  ),
                ],
                if (firstMemory != null || lastMemory != null) ...[
                  const Divider(height: 28),
                  Text(
                    strings.yourTimeline,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (firstMemory != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.first_page_outlined),
                      title: Text(strings.firstLinkedMemory),
                      subtitle: Text(
                        DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(firstMemory),
                      ),
                    ),
                  if (lastMemory != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_outlined),
                      title: Text(strings.latestMemory),
                      subtitle: Text(
                        DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(lastMemory),
                      ),
                    ),
                ],
                if (snapshot.onThisDay.isNotEmpty) ...[
                  const Divider(height: 28),
                  Text(
                    strings.onThisDay,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...snapshot.onThisDay.take(3).map(
                        (memory) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history_toggle_off),
                          title: Text(
                            memory.block.text.trim().isEmpty
                                ? strings.diaryMemory
                                : memory.block.text.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context))
                                .format(memory.date),
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _edit(person);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(strings.edit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openMemories(person);
                        },
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: Text(strings.memories),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _personCard(PersonEntry person) {
    final strings = AnnaStrings.of(context);
    final birthday = widget.store.birthdayForPerson(person);
    final memoryCount = widget.store.personMemoryCount(person.id);
    final lastMemory = widget.store.lastMemoryDateForPerson(person.id);
    final anniversary = person.anniversaryDate;

    final details = <String>[
      if (person.relationship.trim().isNotEmpty) person.relationship.trim(),
      if (birthday != null)
        strings.birthdayDetail(DateFormat('d MMMM', AnnaStrings.intlLocale(context)).format(DateTime(2000, birthday.month, birthday.day))),
      if (anniversary != null)
        strings.anniversaryDetail(DateFormat('d MMMM', AnnaStrings.intlLocale(context)).format(anniversary)),
      strings.linkedMemoriesCount(memoryCount),
      if (lastMemory != null)
        strings.lastMemoryDetail(DateFormat('d MMM yyyy', AnnaStrings.intlLocale(context)).format(lastMemory)),
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
        onTap: () => _openRelationshipOverview(person),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'memories') _openMemories(person);
            if (value == 'edit') _edit(person);
            if (value == 'delete') _delete(person);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'memories',
              child: Text(strings.seeLinkedMemories),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text(strings.edit),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(strings.moveToTrash),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.importantPeople,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: strings.birthdays,
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
        label: Text(strings.person),
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
                      Text(
                        strings.peopleThatMatter,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.importantPeopleDescription,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(strings.addPerson),
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
