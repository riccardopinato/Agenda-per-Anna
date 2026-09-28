part of '../../main.dart';

class TrainingScreen extends StatefulWidget {
  final AgendaStore store;

  const TrainingScreen({
    super.key,
    required this.store,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  bool showPlans = false;
  TrainingSport? sportFilter;

  Future<void> _addSession() async {
    final value = await _showSessionEditor();
    if (value == null) return;
    await widget.store.addTrainingSession(
      sport: value.sport,
      date: value.date,
      title: value.title,
      durationMinutes: value.durationMinutes,
      distanceKm: value.distanceKm,
      elevationMeters: value.elevationMeters,
      calories: value.calories,
      rpe: value.rpe,
      details: value.details,
      notes: value.notes,
    );
  }

  Future<void> _editSession(TrainingRecord record) async {
    final value = await _showSessionEditor(existing: record);
    if (value == null) return;
    await widget.store.saveTrainingRecord(
      record.copyWith(
        sport: value.sport,
        date: value.date,
        title: value.title.trim().isEmpty ? value.sport.label : value.title,
        durationMinutes: value.durationMinutes,
        distanceKm: value.distanceKm,
        elevationMeters: value.elevationMeters,
        calories: value.calories,
        rpe: value.rpe,
        details: value.details,
        notes: value.notes,
      ),
    );
  }

  Future<void> _addPlan() async {
    final value = await _showPlanEditor();
    if (value == null) return;
    await widget.store.addTrainingPlan(
      title: value.title,
      sport: value.sport,
      details: value.details,
      notes: value.notes,
    );
  }

  Future<void> _editPlan(TrainingRecord record) async {
    final value = await _showPlanEditor(existing: record);
    if (value == null) return;
    await widget.store.saveTrainingRecord(
      record.copyWith(
        sport: value.sport,
        title: value.title,
        details: value.details,
        notes: value.notes,
      ),
    );
  }

  Future<void> _delete(TrainingRecord record) async {
    final removed = await widget.store.moveTrainingRecordToTrash(record.id);
    if (!mounted || !removed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allenamento spostato nel Cestino.')),
    );
  }

  Future<_TrainingSessionDraft?> _showSessionEditor({
    TrainingRecord? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final durationController = TextEditingController(
      text: existing != null && existing.durationMinutes > 0
          ? existing.durationMinutes.toString()
          : '',
    );
    final distanceController = TextEditingController(
      text: existing != null && existing.distanceKm > 0
          ? existing.distanceKm.toStringAsFixed(
              existing.distanceKm % 1 == 0 ? 0 : 2,
            )
          : '',
    );
    final elevationController = TextEditingController(
      text: existing != null && existing.elevationMeters > 0
          ? existing.elevationMeters.toString()
          : '',
    );
    final caloriesController = TextEditingController(
      text: existing != null && existing.calories > 0
          ? existing.calories.toString()
          : '',
    );
    final detailsController =
        TextEditingController(text: existing?.details ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    var sport = existing?.sport ?? TrainingSport.running;
    var date = existing?.date ?? DateTime.now();
    var rpe = existing?.rpe ?? 0;

    final result = await showDialog<_TrainingSessionDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Registra allenamento' : 'Modifica allenamento',
          ),
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
                      if (value != null) {
                        setLocal(() => sport = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Titolo (opzionale)',
                      hintText: sport == TrainingSport.gym
                          ? 'es. Gambe + core'
                          : 'es. Lungo collinare',
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
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: date,
                      );
                      if (picked != null) {
                        setLocal(() => date = picked);
                      }
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
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Durata min',
                            hintText: '75',
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
                            labelText: 'Dislivello m',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Calorie',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sforzo percepito · RPE ${rpe == 0 ? '—' : rpe}/10',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Slider(
                    min: 0,
                    max: 10,
                    divisions: 10,
                    value: rpe.toDouble(),
                    label: rpe == 0 ? '—' : '$rpe',
                    onChanged: (value) =>
                        setLocal(() => rpe = value.round()),
                  ),
                  TextField(
                    controller: detailsController,
                    minLines: 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: sport == TrainingSport.gym
                          ? 'Esercizi / serie / ripetizioni / carichi'
                          : 'Dettagli attività',
                      hintText: sport == TrainingSport.gym
                          ? 'Squat 4×6 @ 80 kg\nAffondi 3×10...'
                          : 'Ripetute, fondo, percorso, vasche...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      alignLabelWithHint: true,
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
                double parseDouble(String value) =>
                    double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
                int parseInt(String value) =>
                    int.tryParse(value.trim()) ?? 0;
                Navigator.pop(
                  dialogContext,
                  _TrainingSessionDraft(
                    sport: sport,
                    date: date,
                    title: titleController.text.trim(),
                    durationMinutes:
                        max(0, parseInt(durationController.text)),
                    distanceKm:
                        max(0, parseDouble(distanceController.text)),
                    elevationMeters:
                        max(0, parseInt(elevationController.text)),
                    calories: max(0, parseInt(caloriesController.text)),
                    rpe: rpe,
                    details: detailsController.text.trim(),
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    durationController.dispose();
    distanceController.dispose();
    elevationController.dispose();
    caloriesController.dispose();
    detailsController.dispose();
    notesController.dispose();
    return result;
  }

  Future<_TrainingPlanDraft?> _showPlanEditor({
    TrainingRecord? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final detailsController =
        TextEditingController(text: existing?.details ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var sport = existing?.sport ?? TrainingSport.gym;
    String? importError;

    final result = await showDialog<_TrainingPlanDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Nuova scheda / piano' : 'Modifica scheda',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 560,
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
                      if (value != null) {
                        setLocal(() => sport = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome scheda / piano',
                      hintText: 'es. Scheda forza A/B',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final file = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: const ['txt', 'md'],
                          );
                          if (file == null) return;
                          final bytes = await file.readAsBytes();
                          if (bytes.isEmpty) return;
                          if (bytes.lengthInBytes > 512 * 1024) {
                            setLocal(
                              () => importError =
                                  'La scheda testuale supera 512 KB.',
                            );
                            return;
                          }
                          final text = utf8.decode(
                            bytes,
                            allowMalformed: true,
                          );
                          detailsController.text = text.trim();
                          if (titleController.text.trim().isEmpty &&
                              file != null) {
                            titleController.text = file.name.replaceFirst(
                              RegExp(
                                r'\.(txt|md)$',
                                caseSensitive: false,
                              ),
                              '',
                            );
                          }
                          setLocal(() => importError = null);
                        } catch (_) {
                          setLocal(
                            () => importError =
                                'Non riesco a leggere questo file.',
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Carica scheda .txt / .md'),
                    ),
                  ),
                  if (importError != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        importError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    minLines: 8,
                    maxLines: 18,
                    decoration: const InputDecoration(
                      labelText: 'Scheda / piano',
                      hintText:
                          'Incolla qui esercizi, lavori di corsa, bici, nuoto o qualsiasi programma.',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      alignLabelWithHint: true,
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
                final details = detailsController.text.trim();
                if (details.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  _TrainingPlanDraft(
                    sport: sport,
                    title: titleController.text.trim().isEmpty
                        ? 'Scheda ${sport.label}'
                        : titleController.text.trim(),
                    details: details,
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    detailsController.dispose();
    notesController.dispose();
    return result;
  }

  String _durationText(int minutes) {
    if (minutes <= 0) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return '$hours h';
    return '${hours}h ${mins}m';
  }

  String _paceText(TrainingRecord record) {
    final pace = widget.store.pacePerKm(record);
    if (pace == null) return '';
    final minutes = pace.inMinutes;
    final seconds = pace.inSeconds.remainder(60);
    return "${minutes}'${seconds.toString().padLeft(2, '0')}\"/km";
  }

  String _speedText(TrainingRecord record) {
    final speed = widget.store.averageSpeedKmh(record);
    if (speed <= 0) return '';
    return '${speed.toStringAsFixed(1)} km/h';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store.trainingRevision,
      builder: (context, _) {
        final sessions = widget.store.trainingSessionsForSport(sportFilter);
        final plans = widget.store.trainingPlans
            .where(
              (record) =>
                  sportFilter == null || record.sport == sportFilter,
            )
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Allenamento',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: showPlans ? _addPlan : _addSession,
            icon: Icon(showPlans ? Icons.note_add_outlined : Icons.add),
            label: Text(showPlans ? 'Scheda' : 'Allenamento'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.history),
                        label: Text('Registro'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.description_outlined),
                        label: Text('Schede / Piani'),
                      ),
                    ],
                    selected: {showPlans},
                    onSelectionChanged: (value) =>
                        setState(() => showPlans = value.first),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('Tutti'),
                          selected: sportFilter == null,
                          onSelected: (_) =>
                              setState(() => sportFilter = null),
                        ),
                      ),
                      ...TrainingSport.values.map(
                        (sport) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            avatar: Icon(sport.icon, size: 17),
                            label: Text(sport.label),
                            selected: sportFilter == sport,
                            onSelected: (_) =>
                                setState(() => sportFilter = sport),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: showPlans
                      ? _buildPlans(plans)
                      : _buildSessions(sessions),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessions(List<TrainingRecord> sessions) {
    if (sessions.isEmpty) {
      return const _TrainingEmpty(
        icon: Icons.sports_outlined,
        title: 'Nessun allenamento',
        body:
            'Registra corsa, bici, palestra, trekking, nuoto o qualsiasi altra attività.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final record = sessions[index];
        final metrics = <String>[
          if (record.distanceKm > 0)
            '${record.distanceKm.toStringAsFixed(record.distanceKm % 1 == 0 ? 0 : 2)} km',
          if (record.durationMinutes > 0)
            _durationText(record.durationMinutes),
          if (record.sport == TrainingSport.running &&
              record.distanceKm > 0 &&
              record.durationMinutes > 0)
            _paceText(record),
          if (record.sport == TrainingSport.cycling &&
              record.distanceKm > 0 &&
              record.durationMinutes > 0)
            _speedText(record),
          if (record.elevationMeters > 0)
            '+${record.elevationMeters} m',
          if (record.rpe > 0) 'RPE ${record.rpe}/10',
        ];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(record.sport.icon)),
            title: Text(
              record.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.sport.label} · ${DateFormat('d MMM yyyy', 'it_IT').format(record.date)}',
                ),
                if (metrics.isNotEmpty) Text(metrics.join(' · ')),
                if (record.details.trim().isNotEmpty)
                  Text(
                    record.details.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            isThreeLine: record.details.trim().isNotEmpty,
            onTap: () => _editSession(record),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editSession(record);
                if (value == 'delete') _delete(record);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifica')),
                PopupMenuItem(value: 'delete', child: Text('Elimina')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlans(List<TrainingRecord> plans) {
    if (plans.isEmpty) {
      return const _TrainingEmpty(
        icon: Icons.description_outlined,
        title: 'Nessuna scheda',
        body:
            'Crea un piano oppure carica una scheda testuale .txt/.md. Può essere palestra, corsa, bici, nuoto o altro.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final record = plans[index];
        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(child: Icon(record.sport.icon)),
            title: Text(
              record.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(record.sport.label),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editPlan(record);
                if (value == 'delete') _delete(record);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifica')),
                PopupMenuItem(value: 'delete', child: Text('Elimina')),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(record.details),
                ),
              ),
              if (record.notes.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Note: ${record.notes.trim()}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TrainingSessionDraft {
  final TrainingSport sport;
  final DateTime date;
  final String title;
  final int durationMinutes;
  final double distanceKm;
  final int elevationMeters;
  final int calories;
  final int rpe;
  final String details;
  final String notes;

  const _TrainingSessionDraft({
    required this.sport,
    required this.date,
    required this.title,
    required this.durationMinutes,
    required this.distanceKm,
    required this.elevationMeters,
    required this.calories,
    required this.rpe,
    required this.details,
    required this.notes,
  });
}

class _TrainingPlanDraft {
  final TrainingSport sport;
  final String title;
  final String details;
  final String notes;

  const _TrainingPlanDraft({
    required this.sport,
    required this.title,
    required this.details,
    required this.notes,
  });
}

class _TrainingEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TrainingEmpty({
    required this.icon,
    required this.title,
    required this.body,
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
