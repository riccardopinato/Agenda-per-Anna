part of '../main.dart';

class WeekScreen extends StatefulWidget {
  final AgendaStore store;
  final bool embedded;

  const WeekScreen({
    super.key,
    required this.store,
    this.embedded = false,
  });

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late DateTime start = mondayOf(DateTime.now());

  List<Widget> _weekActions(BuildContext context) => [
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
                        child: Text(
                          AnnaStrings.of(context).d3('moveTrash'),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (confirmed) {
              await widget.store.moveWeekToTrash(start);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'trash',
              child: Text(
                AnnaStrings.of(context).d3('movePageTrash'),
              ),
            ),
          ],
        ),
      ];

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
        AnnaEditorialTodayMode.enabled,
      ]),
      builder: (context, _) {
        final editorial = AnnaEditorialTodayMode.enabled.value;
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
          backgroundColor: editorial ? AnnaEditorialColors.of(context).canvas : null,
          appBar: widget.embedded
              ? null
              : AppBar(
                  backgroundColor:
                      editorial ? AnnaEditorialColors.of(context).canvas : null,
                  surfaceTintColor: editorial ? Colors.transparent : null,
                  title: Text(
                    AnnaStrings.of(context).d3('myWeek'),
                    style: editorial
                        ? AnnaJournalTypography.editorial(context, size: 27)
                        : const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  actions: editorial ? null : _weekActions(context),
                ),
          body: Column(
            children: [
              // In the notebook standalone screen, move all week actions
              // below the title so the localized header never truncates.
              if (widget.embedded || editorial)
                Semantics(
                  identifier: 'calendar-week-view',
                  container: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _weekActions(context),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                  children: [
                    if (editorial)
                      AnnaEditorialCalendarWeekSummary(
                        start: start,
                        end: end,
                        eventCount: events.length,
                        completedTasks: completedTasks,
                        totalTasks: totalTasks,
                      )
                    else
                      _WeekHero(
                        start: start,
                        end: end,
                        eventCount: events.length,
                        completedTasks: completedTasks,
                        totalTasks: totalTasks,
                      ),
              const SizedBox(height: 12),
              AgendaContentFilterBar(
                store: widget.store,
                calendarNotebook: editorial,
              ),
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
              if (editorial)
                AnnaEditorialSectionHeading(
                  title: AnnaStrings.of(context).d3('plannerSevenDays'),
                )
              else
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
                      key: ValueKey(
                        'week-memory-${AgendaStore.dateKey(start)}',
                      ),
                      data: data,
                      autoMemories: beautifulThings,
                      onSave: (value) =>
                          widget.store.saveWeek(start, value),
                    ),
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
              const SizedBox(width: 8),
              Text(AnnaStrings.of(context).d3('weekFocus'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: AnnaStrings.of(context).d3('weekFocusHint'),
              border: const OutlineInputBorder(),
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
              Expanded(
                child: Text(
                  AnnaStrings.of(context).d3('weekPriorities'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
    final organic = AnnaOrganicPastel.enabled(context);
    final scheme = Theme.of(context).colorScheme;

    // Presentation-only. The original 7 dates and the canonical + Capture
    // callback below remain unchanged, including selected civil-day ownership.
    return Container(
      key: organic
          ? ValueKey<String>('organic-week-day-${AgendaStore.dateKey(day)}')
          : null,
      padding: EdgeInsets.all(organic ? 16 : 14),
      decoration: BoxDecoration(
        boxShadow: organic
            ? [
                BoxShadow(
                  color: AnnaEditorialColors.of(context).shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        color: organic
            ? (isToday
                ? Color.alphaBlend(
                    scheme.primary.withValues(alpha: .09),
                    AnnaOrganicPastel.surface(context),
                  )
                : AnnaOrganicPastel.surface(context))
            : (isToday
                ? scheme.primaryContainer.withValues(alpha: 0.55)
                : scheme.surface),
        borderRadius: BorderRadius.circular(organic ? 24 : 20),
        border: Border.all(
          color: organic
              ? (isToday
                  ? scheme.primary.withValues(alpha: .55)
                  : scheme.outlineVariant.withValues(alpha: .68))
              : scheme.outlineVariant,
        ),
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
                      ? scheme.primary
                      : (organic
                          ? scheme.surfaceContainerHighest.withValues(alpha: .65)
                          : scheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(organic ? 16 : 14),
                ),
                child: Text(
                  '${day.day}',
                  style: organic
                      ? AnnaJournalTypography.editorial(
                          context, size: 20,
                        ).copyWith(
                          color: isToday ? scheme.onPrimary : scheme.onSurface,
                        )
                      : TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isToday ? scheme.onPrimary : null,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cap(DateFormat('EEEE', AnnaStrings.intlLocale(context)).format(day)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: organic
                      ? AnnaJournalTypography.editorial(
                          context, size: 18,
                        ).copyWith(color: scheme.onSurface)
                      : const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
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
          if (organic) ...[
            const SizedBox(height: 9),
            const AnnaEditorialAccentRule(
              margin: EdgeInsets.symmetric(horizontal: 2),
            ),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (widget.autoMemories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(AnnaStrings.of(context).d3('niceThings'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...widget.autoMemories.map(
              (memory) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('♡  '),
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
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('howWeek'),
              border: const OutlineInputBorder(),
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

