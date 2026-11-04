part of '../main.dart';

/// Read-only, explainable advice using the same visible agenda as Today.
class RealisticDayAdvice {
  const RealisticDayAdvice({
    required this.freeMinutes,
    required this.pendingTasks,
    required this.reasonCode,
    required this.firstFreeSlot,
    this.bufferMinutes = 0,
    this.recordedTaskMinutes = 0,
    this.tasksWithRecordedTime = 0,
    this.tasksWithoutRecordedTime = 0,
  });

  final int freeMinutes;
  final int pendingTasks;
  final String reasonCode;
  final CalendarFreeSlot? firstFreeSlot;
  /// User-selected voluntary space left unbooked. Never assumed task time.
  final int bufferMinutes;
  /// Sum of explicit start/end task durations, shown for provenance only.
  /// Timed tasks already occupy calendar slots; do NOT subtract twice.
  final int recordedTaskMinutes;
  final int tasksWithRecordedTime;
  final int tasksWithoutRecordedTime;
  int get usableMinutes => max(0, freeMinutes - bufferMinutes);

  bool get hasPressure => reasonCode == 'VISIBLE_WINDOW_CONGESTED';
}

/// Only real time fields on currently visible, authorized task entries count.
class RecordedTaskTime {
  const RecordedTaskTime({
    required this.minutes,
    required this.withTime,
    required this.withoutTime,
  });
  final int minutes;
  final int withTime;
  final int withoutTime;

  static RecordedTaskTime fromVisible(Iterable<UnifiedAgendaEntry> entries) {
    var minutes = 0;
    var withTime = 0;
    var withoutTime = 0;
    final seen = <String>{};
    for (final entry in entries) {
      if (entry.isExternal || entry.type != ItemType.task || entry.done ||
          !seen.add(entry.id)) {
        continue;
      }
      final start = entry.start;
      final end = entry.end;
      if (start == null || end == null) {
        withoutTime++;
        continue;
      }
      final s = start.hour * 60 + start.minute;
      final e = end.hour * 60 + end.minute;
      if (s == e) {
        withoutTime++; // Ambiguous all-day vs zero-length: never guess.
        continue;
      }
      final recorded = e > s ? e - s : 1440 - s + e;
      minutes += recorded;
      withTime++;
    }
    return RecordedTaskTime(
      minutes: minutes,
      withTime: withTime,
      withoutTime: withoutTime,
    );
  }
}

abstract final class RealisticDayAdvisor {
  static RealisticDayAdvice evaluate({
    required DateTime day,
    required Iterable<UnifiedAgendaEntry> visibleEntries,
    required int pendingTasks,
    DateTime? now,
    int bufferMinutes = 0,
  }) {
    final observed = visibleEntries.toList(growable: false);
    final recorded = RecordedTaskTime.fromVisible(observed);
    final slots = findCalendarFreeSlots(
      day: day,
      visibleEntries: observed,
      startHour: 9,
      endHour: 21,
      minimumMinutes: 1,
    );
    final effectiveSlots = now == null
        ? slots
        : slots
            .where((slot) => slot.end.isAfter(now))
            .map((slot) => CalendarFreeSlot(
                  slot.start.isBefore(now) ? now : slot.start,
                  slot.end,
                ))
            .toList(growable: false);
    final minutes = effectiveSlots.fold<int>(
      0,
      (sum, slot) => sum + slot.duration.inMinutes,
    );
    final boundedBuffer = bufferMinutes.clamp(0, 120).toInt();
    final usable = max(0, minutes - boundedBuffer);
    final candidate = effectiveSlots.where(
      (slot) => slot.duration.inMinutes >= 30,
    );
    return RealisticDayAdvice(
      freeMinutes: minutes,
      bufferMinutes: boundedBuffer,
      recordedTaskMinutes: recorded.minutes,
      tasksWithRecordedTime: recorded.withTime,
      tasksWithoutRecordedTime: recorded.withoutTime,
      pendingTasks: pendingTasks,
      firstFreeSlot: candidate.isEmpty ? null : candidate.first,
      reasonCode: pendingTasks > 0 && usable < 90
          ? 'VISIBLE_WINDOW_CONGESTED'
          : 'VISIBLE_WINDOW_CAPACITY',
    );
  }
}

