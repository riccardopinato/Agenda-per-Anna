part of '../main.dart';

class CalendarScreen extends StatefulWidget {
  final AgendaStore store;
  const CalendarScreen({super.key, required this.store});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();

  @override
  void initState() {
    super.initState();
    unawaited(
      ExternalCalendarService.instance.initialize().then(
        (_) => _loadVisibleMonth(focused),
      ),
    );
  }

  Future<void> _loadVisibleMonth(DateTime anchor) {
    final start = DateTime(anchor.year, anchor.month, 1)
        .subtract(const Duration(days: 7));
    final end = DateTime(anchor.year, anchor.month + 1, 1)
        .add(const Duration(days: 7));
    return ExternalCalendarService.instance.loadRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.store.agendaRevision,
        widget.store.sharedRevision,
        widget.store.journalRevision,
        widget.store.planningRevision,
        widget.store.workoutRevision,
        ExternalCalendarService.instance,
      ]),
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final events =
            agendaEntriesForDayWithExternal(widget.store, selected);
        final dayHub = widget.store.dayHubSnapshot(selected);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.calendar,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(
              context,
              widget.store,
              captureDate: selected,
              entryPoint: UnifiedCaptureEntryPoint.month,
            ),
            icon: const Icon(Icons.add),
            label: Text(strings.capture),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<UnifiedAgendaEntry>(
                    locale: AnnaStrings.intlLocale(context),
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2040),
                    focusedDay: focused,
                    selectedDayPredicate: (d) => isSameDay(d, selected),
                    eventLoader: (day) =>
                        agendaEntriesForDayWithExternal(widget.store, day),
                    onDaySelected: (s, f) {
                      setState(() {
                        selected = s;
                        focused = f;
                      });
                      unawaited(_loadVisibleMonth(f));
                    },
                    onPageChanged: (f) {
                      focused = f;
                      unawaited(_loadVisibleMonth(f));
                    },
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AgendaContentFilterBar(store: widget.store),
              const SizedBox(height: 18),
              SectionTitle(
                _cap(
                  DateFormat(
                    'EEEE d MMMM',
                    AnnaStrings.intlLocale(context),
                  ).format(selected),
                ),
              ),
              const SizedBox(height: 10),
              if (events.isEmpty)
                SimpleCard(child: Text(strings.noCommitments))
              else
                ...events.map(
                  (e) => UnifiedAgendaTile(
                    store: widget.store,
                    entry: e,
                  ),
                ),
              const SizedBox(height: 12),
              _CalendarDayContextCard(
                snapshot: dayHub,
                onOpenDay: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlannerScreen(
                      store: widget.store,
                      initialDate: selected,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlannerScreen extends StatefulWidget {
  final AgendaStore store;
  final DateTime? initialDate;

  const PlannerScreen({
    super.key,
    required this.store,
    this.initialDate,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime day;

  @override
  void initState() {
    super.initState();
    day = widget.initialDate ?? DateTime.now();
    unawaited(
      ExternalCalendarService.instance.initialize().then(
        (_) => _loadDay(day),
      ),
    );
  }

  Future<void> _loadDay(DateTime value) {
    final start = DateTime(value.year, value.month, value.day);
    return ExternalCalendarService.instance.loadRange(
      start,
      start.add(const Duration(days: 1)),
    );
  }

  void _selectDay(DateTime value) {
    setState(() => day = value);
    unawaited(_loadDay(value));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.store.agendaRevision,
        widget.store.sharedRevision,
        widget.store.journalRevision,
        widget.store.planningRevision,
        widget.store.workoutRevision,
        ExternalCalendarService.instance,
      ]),
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final snapshot = widget.store.dayHubSnapshot(day);
        final memoryRecall = widget.store.memoryRecallSnapshot(day);
        final timedPrivate = snapshot.agenda
            .where((entry) =>
                entry.type == ItemType.appointment &&
                entry.start != null &&
                entry.isPrivate)
            .map((entry) => entry.privateItem!)
            .toList();

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(
              context,
              widget.store,
              captureDate: day,
              entryPoint: UnifiedCaptureEntryPoint.day,
            ),
            icon: const Icon(Icons.add),
            label: Text(strings.capture),
          ),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.myDay,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _cap(
                    DateFormat(
                      'EEEE d MMMM',
                      AnnaStrings.intlLocale(context),
                    ).format(day),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (!AgendaStore.sameDay(day, DateTime.now()))
                TextButton(
                  onPressed: () => _selectDay(DateTime.now()),
                  child: Text(strings.navToday),
                ),
              IconButton(
                onPressed: () => openUnifiedItemComposer(context, widget.store, day),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          body: Column(
            children: [
              DateStrip(
                selected: day,
                onSelected: _selectDay,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                  children: [
                    _DayOpeningCard(date: day),
                    const SizedBox(height: 12),
                    AgendaContentFilterBar(store: widget.store),
                    const SizedBox(height: 12),
                    _DayLifeOverviewCard(
                      snapshot: snapshot,
                      hideDetails: false,
                    ),
                    const SizedBox(height: 14),
                    if (memoryRecall.onThisDay.isNotEmpty) ...[
                      _DayMemoryRecallCard(
                        store: widget.store,
                        anchor: day,
                        memories: memoryRecall.onThisDay,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _DayLifeStream(
                      snapshot: snapshot,
                      store: widget.store,
                    ),
                    const SizedBox(height: 14),
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(
                        strings.hourlyTimeline,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        strings.noPrivateTimedAppointments(timedPrivate.length),
                      ),
                      children: [
                        _TimelineHint(eventCount: timedPrivate.length),
                        const SizedBox(height: 10),
                        DayTimeline(
                          date: day,
                          events: timedPrivate,
                          store: widget.store,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(strings.diary),
                    const SizedBox(height: 8),
                    JournalEditor(store: widget.store, date: day),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarDayContextCard extends StatelessWidget {
  final DayHubSnapshot snapshot;
  final VoidCallback onOpenDay;

  const _CalendarDayContextCard({
    required this.snapshot,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AnnaStrings.of(context);
    final journalText = snapshot.hasJournalContent
        ? strings.journalStarted
        : strings.journalEmpty;
    final birthdayText = snapshot.birthdays.isEmpty
        ? null
        : snapshot.birthdays
            .map((occurrence) => occurrence.birthday.name)
            .join(', ');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.dayContext,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: onOpenDay,
                child: Text(strings.openDay),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(journalText),
          if (birthdayText != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(Icons.cake_outlined, size: 18, color: scheme.tertiary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    birthdayText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          if (snapshot.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              strings.freeDayDiaryHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _DayMemoryRecallCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime anchor;
  final List<DiaryBlockReference> memories;

  const _DayMemoryRecallCard({
    required this.store,
    required this.anchor,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AnnaStrings.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.onThisDay,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryMemoriesScreen(store: store),
                  ),
                ),
                child: Text(strings.memories),
              ),
            ],
          ),
          ...memories.take(3).map((memory) {
            final years = anchor.year - memory.date.year;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch (memory.block.type) {
                  DiaryBlockType.note => Icons.sticky_note_2_outlined,
                  DiaryBlockType.sketch => Icons.draw_outlined,
                  DiaryBlockType.photo => Icons.photo_outlined,
                  DiaryBlockType.voice => Icons.mic_none_outlined,
                },
              ),
              title: Text(
                store.diaryBlockDisplayTitle(
                  memory.block,
                  strings: AnnaStrings.of(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${years == 1 ? AnnaStrings.of(context).d3('yearsAgo1') : AnnaStrings.of(context).d3Format('yearsAgoN', {'count': years})} · '
                '${DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(memory.date)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlannerScreen(
                    store: store,
                    initialDate: memory.date,
                  ),
                ),
              ),
            );
          }),
          if (memories.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                AnnaStrings.of(context).d3Format(
                  'moreMemories',
                  {'count': memories.length - 3},
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayOpeningCard extends StatelessWidget {
  final DateTime date;
  const _DayOpeningCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final quote = _dailyQuote(date, AnnaStrings.of(context));
    final accent = context.accentSurface;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: accent.gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            color: accent.foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.$1,
                  style: TextStyle(
                    color: accent.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  quote.$2,
                  style: TextStyle(
                    color: accent.secondaryForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayLifeOverviewCard extends StatelessWidget {
  final DayHubSnapshot snapshot;
  final VoidCallback? onOpenDay;
  final bool hideDetails;

  const _DayLifeOverviewCard({
    required this.snapshot,
    this.onOpenDay,
    this.hideDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeDiaryBlocks =
        snapshot.journal.blocks.where((block) => !block.archived).length;
    final metrics = <({IconData icon, String text})>[
      if (snapshot.pendingTaskCount > 0)
        (
          icon: Icons.check_circle_outline,
          text: AnnaStrings.of(context).plannerTasksCount(snapshot.pendingTaskCount),
        ),
      if (snapshot.appointmentCount > 0)
        (
          icon: Icons.event_outlined,
          text: AnnaStrings.of(context).plannerCommitmentsCount(snapshot.appointmentCount),
        ),
      if (snapshot.birthdays.isNotEmpty)
        (
          icon: Icons.cake_outlined,
          text: AnnaStrings.of(context).d3Format('plannerBirthdays', {'count': snapshot.birthdays.length}),
        ),
      if (snapshot.workouts.isNotEmpty)
        (
          icon: Icons.sports_outlined,
          text: AnnaStrings.of(context).workoutsCount(snapshot.workouts.length),
        ),
      if (activeDiaryBlocks > 0)
        (
          icon: Icons.auto_stories_outlined,
          text: AnnaStrings.of(context).d3Format('plannerMoments', {'count': activeDiaryBlocks}),
        ),
    ];

    return Container(
      key: const ValueKey('day-life-overview'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AnnaStrings.of(context).myDay,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (onOpenDay != null)
                TextButton(
                  onPressed: onOpenDay,
                  child: Text(AnnaStrings.of(context).d3('open')),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            snapshot.isEmpty
                ? AnnaStrings.of(context).d3('dayEmpty')
                : snapshot.hasJournalContent
                    ? AnnaStrings.of(context).d3('dayHubEmpty')
                    : AnnaStrings.of(context).d3('dayHubBusy'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: metrics
                  .map(
                    (metric) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(metric.icon, size: 15, color: scheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            hideDetails ? '•••' : metric.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (!hideDetails && snapshot.lifeEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...snapshot.lifeEntries.take(3).map(
                  (entry) => _DayLifePreviewRow(
                    entry: entry,
                    date: snapshot.date,
                  ),
                ),
            if (snapshot.lifeEntries.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AnnaStrings.of(context).d3Format(
                    'moreMoments',
                    {'count': snapshot.lifeEntries.length - 3},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DayLifePreviewRow extends StatelessWidget {
  final DayLifeEntry entry;
  final DateTime date;

  const _DayLifePreviewRow({
    required this.entry,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final data = _dayLifePresentation(
      entry,
      date,
      AnnaStrings.of(context),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(data.icon, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.timeLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DayLifeStream extends StatelessWidget {
  final DayHubSnapshot snapshot;
  final AgendaStore store;

  const _DayLifeStream({
    required this.snapshot,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.lifeEntries;
    return SimpleCard(
      key: const ValueKey('day-life-stream'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_timeline_outlined),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AnnaStrings.of(context).d3('dayMoments'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            AnnaStrings.of(context).d3('dayMomentsSubtitle'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AnnaStrings.of(context).d3('noDayMoments'),
              ),
            )
          else
            ...entries.map(
              (entry) {
                final data = _dayLifePresentation(entry, snapshot.date);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(data.icon, size: 19),
                  ),
                  title: Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: data.subtitle.isEmpty
                      ? null
                      : Text(
                          data.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: Text(
                    data.timeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => _openDayLifeEntry(context, store, entry),
                );
              },
            ),
        ],
      ),
    );
  }
}

typedef _DayLifePresentation = ({
  IconData icon,
  String title,
  String subtitle,
  String timeLabel,
});

_DayLifePresentation _dayLifePresentation(
  DayLifeEntry entry,
  DateTime date,
  AnnaStrings strings,
) {
  switch (entry.kind) {
    case DayLifeEntryKind.agenda:
      final value = entry.agenda!;
      final when = value.start == null ? strings.d3('day') : formatTime(value.start!);
      return (
        icon: value.isExternal
            ? Icons.event_available_outlined
            : value.isShared
                ? Icons.favorite_outline
                : value.type == ItemType.task
                    ? Icons.check_circle_outline
                    : Icons.event_outlined,
        title: value.title,
        subtitle: value.visibilityLabel(strings),
        timeLabel: when,
      );
    case DayLifeEntryKind.birthday:
      final value = entry.birthday!;
      final age = value.age == null ? '' : strings.d3Format('ageYears', {'count': value.age});
      return (
        icon: Icons.cake_outlined,
        title: value.birthday.name,
        subtitle: value.birthday.note.trim().isEmpty
            ? '${strings.birthdays}$age'
            : '${value.birthday.note}$age',
        timeLabel: strings.d3('day'),
      );
    case DayLifeEntryKind.workout:
      final value = entry.workout!;
      final metrics = <String>[
        strings.workoutSportLabel(value.sport),
        if (value.distanceKm != null && value.distanceKm! > 0)
          '${value.distanceKm!.toStringAsFixed(value.distanceKm! % 1 == 0 ? 0 : 1)} km',
        if (value.durationSeconds > 0)
          _dayLifeDuration(value.durationSeconds),
      ];
      return (
        icon: value.sport.icon,
        title: value.title.trim().isEmpty ? strings.workoutSportLabel(value.sport) : value.title,
        subtitle: metrics.join(' · '),
        timeLabel: _dayLifeClock(value.createdAt, date, strings),
      );
    case DayLifeEntryKind.diaryBlock:
      final value = entry.diaryBlock!;
      final type = switch (value.type) {
        DiaryBlockType.note => strings.v100Note,
        DiaryBlockType.sketch => strings.v100Sketch,
        DiaryBlockType.photo => strings.v100Photo,
        DiaryBlockType.voice => strings.v100VoiceNote,
      };
      final icon = switch (value.type) {
        DiaryBlockType.note => Icons.sticky_note_2_outlined,
        DiaryBlockType.sketch => Icons.draw_outlined,
        DiaryBlockType.photo => Icons.photo_outlined,
        DiaryBlockType.voice => Icons.mic_none_outlined,
      };
      final title = value.text.trim().isEmpty ? type : value.text.trim();
      return (
        icon: icon,
        title: title,
        subtitle: strings.d3Format('diaryType', {'type': type}),
        timeLabel: _dayLifeClock(value.createdAt, date, strings),
      );
  }
}

String _dayLifeClock(DateTime value, DateTime day, AnnaStrings strings) {
  if (!AgendaStore.sameDay(value, day)) return strings.d3('day');
  return formatTime(TimeOfDay(hour: value.hour, minute: value.minute));
}

String _dayLifeDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${max(1, minutes)} min';
}

Future<void> _openDayLifeEntry(
  BuildContext context,
  AgendaStore store,
  DayLifeEntry entry,
) async {
  switch (entry.kind) {
    case DayLifeEntryKind.agenda:
      await openUnifiedAgendaEntry(context, store, entry.agenda!);
      return;
    case DayLifeEntryKind.birthday:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BirthdaysScreen(store: store),
        ),
      );
      return;
    case DayLifeEntryKind.workout:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutScreen(store: store),
        ),
      );
      return;
    case DayLifeEntryKind.diaryBlock:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryMemoriesScreen(store: store),
        ),
      );
      return;
  }
}

class _TimelineHint extends StatelessWidget {
  final int eventCount;

  const _TimelineHint({required this.eventCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 17, color: scheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              eventCount == 0
                  ? AnnaStrings.of(context).d3('firstCommitment')
                  : AnnaStrings.of(context).d3('tapFreeSlot'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (eventCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$eventCount',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelinePlacement {
  final AgendaItem item;
  final int lane;
  final int laneCount;

  const _TimelinePlacement({
    required this.item,
    required this.lane,
    required this.laneCount,
  });
}

class DayTimeline extends StatelessWidget {
  final DateTime date;
  final List<AgendaItem> events;
  final AgendaStore store;
  final VoidCallback onChanged;

  const DayTimeline({
    super.key,
    required this.date,
    required this.events,
    required this.store,
    required this.onChanged,
  });

  static const int startHour = 0;
  static const int endHour = 24;
  static const double hourHeight = 74;
  static const double timeColumnWidth = 54;

  static double offsetForMinutes(int minutes) {
    final lower = startHour * 60;
    final upper = endHour * 60;
    final clamped = minutes.clamp(lower, upper);
    return ((clamped - lower) / 60) * hourHeight;
  }

  static int minutesForOffset(double y) {
    final raw = startHour * 60 + ((y / hourHeight) * 60).round();
    return ((raw / 15).round() * 15).clamp(
      startHour * 60,
      endHour * 60 - 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = (endHour - startHour) * hourHeight;
    final placements = _placements(events);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: totalHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) =>
                      _createAtPosition(context, details.localPosition.dy),
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      textColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              ...placements.map(
                (placement) => _eventBlock(
                  context,
                  placement,
                  constraints.maxWidth,
                ),
              ),
              if (AgendaStore.sameDay(date, DateTime.now()))
                _currentTimeIndicator(context),
            ],
          ),
        );
      },
    );
  }

  List<_TimelinePlacement> _placements(List<AgendaItem> source) {
    final sorted = [...source]
      ..sort((a, b) => _startMinutes(a).compareTo(_startMinutes(b)));

    final result = <_TimelinePlacement>[];
    var index = 0;

    while (index < sorted.length) {
      final group = <AgendaItem>[];
      var groupEnd = _endMinutes(sorted[index]);
      group.add(sorted[index]);
      index++;

      while (index < sorted.length &&
          _startMinutes(sorted[index]) < groupEnd) {
        final item = sorted[index];
        group.add(item);
        groupEnd = groupEnd < _endMinutes(item)
            ? _endMinutes(item)
            : groupEnd;
        index++;
      }

      final laneEnds = <int>[];
      final laneForItem = <AgendaItem, int>{};

      for (final item in group) {
        final start = _startMinutes(item);
        var lane = laneEnds.indexWhere((end) => end <= start);
        if (lane == -1) {
          lane = laneEnds.length;
          laneEnds.add(_endMinutes(item));
        } else {
          laneEnds[lane] = _endMinutes(item);
        }
        laneForItem[item] = lane;
      }

      final count = laneEnds.length.clamp(1, 99);
      for (final item in group) {
        result.add(
          _TimelinePlacement(
            item: item,
            lane: laneForItem[item] ?? 0,
            laneCount: count,
          ),
        );
      }
    }

    return result;
  }

  int _startMinutes(AgendaItem item) {
    final start = item.start!;
    return start.hour * 60 + start.minute;
  }

  int _endMinutes(AgendaItem item) {
    final start = _startMinutes(item);
    final end = item.end;
    if (end == null) return start + 60;
    final result = end.hour * 60 + end.minute;
    return result <= start ? start + 15 : result;
  }

  Widget _eventBlock(
    BuildContext context,
    _TimelinePlacement placement,
    double maxWidth,
  ) {
    final event = placement.item;
    final start = event.start!;
    final startMinutes = _startMinutes(event);
    final lower = startHour * 60;
    final upper = endHour * 60;

    if (startMinutes < lower || startMinutes >= upper) {
      return const SizedBox.shrink();
    }

    final endMinutes =
        _endMinutes(event).clamp(startMinutes + 15, upper);
    final top = offsetForMinutes(startMinutes);
    final remainingHeight = max(1.0, totalHeightFromTop(top));
    final naturalHeight =
        ((endMinutes - startMinutes) / 60) * hourHeight;
    final minimumVisibleHeight = min(36.0, remainingHeight);
    final height = naturalHeight.clamp(
      minimumVisibleHeight,
      remainingHeight,
    );

    const gap = 5.0;
    final contentWidth = maxWidth - timeColumnWidth - 16;
    final laneWidth =
        (contentWidth - gap * (placement.laneCount - 1)) /
            placement.laneCount;
    final left = timeColumnWidth +
        8 +
        placement.lane * (laneWidth + gap);

    final base = event.category.color;
    final background = Color.alphaBlend(
      base.withValues(alpha: 0.16),
      Theme.of(context).colorScheme.surface,
    );

    return Positioned(
      top: top + 2,
      left: left,
      width: laneWidth,
      height: max(1.0, height - 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await openItemEditor(
              context,
              store,
              date,
              existing: event,
            );
            onChanged();
          },
          onLongPress: () async {
            await _showAgendaItemActions(context, store, event);
            onChanged();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: placement.laneCount > 2 ? 6 : 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: base.withValues(alpha: 0.55)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Color(0x12000000),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (placement.laneCount <= 2)
                        Row(
                          children: [
                            Icon(event.category.icon, size: 13, color: base),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                AnnaStrings.of(context).editorCategoryLabel(event.category),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: base,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Text(
                        event.title,
                        maxLines: height < 58 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: placement.laneCount > 2 ? 11 : 13,
                        ),
                      ),
                      if (height >= 52)
                        Text(
                          event.end == null
                              ? formatTime(start)
                              : '${formatTime(start)} – ${formatTime(event.end!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: placement.laneCount > 2 ? 9 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (height >= 82 &&
                          placement.laneCount <= 2 &&
                          event.note.trim().isNotEmpty)
                        Text(
                          event.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentTimeIndicator(BuildContext context) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final lower = startHour * 60;
    final upper = endHour * 60;

    if (minutes < lower || minutes >= upper) {
      return const SizedBox.shrink();
    }

    final top = offsetForMinutes(minutes);
    return Positioned(
      top: top,
      left: timeColumnWidth - 3,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFE14F7A),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: const Color(0xFFE14F7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAtPosition(
    BuildContext context,
    double y,
  ) async {
    final minutes = minutesForOffset(y);

    await openUnifiedItemComposer(
      context,
      store,
      date,
      initialTime: TimeOfDay(
        hour: minutes ~/ 60,
        minute: minutes % 60,
      ),
    );
    onChanged();
  }

  double totalHeightFromTop(double top) {
    final total = (endHour - startHour) * hourHeight;
    return total - top;
  }
}

class _TimelinePainter extends CustomPainter {
  final Color color;
  final Color textColor;

  _TimelinePainter({required this.color, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fullPaint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (int hour = DayTimeline.startHour;
        hour <= DayTimeline.endHour;
        hour++) {
      final y = (hour - DayTimeline.startHour) * DayTimeline.hourHeight;
      canvas.drawLine(
        Offset(DayTimeline.timeColumnWidth, y),
        Offset(size.width, y),
        fullPaint,
      );

      if (hour < DayTimeline.endHour) {
        final half = y + DayTimeline.hourHeight / 2;
        canvas.drawLine(
          Offset(DayTimeline.timeColumnWidth, half),
          Offset(size.width, half),
          halfPaint,
        );
      }

      final painter = TextPainter(
        text: TextSpan(
          text: '${hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(
            color: textColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: DayTimeline.timeColumnWidth - 8);

      final labelY = hour == DayTimeline.endHour
          ? max(0.0, y - painter.height - 6)
          : y + 6;

      painter.paint(
        canvas,
        Offset(
          DayTimeline.timeColumnWidth - painter.width - 8,
          labelY,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.textColor != textColor;
  }
}

class WeekScreen extends StatefulWidget {
  final AgendaStore store;
  const WeekScreen({super.key, required this.store});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late DateTime start = mondayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    unawaited(
      ExternalCalendarService.instance.initialize().then(
        (_) => _loadWeek(),
      ),
    );
  }

  Future<void> _loadWeek() {
    return ExternalCalendarService.instance.loadRange(
      start,
      addCivilDays(start, 7),
    );
  }

  void _moveWeek(int days) {
    setState(() => start = addCivilDays(start, days));
    unawaited(_loadWeek());
  }

  void _goToCurrentWeek() {
    setState(() => start = mondayOf(DateTime.now()));
    unawaited(_loadWeek());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.store.agendaRevision,
        widget.store.sharedRevision,
        widget.store.journalRevision,
        widget.store.planningRevision,
        ExternalCalendarService.instance,
      ]),
      builder: (context, _) {
        final data = widget.store.week(start);
        final end = addCivilDays(start, 6);
        final events = <UnifiedAgendaEntry>[
          for (int i = 6; i >= 0; i--)
            ...agendaEntriesForDayWithExternal(
              widget.store,
              addCivilDays(start, i),
            ),
        ];
        final completedTasks = events.where((e) => e.type == ItemType.task && e.done).length;
        final totalTasks = events.where((e) => e.type == ItemType.task).length;
        final beautifulThings = <String>[
          for (int i = 6; i >= 0; i--)
            if (widget.store.journal(addCivilDays(start, i)).beautiful.trim().isNotEmpty)
              widget.store.journal(addCivilDays(start, i)).beautiful.trim(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(AnnaStrings.of(context).d3('myWeek'), style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: AnnaStrings.of(context).d3('previousWeek'),
                onPressed: () => _moveWeek(-7),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: AnnaStrings.of(context).d3('thisWeek'),
                onPressed: _goToCurrentWeek,
                icon: const Icon(Icons.today_outlined),
              ),
              IconButton(
                tooltip: AnnaStrings.of(context).d3('nextWeek'),
                onPressed: () => _moveWeek(7),
                icon: const Icon(Icons.chevron_right),
              ),
              PopupMenuButton<String>(
                tooltip: AnnaStrings.of(context).d3('weekActions'),
                onSelected: (value) async {
                  if (value != 'trash') return;
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            AnnaStrings.of(context).d3('moveWeekTitle'),
                          ),
                          content: Text(AnnaStrings.of(context).d3('weekTrash')),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(AnnaStrings.of(context).cancel),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(AnnaStrings.of(context).d3('moveTrash')),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) {
                    await widget.store.moveWeekToTrash(start);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'trash',
                    child: Text(AnnaStrings.of(context).d3('movePageTrash')),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
            children: [
              _WeekHero(
                start: start,
                end: end,
                eventCount: events.length,
                completedTasks: completedTasks,
                totalTasks: totalTasks,
              ),
              const SizedBox(height: 12),
              AgendaContentFilterBar(store: widget.store),
              const SizedBox(height: 14),
              WeekFocusCard(
                key: ValueKey('week-focus-${AgendaStore.dateKey(start)}'),
                data: data,
                onSave: (value) => widget.store.saveWeek(start, value),
              ),
              const SizedBox(height: 14),
              WeekPrioritiesCard(
                key: ValueKey('week-priorities-${AgendaStore.dateKey(start)}'),
                data: data,
                onSave: (value) => widget.store.saveWeek(start, value),
              ),
              const SizedBox(height: 18),
              SectionTitle(AnnaStrings.of(context).d3('plannerSevenDays')),
              const SizedBox(height: 10),
              for (int i = 6; i >= 0; i--) ...[
                _WeekDayCard(
                  day: addCivilDays(start, i),
                  store: widget.store,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              WeekMemoryCard(
                key: ValueKey('week-memory-${AgendaStore.dateKey(start)}'),
                data: data,
                autoMemories: beautifulThings,
                onSave: (value) => widget.store.saveWeek(start, value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekHero extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int eventCount;
  final int completedTasks;
  final int totalTasks;

  const _WeekHero({
    required this.start,
    required this.end,
    required this.eventCount,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentSurface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: accent.gradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('d MMM', AnnaStrings.intlLocale(context)).format(start)} – ${DateFormat('d MMM yyyy', AnnaStrings.intlLocale(context)).format(end)}',
            style: TextStyle(
              color: accent.secondaryForeground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AnnaStrings.of(context).d3('oneWeek'),
            style: TextStyle(
              color: accent.foreground,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(icon: Icons.event_outlined, text: AnnaStrings.of(context).plannerCommitmentsCount(eventCount)),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: totalTasks == 0
                    ? AnnaStrings.of(context).d3('noTasks')
                    : AnnaStrings.of(context).d3Format(
                        'taskProgress',
                        {'done': completedTasks, 'total': totalTasks},
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: accent.chipBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: accent.chipForeground,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: accent.chipForeground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class WeekFocusCard extends StatefulWidget {
  final WeekData data;
  final ValueChanged<WeekData> onSave;
  const WeekFocusCard({super.key, required this.data, required this.onSave});

  @override
  State<WeekFocusCard> createState() => _WeekFocusCardState();
}

class _WeekFocusCardState extends State<WeekFocusCard> {
  late final TextEditingController controller =
      TextEditingController(text: widget.data.focus);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.center_focus_strong_outlined),
              SizedBox(width: 8),
              Text(AnnaStrings.of(context).d3('weekFocus'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: AnnaStrings.of(context).d3('weekFocusHint'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => widget.onSave(widget.data.copyWith(focus: controller.text.trim())),
              child: Text(AnnaStrings.of(context).d3('saveFocus')),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekPrioritiesCard extends StatelessWidget {
  final WeekData data;
  final ValueChanged<WeekData> onSave;
  const WeekPrioritiesCard({super.key, required this.data, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(AnnaStrings.of(context).d3('weekPriorities'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AnnaStrings.of(context).d3('newPriority')),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(hintText: AnnaStrings.of(context).d3('priorityHint')),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(AnnaStrings.of(context).cancel)),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text.trim()),
                          child: Text(AnnaStrings.of(context).add),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  if (value != null && value.isNotEmpty) {
                    onSave(data.copyWith(priorities: [...data.priorities, value]));
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (data.priorities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(AnnaStrings.of(context).d3('priorityHelper')),
            )
          else
            ...data.priorities.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        final copy = [...data.priorities]..removeAt(entry.key);
                        onSave(data.copyWith(priorities: copy));
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  final DateTime day;
  final AgendaStore store;
  const _WeekDayCard({required this.day, required this.store});

  @override
  Widget build(BuildContext context) {
    final items = agendaEntriesForDayWithExternal(store, day);
    final journal = store.journal(day);
    final isToday = AgendaStore.sameDay(day, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isToday ? Theme.of(context).colorScheme.onPrimary : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cap(DateFormat('EEEE', AnnaStrings.intlLocale(context)).format(day)),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              IconButton(
                tooltip: AnnaStrings.of(context).capture,
                onPressed: () => _showQuickCapture(
                  context,
                  store,
                  captureDate: day,
                  entryPoint: UnifiedCaptureEntryPoint.week,
                ),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(AnnaStrings.of(context).d3('noCommitments')),
            )
          else ...[
            const SizedBox(height: 8),
            ...items.take(4).map((item) => UnifiedAgendaTile(store: store, entry: item, compact: true)),
            if (items.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AnnaStrings.of(context).d3Format(
                    'moreItems',
                    {'count': items.length - 4},
                  ),
                ),
              ),
          ],
          if (journal.beautiful.trim().isNotEmpty) ...[
            const Divider(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_outline, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    journal.beautiful,
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class WeekMemoryCard extends StatefulWidget {
  final WeekData data;
  final List<String> autoMemories;
  final ValueChanged<WeekData> onSave;

  const WeekMemoryCard({
    super.key,
    required this.data,
    required this.autoMemories,
    required this.onSave,
  });

  @override
  State<WeekMemoryCard> createState() => _WeekMemoryCardState();
}

class _WeekMemoryCardState extends State<WeekMemoryCard> {
  late final TextEditingController best =
      TextEditingController(text: widget.data.bestThing);
  late final TextEditingController reflection =
      TextEditingController(text: widget.data.reflection);

  @override
  void dispose() {
    best.dispose();
    reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AnnaStrings.of(context).d3('myWeekHeart'),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (widget.autoMemories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(AnnaStrings.of(context).d3('niceThings'),
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...widget.autoMemories.map(
              (memory) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('♡  '),
                    Expanded(child: Text(memory)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: best,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('bestWeek'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('howWeek'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => widget.onSave(
                widget.data.copyWith(
                  bestThing: best.text.trim(),
                  reflection: reflection.text.trim(),
                ),
              ),
              child: Text(AnnaStrings.of(context).d3('saveWeek')),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthScreen extends StatefulWidget {
  final AgendaStore store;
  final DateTime? initialMonth;

  const MonthScreen({
    super.key,
    required this.store,
    this.initialMonth,
  });

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  late DateTime selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    selected = DateTime(initial.year, initial.month);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.store.agendaRevision, widget.store.sharedRevision, widget.store.planningRevision]),
      builder: (context, _) {
        final data = widget.store.month(selected.year, selected.month);
        final spent = data.expenses.fold<int>(0, (a, b) => a + b.cents);
        return Scaffold(
          appBar: AppBar(
            title: Text(_cap(DateFormat('MMMM yyyy', AnnaStrings.intlLocale(context)).format(selected)),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month - 1)), icon: const Icon(Icons.chevron_left)),
              IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month + 1)), icon: const Icon(Icons.chevron_right)),
              PopupMenuButton<String>(
                tooltip: AnnaStrings.of(context).d3('monthActions'),
                onSelected: (value) async {
                  if (value != 'trash') return;
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            AnnaStrings.of(context).d3('moveMonthTitle'),
                          ),
                          content: Text(AnnaStrings.of(context).d3('monthTrash')),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(AnnaStrings.of(context).cancel),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(AnnaStrings.of(context).d3('moveTrash')),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) {
                    await widget.store.moveMonthToTrash(
                      selected.year,
                      selected.month,
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'trash',
                    child: Text(AnnaStrings.of(context).d3('movePageTrash')),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            children: [
              AgendaContentFilterBar(store: widget.store),
              const SizedBox(height: 12),
              MonthOpeningHero(
                month: selected,
                data: data,
                eventCount: widget.store.unifiedMonthCount(
                  selected.year,
                  selected.month,
                ),
              ),
              const SizedBox(height: 14),
              MonthOpeningJournalCard(
                key: ValueKey('month-opening-${selected.year}-${selected.month}'),
                data: data,
                onSave: (value) => widget.store.saveMonth(
                  selected.year,
                  selected.month,
                  value,
                ),
              ),
              const SizedBox(height: 12),
              _MonthWellbeingCard(store: widget.store, month: selected),
              const SizedBox(height: 12),
              MonthTextCard(
                key: ValueKey('month-intention-${selected.year}-${selected.month}'),
                title: AnnaStrings.of(context).d3('thisMonthWant'),
                initial: data.intention,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(intention: v)),
              ),
              const SizedBox(height: 12),
              MonthlyListCard(title: AnnaStrings.of(context).d3('goals'), items: data.goals, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(goals: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: AnnaStrings.of(context).d3('books'), items: data.books, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(books: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: AnnaStrings.of(context).d3('plannerFilmsSeries'), items: data.films, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(films: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: AnnaStrings.of(context).d3('hobbies'), items: data.hobbies, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(hobbies: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: AnnaStrings.of(context).d3('wishes'), items: data.wishes, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(wishes: v))),
              const SizedBox(height: 12),
              MonthIdeasBoard(
                ideas: data.ideas,
                onChange: (v) => widget.store.saveMonth(
                  selected.year,
                  selected.month,
                  data.copyWith(ideas: v),
                ),
              ),
              const SizedBox(height: 12),
              BudgetCard(
                data: data,
                spentCents: spent,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, v),
              ),
              const SizedBox(height: 12),
              ClosingMonthCard(
                key: ValueKey('month-closing-${selected.year}-${selected.month}'),
                data: data,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, v),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthWellbeingCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime month;

  const _MonthWellbeingCard({
    required this.store,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    final journals = store.journals.entries
        .where((entry) => entry.key.startsWith(prefix))
        .map((entry) => entry.value)
        .toList();

    final moodDays = journals.where((j) => j.mood != null).toList();
    final gratitudeCount =
        journals.fold<int>(0, (sum, j) => sum + j.gratitude.length);
    final completedHabits = journals.fold<int>(
      0,
      (sum, j) => sum + j.completedHabitIds.length,
    );

    DayMood? mostCommonMood;
    if (moodDays.isNotEmpty) {
      final counts = <DayMood, int>{};
      for (final journal in moodDays) {
        final value = journal.mood!;
        counts[value] = (counts[value] ?? 0) + 1;
      }
      mostCommonMood = counts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline),
              SizedBox(width: 8),
              Text(
                AnnaStrings.of(context).d3('monthFromMe'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AnnaStrings.of(context).d3('monthPersonalSummary'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.mood_outlined,
                text: AnnaStrings.of(context).d3Format('moodDays', {'count': moodDays.length}),
              ),
              _MiniPill(
                icon: Icons.auto_awesome_outlined,
                text: AnnaStrings.of(context).d3Format('niceCount', {'count': gratitudeCount}),
              ),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: AnnaStrings.of(context).d3Format('habitsDone', {'count': completedHabits}),
              ),
            ],
          ),
          if (mostCommonMood != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: mostCommonMood.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    mostCommonMood.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AnnaStrings.of(context).d3Format('topMood', {'value': AnnaStrings.of(context).editorMoodLabel(mostCommonMood)}),
                      style: TextStyle(
                        color: mostCommonMood.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MonthOpeningHero extends StatelessWidget {
  final DateTime month;
  final MonthlyData data;
  final int eventCount;

  const MonthOpeningHero({
    super.key,
    required this.month,
    required this.data,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final spent = data.expenses.fold<int>(0, (sum, item) => sum + item.cents);
    final accent = context.accentSurface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: accent.gradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cap(DateFormat('MMMM', AnnaStrings.intlLocale(context)).format(month)),
            style: TextStyle(
              color: accent.foreground,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _monthPhrase(month.month, AnnaStrings.of(context)),
            style: TextStyle(
              color: accent.secondaryForeground,
              fontSize: 14,
            ),
          ),
          if (data.monthWord.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: accent.chipBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AnnaStrings.of(context).d3Format('monthWordValue', {'value': data.monthWord}),
                style: TextStyle(
                  color: accent.chipForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(icon: Icons.event_outlined, text: AnnaStrings.of(context).plannerCommitmentsCount(eventCount)),
              _MiniPill(icon: Icons.flag_outlined, text: AnnaStrings.of(context).plannerGoalsCount(data.goals.length)),
              _MiniPill(
                icon: Icons.lightbulb_outline,
                text: AnnaStrings.of(context).d3Format('ideasCount', {'count': data.ideas.length}),
              ),
              _MiniPill(icon: Icons.wallet_outlined, text: money(context, spent)),
            ],
          ),
        ],
      ),
    );
  }
}

class MonthOpeningJournalCard extends StatefulWidget {
  final MonthlyData data;
  final ValueChanged<MonthlyData> onSave;

  const MonthOpeningJournalCard({
    super.key,
    required this.data,
    required this.onSave,
  });

  @override
  State<MonthOpeningJournalCard> createState() =>
      _MonthOpeningJournalCardState();
}

class _MonthOpeningJournalCardState
    extends State<MonthOpeningJournalCard> {
  late final TextEditingController word =
      TextEditingController(text: widget.data.monthWord);
  late final TextEditingController selfCare =
      TextEditingController(text: widget.data.selfCare);

  @override
  void dispose() {
    word.dispose();
    selfCare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined),
              SizedBox(width: 8),
              Text(
                AnnaStrings.of(context).d3('monthOpening'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AnnaStrings.of(context).d3('monthOpeningSubtitle'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: word,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('monthWord'),
              hintText: AnnaStrings.of(context).d3('monthWordHint'),
              prefixIcon: Icon(Icons.text_fields_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: selfCare,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('selfCare'),
              hintText: AnnaStrings.of(context).d3('selfCareHint'),
              prefixIcon: Icon(Icons.spa_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.bookmark_added_outlined),
              onPressed: () => widget.onSave(
                widget.data.copyWith(
                  monthWord: word.text.trim(),
                  selfCare: selfCare.text.trim(),
                ),
              ),
              label: Text(AnnaStrings.of(context).d3('saveMonthOpening')),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthIdeasBoard extends StatelessWidget {
  final List<String> ideas;
  final ValueChanged<List<String>> onChange;

  const MonthIdeasBoard({
    super.key,
    required this.ideas,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AnnaStrings.of(context).d3('monthIdeas'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text(AnnaStrings.of(context).d3('monthIdeasSubtitle'),
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AnnaStrings.of(context).d3('newIdea')),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: AnnaStrings.of(context).d3('ideaHint'),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(AnnaStrings.of(context).cancel)),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text.trim()),
                          child: Text(AnnaStrings.of(context).add),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  if (value != null && value.isNotEmpty) {
                    onChange([...ideas, value]);
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ideas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(AnnaStrings.of(context).d3('monthMagazine')),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ideas.asMap().entries.map((entry) {
                final icons = [
                  Icons.place_outlined,
                  Icons.restaurant_outlined,
                  Icons.movie_outlined,
                  Icons.local_florist_outlined,
                  Icons.auto_awesome_outlined,
                ];
                return InputChip(
                  avatar: Icon(icons[entry.key % icons.length], size: 17),
                  label: Text(entry.value),
                  onDeleted: () {
                    final copy = [...ideas]..removeAt(entry.key);
                    onChange(copy);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class YearScreen extends StatefulWidget {
  final AgendaStore store;
  final int? initialYear;

  const YearScreen({
    super.key,
    required this.store,
    this.initialYear,
  });

  @override
  State<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends State<YearScreen> {
  late int year;

  @override
  void initState() {
    super.initState();
    year = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.store.journalRevision, widget.store.planningRevision]),
      builder: (context, _) {
        int expenses = 0;
        int goals = 0;
        int memories = 0;
        for (int m = 1; m <= 12; m++) {
          final data = widget.store.month(year, m);
          expenses += data.expenses.fold<int>(0, (a, b) => a + b.cents);
          goals += data.goals.length;
        }
        memories = widget.store.journals.entries.where((e) {
          final d = DateTime.tryParse(e.key);
          return d?.year == year && e.value.beautiful.trim().isNotEmpty;
        }).length;

        return Scaffold(
          appBar: AppBar(title: Text(AnnaStrings.of(context).d3('myYear'), style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setState(() => year--), icon: const Icon(Icons.chevron_left)),
                  Text('$year', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => setState(() => year++), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 20),
              StatCard(icon: Icons.flag_outlined, title: AnnaStrings.of(context).d3('goalsEntered'), value: '$goals'),
              const SizedBox(height: 10),
              StatCard(icon: Icons.favorite_outline, title: AnnaStrings.of(context).d3('plannerMemoryDays'), value: '$memories'),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.account_balance_wallet_outlined,
                title: AnnaStrings.of(context).d3('plannerExpensesRecorded'),
                value: money(context, expenses),
              ),

              const SizedBox(height: 22),
              SectionTitle(AnnaStrings.of(context).d3('plannerTwelveMonths')),
              const SizedBox(height: 10),
              for (int month = 1; month <= 12; month++) ...[
                YearMonthSnapshot(
                  year: year,
                  month: month,
                  data: widget.store.month(year, month),
                  memoryCount: widget.store.journals.entries.where((entry) {
                    final date = DateTime.tryParse(entry.key);
                    return date?.year == year &&
                        date?.month == month &&
                        entry.value.beautiful.trim().isNotEmpty;
                  }).length,
                ),
                const SizedBox(height: 9),
              ],
            ],
          ),
        );
      },
    );
  }
}

class YearMonthSnapshot extends StatelessWidget {
  final int year;
  final int month;
  final MonthlyData data;
  final int memoryCount;

  const YearMonthSnapshot({
    super.key,
    required this.year,
    required this.month,
    required this.data,
    required this.memoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final spent = data.expenses.fold<int>(0, (sum, item) => sum + item.cents);
    final hasStory = data.bestMoment.trim().isNotEmpty ||
        data.reflection.trim().isNotEmpty ||
        memoryCount > 0 ||
        data.goals.isNotEmpty ||
        spent > 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: hasStory
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.28)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              _cap(DateFormat('MMM', AnnaStrings.intlLocale(context)).format(DateTime(year, month))),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Expanded(
            child: hasStory
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.bestMoment.trim().isNotEmpty)
                        Text(
                          '♡ ${data.bestMoment}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      Text(
                        '${AnnaStrings.of(context).plannerGoalsCount(data.goals.length)} · ${AnnaStrings.of(context).plannerMemoriesCount(memoryCount)} · ${money(context, spent)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Text(
                    'Ancora da scrivere',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAgendaItemActions(
  BuildContext context,
  AgendaStore store,
  AgendaItem item,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(AnnaStrings.of(context).edit),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_outlined),
            title: Text(AnnaStrings.of(context).d3('duplicate')),
            subtitle: Text(AnnaStrings.of(context).d3('duplicateSameDay')),
            onTap: () => Navigator.pop(context, 'duplicate'),
          ),
          ListTile(
            leading: Icon(
              item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(
              item.pinned ? AnnaStrings.of(context).unpin : AnnaStrings.of(context).pinToHome,
            ),
            onTap: () => Navigator.pop(context, 'pin'),
          ),
          if (store.sharedAgendaSpaces.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(AnnaStrings.of(context).d3('moveToNoi')),
              subtitle: Text(AnnaStrings.of(context).d3('makeShared')),
              onTap: () => Navigator.pop(context, 'share'),
            ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              AnnaStrings.of(context).delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    ),
  );

  if (action == 'edit' && context.mounted) {
    await openItemEditor(context, store, item.date, existing: item);
  } else if (action == 'duplicate') {
    await store.duplicateItem(item);
  } else if (action == 'pin') {
    await store.toggleItemPinned(item.id);
  } else if (action == 'share' && context.mounted) {
    await _movePrivateAgendaItemToShared(context, store, item);
  } else if (action == 'delete' && context.mounted) {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AnnaStrings.of(context).d3('deleteItem')),
            content: Text(item.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AnnaStrings.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(AnnaStrings.of(context).delete),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await store.deleteItem(item.id);
  }
}
