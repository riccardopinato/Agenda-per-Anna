part of '../../main.dart';

class _TemplateDraft {
  final String name;
  final PersonalTemplateKind kind;
  final DateTime sourceDate;

  const _TemplateDraft({
    required this.name,
    required this.kind,
    required this.sourceDate,
  });
}

class TemplatesScreen extends StatefulWidget {
  final AgendaStore store;
  final bool startAdding;

  const TemplatesScreen({
    super.key,
    required this.store,
    this.startAdding = false,
  });

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.startAdding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _createTemplate();
      });
    }
  }

  Future<void> _createTemplate() async {
    final nameController = TextEditingController();
    var kind = PersonalTemplateKind.day;
    var sourceDate = DateTime.now();

    final draft = await showDialog<_TemplateDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          String sourceLabel() => switch (kind) {
                PersonalTemplateKind.day => DateFormat(
                    'EEEE d MMMM yyyy',
                    'it_IT',
                  ).format(sourceDate),
                PersonalTemplateKind.week =>
                  'Settimana del ' +
                      DateFormat(
                        'd MMMM yyyy',
                        'it_IT',
                      ).format(mondayOf(sourceDate)),
                PersonalTemplateKind.month =>
                  DateFormat('MMMM yyyy', 'it_IT').format(sourceDate),
              };

          return AlertDialog(
            title: const Text('Nuovo modello personale'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        hintText: 'Es. Giornata lavoro, Settimana leggera...',
                        prefixIcon: Icon(Icons.copy_all_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PersonalTemplateKind>(
                      initialValue: kind,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      items: PersonalTemplateKind.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => kind = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Prendi come base'),
                      subtitle: Text(sourceLabel()),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: sourceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          locale: const Locale('it', 'IT'),
                        );
                        if (picked != null) {
                          setDialogState(() => sourceDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        switch (kind) {
                          PersonalTemplateKind.day =>
                            'Salva gli impegni e i task privati della giornata. Diario, mood e ricordi non vengono copiati.',
                          PersonalTemplateKind.week =>
                            'Salva focus e priorità della settimana. Ricordi e consuntivo restano esclusi.',
                          PersonalTemplateKind.month =>
                            'Salva la pianificazione iniziale del mese. Spese, momenti e riflessioni finali restano esclusi.',
                        },
                        style: Theme.of(context).textTheme.bodySmall,
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
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    dialogContext,
                    _TemplateDraft(
                      name: name,
                      kind: kind,
                      sourceDate: sourceDate,
                    ),
                  );
                },
                child: const Text('Crea modello'),
              ),
            ],
          );
        },
      ),
    );
    nameController.dispose();
    if (draft == null || !mounted) return;

    if (draft.kind == PersonalTemplateKind.day) {
      final count = widget.store.items
          .where(
            (item) => AgendaStore.sameDay(item.date, draft.sourceDate),
          )
          .length;
      if (count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'In quella giornata non ci sono impegni o task privati da salvare.',
            ),
          ),
        );
        return;
      }
    }

    switch (draft.kind) {
      case PersonalTemplateKind.day:
        await widget.store.createDayTemplate(draft.name, draft.sourceDate);
        break;
      case PersonalTemplateKind.week:
        await widget.store.createWeekTemplate(draft.name, draft.sourceDate);
        break;
      case PersonalTemplateKind.month:
        await widget.store.createMonthTemplate(draft.name, draft.sourceDate);
        break;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modello “' + draft.name + '” salvato.')),
    );
  }

  bool _weekHasPlanning(DateTime date) {
    final value = widget.store.week(date);
    return value.focus.trim().isNotEmpty || value.priorities.isNotEmpty;
  }

  bool _monthHasPlanning(DateTime date) {
    final value = widget.store.month(date.year, date.month);
    return value.intention.trim().isNotEmpty ||
        value.goals.isNotEmpty ||
        value.books.isNotEmpty ||
        value.films.isNotEmpty ||
        value.hobbies.isNotEmpty ||
        value.wishes.isNotEmpty ||
        value.ideas.isNotEmpty ||
        value.monthWord.trim().isNotEmpty ||
        value.selfCare.trim().isNotEmpty ||
        value.budgetCents != 0;
  }

  Future<bool?> _askPlanningMode(
    PersonalTemplate template,
    DateTime target,
  ) async {
    final hasPlanning = switch (template.kind) {
      PersonalTemplateKind.day => false,
      PersonalTemplateKind.week => _weekHasPlanning(target),
      PersonalTemplateKind.month => _monthHasPlanning(target),
    };
    if (!hasPlanning) return false;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ci sono già dati'),
        content: const Text(
          'Puoi riempire solo i campi ancora vuoti oppure sostituire la pianificazione iniziale con il modello. Ricordi e consuntivi non vengono toccati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Solo campi vuoti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sostituisci pianificazione'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyTemplate(PersonalTemplate template) async {
    final now = DateTime.now();
    final target = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('it', 'IT'),
      helpText: switch (template.kind) {
        PersonalTemplateKind.day => 'Giornata di destinazione',
        PersonalTemplateKind.week => 'Settimana di destinazione',
        PersonalTemplateKind.month => 'Mese di destinazione',
      },
    );
    if (target == null || !mounted) return;

    if (template.kind == PersonalTemplateKind.day) {
      final existing = widget.store.items
          .where((item) => AgendaStore.sameDay(item.date, target))
          .length;
      if (existing > 0) {
        final append = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Aggiungere alla giornata?'),
            content: Text(
              'Ci sono già ' +
                  existing.toString() +
                  ' elementi privati. Il modello verrà aggiunto senza cancellarli.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Aggiungi'),
              ),
            ],
          ),
        );
        if (append != true || !mounted) return;
      }
    }

    final overwrite = await _askPlanningMode(template, target);
    if (overwrite == null || !mounted) return;

    final result = await widget.store.applyTemplate(
      template,
      target,
      overwrite: overwrite,
    );
    if (!mounted) return;

    final message = result.changeCount == 0
        ? 'Il modello non aveva nuovi dati da applicare.'
        : template.kind == PersonalTemplateKind.day
            ? 'Aggiunti ' +
                result.createdAgendaItems.toString() +
                ' elementi alla giornata.'
            : 'Pianificazione applicata.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteTemplate(PersonalTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spostare nel Cestino?'),
        content: Text(
          'Il modello “' +
              template.name +
              '” potrà essere ripristinato dal Cestino.',
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
    );
    if (confirmed != true) return;
    await widget.store.moveTemplateToTrash(template.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelli personali'),
        actions: [
          IconButton(
            tooltip: 'Nuovo modello',
            onPressed: _createTemplate,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTemplate,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo modello'),
      ),
      body: AnimatedBuilder(
        animation: widget.store.planningRevision,
        builder: (context, _) {
          final templates = widget.store.sortedTemplates;
          if (templates.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 40),
                Icon(Icons.copy_all_outlined, size: 58),
                SizedBox(height: 16),
                Text(
                  'Nessun modello personale',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Salva una giornata tipo, il focus di una settimana o la pianificazione iniziale di un mese e riutilizzali quando vuoi.',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            child: Icon(template.kind.icon),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  template.kind.label +
                                      ' · ' +
                                      template.summary,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteTemplate(template);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Sposta nel Cestino'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _applyTemplate(template),
                          icon: const Icon(Icons.playlist_add_outlined),
                          label: const Text('Applica modello'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
