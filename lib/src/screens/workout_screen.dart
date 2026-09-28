part of '../../main.dart';

enum _WorkoutSection { sessions, plans }

class WorkoutScreen extends StatefulWidget {
  final AgendaStore store;

  const WorkoutScreen({
    super.key,
    required this.store,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  _WorkoutSection section = _WorkoutSection.sessions;
  WorkoutSport? sportFilter;

  List<WorkoutSession> get _sessions {
    final all = widget.store.workoutHistory;
    final filter = sportFilter;
    if (filter == null) return all;
    return all.where((session) => session.sport == filter).toList();
  }

  Future<void> _openSessionEditor({
    WorkoutSession? existing,
    WorkoutPlan? plan,
  }) async {
    final result = await showWorkoutSessionEditor(
      context,
      store: widget.store,
      existing: existing,
      plan: plan,
    );
    if (result == null) return;
    await widget.store.saveWorkoutSession(result);
  }

  Future<void> _openPlanEditor({WorkoutPlan? existing}) async {
    final result = await showWorkoutPlanEditor(
      context,
      store: widget.store,
      existing: existing,
    );
    if (result == null) return;
    await widget.store.saveWorkoutPlan(result);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store.workoutRevision,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Allenamento',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: section == _WorkoutSection.sessions
              ? () => _openSessionEditor()
              : () => _openPlanEditor(),
          icon: Icon(
            section == _WorkoutSection.sessions
                ? Icons.add_rounded
                : Icons.playlist_add_rounded,
          ),
          label: Text(
            section == _WorkoutSection.sessions
                ? 'Registra'
                : 'Nuova scheda',
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SegmentedButton<_WorkoutSection>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _WorkoutSection.sessions,
                      icon: Icon(Icons.history_rounded),
                      label: Text('Sessioni'),
                    ),
                    ButtonSegment(
                      value: _WorkoutSection.plans,
                      icon: Icon(Icons.assignment_outlined),
                      label: Text('Schede'),
                    ),
                  ],
                  selected: {section},
                  onSelectionChanged: (value) =>
                      setState(() => section = value.first),
                ),
              ),
              if (section == _WorkoutSection.sessions)
                _buildSportFilters(context),
              Expanded(
                child: section == _WorkoutSection.sessions
                    ? _buildSessions()
                    : _buildPlans(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilters(BuildContext context) {
    final used = <WorkoutSport>{
      for (final session in widget.store.workoutSessions) session.sport,
    };
    final sports = WorkoutSport.values
        .where((sport) => used.contains(sport))
        .toList(growable: false);

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: FilterChip(
              selected: sportFilter == null,
              label: const Text('Tutti'),
              onSelected: (_) => setState(() => sportFilter = null),
            ),
          ),
          for (final sport in sports)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FilterChip(
                selected: sportFilter == sport,
                avatar: Icon(sport.icon, size: 17),
                label: Text(sport.label),
                onSelected: (_) => setState(() => sportFilter = sport),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessions() {
    final sessions = _sessions;
    if (sessions.isEmpty) {
      return const _WorkoutEmptyState(
        icon: Icons.sports_outlined,
        title: 'Nessun allenamento registrato',
        subtitle:
            'Corsa, bici, palestra, nuoto, trekking o qualsiasi altra attività: tutto resta nello stesso storico.',
      );
    }

    final totalDistance = sessions
        .where((session) => session.distanceKm != null)
        .fold<double>(0, (sum, session) => sum + session.distanceKm!);
    final totalSeconds =
        sessions.fold<int>(0, (sum, session) => sum + session.durationSeconds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
      children: [
        _WorkoutSummaryCard(
          sessions: sessions.length,
          totalDistance: totalDistance,
          totalSeconds: totalSeconds,
          store: widget.store,
        ),
        const SizedBox(height: 8),
        for (final session in sessions)
          _WorkoutSessionCard(
            store: widget.store,
            session: session,
            onEdit: () => _openSessionEditor(existing: session),
            onDelete: () async {
              final removed =
                  await widget.store.moveWorkoutSessionToTrash(session.id);
              if (!mounted || !removed) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Allenamento spostato nel Cestino.'),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPlans() {
    final plans = widget.store.workoutPlansSorted;
    if (plans.isEmpty) {
      return const _WorkoutEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Nessuna scheda salvata',
        subtitle:
            'Crea una scheda manualmente oppure importa un file TXT/CSV. Potrai poi registrare una sessione partendo da quella scheda.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
      children: [
        for (final plan in plans)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(plan.sport.icon),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              '${plan.sport.label} · ${plan.exercises.length} voci',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openPlanEditor(existing: plan);
                          } else if (value == 'delete') {
                            final removed = await widget.store
                                .moveWorkoutPlanToTrash(plan.id);
                            if (!mounted || !removed) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Scheda spostata nel Cestino.'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Modifica'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Elimina'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (plan.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(plan.note.trim()),
                  ],
                  if (plan.exercises.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final exercise in plan.exercises.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${_workoutExerciseLabel(exercise)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (plan.exercises.length > 5)
                      Text(
                        '+ ${plan.exercises.length - 5} altre voci',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => _openSessionEditor(plan: plan),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Registra da questa scheda'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  final int sessions;
  final double totalDistance;
  final int totalSeconds;
  final AgendaStore store;

  const _WorkoutSummaryCard({
    required this.sessions,
    required this.totalDistance,
    required this.totalSeconds,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _WorkoutMetric(
              icon: Icons.sports_outlined,
              value: '$sessions',
              label: 'sessioni',
            ),
            if (totalDistance > 0)
              _WorkoutMetric(
                icon: Icons.route_outlined,
                value: totalDistance.toStringAsFixed(
                  totalDistance % 1 == 0 ? 0 : 1,
                ),
                label: 'km',
              ),
            if (totalSeconds > 0)
              _WorkoutMetric(
                icon: Icons.timer_outlined,
                value: store.formatWorkoutDuration(totalSeconds),
                label: 'tempo',
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WorkoutMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _WorkoutSessionCard extends StatelessWidget {
  final AgendaStore store;
  final WorkoutSession session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutSessionCard({
    required this.store,
    required this.session,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final performance = store.workoutPerformanceLabel(session);
    final facts = <String>[
      DateFormat('d MMM yyyy', 'it_IT').format(session.date),
      if (session.distanceKm != null)
        '${session.distanceKm!.toStringAsFixed(session.distanceKm! % 1 == 0 ? 0 : 2)} km',
      if (session.durationSeconds > 0)
        store.formatWorkoutDuration(session.durationSeconds),
      if (performance != null) performance,
      if (session.elevationGainM != null) '+${session.elevationGainM} m',
      if (session.effort != null) 'RPE ${session.effort}/10',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(session.sport.icon),
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${session.sport.label} · ${facts.join(' · ')}'),
            if (session.planName.isNotEmpty)
              Text('Scheda: ${session.planName}'),
            if (session.note.trim().isNotEmpty)
              Text(
                session.note.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine:
            session.note.trim().isNotEmpty || session.planName.isNotEmpty,
        onTap: onEdit,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifica')),
            PopupMenuItem(value: 'delete', child: Text('Elimina')),
          ],
        ),
      ),
    );
  }
}

class _WorkoutEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WorkoutEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Future<WorkoutSession?> showWorkoutSessionEditor(
  BuildContext context, {
  required AgendaStore store,
  WorkoutSession? existing,
  WorkoutPlan? plan,
}) async {
  var sport = existing?.sport ?? plan?.sport ?? WorkoutSport.running;
  var date = existing?.date ?? DateTime.now();
  final titleController = TextEditingController(
    text: existing?.title ?? (plan?.name ?? ''),
  );
  final durationController = TextEditingController(
    text: existing != null && existing.durationSeconds > 0
        ? store.formatWorkoutDuration(existing.durationSeconds)
        : '',
  );
  final distanceController = TextEditingController(
    text: existing?.distanceKm?.toString() ?? '',
  );
  final elevationController = TextEditingController(
    text: existing?.elevationGainM?.toString() ?? '',
  );
  final noteController = TextEditingController(text: existing?.note ?? '');
  var effort = existing?.effort;
  String? error;

  int parseDuration(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 0;
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return -1;
    if (parts.length == 3) {
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    }
    if (parts.length == 2) {
      return parts[0]! * 60 + parts[1]!;
    }
    if (parts.length == 1) {
      return parts[0]! * 60;
    }
    return -1;
  }

  final result = await showModalBottomSheet<WorkoutSession>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) setLocal(() => date = picked);
        }

        void save() {
          final seconds = parseDuration(durationController.text);
          if (seconds < 0) {
            setLocal(
              () => error =
                  'Durata non valida. Usa MM:SS, HH:MM:SS oppure i minuti.',
            );
            return;
          }
          final distance = double.tryParse(
            distanceController.text.trim().replaceAll(',', '.'),
          );
          final elevation = int.tryParse(elevationController.text.trim());
          if (distanceController.text.trim().isNotEmpty &&
              (distance == null || distance <= 0)) {
            setLocal(() => error = 'Distanza non valida.');
            return;
          }
          if (elevationController.text.trim().isNotEmpty &&
              (elevation == null || elevation < 0)) {
            setLocal(() => error = 'Dislivello non valido.');
            return;
          }

          final now = DateTime.now();
          Navigator.pop(
            sheetContext,
            WorkoutSession(
              id: existing?.id ?? const Uuid().v4(),
              sport: sport,
              title: titleController.text.trim().isEmpty
                  ? sport.label
                  : titleController.text.trim(),
              date: date,
              durationSeconds: seconds,
              distanceKm: distance,
              elevationGainM: elevation,
              effort: effort,
              note: noteController.text.trim(),
              planName: existing?.planName ?? plan?.name ?? '',
              exercises:
                  existing?.exercises ?? plan?.exercises ?? const [],
              createdAt: existing?.createdAt ?? now,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null
                        ? 'Registra allenamento'
                        : 'Modifica allenamento',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 5),
                    Text('Da scheda: ${plan.name}'),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<WorkoutSport>(
                    initialValue: sport,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      prefixIcon: Icon(Icons.sports_outlined),
                    ),
                    items: WorkoutSport.values
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Titolo (opzionale)',
                      hintText: sport == WorkoutSport.running
                          ? 'es. Lungo collinare'
                          : sport == WorkoutSport.cycling
                              ? 'es. Giro in bici'
                              : 'es. Sessione serale',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      DateFormat('EEEE d MMMM yyyy', 'it_IT').format(date),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Tempo',
                            hintText: 'es. 1:05:20',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: distanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Distanza km',
                            hintText: 'es. 15',
                            prefixIcon: Icon(Icons.route_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: elevationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dislivello +m',
                            hintText: 'opzionale',
                            prefixIcon: Icon(Icons.terrain_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: effort,
                          decoration: const InputDecoration(
                            labelText: 'Intensità',
                            prefixIcon: Icon(Icons.speed_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('—'),
                            ),
                            for (var value = 1; value <= 10; value++)
                              DropdownMenuItem<int?>(
                                value: value,
                                child: Text('$value / 10'),
                              ),
                          ],
                          onChanged: (value) =>
                              setLocal(() => effort = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText:
                          'Sensazioni, percorso, esercizi extra, dettagli...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if ((existing?.exercises ?? plan?.exercises ?? const [])
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Scheda usata',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    for (final exercise
                        in (existing?.exercises ?? plan?.exercises ?? const [])
                            .take(8))
                      Text('• ${_workoutExerciseLabel(exercise)}'),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salva allenamento'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  titleController.dispose();
  durationController.dispose();
  distanceController.dispose();
  elevationController.dispose();
  noteController.dispose();
  return result;
}

Future<WorkoutPlan?> showWorkoutPlanEditor(
  BuildContext context, {
  required AgendaStore store,
  WorkoutPlan? existing,
}) async {
  var sport = existing?.sport ?? WorkoutSport.gym;
  final nameController = TextEditingController(text: existing?.name ?? '');
  final noteController = TextEditingController(text: existing?.note ?? '');
  final exercisesController = TextEditingController(
    text: existing?.exercises.map(_workoutExerciseLabel).join('\n') ?? '',
  );
  String? error;

  final result = await showModalBottomSheet<WorkoutPlan>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) {
        Future<void> importTextFile() async {
          final picked = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['txt', 'csv'],
            withData: true,
          );
          if (picked == null || picked.files.isEmpty) return;
          final file = picked.files.single;
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            setLocal(
              () => error = 'Non riesco a leggere questo file.',
            );
            return;
          }
          if (bytes.lengthInBytes > 1024 * 1024) {
            setLocal(
              () => error = 'La scheda supera il limite di 1 MB.',
            );
            return;
          }
          final text = utf8.decode(bytes, allowMalformed: true).trim();
          if (text.isEmpty) {
            setLocal(() => error = 'Il file non contiene testo.');
            return;
          }
          exercisesController.text = text;
          setLocal(() => error = null);
        }

        void save() {
          final name = nameController.text.trim();
          if (name.isEmpty) {
            setLocal(() => error = 'Dai un nome alla scheda.');
            return;
          }
          final exercises =
              store.parseWorkoutPlanText(exercisesController.text);
          final now = DateTime.now();
          Navigator.pop(
            sheetContext,
            WorkoutPlan(
              id: existing?.id ?? const Uuid().v4(),
              name: name,
              sport: sport,
              note: noteController.text.trim(),
              exercises: exercises,
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Nuova scheda' : 'Modifica scheda',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome scheda',
                      hintText: 'es. Forza A, Preparazione 10 km...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<WorkoutSport>(
                    initialValue: sport,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      prefixIcon: Icon(Icons.sports_outlined),
                    ),
                    items: WorkoutSport.values
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note generali',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: exercisesController,
                    minLines: 7,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      labelText: 'Scheda / esercizi',
                      hintText:
                          'Un esercizio o blocco per riga\nPanca 4x8 @ 60kg\nSquat 4x6 @ 80kg\nCorsa facile 30 min',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: importTextFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Importa scheda TXT / CSV'),
                  ),
                  Text(
                    'Puoi usare anche testo libero: ciò che non segue il formato serie × ripetizioni resta comunque salvato come voce della scheda.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salva scheda'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  nameController.dispose();
  noteController.dispose();
  exercisesController.dispose();
  return result;
}

String _workoutExerciseLabel(WorkoutExercise exercise) {
  final parts = <String>[exercise.name.trim()];
  if (exercise.sets > 0 && exercise.reps.trim().isNotEmpty) {
    parts.add('${exercise.sets}×${exercise.reps.trim()}');
  } else if (exercise.sets > 0) {
    parts.add('${exercise.sets} serie');
  } else if (exercise.reps.trim().isNotEmpty) {
    parts.add(exercise.reps.trim());
  }
  if (exercise.loadKg != null) {
    parts.add(
      '${exercise.loadKg!.toStringAsFixed(exercise.loadKg! % 1 == 0 ? 0 : 1)} kg',
    );
  }
  if (exercise.note.trim().isNotEmpty) parts.add(exercise.note.trim());
  return parts.join(' · ');
}
