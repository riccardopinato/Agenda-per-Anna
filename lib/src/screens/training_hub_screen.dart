part of '../../main.dart';

class TrainingHubScreen extends StatefulWidget {
  final AgendaStore store;
  const TrainingHubScreen({super.key, required this.store});

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen> {
  bool showPlans = false;
  TrainingSport? sportFilter;

  String durationLabel(int seconds) {
    if (seconds <= 0) return '';
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
  }

  int parseDuration(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return 0;
    if (value.contains(':')) {
      final parts = value.split(':').map(int.tryParse).toList();
      if (parts.any((part) => part == null)) return 0;
      if (parts.length == 3) {
        return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
      }
      if (parts.length == 2) {
        return parts[0]! * 60 + parts[1]!;
      }
    }
    return ((double.tryParse(value.replaceAll(',', '.')) ?? 0) * 60).round();
  }

  double? parseNumber(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  Future<void> editSession([TrainingEntry? existing]) async {
    var sport = existing?.sport ?? TrainingSport.running;
    var date = existing?.date ?? DateTime.now();
    var effort = existing?.effort ?? 0;
    var planId = existing?.planId ?? '';
    final title = TextEditingController(text: existing?.title ?? '');
    final distance = TextEditingController(
      text: existing?.distanceKm?.toString() ?? '',
    );
    final duration = TextEditingController(
      text: existing == null || existing.durationSeconds <= 0
          ? ''
          : durationLabel(existing.durationSeconds),
    );
    final elevation = TextEditingController(
      text: existing?.elevationMeters?.toString() ?? '',
    );
    final notes = TextEditingController(text: existing?.notes ?? '');

    final result = await showDialog<TrainingEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nuovo allenamento' : 'Modifica allenamento'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TrainingSport>(
                    initialValue: sport,
                    decoration: const InputDecoration(labelText: 'Sport'),
                    items: TrainingSport.values
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setLocal(() => sport = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(DateFormat('d MMMM yyyy', 'it_IT').format(date)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setLocal(() => date = picked);
                    },
                  ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Titolo opzionale',
                      hintText: 'Lungo, Giro collinare, Gambe...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distance,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Distanza km',
                            hintText: '15',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: duration,
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
                    controller: elevation,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Dislivello m opzionale',
                    ),
                  ),
                  if (widget.store.trainingPlans.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: planId.isEmpty ? '' : planId,
                      decoration: const InputDecoration(
                        labelText: 'Scheda / piano opzionale',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Nessun piano'),
                        ),
                        ...widget.store.trainingPlans.map(
                          (plan) => DropdownMenuItem(
                            value: plan.id,
                            child: Text(plan.title),
                          ),
                        ),
                      ],
                      onChanged: (value) => setLocal(() => planId = value ?? ''),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Sforzo'),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: 10,
                          divisions: 10,
                          value: effort.toDouble(),
                          label: effort == 0 ? '—' : '$effort/10',
                          onChanged: (value) =>
                              setLocal(() => effort = value.round()),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: notes,
                    minLines: 3,
                    maxLines: 6,
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
                final plan = widget.store.trainingPlanById(planId);
                Navigator.pop(
                  dialogContext,
                  TrainingEntry(
                    id: existing?.id ?? const Uuid().v4(),
                    kind: TrainingEntryKind.session,
                    sport: sport,
                    title: title.text.trim().isEmpty
                        ? sport.label
                        : title.text.trim(),
                    date: DateTime(date.year, date.month, date.day),
                    durationSeconds: parseDuration(duration.text),
                    distanceKm: parseNumber(distance.text),
                    elevationMeters: parseNumber(elevation.text),
                    effort: effort,
                    notes: notes.text.trim(),
                    planId: planId,
                    exercises: existing?.exercises.isNotEmpty == true
                        ? existing!.exercises
                        : (plan?.exercises ?? const []),
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  ),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    distance.dispose();
    duration.dispose();
    elevation.dispose();
    notes.dispose();
    if (result != null) await widget.store.saveTrainingEntry(result);
  }

  List<TrainingExercise> parseExercises(String raw) {
    final result = <TrainingExercise>[];
    for (final row in raw.split('\n')) {
      final parts = row.split('|').map((value) => value.trim()).toList();
      if (parts.isEmpty || parts.first.isEmpty) continue;
      var sets = 0;
      var reps = 0;
      if (parts.length > 1) {
        final match = RegExp(r'(\d+)\s*[x×]\s*(\d+)').firstMatch(parts[1]);
        if (match != null) {
          sets = int.tryParse(match.group(1) ?? '') ?? 0;
          reps = int.tryParse(match.group(2) ?? '') ?? 0;
        }
      }
      double? weight;
      if (parts.length > 2) {
        weight = double.tryParse(
          parts[2].toLowerCase().replaceAll('kg', '').trim().replaceAll(',', '.'),
        );
      }
      result.add(
        TrainingExercise(
          name: parts.first,
          sets: sets,
          reps: reps,
          weightKg: weight,
          note: parts.length > 3 ? parts.sublist(3).join(' | ') : '',
        ),
      );
    }
    return result;
  }

  Future<void> editPlan([TrainingEntry? existing]) async {
    var sport = existing?.sport ?? TrainingSport.gym;
    var attachmentName = existing?.attachmentName ?? '';
    var attachmentMime = existing?.attachmentMimeType ?? '';
    var attachmentBase64 = existing?.attachmentBase64 ?? '';
    final title = TextEditingController(text: existing?.title ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    final exercises = TextEditingController(
      text: (existing?.exercises ?? const [])
          .map((exercise) {
            final left = exercise.sets > 0 && exercise.reps > 0
                ? '${exercise.sets}x${exercise.reps}'
                : '';
            final weight = exercise.weightKg == null
                ? ''
                : '${exercise.weightKg} kg';
            return [exercise.name, left, weight, exercise.note]
                .where((part) => part.isNotEmpty)
                .join(' | ');
          })
          .join('\n'),
    );

    final result = await showDialog<TrainingEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nuovo piano / scheda' : 'Modifica piano'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Nome piano',
                      hintText: 'Scheda A/B, Preparazione 10 km...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TrainingSport>(
                    initialValue: sport,
                    decoration: const InputDecoration(labelText: 'Sport'),
                    items: TrainingSport.values
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setLocal(() => sport = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: exercises,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Esercizi / struttura',
                      alignLabelWithHint: true,
                      hintText: 'Squat | 4x8 | 80 kg\nPanca | 4x6 | 60 kg',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Note del piano',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file),
                    title: Text(
                      attachmentName.isEmpty ? 'Carica scheda' : attachmentName,
                    ),
                    subtitle: const Text('PDF, immagine o TXT · max 3 MB'),
                    trailing: attachmentName.isEmpty
                        ? const Icon(Icons.upload_file_outlined)
                        : IconButton(
                            onPressed: () => setLocal(() {
                              attachmentName = '';
                              attachmentMime = '';
                              attachmentBase64 = '';
                            }),
                            icon: const Icon(Icons.close),
                          ),
                    onTap: () async {
                      final file = await FilePicker.pickFile(
                        type: FileType.custom,
                        allowedExtensions: const [
                          'pdf',
                          'png',
                          'jpg',
                          'jpeg',
                          'txt',
                        ],
                      );
                      if (file == null) return;
                      final bytes = await file.readAsBytes();
                      if (bytes.lengthInBytes > 3 * 1024 * 1024) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La scheda supera il limite di 3 MB.'),
                            ),
                          );
                        }
                        return;
                      }
                      final ext = (file.extension ?? '').toLowerCase();
                      setLocal(() {
                        attachmentName = file.name;
                        attachmentMime = switch (ext) {
                          'pdf' => 'application/pdf',
                          'png' => 'image/png',
                          'jpg' || 'jpeg' => 'image/jpeg',
                          'txt' => 'text/plain',
                          _ => 'application/octet-stream',
                        };
                        attachmentBase64 = base64Encode(bytes);
                      });
                    },
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
                if (title.text.trim().isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  TrainingEntry(
                    id: existing?.id ?? const Uuid().v4(),
                    kind: TrainingEntryKind.plan,
                    sport: sport,
                    title: title.text.trim(),
                    date: existing?.date ?? DateTime.now(),
                    notes: notes.text.trim(),
                    exercises: parseExercises(exercises.text),
                    attachmentName: attachmentName,
                    attachmentMimeType: attachmentMime,
                    attachmentBase64: attachmentBase64,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  ),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    notes.dispose();
    exercises.dispose();
    if (result != null) await widget.store.saveTrainingEntry(result);
  }

  Future<void> deleteEntry(TrainingEntry entry) async {
    await widget.store.moveTrainingEntryToTrash(entry.id);
  }

  Future<void> showEntry(TrainingEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Icon(entry.sport.icon)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(entry.sport.label),
              if (entry.kind == TrainingEntryKind.session) ...[
                const SizedBox(height: 5),
                Text(DateFormat('d MMMM yyyy', 'it_IT').format(entry.date)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (entry.distanceKm != null)
                      Chip(label: Text('${entry.distanceKm} km')),
                    if (entry.durationSeconds > 0)
                      Chip(label: Text(durationLabel(entry.durationSeconds))),
                    if (entry.elevationMeters != null)
                      Chip(label: Text('${entry.elevationMeters!.round()} m D+')),
                    if (entry.effort > 0)
                      Chip(label: Text('Sforzo ${entry.effort}/10')),
                  ],
                ),
              ],
              if (entry.exercises.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Esercizi',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                ...entry.exercises.map(
                  (exercise) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(exercise.name),
                    subtitle: Text(
                      [
                        if (exercise.sets > 0 && exercise.reps > 0)
                          '${exercise.sets}×${exercise.reps}',
                        if (exercise.weightKg != null)
                          '${exercise.weightKg} kg',
                        if (exercise.note.isNotEmpty) exercise.note,
                      ].join(' · '),
                    ),
                  ),
                ),
              ],
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(entry.notes),
              ],
              if (entry.hasAttachment) ...[
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: Text(entry.attachmentName),
                  subtitle: const Text('Allegato salvato nella scheda'),
                ),
                if (entry.attachmentMimeType.startsWith('image/'))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(base64Decode(entry.attachmentBase64)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store.trainingRevision,
      builder: (context, _) {
        final sessions = sportFilter == null
            ? widget.store.trainingSessions
            : widget.store.trainingSessionsForSport(sportFilter!);
        final plans = widget.store.trainingPlans;
        final sports = widget.store.trainingSessions
            .map((entry) => entry.sport)
            .toSet()
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Allenamento',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: showPlans ? () => editPlan() : () => editSession(),
            icon: const Icon(Icons.add),
            label: Text(showPlans ? 'Nuovo piano' : 'Registra'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.history),
                      label: Text('Storico'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.description_outlined),
                      label: Text('Piani / schede'),
                    ),
                  ],
                  selected: {showPlans},
                  onSelectionChanged: (value) =>
                      setState(() => showPlans = value.first),
                ),
              ),
              if (!showPlans && sports.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Tutti'),
                        selected: sportFilter == null,
                        onSelected: (_) => setState(() => sportFilter = null),
                      ),
                      const SizedBox(width: 6),
                      ...sports.map(
                        (sport) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
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
              Expanded(
                child: showPlans
                    ? _TrainingList(
                        entries: plans,
                        emptyText: 'Nessun piano o scheda salvata.',
                        onTap: showEntry,
                        onEdit: editPlan,
                        onDelete: deleteEntry,
                        durationLabel: durationLabel,
                      )
                    : _TrainingList(
                        entries: sessions,
                        emptyText:
                            'Registra corsa, bici, palestra o qualsiasi altro sport.',
                        onTap: showEntry,
                        onEdit: editSession,
                        onDelete: deleteEntry,
                        durationLabel: durationLabel,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrainingList extends StatelessWidget {
  final List<TrainingEntry> entries;
  final String emptyText;
  final ValueChanged<TrainingEntry> onTap;
  final ValueChanged<TrainingEntry> onEdit;
  final ValueChanged<TrainingEntry> onDelete;
  final String Function(int) durationLabel;

  const _TrainingList({
    required this.entries,
    required this.emptyText,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final details = <String>[
          entry.sport.label,
          if (entry.kind == TrainingEntryKind.session)
            DateFormat('d MMM yyyy', 'it_IT').format(entry.date),
          if (entry.distanceKm != null) '${entry.distanceKm} km',
          if (entry.durationSeconds > 0) durationLabel(entry.durationSeconds),
          if (entry.kind == TrainingEntryKind.plan && entry.hasAttachment)
            entry.attachmentName,
        ];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Icon(entry.sport.icon)),
            title: Text(
              entry.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(details.join(' · ')),
            onTap: () => onTap(entry),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit(entry);
                if (value == 'delete') onDelete(entry);
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
}
