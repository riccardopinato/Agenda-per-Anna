part of '../../main.dart';

enum _TrainingView { today, history, plans }

class TrainingScreen extends StatefulWidget {
  final AgendaStore store;

  const TrainingScreen({super.key, required this.store});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  _TrainingView view = _TrainingView.today;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store.trainingRevision,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Allenamento',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editSession(context),
          icon: const Icon(Icons.add),
          label: const Text('Registra'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SegmentedButton<_TrainingView>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _TrainingView.today,
                      icon: Icon(Icons.today_outlined),
                      label: Text('Oggi'),
                    ),
                    ButtonSegment(
                      value: _TrainingView.history,
                      icon: Icon(Icons.history),
                      label: Text('Storico'),
                    ),
                    ButtonSegment(
                      value: _TrainingView.plans,
                      icon: Icon(Icons.assignment_outlined),
                      label: Text('Schede'),
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (value) =>
                      setState(() => view = value.first),
                ),
              ),
              Expanded(
                child: switch (view) {
                  _TrainingView.today => _todayView(),
                  _TrainingView.history => _historyView(),
                  _TrainingView.plans => _plansView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayView() {
    final today = DateTime.now();
    final plans = widget.store.trainingPlansForDay(today);
    final sessions = widget.store.trainingHistory
        .where((session) => AgendaStore.sameDay(session.date, today))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
      children: [
        _TrainingHeroCard(
          plans: plans,
          sessions: sessions,
          onFreeSession: () => _editSession(context),
        ),
        const SizedBox(height: 16),
        if (plans.isNotEmpty) ...[
          const SectionTitle('Schede previste oggi'),
          const SizedBox(height: 8),
          ...plans.map(
            (plan) => _TrainingPlanCard(
              plan: plan,
              onStart: () => _editSession(context, plan: plan),
              onEdit: () => _editPlan(context, existing: plan),
              onDelete: () => _deletePlan(plan),
              onAttachment: plan.attachmentAssetId.isEmpty
                  ? null
                  : () => _previewAttachment(plan),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SectionTitle('Allenamenti di oggi'),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          const SimpleCard(
            child: Text(
              'Nessun allenamento registrato oggi. Puoi registrare corsa, bici, palestra, trekking, nuoto o qualsiasi altra attività.',
            ),
          )
        else
          ...sessions.map(
            (session) => _TrainingSessionCard(
              session: session,
              onOpen: () => _openSession(session),
              onEdit: () => _editSession(context, existing: session),
              onDelete: () => _deleteSession(session),
            ),
          ),
      ],
    );
  }

  Widget _historyView() {
    final sessions = widget.store.trainingHistory;
    if (sessions.isEmpty) {
      return const _TrainingEmpty(
        icon: Icons.history,
        title: 'Storico vuoto',
        text:
            'Ogni allenamento resterà qui consultabile singolarmente, indipendentemente dallo sport.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _TrainingSessionCard(
          session: session,
          onOpen: () => _openSession(session),
          onEdit: () => _editSession(context, existing: session),
          onDelete: () => _deleteSession(session),
        );
      },
    );
  }

  Widget _plansView() {
    final plans = [...widget.store.trainingPlans]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
      children: [
        FilledButton.icon(
          onPressed: () => _editPlan(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuova scheda / piano'),
        ),
        const SizedBox(height: 12),
        const SimpleCard(
          child: Text(
            'Puoi creare una scheda strutturata, allegare il file originale foto/PDF e scegliere i giorni in cui deve comparire. Non è obbligatoria: puoi sempre registrare un allenamento libero.',
          ),
        ),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          const _TrainingEmpty(
            icon: Icons.assignment_outlined,
            title: 'Nessuna scheda',
            text:
                'Le schede sono opzionali. Corsa, bici e altri sport possono essere registrati direttamente nello storico.',
          )
        else
          ...plans.map(
            (plan) => _TrainingPlanCard(
              plan: plan,
              onStart: () => _editSession(context, plan: plan),
              onEdit: () => _editPlan(context, existing: plan),
              onDelete: () => _deletePlan(plan),
              onAttachment: plan.attachmentAssetId.isEmpty
                  ? null
                  : () => _previewAttachment(plan),
            ),
          ),
      ],
    );
  }

  Future<void> _editSession(
    BuildContext context, {
    TrainingSession? existing,
    TrainingPlan? plan,
  }) async {
    final titleController = TextEditingController(
      text: existing?.title ?? plan?.title ?? '',
    );
    final customSportController = TextEditingController(
      text: existing?.customSport ?? plan?.customSport ?? '',
    );
    final distanceController = TextEditingController(
      text: existing?.distanceKm?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: existing?.durationLabel ?? '',
    );
    final elevationController = TextEditingController(
      text: existing?.elevationMeters?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: existing?.note ?? '',
    );
    var sport = existing?.sport ?? plan?.sport ?? TrainingSport.running;
    var date = existing?.date ?? DateTime.now();
    final exercises = <TrainingExercise>[
      ...(existing?.exercises ?? plan?.exercises ?? const <TrainingExercise>[]),
    ];

    final result = await showDialog<TrainingSession>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Registra allenamento' : 'Modifica allenamento'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TrainingSport>(
                    initialValue: sport,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      prefixIcon: Icon(Icons.sports_outlined),
                    ),
                    items: TrainingSport.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setLocal(() => sport = value);
                    },
                  ),
                  if (sport == TrainingSport.other) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customSportController,
                      decoration: const InputDecoration(
                        labelText: 'Nome sport',
                        hintText: 'es. Canottaggio, arrampicata...',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titolo (opzionale)',
                      hintText: 'es. Lungo collinare, Scheda A...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Data'),
                    subtitle: Text(
                      DateFormat('EEEE d MMMM yyyy', 'it_IT').format(date),
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 366)),
                      );
                      if (picked != null) setLocal(() => date = picked);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Distanza km',
                            hintText: '15',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Tempo',
                            hintText: '1:05:20',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: elevationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dislivello m (opzionale)',
                      hintText: 'es. 650',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Sensazioni, percorso, dettagli...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ExerciseEditorList(
                    exercises: exercises,
                    onChanged: () => setLocal(() {}),
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
                final custom = customSportController.text.trim();
                if (sport == TrainingSport.other && custom.isEmpty) return;
                final session = TrainingSession(
                  id: existing?.id ?? const Uuid().v4(),
                  title: titleController.text.trim().isEmpty
                      ? (sport == TrainingSport.other ? custom : sport.label)
                      : titleController.text.trim(),
                  sport: sport,
                  customSport: custom,
                  date: date,
                  durationSeconds:
                      _parseTrainingDuration(durationController.text),
                  distanceKm: _parseTrainingDouble(distanceController.text),
                  elevationMeters:
                      int.tryParse(elevationController.text.trim()),
                  note: noteController.text.trim(),
                  exercises: List.unmodifiable(exercises),
                  planId: existing?.planId ?? plan?.id ?? '',
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                Navigator.pop(dialogContext, session);
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    customSportController.dispose();
    distanceController.dispose();
    durationController.dispose();
    elevationController.dispose();
    noteController.dispose();

    if (result != null) {
      await widget.store.saveTrainingSession(result);
    }
  }

  Future<void> _editPlan(
    BuildContext context, {
    TrainingPlan? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final customSportController =
        TextEditingController(text: existing?.customSport ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    var sport = existing?.sport ?? TrainingSport.gym;
    var active = existing?.active ?? true;
    var startDate = existing?.startDate;
    var endDate = existing?.endDate;
    final weekdays = <int>{...(existing?.weekdays ?? const <int>[])};
    final exercises =
        <TrainingExercise>[...(existing?.exercises ?? const <TrainingExercise>[])];
    var attachmentAssetId = existing?.attachmentAssetId ?? '';
    var attachmentName = existing?.attachmentName ?? '';
    var attachmentMimeType = existing?.attachmentMimeType ?? '';
    var attachmentSizeBytes = existing?.attachmentSizeBytes ?? 0;

    final result = await showDialog<TrainingPlan>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) {
          Future<void> pickAttachment() async {
            final file = await FilePicker.pickFile(
              type: FileType.custom,
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              dialogTitle: 'Carica la scheda originale',
            );
            if (file == null) return;
            final bytes = await file.readAsBytes();
            if (bytes.isEmpty || bytes.lengthInBytes > 15 * 1024 * 1024) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Il file deve essere compreso tra 1 byte e 15 MB.'),
                  ),
                );
              }
              return;
            }
            final id = await MediaAssetStore.instance.put(bytes);
            final name = file.name;
            final lower = name.toLowerCase();
            final mime = lower.endsWith('.pdf')
                ? 'application/pdf'
                : lower.endsWith('.png')
                    ? 'image/png'
                    : lower.endsWith('.webp')
                        ? 'image/webp'
                        : 'image/jpeg';
            setLocal(() {
              attachmentAssetId = id;
              attachmentName = name;
              attachmentMimeType = mime;
              attachmentSizeBytes = bytes.lengthInBytes;
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'Nuova scheda' : 'Modifica scheda'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 540,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Nome scheda / piano',
                        hintText: 'es. Scheda A, Preparazione 10 km...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TrainingSport>(
                      initialValue: sport,
                      decoration: const InputDecoration(labelText: 'Sport'),
                      items: TrainingSport.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setLocal(() => sport = value);
                      },
                    ),
                    if (sport == TrainingSport.other) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customSportController,
                        decoration: const InputDecoration(labelText: 'Nome sport'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Giorni della settimana',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          FilterChip(
                            label: Text(
                              const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][day - 1],
                            ),
                            selected: weekdays.contains(day),
                            onSelected: (selected) => setLocal(() {
                              if (selected) {
                                weekdays.add(day);
                              } else {
                                weekdays.remove(day);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TrainingDateField(
                            label: 'Dal',
                            value: startDate,
                            onChanged: (value) => setLocal(() => startDate = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TrainingDateField(
                            label: 'Al',
                            value: endDate,
                            onChanged: (value) => setLocal(() => endDate = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Scheda attiva'),
                      subtitle: const Text('Compare nei giorni selezionati.'),
                      value: active,
                      onChanged: (value) => setLocal(() => active = value),
                    ),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Indicazioni generali, recuperi, obiettivi...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExerciseEditorList(
                      exercises: exercises,
                      onChanged: () => setLocal(() {}),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(
                          attachmentMimeType == 'application/pdf'
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                        ),
                        title: Text(
                          attachmentName.isEmpty
                              ? 'Carica scheda originale'
                              : attachmentName,
                        ),
                        subtitle: Text(
                          attachmentName.isEmpty
                              ? 'Foto o PDF, massimo 15 MB'
                              : '${(attachmentSizeBytes / 1024).ceil()} KB conservati nell’app',
                        ),
                        onTap: pickAttachment,
                        trailing: attachmentName.isEmpty
                            ? const Icon(Icons.upload_file_outlined)
                            : IconButton(
                                tooltip: 'Rimuovi allegato',
                                onPressed: () => setLocal(() {
                                  attachmentAssetId = '';
                                  attachmentName = '';
                                  attachmentMimeType = '';
                                  attachmentSizeBytes = 0;
                                }),
                                icon: const Icon(Icons.close),
                              ),
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
                  final title = titleController.text.trim();
                  final custom = customSportController.text.trim();
                  if (title.isEmpty ||
                      (sport == TrainingSport.other && custom.isEmpty)) {
                    return;
                  }
                  Navigator.pop(
                    dialogContext,
                    TrainingPlan(
                      id: existing?.id ?? const Uuid().v4(),
                      title: title,
                      sport: sport,
                      customSport: custom,
                      note: noteController.text.trim(),
                      exercises: List.unmodifiable(exercises),
                      weekdays: weekdays.toList()..sort(),
                      startDate: startDate,
                      endDate: endDate,
                      active: active,
                      attachmentAssetId: attachmentAssetId,
                      attachmentName: attachmentName,
                      attachmentMimeType: attachmentMimeType,
                      attachmentSizeBytes: attachmentSizeBytes,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    ),
                  );
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    customSportController.dispose();
    noteController.dispose();

    if (result != null) {
      if (existing != null &&
          existing.attachmentAssetId.isNotEmpty &&
          existing.attachmentAssetId != result.attachmentAssetId) {
        // Old bytes become unreachable and are reclaimed by ordinary media maintenance.
        widget.store._scheduleMediaMaintenance(
          delay: const Duration(seconds: 1),
        );
      }
      await widget.store.saveTrainingPlan(result);
    }
  }

  Future<void> _deletePlan(TrainingPlan plan) async {
    await widget.store.moveTrainingPlanToTrash(plan.id);
  }

  Future<void> _deleteSession(TrainingSession session) async {
    await widget.store.moveTrainingSessionToTrash(session.id);
  }

  Future<void> _previewAttachment(TrainingPlan plan) async {
    final bytes = await MediaAssetStore.instance.read(plan.attachmentAssetId);
    if (!mounted || bytes == null || bytes.isEmpty) return;
    if (plan.attachmentMimeType.startsWith('image/')) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
            child: InteractiveViewer(
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${plan.attachmentName} è conservato nella scheda e incluso in sync/backup. '
          'Il PDF resta disponibile come file originale, mentre la consultazione quotidiana usa i dati della scheda.',
        ),
      ),
    );
  }

  Future<void> _openSession(TrainingSession session) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => _TrainingSessionDetail(session: session),
      );
}

class _TrainingHeroCard extends StatelessWidget {
  final List<TrainingPlan> plans;
  final List<TrainingSession> sessions;
  final VoidCallback onFreeSession;

  const _TrainingHeroCard({
    required this.plans,
    required this.sessions,
    required this.onFreeSession,
  });

  @override
  Widget build(BuildContext context) {
    final text = plans.isEmpty
        ? 'Nessuna scheda prevista oggi'
        : plans.length == 1
            ? 'Oggi: ${plans.first.title}'
            : 'Oggi: ${plans.length} schede previste';
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              child: Icon(Icons.fitness_center_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    sessions.isEmpty
                        ? 'Registra liberamente qualsiasi sport.'
                        : '${sessions.length} allenament${sessions.length == 1 ? 'o' : 'i'} registrat${sessions.length == 1 ? 'o' : 'i'} oggi.',
                  ),
                ],
              ),
            ),
            IconButton.filled(
              tooltip: 'Registra allenamento',
              onPressed: onFreeSession,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingPlanCard extends StatelessWidget {
  final TrainingPlan plan;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAttachment;

  const _TrainingPlanCard({
    required this.plan,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    this.onAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final days = plan.weekdays
        .map((day) => const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][day - 1])
        .join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(plan.sport.icon)),
              title: Text(
                plan.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                [
                  plan.sportLabel,
                  if (days.isNotEmpty) days,
                  if (plan.exercises.isNotEmpty) '${plan.exercises.length} esercizi',
                  if (plan.attachmentName.isNotEmpty) plan.attachmentName,
                  if (!plan.active) 'In pausa',
                ].join(' · '),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifica')),
                  PopupMenuItem(value: 'delete', child: Text('Sposta nel Cestino')),
                ],
              ),
            ),
            if (plan.note.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(plan.note),
                ),
              ),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Registra da scheda'),
                ),
                if (onAttachment != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onAttachment,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Originale'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingSessionCard extends StatelessWidget {
  final TrainingSession session;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TrainingSessionCard({
    required this.session,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(session.sport.icon)),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            DateFormat('d MMM yyyy', 'it_IT').format(session.date),
            session.sportLabel,
            if (session.distanceKm != null)
              '${session.distanceKm!.toStringAsFixed(2)} km',
            if (session.durationLabel.isNotEmpty) session.durationLabel,
          ].join(' · '),
        ),
        onTap: onOpen,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifica')),
            PopupMenuItem(value: 'delete', child: Text('Sposta nel Cestino')),
          ],
        ),
      ),
    );
  }
}

