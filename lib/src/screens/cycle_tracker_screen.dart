part of '../../main.dart';

class PrivateCycleTrackerScreen extends StatefulWidget {
  const PrivateCycleTrackerScreen({super.key});

  @override
  State<PrivateCycleTrackerScreen> createState() =>
      _PrivateCycleTrackerScreenState();
}

class _PrivateCycleTrackerScreenState extends State<PrivateCycleTrackerScreen> {
  static const _periodReminderId = 'vault-cycle-period-reminder';
  static const _dailyLogReminderId = 'vault-cycle-daily-log-reminder';
  static const _contraceptiveReminderId = 'vault-cycle-contraceptive-reminder';

  final vault = PrivateVaultService.instance;
  final premium = PremiumEntitlementService.instance;
  DateTime _selectedDay = cycleDateOnly(DateTime.now());
  DateTime _focusedDay = cycleDateOnly(DateTime.now());
  bool _onboardingPrompted = false;

  @override
  void initState() {
    super.initState();
    vault.noteUserActivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !vault.unlocked) return;
      unawaited(_syncCycleReminders());
      unawaited(_maybeShowOnboarding());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([vault, premium]),
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
            length: 5,
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
                      icon: const Icon(Icons.insights_outlined),
                      text: strings.cycleInsights,
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
                  _buildInsights(context, state, prediction),
                  _buildSettings(context, state, prediction),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _maybeShowOnboarding() async {
    if (_onboardingPrompted || !mounted || !vault.unlocked) return;
    _onboardingPrompted = true;

    final state = vault.cycleTrackerState;
    if (state.settings.onboardingComplete) return;
    if (CycleTrackerEngine.periods(state).isNotEmpty) {
      await vault.updateCycleSettings(
        state.settings.copyWith(onboardingComplete: true),
      );
      return;
    }

    final strings = AnnaStrings.of(context);
    var lastPeriodStart =
        cycleDateOnly(DateTime.now().subtract(const Duration(days: 28)));
    var cycleLength = state.settings.averageCycleLength.clamp(21, 40).toInt();
    var periodLength = state.settings.averagePeriodLength.clamp(2, 10).toInt();
    var regularity = state.settings.regularityMode;
    var trackFertility = state.settings.trackFertility;
    var periodReminder = state.settings.periodReminderEnabled;
    var dailyReminder = state.settings.dailyLogReminderEnabled;

    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.cycleOnboardingTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(strings.cycleOnboardingDescription),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(strings.cycleLastPeriodStart),
                  subtitle: Text(
                    DateFormat(
                      'd MMMM yyyy',
                      AnnaStrings.intlLocale(context),
                    ).format(lastPeriodStart),
                  ),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: lastPeriodStart,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365 * 3),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(
                        () => lastPeriodStart = cycleDateOnly(picked),
                      );
                    }
                  },
                ),
                Text(strings.cycleAverageLength),
                Slider(
                  min: 21,
                  max: 40,
                  divisions: 19,
                  value: cycleLength.toDouble(),
                  label: strings.cycleDays(cycleLength),
                  onChanged: (value) =>
                      setSheetState(() => cycleLength = value.round()),
                ),
                Text(strings.cycleAveragePeriodLength),
                Slider(
                  min: 2,
                  max: 10,
                  divisions: 8,
                  value: periodLength.toDouble(),
                  label: strings.cycleDays(periodLength),
                  onChanged: (value) =>
                      setSheetState(() => periodLength = value.round()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: regularity,
                  decoration: InputDecoration(
                    labelText: strings.cycleRegularity,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'unknown',
                      child: Text(strings.cycleRegularityUnknown),
                    ),
                    DropdownMenuItem(
                      value: 'regular',
                      child: Text(strings.cycleRegularityRegular),
                    ),
                    DropdownMenuItem(
                      value: 'irregular',
                      child: Text(strings.cycleRegularityIrregular),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => regularity = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: trackFertility,
                  onChanged: (value) =>
                      setSheetState(() => trackFertility = value),
                  title: Text(strings.cycleTrackFertility),
                  subtitle: Text(strings.cycleFertilityEstimateOnly),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: periodReminder,
                  onChanged: (value) =>
                      setSheetState(() => periodReminder = value),
                  title: Text(strings.cyclePeriodReminder),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: dailyReminder,
                  onChanged: (value) =>
                      setSheetState(() => dailyReminder = value),
                  title: Text(strings.cycleDailyLogReminder),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(strings.cycleOnboardingStart),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(strings.cycleOnboardingSkip),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted || !vault.unlocked) return;
    final settings = state.settings.copyWith(
      onboardingComplete: true,
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
      regularityMode: regularity,
      trackFertility: trackFertility,
      periodReminderEnabled: periodReminder,
      dailyLogReminderEnabled: dailyReminder,
    );
    await vault.updateCycleSettings(settings);

    if (completed == true) {
      await _markPeriodRange(
        start: lastPeriodStart,
        end: lastPeriodStart.add(Duration(days: periodLength - 1)),
      );
    }
    if (mounted && vault.unlocked) {
      await _syncCycleReminders();
    }
  }

  Future<void> _markPeriodRange({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!vault.unlocked) return;
    var from = cycleDateOnly(start);
    var to = cycleDateOnly(end);
    if (to.isBefore(from)) {
      final swap = from;
      from = to;
      to = swap;
    }
    if (to.difference(from).inDays > 13) {
      to = from.add(const Duration(days: 13));
    }

    final state = vault.cycleTrackerState;
    final now = DateTime.now();
    final logs = <CycleDayLog>[];
    for (var date = from;
        !date.isAfter(to);
        date = date.add(const Duration(days: 1))) {
      final existing = state.logFor(date);
      logs.add(
        CycleDayLog(
          date: date,
          flow: isSameDay(date, from)
              ? CycleFlow.medium
              : CycleFlow.light,
          painLevel: existing?.painLevel ?? 0,
          energyLevel: existing?.energyLevel ?? 3,
          symptoms: existing?.symptoms ?? const [],
          moods: existing?.moods ?? const [],
          discharge: existing?.discharge ?? '',
          hadSex: existing?.hadSex ?? false,
          basalTemperature: existing?.basalTemperature,
          ovulationTest: existing?.ovulationTest ?? '',
          notes: existing?.notes ?? '',
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
    await vault.upsertCycleDayLogs(logs);
  }

  Future<void> _showQuickPeriodRange() async {
    if (!vault.unlocked) return;
    final strings = AnnaStrings.of(context);
    var start = cycleDateOnly(DateTime.now());
    var end = start;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.cycleQuickPeriodTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.cyclePeriodStart),
                subtitle: Text(
                  DateFormat(
                    'd MMM yyyy',
                    AnnaStrings.intlLocale(context),
                  ).format(start),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365 * 3),
                    ),
                    lastDate: DateTime.now().add(
                      const Duration(days: 30),
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      start = cycleDateOnly(picked);
                      if (end.isBefore(start)) end = start;
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.cyclePeriodEnd),
                subtitle: Text(
                  DateFormat(
                    'd MMM yyyy',
                    AnnaStrings.intlLocale(context),
                  ).format(end),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: end,
                    firstDate: start,
                    lastDate: start.add(const Duration(days: 13)),
                  );
                  if (picked != null) {
                    setDialogState(() => end = cycleDateOnly(picked));
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                strings.cycleQuickPeriodDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted || !vault.unlocked) return;
    await _markPeriodRange(start: start, end: end);
    if (mounted && vault.unlocked) await _syncCycleReminders();
  }

  Widget _buildPrivacyBanner(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: strings.cyclePrivacyBanner,
      child: Container(
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
    final locale = AnnaStrings.intlLocale(context);
    final nextLabel = next == null
        ? strings.cycleNoPrediction
        : prediction.periodWindowStart != null &&
                prediction.periodWindowEnd != null
            ? '${DateFormat('d MMM', locale).format(prediction.periodWindowStart!)}'
                ' – '
                '${DateFormat('d MMM', locale).format(prediction.periodWindowEnd!)}'
            : DateFormat('d MMMM', locale).format(next);

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
              const SizedBox(height: 8),
              Semantics(
                label: strings.cyclePredictionConfidenceLabel(
                  _confidenceLabel(strings, prediction.confidence),
                ),
                child: Chip(
                  avatar: const Icon(Icons.analytics_outlined, size: 18),
                  label: Text(
                    strings.cyclePredictionConfidenceLabel(
                      _confidenceLabel(strings, prediction.confidence),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _responsivePair(
                context,
                _metricCard(
                  context,
                  strings.cycleNextPeriod,
                  nextLabel,
                  Icons.event_outlined,
                ),
                _metricCard(
                  context,
                  strings.cycleAverageLength,
                  strings.cycleDays(prediction.averageCycleLength),
                  Icons.autorenew,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showDayEditor(
                  cycleDateOnly(DateTime.now()),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  todayLog == null
                      ? strings.cycleLogToday
                      : strings.cycleEditToday,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showQuickPeriodRange,
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(strings.cycleQuickPeriodAction),
              ),
            ),
          ],
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

  Widget _responsivePair(
    BuildContext context,
    Widget first,
    Widget second,
  ) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final stack = scale >= 1.3 || MediaQuery.sizeOf(context).width < 380;
    if (stack) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: first),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: second),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
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
    return Semantics(
      container: true,
      label: '$title: $value',
      child: Container(
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
            markersMaxCount: 5,
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
    if (state.settings.trackFertility &&
        prediction.ovulationDate != null &&
        isSameDay(day, prediction.ovulationDate)) {
      markers.add('ovulation');
    }
    if (prediction.predictedPeriodContains(day) &&
        (log == null || log.flow == CycleFlow.none)) {
      markers.add('predicted');
    }
    if (log != null &&
        (log.symptoms.isNotEmpty ||
            log.moods.isNotEmpty ||
            log.painLevel > 0 ||
            log.notes.trim().isNotEmpty)) {
      markers.add('symptom');
    }
    return markers;
  }

  Color _markerColor(BuildContext context, String marker) {
    final scheme = Theme.of(context).colorScheme;
    return switch (marker) {
      'period' => scheme.primary,
      'fertile' => scheme.tertiary,
      'ovulation' => scheme.secondary,
      'symptom' => scheme.error,
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
        item(scheme.secondary, strings.cycleEstimatedOvulation),
        item(scheme.error, strings.cycleSymptomsOrNotes),
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

  Widget _buildPremiumPreviewBanner(BuildContext context) {
    if (!premium.previewMode) return const SizedBox.shrink();
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.cyclePremiumPreviewDescription,
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(
    BuildContext context,
    CycleTrackerState state,
    CyclePrediction prediction,
  ) {
    final strings = AnnaStrings.of(context);
    if (!premium.allows(PremiumCapability.cycleInsights)) {
      return _buildPremiumLocked(context, strings.cycleInsights);
    }

    final insights = CyclePremiumAnalytics.insights(state);
    final periods = CycleTrackerEngine.periods(state);
    final recentLengths = periods
        .where((period) => period.cycleLength != null)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .toList();
    final locale = AnnaStrings.intlLocale(context);
    final range = insights.estimatedWindowStart == null ||
            insights.estimatedWindowEnd == null
        ? strings.cycleNoPrediction
        : '${DateFormat('d MMM', locale).format(insights.estimatedWindowStart!)}'
            ' – '
            '${DateFormat('d MMM', locale).format(insights.estimatedWindowEnd!)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        _buildPremiumPreviewBanner(context),
        if (premium.previewMode) const SizedBox(height: 14),
        Text(
          strings.cycleInsightsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        _responsivePair(
          context,
          _metricCard(
            context,
            strings.cycleLoggedDays,
            '${insights.loggedDays}',
            Icons.event_available_outlined,
          ),
          _metricCard(
            context,
            strings.cycleRecordedCycles,
            '${insights.periodCount}',
            Icons.loop_outlined,
          ),
        ),
        const SizedBox(height: 10),
        _responsivePair(
          context,
          _metricCard(
            context,
            strings.cycleEstimatedWindow,
            range,
            Icons.date_range_outlined,
          ),
          _metricCard(
            context,
            strings.cycleVariability,
            insights.shortestCycle == null
                ? '—'
                : strings.cycleRangeDays(
                    insights.shortestCycle!,
                    insights.longestCycle!,
                  ),
            Icons.multiline_chart_outlined,
          ),
        ),
        const SizedBox(height: 14),
        if (recentLengths.isNotEmpty) ...[
          _buildTrendCard(
            context,
            title: strings.cycleLengthTrend,
            entries: [
              for (var index = 0; index < recentLengths.length; index++)
                MapEntry(
                  DateFormat(
                    'MMM',
                    locale,
                  ).format(recentLengths[index].start),
                  recentLengths[index].cycleLength!.toDouble(),
                ),
            ],
            valueLabel: (value) => strings.cycleDays(value.round()),
          ),
          const SizedBox(height: 12),
        ],
        if (insights.topSymptoms.isNotEmpty) ...[
          _buildTrendCard(
            context,
            title: strings.cycleTopSymptomsChart,
            entries: [
              for (final item in insights.topSymptoms)
                MapEntry(
                  _symptomLabel(strings, item.key),
                  item.count.toDouble(),
                ),
            ],
            valueLabel: (value) => '${value.round()}',
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.cycleSymptomPatterns,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (insights.symptomPatterns.isEmpty)
                  Text(strings.cycleNotEnoughInsightData)
                else
                  for (final item in insights.symptomPatterns) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.bubble_chart_outlined),
                      title: Text(_symptomLabel(strings, item.key)),
                      subtitle: Text(
                        strings.cycleSymptomPatternDetail(
                          item.totalCount,
                          item.periodCount,
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.cycleFertilityObservations,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _insightRow(
                  context,
                  Icons.device_thermostat_outlined,
                  strings.cycleBasalTemperature,
                  '${insights.basalTemperatureEntries}',
                ),
                _insightRow(
                  context,
                  Icons.science_outlined,
                  strings.cycleOvulationTests,
                  '${insights.positiveOvulationTests}',
                ),
                _insightRow(
                  context,
                  Icons.water_drop_outlined,
                  strings.cycleCervicalMucus,
                  '${insights.cervicalMucusEntries}',
                ),
                _insightRow(
                  context,
                  Icons.favorite_border,
                  strings.cycleSexualActivity,
                  '${insights.sexualActivityEntries}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: premium.allows(PremiumCapability.cyclePrivateReport)
              ? () => _copyPrivateReport(state, prediction, insights)
              : null,
          icon: const Icon(Icons.copy_all_outlined),
          label: Text(strings.cycleCopyPrivateReport),
        ),
        const SizedBox(height: 10),
        Text(
          strings.cycleInsightsDisclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTrendCard(
    BuildContext context, {
    required String title,
    required List<MapEntry<String, double>> entries,
    required String Function(double value) valueLabel,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = entries.fold<double>(
      0,
      (current, entry) => max(current, entry.value),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final entry in entries) ...[
              Semantics(
                label: '${entry.key}: ${valueLabel(entry.value)}',
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: maxValue <= 0
                              ? 0
                              : (entry.value / maxValue).clamp(0, 1),
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 56,
                      child: Text(
                        valueLabel(entry.value),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }

  Widget _insightRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );

  Widget _buildPremiumLocked(BuildContext context, String feature) {
    final strings = AnnaStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 58),
            const SizedBox(height: 12),
            Text(
              strings.cyclePremiumFeature,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              strings.cyclePremiumFeatureDescription(feature),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PremiumScreen(),
                ),
              ),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(strings.premiumTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTrackingSettings(
    BuildContext context,
    CycleSettings settings,
  ) {
    final strings = AnnaStrings.of(context);
    if (!premium.allows(PremiumCapability.cycleAdvancedTracking)) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: Text(strings.cycleAdvancedTracking),
          subtitle: Text(strings.cyclePremiumFeatureDescription(
            strings.cycleAdvancedTracking,
          )),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const PremiumScreen(),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(strings.cycleAdvancedTracking),
            subtitle: premium.previewMode
                ? Text(strings.cyclePremiumPreviewShort)
                : null,
          ),
          SwitchListTile(
            value: settings.trackBasalTemperature,
            onChanged: (value) => _saveSettings(
              settings.copyWith(trackBasalTemperature: value),
            ),
            title: Text(strings.cycleBasalTemperature),
          ),
          SwitchListTile(
            value: settings.trackCervicalMucus,
            onChanged: (value) => _saveSettings(
              settings.copyWith(trackCervicalMucus: value),
            ),
            title: Text(strings.cycleCervicalMucus),
          ),
          SwitchListTile(
            value: settings.trackSexualActivity,
            onChanged: (value) => _saveSettings(
              settings.copyWith(trackSexualActivity: value),
            ),
            title: Text(strings.cycleSexualActivity),
          ),
          if (premium.allows(PremiumCapability.cycleCustomSymptoms)) ...[
            const Divider(height: 1),
            ListTile(
              title: Text(strings.cycleCustomSymptoms),
              subtitle: Text(strings.cycleCustomSymptomsDescription),
              trailing: IconButton(
                tooltip: strings.add,
                onPressed: () => _addCustomSymptom(settings),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
            if (settings.customSymptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final symptom in settings.customSymptoms)
                        InputChip(
                          label: Text(symptom),
                          onDeleted: () {
                            final next = settings.customSymptoms
                                .where((value) => value != symptom)
                                .toList(growable: false);
                            unawaited(_saveSettings(
                              settings.copyWith(customSymptoms: next),
                            ));
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _addCustomSymptom(CycleSettings settings) async {
    final strings = AnnaStrings.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.cycleAddCustomSymptom),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            labelText: strings.cycleCustomSymptomName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(strings.add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    await _saveSettings(
      settings.copyWith(
        customSymptoms: [...settings.customSymptoms, value],
      ),
    );
  }

  Future<void> _copyPrivateReport(
    CycleTrackerState state,
    CyclePrediction prediction,
    CycleInsightSummary insights,
  ) async {
    final strings = AnnaStrings.of(context);
    final locale = AnnaStrings.intlLocale(context);
    String date(DateTime? value) =>
        value == null ? '—' : DateFormat('d MMM yyyy', locale).format(value);

    final lines = <String>[
      strings.cyclePrivateReportTitle,
      '',
      '${strings.cycleRecordedCycles}: ${insights.periodCount}',
      '${strings.cycleLoggedDays}: ${insights.loggedDays}',
      '${strings.cycleAverageLength}: ${prediction.averageCycleLength}',
      '${strings.cycleAveragePeriodLength}: ${prediction.averagePeriodLength}',
      '${strings.cycleNextPeriod}: ${date(prediction.nextPeriodStart)}',
      if (insights.estimatedWindowStart != null &&
          insights.estimatedWindowEnd != null)
        '${strings.cycleEstimatedWindow}: '
            '${date(insights.estimatedWindowStart)} – '
            '${date(insights.estimatedWindowEnd)}',
      '',
      strings.cycleSymptomPatterns,
      if (insights.symptomPatterns.isEmpty)
        strings.cycleNotEnoughInsightData
      else
        for (final item in insights.symptomPatterns)
          '- ${_symptomLabel(strings, item.key)}: '
              '${strings.cycleSymptomPatternDetail(item.totalCount, item.periodCount)}',
      '',
      strings.cycleInsightsDisclaimer,
    ];

    final report = lines.join('\n');
    await Clipboard.setData(ClipboardData(text: report));
    Timer(const Duration(seconds: 60), () async {
      try {
        final current = await Clipboard.getData('text/plain');
        if (current?.text == report) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {}
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.cyclePrivateReportCopied)),
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
              ListTile(
                title: Text(strings.cycleRegularity),
                trailing: DropdownButton<String>(
                  value: settings.regularityMode,
                  items: [
                    DropdownMenuItem(
                      value: 'unknown',
                      child: Text(strings.cycleRegularityUnknown),
                    ),
                    DropdownMenuItem(
                      value: 'regular',
                      child: Text(strings.cycleRegularityRegular),
                    ),
                    DropdownMenuItem(
                      value: 'irregular',
                      child: Text(strings.cycleRegularityIrregular),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(
                        _saveSettings(
                          settings.copyWith(regularityMode: value),
                        ),
                      );
                    }
                  },
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
        _buildAdvancedTrackingSettings(context, settings),
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
                  await _syncCycleReminders();
                },
                title: Text(strings.cyclePeriodReminder),
                subtitle: Text(strings.cyclePeriodReminderDescription),
              ),
              SwitchListTile(
                value: settings.dailyLogReminderEnabled,
                onChanged: (value) async {
                  await _saveSettings(
                    settings.copyWith(dailyLogReminderEnabled: value),
                  );
                  await _syncCycleReminders();
                },
                title: Text(strings.cycleDailyLogReminder),
                subtitle: Text(strings.cycleDailyLogReminderDescription),
              ),
              if (settings.dailyLogReminderEnabled)
                ListTile(
                  title: Text(strings.cycleReminderTime),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay(
                        hour: settings.dailyLogReminderHour,
                        minute: settings.dailyLogReminderMinute,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap: () => _pickDailyReminderTime(settings),
                ),
              SwitchListTile(
                value: settings.contraceptiveReminderEnabled,
                onChanged: (value) async {
                  await _saveSettings(
                    settings.copyWith(
                      contraceptiveReminderEnabled: value,
                    ),
                  );
                  await _syncCycleReminders();
                },
                title: Text(strings.cycleContraceptiveReminder),
                subtitle: Text(
                  strings.cycleContraceptiveReminderDescription,
                ),
              ),
              if (settings.contraceptiveReminderEnabled)
                ListTile(
                  title: Text(strings.cycleReminderTime),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay(
                        hour: settings.contraceptiveReminderHour,
                        minute: settings.contraceptiveReminderMinute,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap: () => _pickContraceptiveReminderTime(settings),
                ),
              SwitchListTile(
                value: settings.discreetNotifications,
                onChanged: (value) async {
                  await _saveSettings(
                    settings.copyWith(discreetNotifications: value),
                  );
                  await _syncCycleReminders();
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

  Future<void> _syncCycleReminders() async {
    if (!mounted || !vault.unlocked) return;
    await _syncPeriodReminder();
    if (!mounted || !vault.unlocked) return;
    await _syncDailyLogReminder();
    if (!mounted || !vault.unlocked) return;
    await _syncContraceptiveReminder();
  }

  Future<void> _syncPeriodReminder() async {
    if (!mounted || !vault.unlocked) return;
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

  Future<void> _syncDailyLogReminder() async {
    if (!mounted || !vault.unlocked) return;
    final settings = vault.cycleTrackerState.settings;
    if (!settings.dailyLogReminderEnabled) {
      await NotificationService.instance.cancel(_dailyLogReminderId);
      return;
    }
    final strings = AnnaStrings.of(context);
    await NotificationService.instance.scheduleDaily(
      stableId: _dailyLogReminderId,
      title: settings.discreetNotifications
          ? 'Anna\'s Diary'
          : strings.cycleTitle,
      body: settings.discreetNotifications
          ? strings.cyclePrivateReminder
          : strings.cycleDailyLogReminderBody,
      hour: settings.dailyLogReminderHour,
      minute: settings.dailyLogReminderMinute,
    );
  }

  Future<void> _syncContraceptiveReminder() async {
    if (!mounted || !vault.unlocked) return;
    final settings = vault.cycleTrackerState.settings;
    if (!settings.contraceptiveReminderEnabled) {
      await NotificationService.instance.cancel(_contraceptiveReminderId);
      return;
    }
    final strings = AnnaStrings.of(context);
    await NotificationService.instance.scheduleDaily(
      stableId: _contraceptiveReminderId,
      title: settings.discreetNotifications
          ? 'Anna\'s Diary'
          : strings.cycleTitle,
      body: settings.discreetNotifications
          ? strings.cyclePrivateReminder
          : strings.cycleContraceptiveReminderBody,
      hour: settings.contraceptiveReminderHour,
      minute: settings.contraceptiveReminderMinute,
    );
  }

  Future<void> _pickDailyReminderTime(CycleSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.dailyLogReminderHour,
        minute: settings.dailyLogReminderMinute,
      ),
    );
    if (picked == null || !mounted || !vault.unlocked) return;
    await _saveSettings(
      settings.copyWith(
        dailyLogReminderHour: picked.hour,
        dailyLogReminderMinute: picked.minute,
      ),
    );
    if (mounted && vault.unlocked) await _syncCycleReminders();
  }

  Future<void> _pickContraceptiveReminderTime(
    CycleSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.contraceptiveReminderHour,
        minute: settings.contraceptiveReminderMinute,
      ),
    );
    if (picked == null || !mounted || !vault.unlocked) return;
    await _saveSettings(
      settings.copyWith(
        contraceptiveReminderHour: picked.hour,
        contraceptiveReminderMinute: picked.minute,
      ),
    );
    if (mounted && vault.unlocked) await _syncCycleReminders();
  }

  Future<void> _showDayEditor(DateTime date) async {
    if (!vault.unlocked) return;
    final strings = AnnaStrings.of(context);
    final state = vault.cycleTrackerState;
    final settings = state.settings;
    final existing = state.logFor(date);
    final advancedAccess =
        premium.allows(PremiumCapability.cycleAdvancedTracking);
    var flow = existing?.flow ?? CycleFlow.none;
    var pain = existing?.painLevel ?? 0;
    var energy = existing?.energyLevel ?? 3;
    var discharge = existing?.discharge ?? '';
    var hadSex = existing?.hadSex ?? false;
    var ovulationTest = existing?.ovulationTest ?? '';
    final symptoms = <String>{...?existing?.symptoms};
    final moods = <String>{...?existing?.moods};
    final basalTemperatureController = TextEditingController(
      text: existing?.basalTemperature?.toStringAsFixed(2) ?? '',
    );
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
                  if (premium.allows(PremiumCapability.cycleCustomSymptoms) &&
                      settings.customSymptoms.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      strings.cycleCustomSymptoms,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final custom in settings.customSymptoms)
                          FilterChip(
                            label: Text(custom),
                            selected: symptoms.contains('custom:$custom'),
                            onSelected: (selected) => setSheetState(() {
                              final key = 'custom:$custom';
                              selected
                                  ? symptoms.add(key)
                                  : symptoms.remove(key);
                            }),
                          ),
                      ],
                    ),
                  ],
                  if (advancedAccess &&
                      (settings.trackBasalTemperature ||
                          settings.trackCervicalMucus ||
                          settings.trackSexualActivity ||
                          settings.trackFertility)) ...[
                    const SizedBox(height: 18),
                    Text(
                      strings.cycleAdvancedDailyTracking,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    if (settings.trackBasalTemperature)
                      TextField(
                        controller: basalTemperatureController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: strings.cycleBasalTemperature,
                          suffixText: '°C',
                        ),
                      ),
                    if (settings.trackBasalTemperature)
                      const SizedBox(height: 12),
                    if (settings.trackCervicalMucus)
                      DropdownButtonFormField<String>(
                        initialValue: discharge.isEmpty ? '' : discharge,
                        decoration: InputDecoration(
                          labelText: strings.cycleCervicalMucus,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(strings.cycleObservationNone),
                          ),
                          for (final value in const [
                            'dry',
                            'sticky',
                            'creamy',
                            'watery',
                            'eggWhite',
                          ])
                            DropdownMenuItem(
                              value: value,
                              child: Text(_dischargeLabel(strings, value)),
                            ),
                        ],
                        onChanged: (value) =>
                            setSheetState(() => discharge = value ?? ''),
                      ),
                    if (settings.trackCervicalMucus)
                      const SizedBox(height: 12),
                    if (settings.trackFertility)
                      DropdownButtonFormField<String>(
                        initialValue:
                            ovulationTest.isEmpty ? '' : ovulationTest,
                        decoration: InputDecoration(
                          labelText: strings.cycleOvulationTest,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(strings.cycleObservationNone),
                          ),
                          DropdownMenuItem(
                            value: 'negative',
                            child: Text(strings.cycleTestNegative),
                          ),
                          DropdownMenuItem(
                            value: 'positive',
                            child: Text(strings.cycleTestPositive),
                          ),
                        ],
                        onChanged: (value) =>
                            setSheetState(() => ovulationTest = value ?? ''),
                      ),
                    if (settings.trackSexualActivity)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: hadSex,
                        onChanged: (value) =>
                            setSheetState(() => hadSex = value),
                        title: Text(strings.cycleSexualActivity),
                      ),
                  ],
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
                              discharge: discharge,
                              hadSex: hadSex,
                              basalTemperature: advancedAccess &&
                                      settings.trackBasalTemperature
                                  ? double.tryParse(
                                      basalTemperatureController.text
                                          .trim()
                                          .replaceAll(',', '.'),
                                    )
                                  : existing?.basalTemperature,
                              ovulationTest: ovulationTest,
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
    basalTemperatureController.dispose();
    notesController.dispose();
    if (saved == true && mounted && vault.unlocked) {
      await _syncCycleReminders();
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

  String _confidenceLabel(
    AnnaStrings strings,
    CyclePredictionConfidence confidence,
  ) =>
      switch (confidence) {
        CyclePredictionConfidence.low => strings.cycleConfidenceLow,
        CyclePredictionConfidence.medium => strings.cycleConfidenceMedium,
        CyclePredictionConfidence.high => strings.cycleConfidenceHigh,
      };

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

  String _symptomLabel(AnnaStrings strings, String value) {
    if (value.startsWith('custom:')) {
      return value.substring('custom:'.length);
    }
    return switch (value) {
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
  }

  String _dischargeLabel(AnnaStrings strings, String value) => switch (value) {
        'dry' => strings.cycleMucusDry,
        'sticky' => strings.cycleMucusSticky,
        'creamy' => strings.cycleMucusCreamy,
        'watery' => strings.cycleMucusWatery,
        'eggWhite' => strings.cycleMucusEggWhite,
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