/// Preparation candidates are private events by civil date, not only timed
/// entries. No shared/private-scope promotion or implicit changes.
List<AgendaItem> upcomingPreparationItems(AgendaStore store, DateTime now) {
  if (store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
    return const [];
  }
  final today = DateTime(now.year, now.month, now.day);
  final cutoff = DateTime(today.year, today.month, today.day + 3);
  final result = store.items
      .where((item) =>
          canPrepareEvent(item) &&
          !item.date.isBefore(today) &&
          item.date.isBefore(cutoff) &&
          (item.start == null ||
              item.date.isAfter(today) ||
              item.start!.hour * 60 + item.start!.minute >=
                  now.hour * 60 + now.minute))
      .toList(growable: false)
    ..sort((a, b) {
      final day = a.date.compareTo(b.date);
      if (day != 0) return day;
      final aMinutes = a.start == null
          ? 0
          : a.start!.hour * 60 + a.start!.minute;
      final bMinutes = b.start == null
          ? 0
          : b.start!.hour * 60 + b.start!.minute;
      final clock = aMinutes.compareTo(bMinutes);
      return clock != 0 ? clock : a.id.compareTo(b.id);
    });
  return List.unmodifiable(result);
}

/// Read-only daily guidance may be dismissed on this device for one day.
/// Only a SHA-256 digest of account scope and civil date is persisted.
class RealisticDayCard extends StatefulWidget {
  const RealisticDayCard({
    required this.store,
    required this.snapshot,
    required this.hideDetails,
    super.key,
  });

  final AgendaStore store;
  final DayHubSnapshot snapshot;
  final bool hideDetails;

  @override
  State<RealisticDayCard> createState() => _RealisticDayCardState();
}

class _RealisticDayCardState extends State<RealisticDayCard> {
  static const _preferenceKey = 'anna_contextual_day_dismissed_v1';
  bool _loaded = false;
  int _bufferMinutes = 0;
  bool _nudgesEnabled = false;
  int _snoozedThrough = 0;
  String? _observedAccount;
  static const _bufferPreferencePrefix = 'anna_realistic_buffer_v1_';
  String get _bufferKey => _bufferPreferencePrefix +
      sha256.convert(utf8.encode(widget.store.activeAccountId ?? 'local'))
          .toString();
  final Set<String> _dismissed = <String>{};

  String get _dayKey {
    final date = widget.snapshot.date;
    final owner = widget.store.activeAccountId ?? 'local';
    final raw = '$owner:${date.year}-${date.month}-${date.day}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  @override
  void initState() {
    super.initState();
    _observedAccount = _bufferKey;
    _load();
  }

  @override
  void didUpdateWidget(covariant RealisticDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_observedAccount != _bufferKey) {
      _observedAccount = _bufferKey;
      _loaded = false;
      _bufferMinutes = 0;
      _nudgesEnabled = false;
      _snoozedThrough = 0;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final key = _bufferKey;
      final buffer = (prefs.getInt(key) ?? 0).clamp(0, 120).toInt();
      final nudges = prefs.getBool('${key}_nudges') ?? false;
      final snoozed = prefs.getInt('${key}_snoozed_through') ?? 0;
      if (key != _observedAccount) return;
      setState(() {
        _dismissed.addAll(prefs.getStringList(_preferenceKey) ?? const []);
        _bufferMinutes = buffer;
        _nudgesEnabled = nudges;
        _snoozedThrough = snoozed;
        _loaded = true;
      });
    } catch (_) {
      // Fail closed on inability to restore local visibility preferences.
    }
  }