class _TrainingSessionDetail extends StatelessWidget {
  final TrainingSession session;

  const _TrainingSessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    final speed = session.averageSpeedKmh;
    final pace = session.averagePacePerKm;
    final paceText = pace == null
        ? ''
        : '${pace.inMinutes}:${(pace.inSeconds % 60).toString().padLeft(2, '0')} /km';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('EEEE d MMMM yyyy', 'it_IT').format(session.date)} · ${session.sportLabel}',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (session.distanceKm != null)
                  Chip(
                    avatar: const Icon(Icons.straighten, size: 17),
                    label: Text('${session.distanceKm!.toStringAsFixed(2)} km'),
                  ),
                if (session.durationLabel.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 17),
                    label: Text(session.durationLabel),
                  ),
                if (session.elevationMeters != null)
                  Chip(
                    avatar: const Icon(Icons.terrain_outlined, size: 17),
                    label: Text('${session.elevationMeters} m D+'),
                  ),
                if (speed != null)
                  Chip(label: Text('${speed.toStringAsFixed(1)} km/h')),
                if (paceText.isNotEmpty &&
                    (session.sport == TrainingSport.running ||
                        session.sport == TrainingSport.walking ||
                        session.sport == TrainingSport.hiking))
                  Chip(label: Text(paceText)),
              ],
            ),
            if (session.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Note', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(session.note),
            ],
            if (session.exercises.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Esercizi',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              ...session.exercises.map(
                (exercise) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center_outlined),
                  title: Text(exercise.name),
                  subtitle: Text(
                    [
                      if (exercise.sets != null) '${exercise.sets} serie',
                      if (exercise.reps.isNotEmpty) '${exercise.reps} reps',
                      if (exercise.weightKg != null)
                        '${exercise.weightKg!.toStringAsFixed(1)} kg',
                      if (exercise.note.isNotEmpty) exercise.note,
                    ].join(' · '),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseEditorList extends StatelessWidget {
  final List<TrainingExercise> exercises;
  final VoidCallback onChanged;

  const _ExerciseEditorList({
    required this.exercises,
    required this.onChanged,
  });

  Future<void> _add(BuildContext context, [TrainingExercise? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final sets = TextEditingController(text: existing?.sets?.toString() ?? '');
    final reps = TextEditingController(text: existing?.reps ?? '');
    final weight =
        TextEditingController(text: existing?.weightKg?.toString() ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    final value = await showDialog<TrainingExercise>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Aggiungi esercizio' : 'Modifica esercizio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Esercizio'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sets,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Serie'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: reps,
                      decoration: const InputDecoration(labelText: 'Ripetizioni'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Kg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
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
              if (name.text.trim().isEmpty) return;
              Navigator.pop(
                dialogContext,
                TrainingExercise(
                  id: existing?.id ?? const Uuid().v4(),
                  name: name.text.trim(),
                  sets: int.tryParse(sets.text.trim()),
                  reps: reps.text.trim(),
                  weightKg: _parseTrainingDouble(weight.text),
                  note: note.text.trim(),
                ),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    name.dispose();
    sets.dispose();
    reps.dispose();
    weight.dispose();
    note.dispose();

    if (value == null) return;
    if (existing == null) {
      exercises.add(value);
    } else {
      final index = exercises.indexWhere((item) => item.id == existing.id);
      if (index >= 0) exercises[index] = value;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Esercizi / struttura',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('Esercizio'),
            ),
          ],
        ),
        for (final exercise in exercises)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fitness_center_outlined),
            title: Text(exercise.name),
            subtitle: Text(
              [
                if (exercise.sets != null) '${exercise.sets} serie',
                if (exercise.reps.isNotEmpty) exercise.reps,
                if (exercise.weightKg != null)
                  '${exercise.weightKg!.toStringAsFixed(1)} kg',
              ].join(' · '),
            ),
            onTap: () => _add(context, exercise),
            trailing: IconButton(
              tooltip: 'Rimuovi',
              onPressed: () {
                exercises.removeWhere((item) => item.id == exercise.id);
                onChanged();
              },
              icon: const Icon(Icons.close),
            ),
          ),
      ],
    );
  }
}

class _TrainingDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _TrainingDateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(
        value == null ? label : '$label: ${DateFormat('d MMM yy', 'it_IT').format(value!)}',
      ),
    );
  }
}

class _TrainingEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TrainingEmpty({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

double? _parseTrainingDouble(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));

int _parseTrainingDuration(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return 0;
  final parts = value.split(':').map(int.tryParse).toList();
  if (parts.any((value) => value == null)) return 0;
  if (parts.length == 1) return max(0, parts.first! * 60);
  if (parts.length == 2) {
    return max(0, parts[0]! * 60 + parts[1]!);
  }
  if (parts.length == 3) {
    return max(0, parts[0]! * 3600 + parts[1]! * 60 + parts[2]!);
  }
  return 0;
}
