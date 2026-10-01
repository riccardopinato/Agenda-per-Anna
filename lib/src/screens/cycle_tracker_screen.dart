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
  final premium = PremiumEntitlementService.instance;
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
        Row(
          children: [
            Expanded(
              child: _metricCard(
                context,
                strings.cycleLoggedDays,
                '${insights.loggedDays}',
                Icons.event_available_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                context,
                strings.cycleRecordedCycles,
                '${insights.periodCount}',
                Icons.loop_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                context,
                strings.cycleEstimatedWindow,
                range,
                Icons.date_range_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
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
          ],
        ),
        const SizedBox(height: 14),
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

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
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
