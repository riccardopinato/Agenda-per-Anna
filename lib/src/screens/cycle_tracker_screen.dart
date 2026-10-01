part of '../../main.dart';

class PrivateCycleTrackerScreen extends StatefulWidget {
  const PrivateCycleTrackerScreen({super.key});

  @override
  State<PrivateCycleTrackerScreen> createState() =>
      _PrivateCycleTrackerScreenState();
}

class _PrivateCycleTrackerScreenState extends State<PrivateCycleTrackerScreen> {
  static const _periodReminderId = 'vault-cycle-period-reminder';

  final vault = PrivateVaultService.instance;
  DateTime _selectedDay = cycleDateOnly(DateTime.now());
  DateTime _focusedDay = cycleDateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    vault.noteUserActivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && vault.unlocked) unawaited(_syncPeriodReminder());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vault,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        if (!vault.unlocked) {
          return Scaffold(
            appBar: AppBar(title: Text(strings.cycleTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      strings.vaultLocked,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.vaultLockedDescription,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.vaultOpen),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final state = vault.cycleTrackerState;
        final prediction = CycleTrackerEngine.predict(state);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => vault.noteUserActivity(),
          child: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                title: Text(strings.cycleTitle),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.favorite_outline),
                      text: strings.cycleOverview,
                    ),
                    Tab(
                      icon: const Icon(Icons.calendar_month_outlined),
                      text: strings.cycleCalendar,
                    ),
                    Tab(
                      icon: const Icon(Icons.history),
                      text: strings.cycleHistory,
                    ),
                    Tab(
                      icon: const Icon(Icons.tune),
                      text: strings.cycleSettings,
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _buildOverview(context, state, prediction),
                  _buildCalendar(context, state, prediction),
                  _buildHistory(context, state),
                  _buildSettings(context, state, prediction),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyBanner(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.cyclePrivacyBanner,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    CycleTrackerState state,
    CyclePrediction prediction,
  ) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final todayLog = state.logFor(DateTime.now());
    final next = prediction.nextPeriodStart;
    final nextLabel = next == null
        ? strings.cycleNoPrediction
        : DateFormat(
            'd MMMM',
            AnnaStrings.intlLocale(context),
          ).format(next);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        _buildPrivacyBanner(context),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer,
                scheme.tertiaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prediction.currentCycleDay == null
                    ? strings.cycleNoData
                    : strings.cycleDayNumber(prediction.currentCycleDay!),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _phaseLabel(strings, prediction.phase),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      context,
                      strings.cycleNextPeriod,
                      nextLabel,
                      Icons.event_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      context,
                      strings.cycleAverageLength,
                      strings.cycleDays(prediction.averageCycleLength),
                      Icons.autorenew,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _showDayEditor(cycleDateOnly(DateTime.now())),
          icon: const Icon(Icons.add_circle_outline),
          label: Text(
            todayLog == null
                ? strings.cycleLogToday
                : strings.cycleEditToday,
          ),
        ),
        const SizedBox(height: 12),
        if (todayLog != null)
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.check_circle_outline),
              ),
              title: Text(strings.cycleTodayRecorded),
              subtitle: Text(
                _todaySummary(strings, todayLog),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _showDayEditor(todayLog.date),
            ),
          ),
        if (state.settings.trackFertility &&
            prediction.fertileStart != null &&
            prediction.fertileEnd != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.eco_outlined),
              ),
              title: Text(strings.cycleFertileWindow),
              subtitle: Text(
                '${DateFormat('d MMM', AnnaStrings.intlLocale(context)).format(prediction.fertileStart!)}'
                ' – '
                '${DateFormat('d MMM', AnnaStrings.intlLocale(context)).format(prediction.fertileEnd!)}',
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          strings.cyclePredictionDisclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    CycleTrackerState state,
    CyclePrediction prediction,
  ) {
    final strings = AnnaStrings.of(context);
    final selectedLog = state.logFor(_selectedDay);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      children: [
        TableCalendar<Object>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = cycleDateOnly(selected);
              _focusedDay = cycleDateOnly(focused);
            });
          },
          onPageChanged: (focused) =>
              setState(() => _focusedDay = cycleDateOnly(focused)),
          eventLoader: (day) =>
              _calendarMarkers(state, prediction, cycleDateOnly(day)),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 3,
          ),
          calendarBuilders: CalendarBuilders<Object>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final event in events.take(3))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _markerColor(context, event.toString()),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                selectedLog == null
                    ? Icons.add_outlined
                    : Icons.edit_calendar_outlined,
              ),
            ),
            title: Text(
              DateFormat(
                'EEEE d MMMM',
                AnnaStrings.intlLocale(context),
              ).format(_selectedDay),
            ),
            subtitle: Text(
              selectedLog == null
                  ? strings.cycleNoLogForDay
                  : _todaySummary(strings, selectedLog),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDayEditor(_selectedDay),
          ),
        ),
        const SizedBox(height: 10),
        _buildCalendarLegend(context),
      ],
    );
  }

  List<Object> _calendarMarkers(
    CycleTrackerState state,
    CyclePrediction prediction,
    DateTime day,
  ) {
    final markers = <Object>[];
    final log = state.logFor(day);
    if (log != null && log.flow != CycleFlow.none) markers.add('period');
    if (state.settings.trackFertility && prediction.fertileContains(day)) {
      markers.add('fertile');
    }
    if (prediction.predictedPeriodContains(day) &&
        (log == null || log.flow == CycleFlow.none)) {
      markers.add('predicted');
    }
    return markers;
  }

  Color _markerColor(BuildContext context, String marker) {
    final scheme = Theme.of(context).colorScheme;
    return switch (marker) {
      'period' => scheme.primary,
      'fertile' => scheme.tertiary,
      _ => scheme.outline,
    };
  }

  Widget _buildCalendarLegend(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color color, String label) => Padding(
          padding: const EdgeInsets.only(right: 14, bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        );
    return Wrap(
      children: [
        item(scheme.primary, strings.cycleRecordedPeriod),
        item(scheme.outline, strings.cyclePredictedPeriod),
        item(scheme.tertiary, strings.cycleFertileWindow),
      ],
    );
  }

  Widget _buildHistory(BuildContext context, CycleTrackerState state) {
    final strings = AnnaStrings.of(context);
    final periods = CycleTrackerEngine.periods(state).reversed.toList();
    if (periods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off, size: 56),
              const SizedBox(height: 12),
              Text(
                strings.cycleNoHistory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                strings.cycleNoHistoryDescription,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final period = periods[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.water_drop_outlined),
            ),
            title: Text(
              DateFormat(
                'd MMM yyyy',
                AnnaStrings.intlLocale(context),
              ).format(period.start),
            ),
            subtitle: Text(
              [
                strings.cyclePeriodLength(period.periodLength),
                if (period.cycleLength != null)
                  strings.cycleCycleLength(period.cycleLength!),
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettings(
    BuildContext context,
    CycleTrackerState state,
    CyclePrediction prediction,
  ) {
    final strings = AnnaStrings.of(context);
    final settings = state.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        _buildPrivacyBanner(context),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(strings.cycleAverageLength),
                subtitle: Text(strings.cycleDays(settings.averageCycleLength)),
                trailing: SizedBox(
                  width: 160,
                  child: Slider(
                    min: 21,
                    max: 40,
                    divisions: 19,
                    value: settings.averageCycleLength.clamp(21, 40).toDouble(),
                    onChanged: (value) => _saveSettings(
                      settings.copyWith(averageCycleLength: value.round()),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: Text(strings.cycleAveragePeriodLength),
                subtitle: Text(strings.cycleDays(settings.averagePeriodLength)),
                trailing: SizedBox(
                  width: 160,
                  child: Slider(
                    min: 2,
                    max: 10,
                    divisions: 8,
                    value:
                        settings.averagePeriodLength.clamp(2, 10).toDouble(),
                    onChanged: (value) => _saveSettings(
                      settings.copyWith(averagePeriodLength: value.round()),
                    ),
                  ),
                ),
              ),
              SwitchListTile(
                value: settings.trackFertility,
                onChanged: (value) => _saveSettings(
                  settings.copyWith(trackFertility: value),
                ),
                title: Text(strings.cycleTrackFertility),
                subtitle: Text(strings.cycleFertilityEstimateOnly),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: settings.periodReminderEnabled,
                onChanged: (value) async {
                  await _saveSettings(
                    settings.copyWith(periodReminderEnabled: value),
                  );
                  await _syncPeriodReminder();
                },
                title: Text(strings.cyclePeriodReminder),
                subtitle: Text(strings.cyclePeriodReminderDescription),
              ),
              SwitchListTile(
                value: settings.discreetNotifications,
                onChanged: (value) async {
                  await _saveSettings(
                    settings.copyWith(discreetNotifications: value),
                  );
                  await _syncPeriodReminder();
                },
                title: Text(strings.cycleDiscreetNotifications),
                subtitle: Text(strings.cycleDiscreetNotificationsDescription),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.cyclePredictionDisclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _saveSettings(CycleSettings settings) async {
    if (!vault.unlocked) return;
    await vault.updateCycleSettings(settings);
  }

  Future<void> _syncPeriodReminder() async {
    if (!vault.unlocked) return;
    final state = vault.cycleTrackerState;
    final settings = state.settings;
    if (!settings.periodReminderEnabled) {
      await NotificationService.instance.cancel(_periodReminderId);
      return;
    }
    final prediction = CycleTrackerEngine.predict(state);
    final next = prediction.nextPeriodStart;
    if (next == null) {
      await NotificationService.instance.cancel(_periodReminderId);
      return;
    }
    final when = DateTime(
      next.year,
      next.month,
      next.day,
      9,
    ).subtract(Duration(days: settings.periodReminderDaysBefore));
    final strings = AnnaStrings.of(context);
    await NotificationService.instance.schedule(
      stableId: _periodReminderId,
      title: settings.discreetNotifications
          ? 'Anna\'s Diary'
          : strings.cycleTitle,
      body: settings.discreetNotifications
          ? strings.cyclePrivateReminder
          : strings.cyclePeriodReminderBody,
      when: when,
    );
  }

  Future<void> _showDayEditor(DateTime date) async {
    if (!vault.unlocked) return;
    final strings = AnnaStrings.of(context);
    final existing = vault.cycleTrackerState.logFor(date);
    var flow = existing?.flow ?? CycleFlow.none;
    var pain = existing?.painLevel ?? 0;
    var energy = existing?.energyLevel ?? 3;
    final symptoms = <String>{...?existing?.symptoms};
    final moods = <String>{...?existing?.moods};
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'EEEE d MMMM',
                      AnnaStrings.intlLocale(context),
                    ).format(date),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<CycleFlow>(
                    initialValue: flow,
                    decoration: InputDecoration(labelText: strings.cycleFlow),
                    items: [
                      for (final value in CycleFlow.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(_flowLabel(strings, value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => flow = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('${strings.cyclePain}: $pain/5'),
                  Slider(
                    value: pain.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: '$pain',
                    onChanged: (value) =>
                        setSheetState(() => pain = value.round()),
                  ),
                  Text('${strings.cycleEnergy}: $energy/5'),
                  Slider(
                    value: energy.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: '$energy',
                    onChanged: (value) =>
                        setSheetState(() => energy = value.round()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.cycleSymptoms,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final symptom in const [
                        'cramps',
                        'bloating',
                        'headache',
                        'breast',
                        'fatigue',
                        'acne',
                        'nausea',
                        'backPain',
                      ])
                        FilterChip(
                          label: Text(_symptomLabel(strings, symptom)),
                          selected: symptoms.contains(symptom),
                          onSelected: (selected) => setSheetState(() {
                            selected
                                ? symptoms.add(symptom)
                                : symptoms.remove(symptom);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.cycleMood,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final mood in const [
                        'calm',
                        'happy',
                        'sensitive',
                        'irritable',
                        'sad',
                        'anxious',
                        'energetic',
                      ])
                        FilterChip(
                          label: Text(_moodLabel(strings, mood)),
                          selected: moods.contains(mood),
                          onSelected: (selected) => setSheetState(() {
                            selected ? moods.add(mood) : moods.remove(mood);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: strings.cycleNotes,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (existing != null)
                        TextButton.icon(
                          onPressed: () async {
                            await vault.deleteCycleDayLog(date);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext, true);
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text(strings.delete),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          await vault.upsertCycleDayLog(
                            CycleDayLog(
                              date: date,
                              flow: flow,
                              painLevel: pain,
                              energyLevel: energy,
                              symptoms: symptoms.toList(growable: false),
                              moods: moods.toList(growable: false),
                              notes: notesController.text,
                              createdAt: existing?.createdAt ?? now,
                              updatedAt: now,
                            ),
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, true);
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: Text(strings.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    notesController.dispose();
    if (saved == true && mounted && vault.unlocked) {
      await _syncPeriodReminder();
    }
  }

  String _todaySummary(AnnaStrings strings, CycleDayLog log) {
    final parts = <String>[
      if (log.flow != CycleFlow.none) _flowLabel(strings, log.flow),
      if (log.painLevel > 0) '${strings.cyclePain} ${log.painLevel}/5',
      if (log.symptoms.isNotEmpty)
        log.symptoms.map((value) => _symptomLabel(strings, value)).join(', '),
    ];
    return parts.isEmpty ? strings.cycleDaySaved : parts.join(' · ');
  }

  String _phaseLabel(AnnaStrings strings, CyclePhase phase) => switch (phase) {
        CyclePhase.period => strings.cyclePhasePeriod,
        CyclePhase.follicular => strings.cyclePhaseFollicular,
        CyclePhase.fertile => strings.cyclePhaseFertile,
        CyclePhase.ovulation => strings.cyclePhaseOvulation,
        CyclePhase.luteal => strings.cyclePhaseLuteal,
        CyclePhase.unknown => strings.cyclePhaseUnknown,
      };

  String _flowLabel(AnnaStrings strings, CycleFlow flow) => switch (flow) {
        CycleFlow.none => strings.cycleFlowNone,
        CycleFlow.spotting => strings.cycleFlowSpotting,
        CycleFlow.light => strings.cycleFlowLight,
        CycleFlow.medium => strings.cycleFlowMedium,
        CycleFlow.heavy => strings.cycleFlowHeavy,
      };

  String _symptomLabel(AnnaStrings strings, String value) => switch (value) {
        'cramps' => strings.cycleSymptomCramps,
        'bloating' => strings.cycleSymptomBloating,
        'headache' => strings.cycleSymptomHeadache,
        'breast' => strings.cycleSymptomBreast,
        'fatigue' => strings.cycleSymptomFatigue,
        'acne' => strings.cycleSymptomAcne,
        'nausea' => strings.cycleSymptomNausea,
        'backPain' => strings.cycleSymptomBackPain,
        _ => value,
      };

  String _moodLabel(AnnaStrings strings, String value) => switch (value) {
        'calm' => strings.cycleMoodCalm,
        'happy' => strings.cycleMoodHappy,
        'sensitive' => strings.cycleMoodSensitive,
        'irritable' => strings.cycleMoodIrritable,
        'sad' => strings.cycleMoodSad,
        'anxious' => strings.cycleMoodAnxious,
        'energetic' => strings.cycleMoodEnergetic,
        _ => value,
      };
}
