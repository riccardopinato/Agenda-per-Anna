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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final events = widget.store.unifiedForDay(selected);
        return Scaffold(
          appBar: AppBar(title: const Text('Calendario', style: TextStyle(fontWeight: FontWeight.w800))),
          floatingActionButton: FloatingActionButton(
            onPressed: () => openUnifiedItemComposer(context, widget.store, selected),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<UnifiedAgendaEntry>(
                    locale: 'it_IT',
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2040),
                    focusedDay: focused,
                    selectedDayPredicate: (d) => isSameDay(d, selected),
                    eventLoader: widget.store.unifiedForDay,
                    onDaySelected: (s, f) => setState(() {
                      selected = s;
                      focused = f;
                    }),
                    onPageChanged: (f) => focused = f,
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
              SectionTitle(_cap(DateFormat('EEEE d MMMM', 'it_IT').format(selected))),
              const SizedBox(height: 10),
              if (events.isEmpty)
                const SimpleCard(child: Text('Nessun impegno.'))
              else
                ...events.map((e) => UnifiedAgendaTile(store: widget.store, entry: e)),
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
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final events = widget.store.unifiedForDay(day);
        final tasks = events.where((e) => e.type == ItemType.task).toList();
        final allDay = events
            .where((e) => e.type == ItemType.appointment && e.start == null)
            .toList();
        final timedPrivate = events
            .where((e) =>
                e.type == ItemType.appointment &&
                e.start != null &&
                e.isPrivate)
            .map((e) => e.privateItem!)
            .toList();
        final timedShared = events
            .where((e) =>
                e.type == ItemType.appointment &&
                e.start != null &&
                e.isShared)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('La mia giornata',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  _cap(DateFormat('EEEE d MMMM', 'it_IT').format(day)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (!AgendaStore.sameDay(day, DateTime.now()))
                TextButton(
                  onPressed: () => setState(() => day = DateTime.now()),
                  child: const Text('Oggi'),
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
                onSelected: (d) => setState(() => day = d),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                  children: [
                    _DayOpeningCard(date: day),
                    const SizedBox(height: 12),
                    AgendaContentFilterBar(store: widget.store),
                    if (tasks.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _DaySmallSection(
                        title: 'Da fare',
                        icon: Icons.check_circle_outline,
                        child: Column(
                          children: tasks
                              .map((e) => UnifiedAgendaTile(
                                    store: widget.store,
                                    entry: e,
                                    compact: true,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (allDay.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _DaySmallSection(
                        title: 'Tutto il giorno',
                        icon: Icons.event_outlined,
                        child: Column(
                          children: allDay
                              .map((e) => UnifiedAgendaTile(
                                    store: widget.store,
                                    entry: e,
                                    compact: true,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (timedShared.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _DaySmallSection(
                        title: 'Noi ♡ · con orario',
                        icon: Icons.favorite_outline,
                        child: Column(
                          children: timedShared
                              .map((e) => UnifiedAgendaTile(
                                    store: widget.store,
                                    entry: e,
                                    compact: true,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const SectionTitle('La mia giornata'),
                    const SizedBox(height: 8),
                    _TimelineHint(eventCount: timedPrivate.length),
                    const SizedBox(height: 10),
                    DayTimeline(
                      date: day,
                      events: timedPrivate,
                      store: widget.store,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 22),
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

class _DayOpeningCard extends StatelessWidget {
  final DateTime date;
  const _DayOpeningCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final quote = _dailyQuote(date);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEAF0), Color(0xFFF5F0FF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(quote.$2, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySmallSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DaySmallSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
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
                  ? 'Tocca un orario libero per aggiungere il primo impegno.'
                  : 'Tocca uno spazio libero per aggiungere · tocca un impegno per modificarlo.',
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

  static const int startHour = 6;
  static const int endHour = 24;
  static const double hourHeight = 74;
  static const double timeColumnWidth = 54;

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
    final top = ((upper - endMinutes) / 60) * hourHeight;
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
                                event.category.label,
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

    final top = ((upper - minutes) / 60) * hourHeight;
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
    var minutes =
        endHour * 60 - ((y / hourHeight) * 60).round();
    minutes = ((minutes / 15).round() * 15).clamp(
      startHour * 60,
      endHour * 60 - 15,
    );

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

    for (int hour = DayTimeline.endHour;
        hour >= DayTimeline.startHour;
        hour--) {
      final y = (DayTimeline.endHour - hour) * DayTimeline.hourHeight;
      canvas.drawLine(
        Offset(DayTimeline.timeColumnWidth, y),
        Offset(size.width, y),
        fullPaint,
      );

      if (hour > DayTimeline.startHour) {
        final half = y + DayTimeline.hourHeight / 2;
        canvas.drawLine(
          Offset(DayTimeline.timeColumnWidth, half),
          Offset(size.width, half),
          halfPaint,
        );

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

        painter.paint(
          canvas,
          Offset(
            DayTimeline.timeColumnWidth - painter.width - 8,
            y + 6,
          ),
        );
      }
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final data = widget.store.week(start);
        final end = addCivilDays(start, 6);
        final events = <UnifiedAgendaEntry>[
          for (int i = 0; i < 7; i++)
            ...widget.store.unifiedForDay(addCivilDays(start, i)),
        ];
        final completedTasks = events.where((e) => e.type == ItemType.task && e.done).length;
        final totalTasks = events.where((e) => e.type == ItemType.task).length;
        final beautifulThings = <String>[
          for (int i = 0; i < 7; i++)
            if (widget.store.journal(addCivilDays(start, i)).beautiful.trim().isNotEmpty)
              widget.store.journal(addCivilDays(start, i)).beautiful.trim(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('La mia settimana', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Settimana precedente',
                onPressed: () => setState(() => start = addCivilDays(start, -7)),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Questa settimana',
                onPressed: () => setState(() => start = mondayOf(DateTime.now())),
                icon: const Icon(Icons.today_outlined),
              ),
              IconButton(
                tooltip: 'Settimana successiva',
                onPressed: () => setState(() => start = addCivilDays(start, 7)),
                icon: const Icon(Icons.chevron_right),
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
              const SectionTitle('I 7 giorni'),
              const SizedBox(height: 10),
              for (int i = 0; i < 7; i++) ...[
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE5ED), Color(0xFFEDE8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('d MMM', 'it_IT').format(start)} – ${DateFormat('d MMM yyyy', 'it_IT').format(end)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Una settimana alla volta',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(icon: Icons.event_outlined, text: '$eventCount impegni'),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: totalTasks == 0 ? 'Nessun task' : '$completedTasks / $totalTasks task',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
          const Row(
            children: [
              Icon(Icons.center_focus_strong_outlined),
              SizedBox(width: 8),
              Text('Focus della settimana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Qual è la cosa più importante di questa settimana?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => widget.onSave(widget.data.copyWith(focus: controller.text.trim())),
              child: const Text('Salva focus'),
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
                child: Text('Priorità della settimana',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nuova priorità'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'Es. Finire la tesi'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text.trim()),
                          child: const Text('Aggiungi'),
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
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Aggiungi fino a poche cose davvero importanti, senza riempire troppo la settimana.'),
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
    final items = store.unifiedForDay(day);
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
                  _cap(DateFormat('EEEE', 'it_IT').format(day)),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              IconButton(
                onPressed: () => openUnifiedItemComposer(context, store, day),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Nessun impegno'),
            )
          else ...[
            const SizedBox(height: 8),
            ...items.take(4).map((item) => UnifiedAgendaTile(store: store, entry: item, compact: true)),
            if (items.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+ ${items.length - 4} altri'),
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
          const Text('La mia settimana ♡',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (widget.autoMemories.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Cose belle annotate nei giorni',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
            decoration: const InputDecoration(
              labelText: 'La cosa più bella della settimana',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Come è andata questa settimana?',
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
              child: const Text('Salva settimana'),
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
      animation: widget.store,
      builder: (context, _) {
        final data = widget.store.month(selected.year, selected.month);
        final spent = data.expenses.fold<int>(0, (a, b) => a + b.cents);
        return Scaffold(
          appBar: AppBar(
            title: Text(_cap(DateFormat('MMMM yyyy', 'it_IT').format(selected)),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month - 1)), icon: const Icon(Icons.chevron_left)),
              IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month + 1)), icon: const Icon(Icons.chevron_right)),
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
                title: 'Questo mese voglio...',
                initial: data.intention,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(intention: v)),
              ),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Obiettivi', items: data.goals, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(goals: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Libri', items: data.books, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(books: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Film e serie', items: data.films, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(films: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Hobby', items: data.hobbies, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(hobbies: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Desideri', items: data.wishes, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(wishes: v))),
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
          const Row(
            children: [
              Icon(Icons.favorite_outline),
              SizedBox(width: 8),
              Text(
                'Il mese, visto da me',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Un piccolo riepilogo delle giornate che hai raccontato.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.mood_outlined,
                text: '${moodDays.length} giorni con mood',
              ),
              _MiniPill(
                icon: Icons.auto_awesome_outlined,
                text: '$gratitudeCount cose belle',
              ),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: '$completedHabits abitudini fatte',
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
                      'Mood più presente: ${mostCommonMood.label}',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE2EB), Color(0xFFFFF4E8), Color(0xFFEDE7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cap(DateFormat('MMMM', 'it_IT').format(month)),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            _monthPhrase(month.month),
            style: const TextStyle(fontSize: 14),
          ),
          if (data.monthWord.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Parola del mese: ${data.monthWord}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(icon: Icons.event_outlined, text: '$eventCount impegni'),
              _MiniPill(icon: Icons.flag_outlined, text: '${data.goals.length} obiettivi'),
              _MiniPill(icon: Icons.lightbulb_outline, text: '${data.ideas.length} idee'),
              _MiniPill(icon: Icons.wallet_outlined, text: money(spent)),
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
          const Row(
            children: [
              Icon(Icons.auto_awesome_outlined),
              SizedBox(width: 8),
              Text(
                'Apertura del mese',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Una piccola pagina per dare un tono al mese prima di riempirlo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: word,
            decoration: const InputDecoration(
              labelText: 'La parola del mese',
              hintText: 'Es. calma, coraggio, leggerezza...',
              prefixIcon: Icon(Icons.text_fields_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: selfCare,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Come voglio prendermi cura di me',
              hintText: 'Una piccola attenzione concreta...',
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
              label: const Text('Salva apertura del mese'),
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
                    Text('Idee del mese',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Posti, ricette, film, cose da provare e piccoli desideri.',
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
                      title: const Text('Nuova idea'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Es. Fare una passeggiata al lago',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text.trim()),
                          child: const Text('Aggiungi'),
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
              child: const Text(
                'Qui può diventare la piccola “rivista” del mese: aggiungi qualcosa che ti piacerebbe fare, vedere, leggere o provare.',
              ),
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
      animation: widget.store,
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
          appBar: AppBar(title: const Text('Il mio anno', style: TextStyle(fontWeight: FontWeight.w800))),
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
              StatCard(icon: Icons.flag_outlined, title: 'Obiettivi inseriti', value: '$goals'),
              const SizedBox(height: 10),
              StatCard(icon: Icons.favorite_outline, title: 'Giorni con un bel ricordo', value: '$memories'),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Spese registrate',
                value: money(expenses),
              ),

              const SizedBox(height: 22),
              const SectionTitle('I miei 12 mesi'),
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
              _cap(DateFormat('MMM', 'it_IT').format(DateTime(year, month))),
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
                        '${data.goals.length} obiettivi · $memoryCount ricordi · ${money(spent)}',
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
            title: const Text('Modifica'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_outlined),
            title: const Text('Duplica'),
            subtitle: const Text('Crea una copia nello stesso giorno'),
            onTap: () => Navigator.pop(context, 'duplicate'),
          ),
          ListTile(
            leading: Icon(
              item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(
              item.pinned ? 'Togli dai fissati' : 'Fissa in Home',
            ),
            onTap: () => Navigator.pop(context, 'pin'),
          ),
          if (store.sharedAgendaSpaces.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Sposta in Noi ♡'),
              subtitle: const Text('Rendi questo elemento condiviso.'),
              onTap: () => Navigator.pop(context, 'share'),
            ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Elimina',
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
            title: const Text('Eliminare questo elemento?'),
            content: Text(item.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await store.deleteItem(item.id);
  }
}