  Future<void> _chooseBuffer(int minutes) async {
    final choice = minutes.clamp(0, 120).toInt();
    final previous = _bufferMinutes;
    final accountKey = _bufferKey;
    setState(() => _bufferMinutes = choice);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_bufferKey != accountKey) return;
      final stored = await prefs.setInt(accountKey, choice);
      if (!stored) throw StateError('buffer not saved');
    } catch (_) {
      if (!mounted || _bufferKey != accountKey) return;
      setState(() => _bufferMinutes = previous);
    }
  }

  Future<void> _setNudgesEnabled(bool enabled) async {
    final key = _bufferKey;
    final previous = _nudgesEnabled;
    setState(() => _nudgesEnabled = enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_bufferKey != key) return;
      if (!await prefs.setBool('${key}_nudges', enabled)) {
        throw StateError('nudge setting not saved');
      }
    } catch (_) {
      if (mounted && _bufferKey == key) {
        setState(() => _nudgesEnabled = previous);
      }
    }
  }

  /// Snooze is at most 7 civil days, local to this account and device.
  /// An always-visible resume control keeps the action reversible.
  Future<void> _setSnooze(bool snooze) async {
    final key = _bufferKey;
    final previous = _snoozedThrough;
    final now = DateTime.now();
    final until = snooze
        ? DateTime(now.year, now.month, now.day + 7)
        : null;
    final next = until == null
        ? 0 : until.year * 10000 + until.month * 100 + until.day;
    setState(() => _snoozedThrough = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_bufferKey != key) return;
      if (!await prefs.setInt('${key}_snoozed_through', next)) {
        throw StateError('snooze setting not saved');
      }
    } catch (_) {
      if (mounted && _bufferKey == key) {
        setState(() => _snoozedThrough = previous);
      }
    }
  }

  Future<void> _dismissToday() async {
    final key = _dayKey;
    setState(() {
      _dismissed.remove(key);
      _dismissed.add(key);
      while (_dismissed.length > 90) {
        _dismissed.remove(_dismissed.first);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _preferenceKey,
        _dismissed.take(90).toList(growable: false),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _dismissed.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile salvare la preferenza locale.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || widget.hideDetails || _dismissed.contains(_dayKey)) {
      return const SizedBox.shrink();
    }
    return _RealisticDayCardBody(
      store: widget.store,
      snapshot: widget.snapshot,
      hideDetails: widget.hideDetails,
      onDismiss: _dismissToday,
      bufferMinutes: _bufferMinutes,
      onSelectBuffer: _chooseBuffer,
      nudgesEnabled: _nudgesEnabled,
      onSetNudges: _setNudgesEnabled,
      snoozedThrough: _snoozedThrough,
      onSetSnooze: _setSnooze,
    );
  }
}

class _RealisticDayCardBody extends StatelessWidget {
  const _RealisticDayCardBody({
    required this.store,
    required this.snapshot,
    required this.hideDetails,
    required this.onDismiss,
    required this.bufferMinutes,
    required this.onSelectBuffer,
    required this.nudgesEnabled,
    required this.onSetNudges,
    required this.snoozedThrough,
    required this.onSetSnooze,
  });

  final AgendaStore store;
  final DayHubSnapshot snapshot;
  final bool hideDetails;
  final VoidCallback onDismiss;
  final int bufferMinutes;
  final ValueChanged<int> onSelectBuffer;
  final bool nudgesEnabled;
  final ValueChanged<bool> onSetNudges;
  final int snoozedThrough;
  final ValueChanged<bool> onSetSnooze;

  String _localized(String lang, String key) {
    const copy = <String, List<String>>{
      'title': [
        'Plan a realistic day',
        'Organizza una giornata realistica',
        'Organiza un día realista',
        'Organisez une journée réaliste',
        'Planeie um dia realista',
      ],
      'pressure': [
        'Your visible calendar is almost full. Review commitments before '
            'planning more.',
        'Il calendario visibile è quasi pieno. Rivedi gli impegni prima '
            'di pianificare altro.',
        'El calendario visible está casi lleno. Revisa los compromisos.',
        'Le calendrier visible est presque plein. Vérifiez vos rendez-vous.',
        'O calendário visível está quase cheio. Reveja seus compromissos.',
      ],
      'capacity': [
        'Free time in the visible calendar',
        'Tempo libero nel calendario visibile',
        'Tiempo libre en el calendario visible',
        'Temps libre dans le calendrier visible',
        'Tempo livre no calendário visível',
      ],
      'scope': [
        'Estimates exclude unscheduled tasks and unavailable calendars.',
        'Stima: esclusi task non pianificati e calendari non disponibili.',
        'Estimación: no incluye tareas sin horario ni otros calendarios.',
        'Estimation : hors tâches non planifiées et calendriers indisponibles.',
        'Estimativa: exclui tarefas sem horário e calendários indisponíveis.',
      ],
      'buffer': [
        'Keep free as buffer', 'Tieni libero come margine',
        'Reservar como margen', 'Garder comme marge',
        'Reservar como margem',
      ],
      'usable': [
        'Time left after buffer', 'Tempo dopo il margine',
        'Tiempo después del margen', 'Temps après la marge',
        'Tempo depois da margem',
      ],
      'slots': [
        'Review free times',
        'Controlla gli orari',
        'Revisar horarios',
        'Voir les créneaux',
        'Ver horários',
      ],
      'prepare': [
        'Prepare appointment',
        'Prepara appuntamento',
        'Preparar cita',
        'Préparer le rendez-vous',
        'Preparar compromisso',
      ],
      'taskTime': [
        'Recorded task duration', 'Durata registrata delle attività',
        'Duración registrada de las tareas', 'Durée enregistrée des tâches',
        'Duração registada das tarefas',
      ],
      'taskUnknown': [
        'Tasks with unknown duration', 'Attività senza durata nota',
        'Tareas sin duración conocida', 'Tâches sans durée connue',
        'Tarefas sem duração conhecida',
      ],
      'partial': [
        'Other calendars may be missing. Time is not guaranteed free.',
        'Altri calendari potrebbero mancare: il tempo non è certamente libero.',
        'Pueden faltar otros calendarios. El tiempo no está garantizado.',
        'D’autres agendas peuvent manquer : temps libre non garanti.',
        'Podem faltar outros calendários: tempo livre não garantido.',
      ],
      'nudge': [
        'Enable workload advice', 'Attiva consigli sul carico',
        'Activar consejos de carga', 'Activer les conseils de charge',
        'Ativar conselhos de carga',
      ],
      'snooze': [
        'Pause advice for 7 days', 'Sospendi consigli per 7 giorni',
        'Pausar consejos 7 días', 'Suspendre les conseils 7 jours',
        'Pausar conselhos 7 dias',
      ],
      'resume': [
        'Resume advice', 'Riattiva consigli',
        'Reanudar consejos', 'Reprendre les conseils',
        'Retomar conselhos',
      ],
      'dismiss': [
        'Hide for today',
        'Ignora per oggi',
        'Ocultar por hoy',
        'Masquer pour aujourd’hui',
        'Ocultar por hoje',
      ],
    };
    final index = switch (lang) {
      'it' => 1,
      'es' => 2,
      'fr' => 3,
      'pt' => 4,
      _ => 0,
    };
    return copy[key]![index];
  }

  @override
  Widget build(BuildContext context) {
    if (hideDetails) return const SizedBox.shrink();
    final strings = AnnaStrings.of(context);
    final now = DateTime.now();
    final external = ExternalCalendarService.instance;
    final day = snapshot.date;
    final externalReady = store.agendaContentFilter == AgendaContentFilter.all &&
        external.coversRange(
          DateTime(day.year, day.month, day.day - 1),
          DateTime(day.year, day.month, day.day + 2),
        );
    final advice = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [
        ...visibleEntriesForCalendarFreeSlots(
          store,
          day,
          externalReady: externalReady,
        ),
        // Coverage can be partial while Today already has authorized
        // current-day external events. Preserve those observed busy hours;
        // do not claim the unseen adjacent days are empty.
        if (!externalReady &&
            store.agendaContentFilter == AgendaContentFilter.all &&
            external.enabled &&
            external.permissionGranted)
          ...snapshot.agenda.where((entry) => entry.isExternal),
      ],
      pendingTasks: snapshot.pendingTaskCount,
      now: now,
      bufferMinutes: bufferMinutes,
    );
    final upcoming = upcomingPreparationItems(store, now);
    final prep = upcoming.isEmpty ? null : upcoming.first;
    if (snapshot.pendingTaskCount == 0 && prep == null) {
      return const SizedBox.shrink();
    }
    final hours = advice.freeMinutes ~/ 60;
    final minutes = advice.freeMinutes % 60;
    final usableHours = advice.usableMinutes ~/ 60;
    final usableMinutes = advice.usableMinutes % 60;
    final snoozeDate = DateTime.now();
    final todayKey = snoozeDate.year * 10000 +
        snoozeDate.month * 100 + snoozeDate.day;
    final snoozed = snoozedThrough >= todayKey;
    final advisePressure = nudgesEnabled && !snoozed && advice.hasPressure;
    return Card(
      key: const ValueKey('realistic-day-advice'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localized(strings.languageCode, 'title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              advisePressure
                  ? _localized(strings.languageCode, 'pressure')
                  : '${_localized(strings.languageCode, 'capacity')}: '
                      '${hours}h ${minutes}m',
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(_localized(strings.languageCode, 'buffer')),
                for (final choice in const [0, 15, 30, 60])
                  ChoiceChip(
                    key: ValueKey('day-buffer-$choice'),
                    label: Text('${choice}m'),
                    selected: bufferMinutes == choice,
                    onSelected: (_) => onSelectBuffer(choice),
                  ),
              ],
            ),
            Text(
              '${_localized(strings.languageCode, 'usable')}: '
              '${usableHours}h ${usableMinutes}m',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (advice.tasksWithRecordedTime > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${_localized(strings.languageCode, 'taskTime')}: '
                '${advice.recordedTaskMinutes}m '
                '(${advice.tasksWithRecordedTime})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (advice.tasksWithoutRecordedTime > 0)
              Text(
                '${_localized(strings.languageCode, 'taskUnknown')}: '
                '${advice.tasksWithoutRecordedTime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (store.agendaContentFilter == AgendaContentFilter.all &&
                external.enabled && !externalReady)
              Text(
                _localized(strings.languageCode, 'partial'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            SwitchListTile.adaptive(
              key: const ValueKey('realistic-day-nudge-optin'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: nudgesEnabled,
              onChanged: onSetNudges,
              title: Text(_localized(strings.languageCode, 'nudge')),
            ),
            if (nudgesEnabled)
              TextButton.icon(
                key: const ValueKey('realistic-day-nudge-snooze'),
                onPressed: () => onSetSnooze(!snoozed),
                icon: Icon(snoozed ? Icons.play_arrow_outlined : Icons.snooze),
                label: Text(_localized(
                  strings.languageCode, snoozed ? 'resume' : 'snooze')),
              ),
            const SizedBox(height: 4),
            Text(
              _localized(strings.languageCode, 'scope'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => showCalendarFreeSlots(
                    context,
                    store,
                    snapshot.date,
                  ),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(_localized(strings.languageCode, 'slots')),
                ),
                if (prep != null)
                  TextButton.icon(
                    onPressed: () => openEventPreparation(
                      context,
                      store,
                      prep,
                    ),
                    icon: const Icon(Icons.checklist_outlined),
                    label: Text(_localized(strings.languageCode, 'prepare')),
                  ),
                TextButton.icon(
                  key: const ValueKey('realistic-day-dismiss-today'),
                  onPressed: onDismiss,
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: Text(_localized(strings.languageCode, 'dismiss')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
