part of '../../main.dart';

class BirthdaysScreen extends StatelessWidget {
  final AgendaStore store;

  const BirthdaysScreen({
    super.key,
    required this.store,
  });

  Future<void> _edit(
    BuildContext context, {
    BirthdayEntry? existing,
  }) async {
    final strings = AnnaStrings.of(context);
    final name = TextEditingController(text: existing?.name ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    final now = DateTime.now();
    var selectedDate = DateTime(
      existing?.year ?? 2000,
      existing?.month ?? now.month,
      existing?.day ?? now.day,
    );
    var keepYear = existing?.year != null;
    int? reminderDays = existing?.reminderDaysBefore ?? 1;

    final saved = await showDialog<BirthdayEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? strings.newBirthday : strings.editBirthday),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: strings.name,
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(strings.date),
                    subtitle: Text(
                      keepYear
                          ? DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(selectedDate)
                          : DateFormat('d MMMM', AnnaStrings.intlLocale(context)).format(selectedDate),
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(now.year + 1),
                        helpText: strings.birthDate,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: keepYear,
                    title: Text(strings.rememberYear),
                    subtitle: Text(strings.yearOnlyForAge),
                    onChanged: (value) => setDialogState(() => keepYear = value),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int?>(
                    initialValue: reminderDays,
                    decoration: InputDecoration(
                      labelText: strings.reminder,
                      prefixIcon: Icon(Icons.notifications_none),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(strings.noReminder),
                      ),
                      DropdownMenuItem<int?>(
                        value: 0,
                        child: Text(strings.reminderSameDayTime),
                      ),
                      DropdownMenuItem<int?>(
                        value: 1,
                        child: Text(strings.reminderDaysBeforeTime(1)),
                      ),
                      DropdownMenuItem<int?>(
                        value: 3,
                        child: Text(strings.reminderDaysBeforeTime(3)),
                      ),
                      DropdownMenuItem<int?>(
                        value: 7,
                        child: Text(strings.reminderDaysBeforeTime(7)),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => reminderDays = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: strings.optionalNote,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
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
                final value = name.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  BirthdayEntry(
                    id: existing?.id ?? const Uuid().v4(),
                    name: value,
                    day: selectedDate.day,
                    month: selectedDate.month,
                    year: keepYear ? selectedDate.year : null,
                    note: note.text.trim(),
                    reminderDaysBefore: reminderDays,
                  ),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    note.dispose();
    if (saved == null) return;
    await store.saveBirthday(saved);
  }

  Future<void> _delete(
    BuildContext context,
    BirthdayEntry birthday,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Spostare nel Cestino?'),
            content: Text(
              'Il compleanno di “${birthday.name}” potrà essere ripristinato dal Cestino.',
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
    await store.moveBirthdayToTrash(birthday.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.planningRevision,
      builder: (context, _) {
        final upcoming = store.upcomingBirthdays(limit: 100);
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Compleanni',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi'),
          ),
          body: upcoming.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cake_outlined, size: 54),
                        const SizedBox(height: 12),
                        Text(
                          'Nessun compleanno salvato',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Aggiungili una volta: compariranno ogni anno nella giornata giusta e nei promemoria.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final occurrence = upcoming[index];
                    final birthday = occurrence.birthday;
                    final age = occurrence.age == null
                        ? ''
                        : ' · ${occurrence.age} anni';
                    final reminder = birthday.reminderDaysBefore == null
                        ? 'Promemoria disattivato'
                        : birthday.reminderDaysBefore == 0
                            ? 'Promemoria il giorno stesso'
                            : 'Promemoria ${birthday.reminderDaysBefore} gg prima';
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.cake_outlined),
                        ),
                        title: Text(
                          birthday.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${DateFormat('d MMMM yyyy', 'it_IT').format(occurrence.date)}$age\n$reminder',
                        ),
                        isThreeLine: true,
                        onTap: () => _edit(context, existing: birthday),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _edit(context, existing: birthday);
                            } else if (value == 'delete') {
                              _delete(context, birthday);
                            }
                          },
                          itemBuilder: (_) => const [
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
                  },
                ),
        );
      },
    );
  }
}
