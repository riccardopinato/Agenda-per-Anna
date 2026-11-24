part of '../main.dart';

enum _CalendarHubView { month, week }

String approvedTodayGreeting(String lang, String displayName, int hour) {
  final part = hour < 12 ? 0 : hour < 18 ? 1 : 2;
  final greetings = switch (lang) {
    'en' => const ['Good morning', 'Good afternoon', 'Good evening'],
    'es' => const ['Buenos días', 'Buenas tardes', 'Buenas noches'],
    'fr' => const ['Bonjour', 'Bon après-midi', 'Bonsoir'],
    'pt' => const ['Bom dia', 'Boa tarde', 'Boa noite'],
    _ => const ['Buongiorno', 'Buon pomeriggio', 'Buonasera'],
  };
  final name = displayName.trim();
  return name.isEmpty ? greetings[part] : '${greetings[part]}, $name';
}

/// DS6 Today ticker: the greeting stays on one line in the icon band.
/// Only presentation changes: the calendar/Classic routes and real account
/// display name remain owned by PlannerScreen and AgendaStore.
class AnnaTodayEditorialGreetingToolbar extends StatefulWidget {
  final String greeting;
  final bool activeInShell;
  final String calendarTooltip;
  final String classicTooltip;
  final VoidCallback onOpenCalendar;
  final VoidCallback onReturnToClassic;

  const AnnaTodayEditorialGreetingToolbar({
    super.key,
    required this.greeting,
    this.activeInShell = true,
    required this.calendarTooltip,
    required this.classicTooltip,
    required this.onOpenCalendar,
    required this.onReturnToClassic,
  });

  @override
  State<AnnaTodayEditorialGreetingToolbar> createState() =>
      _AnnaTodayEditorialGreetingToolbarState();
}

class _AnnaTodayEditorialGreetingToolbarState
    extends State<AnnaTodayEditorialGreetingToolbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  bool _shouldScroll = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didUpdateWidget(covariant AnnaTodayEditorialGreetingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.greeting != widget.greeting) {
      _ticker.value = 0;
    }
  }

  // Synchronize only after layout: the width is unknown before LayoutBuilder.
  // An inactive or reduced-motion greeting does not keep a ticker running.
  void _setScrolling(bool active) {
    // AnimationController.value stops repeat() even when the overflow flag
    // remains true (e.g. a changed account name / locale). Compare the actual
    // ticker state too, so updates restart instead of freezing the greeting.
    if (_shouldScroll == active && _ticker.isAnimating == active) return;
    _shouldScroll = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_shouldScroll) {
        if (!_ticker.isAnimating) _ticker.repeat();
      } else {
        if (_ticker.isAnimating) _ticker.stop();
        if (_ticker.value != 0) _ticker.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AnnaEditorialColors.of(context).ink;
    final organic = AnnaOrganicPastel.enabled(context);
    final style = AnnaJournalTypography.editorial(
      context,
      // Keep the entire owner greeting visible at 390dp instead of
      // gratuitously marquing a short real name over the scenic header.
      size: organic ? 22 : 26,
    ).copyWith(
      height: 1.12,
      letterSpacing: -0.55,
      color: color,
      // Subtle halo preserves contrast against either collapsed image or sky
      // without placing a separate rectangular tile behind the title.
      shadows: organic
          ? [
              Shadow(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? AnnaEditorialColors.of(context).canvas
                        : AnnaOrganicPastel.canvas)
                    .withValues(alpha: .95),
                blurRadius: 5,
              ),
            ]
          : null,
    );

    return Row(
      key: const ValueKey<String>('ds6-today-compact-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: widget.greeting, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout(maxWidth: double.infinity);
              final textWidth = painter.width;
              final textHeight = painter.height;
              painter.dispose();

              final height = textHeight + 8 > 48 ? textHeight + 8 : 48.0;
              final visibleWidth = constraints.maxWidth;
              // IndexedStack retains offscreen tabs: never animate a
              // hidden Today screen (CPU/battery), even with overflow.
              final scroll = widget.activeInShell &&
                  AnnaMotionV108.enabled(context) &&
                  textWidth > visibleWidth + 1;
              _setScrolling(scroll);

              final text = Semantics(
                header: true,
                label: widget.greeting,
                child: ExcludeSemantics(
                  child: SizedBox(
                    key: const ValueKey<String>('ds6-today-greeting'),
                    height: height,
                    child: scroll
                        ? ClipRect(
                            key: const ValueKey<String>('ds6-today-marquee'),
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _ticker,
                                builder: (context, _) {
                                  const gap = 36.0;
                                  final cycle = textWidth + gap;
                                  final shift = _ticker.value * cycle;
                                  final count =
                                      (visibleWidth / cycle).ceil() + 2;
                                  return Stack(
                                    clipBehavior: Clip.hardEdge,
                                    children: [
                                      for (var i = 0; i < count; i++)
                                        Positioned(
                                          left: i * cycle - shift,
                                          top: (height - textHeight) / 2,
                                          width: textWidth + 2,
                                          child: Text(
                                            widget.greeting,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            style: style,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.greeting,
                              key: const ValueKey<String>(
                                'ds6-today-static-greeting',
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                          ),
                  ),
                ),
              );
              return text;
            },
          ),
        ),
        IconButton(
          key: const ValueKey<String>('today-editorial-disable'),
          tooltip: widget.classicTooltip,
          onPressed: widget.onReturnToClassic,
          icon: const Icon(Icons.view_agenda_outlined),
        ),
      ],
    );
  }
}

String approvedCalendarTagline(String languageCode) => switch (languageCode) {
  'en' => 'Every day, a story.',
  'es' => 'Cada día, una historia.',
  'fr' => 'Chaque jour, une histoire.',
  'pt' => 'Cada dia, uma história.',
  _ => 'Ogni giorno, una storia.',
};

class CalendarHubScreen extends StatefulWidget {
  final AgendaStore store;
  final ValueChanged<DateTime>? onSelectedDateChanged;

  const CalendarHubScreen({
    super.key,
    required this.store,
    this.onSelectedDateChanged,
  });

  @override
  State<CalendarHubScreen> createState() => _CalendarHubScreenState();
}

class _CalendarHubScreenState extends State<CalendarHubScreen> {
  _CalendarHubView view = _CalendarHubView.month;
  DateTime _captureDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: AnnaEditorialTodayMode.enabled,
      builder: (context, editorial, _) => Scaffold(
      backgroundColor: editorial ? AnnaEditorialColors.of(context).canvas : null,
      floatingActionButton: editorial
          ? Padding(
              padding: const EdgeInsetsDirectional.only(end: 6, bottom: 5),
              child: AnnaOrganicPastelAction(
                key: const ValueKey<String>('organic-calendar-create'),
                icon: Icons.add,
                label: strings.d3('ui5Create'),
                onPressed: () => showUnifiedCapture(
                  context,
                  widget.store,
                  initialDate: _captureDay,
                  entryPoint: UnifiedCaptureEntryPoint.month,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => showUnifiedCapture(
                context,
                widget.store,
                initialDate: _captureDay,
                entryPoint: UnifiedCaptureEntryPoint.month,
              ),
              icon: const Icon(Icons.add),
              label: Text(strings.d3('ui5Create')),
            ),
      appBar: AppBar(
        backgroundColor: editorial ? AnnaEditorialColors.of(context).canvas : null,
        surfaceTintColor: editorial ? Colors.transparent : null,
        toolbarHeight: 78,
        title: Text(
          strings.calendar,
          style: editorial
              ? AnnaJournalTypography.editorial(context, size: 29)
              : Theme.of(context).textTheme.headlineMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SizedBox(
              width: double.infinity,
              child: editorial
                  ? AnnaOrganicCalendarModePicker(
                      monthSelected: view == _CalendarHubView.month,
                      monthLabel: strings.navMonth,
                      weekLabel: strings.navWeek,
                      onSelected: (month) => setState(() {
                        view = month
                            ? _CalendarHubView.month
                            : _CalendarHubView.week;
                      }),
                    )
                  : SegmentedButton<_CalendarHubView>(
                style: ButtonStyle(
                  backgroundColor: editorial
                      ? WidgetStatePropertyAll(AnnaEditorialColors.of(context).quiet)
                      : null,
                  minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AnnaDesignTokens.radiusMd,
                      ),
                    ),
                  ),
                ),
                segments: [
                  ButtonSegment<_CalendarHubView>(
                    value: _CalendarHubView.month,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(strings.navMonth),
                  ),
                  ButtonSegment<_CalendarHubView>(
                    value: _CalendarHubView.week,
                    icon: const Icon(Icons.view_week_outlined),
                    label: Text(strings.navWeek),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (value) {
                  setState(() => view = value.first);
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AnnaDesignTokens.spaceMd,
              AnnaDesignTokens.spaceSm,
              AnnaDesignTokens.spaceMd,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                approvedCalendarTagline(strings.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AnnaJournalTypography.editorial(
                  context, size: editorial ? 20 : 18,
                ).copyWith(
                  color: editorial ? AnnaEditorialColors.of(context).ink : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AnnaDesignTokens.spaceMd,
              AnnaDesignTokens.spaceXs,
              AnnaDesignTokens.spaceMd,
              0,
            ),
            child: Builder(
              builder: (context) {
                // Canonical month/year routes; Organic gets only journal chrome.
                final monthLink = Semantics(
                  identifier: 'calendar-open-month-notebook',
                  button: true,
                  label: strings.v100MyMonth,
                  child: editorial
                      ? AnnaOrganicCalendarNotebookLink(
                          key: const ValueKey<String>(
                            'calendar-open-month-notebook',
                          ),
                          label: strings.v100MyMonth,
                          icon: Icons.auto_awesome_outlined,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => MonthScreen(store: widget.store),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          key: const ValueKey<String>(
                            'calendar-open-month-notebook',
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => MonthScreen(store: widget.store),
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text(strings.v100MyMonth),
                        ),
                );
                final yearLink = Semantics(
                  identifier: 'calendar-open-year-overview',
                  button: true,
                  label: strings.v100MyYear,
                  child: editorial
                      ? AnnaOrganicCalendarNotebookLink(
                          key: const ValueKey<String>(
                            'calendar-open-year-overview',
                          ),
                          label: strings.v100MyYear,
                          icon: Icons.insights_outlined,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => YearScreen(store: widget.store),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          key: const ValueKey<String>(
                            'calendar-open-year-overview',
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => YearScreen(store: widget.store),
                            ),
                          ),
                          icon: const Icon(Icons.insights_outlined),
                          label: Text(strings.v100MyYear),
                        ),
                );
                final notebookLinks = LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = editorial &&
                        (constraints.maxWidth < 310 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.3);
                    if (stacked) {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: monthLink),
                          const SizedBox(height: AnnaDesignTokens.spaceSm),
                          SizedBox(width: double.infinity, child: yearLink),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: monthLink),
                        const SizedBox(width: AnnaDesignTokens.spaceSm),
                        Expanded(child: yearLink),
                      ],
                    );
                  },
                );
                return editorial
                    ? AnnaEditorialSurface(
                        key: const ValueKey<String>('editorial-calendar-notebooks'),
                        padding: const EdgeInsets.all(8),
                        child: notebookLinks,
                      )
                    : AnnaJournalCard(
                        domain: AnnaVisualDomain.calendar,
                        padding: const EdgeInsets.all(AnnaDesignTokens.spaceXs),
                        child: notebookLinks,
                      );
              },
            ),
          ),
          const SizedBox(height: AnnaDesignTokens.spaceXs),
          Expanded(
            child: AnnaMotionReveal(
              token: view.index,
              child: IndexedStack(
                index: view.index,
                children: [
                CalendarScreen(
                  store: widget.store,
                  embedded: true,
                  onSelectedDateChanged: (selected) {
                    _captureDay = selected;
                    widget.onSelectedDateChanged?.call(selected);
                  },
                ),
                WeekScreen(
                  store: widget.store,
                  embedded: true,
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final AgendaStore store;
  final bool embedded;
  final ValueChanged<DateTime>? onSelectedDateChanged;

  const CalendarScreen({
    super.key,
    required this.store,
    this.embedded = false,
    this.onSelectedDateChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();
  bool _calendarReflow = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ExternalCalendarService.instance.initialize().then(
        (_) => _loadVisibleMonth(focused),
      ),
    );
  }

  Future<void> _createAtHour(int hour) async {
    if (hour < 7 || hour > 22 || !mounted) return;
    final date = DateTime(selected.year, selected.month, selected.day);
    await openItemEditor(
      context,
      widget.store,
      date,
      initialTime: TimeOfDay(hour: hour, minute: 0),
      initialType: ItemType.appointment,
    );
    // The canonical editor owns Save and persistence; agendaRevision
    // refreshes both the timeline and the selected-day list after Save.
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
        widget.store.inboxRevision,
        widget.store.sharedRevision,
        widget.store.journalRevision,
        widget.store.planningRevision,
        widget.store.workoutRevision,
        ExternalCalendarService.instance,
        AnnaEditorialTodayMode.enabled,
      ]),
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final editorial = AnnaEditorialTodayMode.enabled.value;
        final events =
            agendaEntriesForDayWithExternal(widget.store, selected);
        final dayHub = widget.store.dayHubSnapshot(selected);
        final selectedDateTitle = _cap(
          DateFormat(
            'EEEE d MMMM',
            AnnaStrings.intlLocale(context),
          ).format(selected),
        );
        return Scaffold(
          backgroundColor: editorial ? AnnaEditorialColors.of(context).canvas : null,
          appBar: widget.embedded
              ? null
              : AppBar(
                  backgroundColor:
                      editorial ? AnnaEditorialColors.of(context).canvas : null,
                  surfaceTintColor: editorial ? Colors.transparent : null,
                  title: Text(
                    strings.calendar,
                    style: editorial
                        ? AnnaJournalTypography.editorial(context, size: 27)
                        : const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
          floatingActionButton: widget.embedded
              ? null
              : editorial
                  ? AnnaOrganicPastelAction(
                      label: strings.capture,
                      icon: Icons.add_rounded,
                      onPressed: () => _showQuickCapture(
                        context,
                        widget.store,
                        captureDate: selected,
                        entryPoint: UnifiedCaptureEntryPoint.month,
                      ),
                    )
                  : FloatingActionButton.extended(
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
              AnnaEditorialCalendarPanel(
                key: const ValueKey<String>('editorial-calendar-month-grid'),
                enabled: editorial,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedScale(
                    scale: _calendarReflow ? 0.98 : 1.0,
                    duration: AnnaMotionV108.duration(context, 250),
                    curve: Curves.easeOutCubic,
                    child: TableCalendar<UnifiedAgendaEntry>(
                    locale: AnnaStrings.intlLocale(context),
                    daysOfWeekHeight: editorial ? 30 : 16,
                    rowHeight: editorial ? 50 : 52,
                    daysOfWeekStyle: editorial
                        ? DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              fontFamily: AnnaJournalTypography.uiFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AnnaEditorialColors.of(context).mutedInk,
                            ),
                            weekendStyle: TextStyle(
                              fontFamily: AnnaJournalTypography.uiFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AnnaEditorialColors.of(context).accent,
                            ),
                          )
                        : const DaysOfWeekStyle(),
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2040),
                    focusedDay: focused,
                    selectedDayPredicate: (d) => isSameDay(d, selected),
                    eventLoader: (day) =>
                        agendaEntriesForDayWithExternal(widget.store, day),
                    // The existing eventLoader remains canonical. Only its
                    // visible markers are redrawn for selected-day contrast.
                    calendarBuilders: editorial
                        ? CalendarBuilders<UnifiedAgendaEntry>(
                            markerBuilder: (context, day, loadedEvents) {
                              if (loadedEvents.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final markerInk = isSameDay(day, selected)
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : AnnaEditorialColors.of(context).accent;
                              return ExcludeSemantics(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (var i = 0;
                                            i < loadedEvents.length && i < 3;
                                            i++)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 1.5),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: markerInk,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const SizedBox(
                                                width: 5,
                                                height: 5,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : const CalendarBuilders<UnifiedAgendaEntry>(),
                    onDaySelected: (s, f) {
                      setState(() {
                        selected = s;
                        focused = f;
                      });
                      widget.onSelectedDateChanged?.call(s);
                      unawaited(_loadVisibleMonth(f));
                    },
                    onPageChanged: (f) {
                      focused = f;
                      if (AnnaMotionV108.enabled(context)) {
                        setState(() => _calendarReflow = true);
                        Future<void>.delayed(
                          const Duration(milliseconds: 100), () {
                            if (mounted) {
                              setState(() => _calendarReflow = false);
                            }
                          });
                      }
                      unawaited(_loadVisibleMonth(f));
                    },
                    headerStyle: editorial
                        ? HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            headerPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            leftChevronIcon: Icon(
                              Icons.chevron_left_rounded,
                              color: AnnaEditorialColors.of(context).ink,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right_rounded,
                              color: AnnaEditorialColors.of(context).ink,
                            ),
                            titleTextStyle: AnnaJournalTypography.editorial(
                              context,
                              size: 21,
                            ).copyWith(
                              color: AnnaEditorialColors.of(context).ink,
                            ),
                          )
                        : HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle:
                                Theme.of(context).textTheme.titleLarge!,
                          ),
                    // Notebook selection belongs to the existing
                    // TableCalendar; canonical events and callbacks remain.
                    // Shape and border distinguish focus from a mere marker.
                    calendarStyle: editorial
                        ? CalendarStyle(
                            outsideDaysVisible: false,
                            cellMargin: const EdgeInsets.all(3),
                            markerSize: 5.5,
                            markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                            defaultTextStyle: TextStyle(
                              fontFamily: AnnaJournalTypography.uiFamily,
                              fontWeight: FontWeight.w600,
                              color: AnnaEditorialColors.of(context).ink,
                            ),
                            weekendTextStyle: TextStyle(
                              fontFamily: AnnaJournalTypography.uiFamily,
                              fontWeight: FontWeight.w600,
                              color: AnnaEditorialColors.of(context).accent,
                            ),
                            selectedTextStyle: TextStyle(
                              fontFamily: AnnaJournalTypography.uiFamily,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            todayTextStyle: TextStyle(
                              fontFamily: AnnaJournalTypography.uiFamily,
                              fontWeight: FontWeight.w800,
                              color: AnnaEditorialColors.of(context).ink,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onPrimary
                                    .withValues(alpha: .35),
                              ),
                            ),
                            todayDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme
                                  .primaryContainer.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.6,
                              ),
                            ),
                            markerDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                          )
                        : CalendarStyle(
                            outsideDaysVisible: false,
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AgendaContentFilterBar(
                store: widget.store,
                calendarNotebook: editorial,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const ValueKey('b2-calendar-free-slots'),
                  onPressed: () => showCalendarFreeSlots(
                      context, widget.store, selected),
                  icon: const Icon(Icons.event_available_outlined),
                  style: editorial
                      ? OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: AnnaEditorialColors.of(context).ink,
                          side: BorderSide(
                            color: AnnaEditorialColors.of(context).border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )
                      : null,
                  label: Text(calendarFreeSlotLabel(
                      strings, 'open')),
                ),
              ),
              const SizedBox(height: 10),
              // Approved calendar-only preview: no second writer or record
              // ownership. The full existing agenda remains immediately below.
              AnnaEditorialCalendarPanel(
                enabled: editorial,
                child: ExpansionTile(
                key: const ValueKey<String>('approved-calendar-hourly-timeline'),
                initiallyExpanded: false,
                tilePadding: editorial
                    ? const EdgeInsets.symmetric(horizontal: 16)
                    : null,
                iconColor: editorial
                    ? AnnaEditorialColors.of(context).accent
                    : null,
                collapsedIconColor: editorial
                    ? AnnaEditorialColors.of(context).mutedInk
                    : null,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(
                  strings.hourlyTimeline,
                  style: editorial
                      ? AnnaJournalTypography.editorial(context, size: 18)
                      : null,
                ),
                subtitle: const Text('07:00–22:00'),
                children: [
                  for (var hour = 7; hour <= 22; hour++)
                    Builder(
                      builder: (context) {
                        final timed = events
                            .where((entry) => entry.start?.hour == hour)
                            .toList()
                          ..sort((a, b) =>
                              a.sortMinutes.compareTo(b.sortMinutes));
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 62,
                                child: TextButton(
                                  key: ValueKey('calendar-hour-create-$hour'),
                                  onPressed: () => _createAtHour(hour),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2, vertical: 12),
                                  ),
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: timed.isEmpty
                                    ? Semantics(
                                        identifier: 'calendar-hour-slot-$hour',
                                        button: true,
                                        child: InkWell(
                                          key: ValueKey('calendar-hour-slot-$hour'),
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () => _createAtHour(hour),
                                          child: SizedBox(
                                            height: 44,
                                            child: Row(children: [
                                              const Icon(
                                                Icons.add_circle_outline,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  '${strings.d3('ui5Create')} ${strings.appointment}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme.bodySmall,
                                                ),
                                              ),
                                            ]),
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          for (final entry in timed)
                                            ListTile(
                                              dense: true,
                                              minVerticalPadding: 0,
                                              title: Text(
                                                entry.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                entry.visibilityLabel(strings),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: const Icon(
                                                Icons.chevron_right, size: 16),
                                              onTap: () =>
                                                  openUnifiedAgendaEntry(
                                                    context,
                                                    widget.store,
                                                    entry,
                                                  ),
                                            ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              ),
              const SizedBox(height: 18),
              if (editorial)
                AnnaEditorialSectionHeading(title: selectedDateTitle)
              else
                SectionTitle(selectedDateTitle),
              const SizedBox(height: 10),
              if (events.isEmpty)
                editorial
                    ? AnnaOrganicCalendarEmptyAgenda(label: strings.noCommitments)
                    : SimpleCard(child: Text(strings.noCommitments))
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

/// Approved Oggi R3: one civil date and two accessible arrows.
class _TodaySingleDateNavigator extends StatelessWidget {
  const _TodaySingleDateNavigator({
    required this.selected,
    required this.onSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final language = AnnaStrings.of(context).languageCode;
    final date = _cap(DateFormat(
      'EEEE d MMMM yyyy',
      AnnaStrings.intlLocale(context),
    ).format(selected));
    final copy = switch (language) {
      'en' => ('Previous day', 'Next day'),
      'es' => ('Día anterior', 'Día siguiente'),
      'fr' => ('Jour précédent', 'Jour suivant'),
      'pt' => ('Dia anterior', 'Dia seguinte'),
      _ => ('Giorno precedente', 'Giorno successivo'),
    };
    return Semantics(
      identifier: 'ui5-today-single-date',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Semantics(
              identifier: 'today-date-prev',
              button: true,
              child: IconButton(
                key: const ValueKey('today-date-prev'),
                tooltip: copy.$1,
                onPressed: () => onSelected(addCivilDays(selected, -1)),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AnnaMotionV108.duration(context, 210),
                child: Text(
                  date,
                  key: ValueKey<String>(AgendaStore.dateKey(selected)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Semantics(
              identifier: 'today-date-next',
              button: true,
              child: IconButton(
                key: const ValueKey('today-date-next'),
                tooltip: copy.$2,
                onPressed: () => onSelected(addCivilDays(selected, 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  final AgendaStore store;
  final DateTime? initialDate;
  final bool embedded;
  // IndexedStack retains hidden tab states. Only foreground Oggi may clear
  // the transient shared filter for the chip-free Editorial presentation.
  final bool activeInShell;

  const PlannerScreen({
    super.key,
    required this.store,
    this.initialDate,
    this.embedded = false,
    this.activeInShell = true,
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
    // N18-01: Organic Today no longer mounts WeeklyReviewHomeCard, whose
    // initState previously reconciled enabled reminders. Keep that behavior
    // in the original Today owner without rendering a duplicate card.
    // Classic still reconciles through WeeklyReviewHomeCard.
    if (widget.embedded &&
        AnnaEditorialTodayMode.enabled.value &&
        widget.store.preferences.weeklyReviewReminderEnabled) {
      unawaited(WeeklyReviewReminders.reconcile(widget.store));
    }
    unawaited(AnnaEditorialTodayMode.ensureLoaded());
    unawaited(
      ExternalCalendarService.instance.initialize().then(
        (_) => _loadDay(day),
      ),
    );
  }

  Future<void> _loadDay(DateTime value) {
    // The Today advisor and free-slot engine inspect overnight appointments.
    // Load adjacent civil days so external entries match local overlap rules.
    final start = DateTime(value.year, value.month, value.day - 1);
    final end = DateTime(value.year, value.month, value.day + 2);
    return ExternalCalendarService.instance.loadRange(start, end);
  }

  void _selectDay(DateTime value) {
    setState(() => day = value);
    unawaited(_loadDay(value));
  }

  Future<void> _setEditorialMode(bool enabled) async {
    final saved = await AnnaEditorialTodayMode.setEnabled(enabled);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(annaEditorialTodaySaveFailure(
          AnnaStrings.of(context).languageCode,
        )),
      ));
    }
  }

  void _openSelectedDay() {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => PlannerScreen(store: widget.store, initialDate: day),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.store.agendaRevision,
        widget.store.inboxRevision,
        widget.store.sharedRevision,
        widget.store.journalRevision,
        widget.store.planningRevision,
        widget.store.workoutRevision,
        widget.store.settingsRevision,
        AnnaEditorialTodayMode.enabled,
        ExternalCalendarService.instance,
      ]),
      builder: (context, _) {
        unawaited(HomeWidgetBridge.instance.sync(widget.store));
        final strings = AnnaStrings.of(context);
        final editorial = widget.embedded && AnnaEditorialTodayMode.enabled.value;
        final organic = editorial && AnnaOrganicPastel.enabled(context);
        // Hybrid deliberately shows the complete day without filter chips.
        // A filter selected in Calendar/Week must not remain invisibly active
        // when returning to this Home. Reset only the in-memory view filter,
        // never the private/shared records or their persisted preferences.
        if (editorial &&
            widget.activeInShell &&
            ModalRoute.of(context)?.isCurrent == true &&
            widget.store.agendaContentFilter != AgendaContentFilter.all) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                !widget.embedded ||
                !widget.activeInShell ||
                ModalRoute.of(context)?.isCurrent != true ||
                !AnnaEditorialTodayMode.enabled.value) {
              return;
            }
            if (widget.store.agendaContentFilter != AgendaContentFilter.all) {
              widget.store.setAgendaContentFilter(AgendaContentFilter.all);
            }
          });
        }
        final snapshot = widget.store.dayHubSnapshot(day);
        final memoryRecall = widget.store.memoryRecallSnapshot(day);
        final timedPrivate = snapshot.agenda
            .where((entry) =>
                entry.type == ItemType.appointment &&
                entry.start != null &&
                entry.isPrivate)
            .map((entry) => entry.privateItem!)
            .toList();

        final isToday = AgendaStore.sameDay(day, DateTime.now());
        final upcoming = isToday
            ? widget.store.unifiedUpcoming(DateTime.now())
            : const <UnifiedAgendaEntry>[];
        final pinnedItems = isToday &&
                widget.store.agendaContentFilter !=
                    AgendaContentFilter.sharedOnly
            ? widget.store.items.where((item) => item.pinned).toList()
            : const <AgendaItem>[];

        // Existing approved cards keep their order and data ownership.
        // Editorial places them BELOW its journal hero, while Classic
        // preserves the original review-first sequence.
        final planningCards = <Widget>[
          if (widget.embedded && isToday)
            for (final card in widget.store.preferences.todayCardOrder) ...[
              if (card == 'review' && !editorial) ...[
                const SizedBox(height: 12),
                WeeklyReviewHomeCard(
                  key: const ValueKey('cap0147-review'),
                  store: widget.store,
                ),
              ],
              if (card == 'realistic') ...[
                const SizedBox(height: 12),
                RealisticDayCard(
                  key: const ValueKey('cap0147-realistic'),
                  store: widget.store,
                  snapshot: snapshot,
                  hideDetails: widget.store.preferences.hideHomeDetails,
                ),
              ],
            ],
        ];

        return Scaffold(
          backgroundColor: editorial
              ? Theme.of(context).brightness == Brightness.dark
                  ? AnnaEditorialColors.of(context).canvas
                  : AnnaOrganicPastel.canvas
              : null,
          floatingActionButton: widget.embedded ? null : FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(
              context,
              widget.store,
              captureDate: day,
              entryPoint: UnifiedCaptureEntryPoint.day,
            ),
            icon: const Icon(Icons.add),
            label: Text(strings.capture),
          ),
          appBar: editorial ? null : AppBar(
            toolbarHeight: 82,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.embedded
                      ? approvedTodayGreeting(
                          strings.languageCode,
                          widget.store.preferences.displayName,
                          DateTime.now().hour,
                        )
                      : strings.myDay,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  widget.embedded
                      ? _dailyQuote(day, strings).$2
                      : _cap(DateFormat(
                          'EEEE d MMMM',
                          AnnaStrings.intlLocale(context),
                        ).format(day)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (widget.embedded)
                IconButton(
                  key: const ValueKey<String>('today-open-calendar'),
                  tooltip: strings.navCalendar,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CalendarHubScreen(store: widget.store),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              if (widget.embedded)
                IconButton(
                  key: const ValueKey<String>('today-editorial-enable'),
                  tooltip: annaEditorialTodayModeLabel(
                    strings.languageCode, returnToClassic: false,
                  ),
                  onPressed: () => unawaited(_setEditorialMode(true)),
                  icon: const Icon(Icons.auto_awesome_outlined),
                ),
              if (!AgendaStore.sameDay(day, DateTime.now()))
                TextButton(
                  onPressed: () => _selectDay(DateTime.now()),
                  child: Text(strings.navToday),
                ),
            ],
          ),
          body: SafeArea(
            // The Organic masthead paints behind the status bar; its buttons
            // independently respect the device's top viewPadding.
            top: editorial && !organic,
            bottom: false,
            child: Column(
            children: [
              if (widget.embedded && !editorial)
                _TodaySingleDateNavigator(
                  selected: day,
                  onSelected: _selectDay,
                )
              else if (!widget.embedded)
                DateStrip(
                  selected: day,
                  onSelected: _selectDay,
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AnnaDesignTokens.readingContentWidth,
                    ),
                    child: AnnaMotionReveal(
                      token: day.millisecondsSinceEpoch,
                      child: Builder(
                        builder: (context) {
                          final pageContent = <Widget>[
                        for (final content in <Widget>[
                        if (editorial && !organic) ...[
                          AnnaTodayEditorialGreetingToolbar(
                            activeInShell: widget.activeInShell,
                            greeting: approvedTodayGreeting(
                              strings.languageCode,
                              widget.store.preferences.displayName,
                              DateTime.now().hour,
                            ),
                            calendarTooltip: strings.navCalendar,
                            classicTooltip: annaEditorialTodayModeLabel(
                              strings.languageCode, returnToClassic: true,
                            ),
                            onOpenCalendar: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => CalendarHubScreen(
                                  store: widget.store,
                                ),
                              ),
                            ),
                            onReturnToClassic: () =>
                                unawaited(_setEditorialMode(false)),
                          ),
                          const SizedBox(height: 4),
                          if (!AgendaStore.sameDay(day, DateTime.now()))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const ValueKey<String>('editorial-today-return'),
                                onPressed: () => _selectDay(DateTime.now()),
                                icon: const Icon(Icons.today_outlined),
                                label: Text(strings.navToday),
                              ),
                            ),
                          const SizedBox(height: 12),
                          const AnnaOrganicPastelLandscape(
                            height: 96,
                            radius: 20,
                          ),
                          const SizedBox(height: 12),
                          AnnaOrganicPastelWeekStrip(
                            selected: day,
                            onSelected: _selectDay,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (organic) ...[
                          if (!AgendaStore.sameDay(day, DateTime.now()))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const ValueKey<String>(
                                  'editorial-today-return',
                                ),
                                onPressed: () => _selectDay(DateTime.now()),
                                icon: const Icon(Icons.today_outlined),
                                label: Text(strings.navToday),
                              ),
                            ),
                          AnnaOrganicPastelWeekStrip(
                            selected: day,
                            onSelected: _selectDay,
                          ),
                          const SizedBox(height: 14),
                        ],
                        // R3 embeds the daily wish directly below the greeting,
                        // not in a repeated standalone opening card.
                        if (!widget.embedded) _DayOpeningCard(date: day),
                        // Classic keeps its original planning-first hierarchy.
                        if (!editorial) ...planningCards,
                        if (!editorial) ...[
                          const SizedBox(height: 12),
                          AgendaContentFilterBar(store: widget.store),
                          const SizedBox(height: AnnaDesignTokens.spaceMd),
                        ] else
                          const SizedBox(height: 4),
                        if (widget.embedded) ...[
                          // Organic Preview: only actual authorized
                          // agenda entries. Open via the existing editor.
                          if (editorial && snapshot.agenda.isNotEmpty) ...[
                            AnnaOrganicPastelAgendaDigest(
                              entries: snapshot.agenda,
                              hideDetails:
                                  widget.store.preferences.hideHomeDetails,
                              onOpenEntry: (entry) =>
                                  openUnifiedAgendaEntry(
                                    context, widget.store, entry,
                                  ),
                              onOpenDay: _openSelectedDay,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (editorial) ...[
                            AnnaOrganicPastelQuickLinks(
                              store: widget.store,
                              selectedDate: day,
                            ),
                            const SizedBox(height: 14),
                          ],
                          // DF-08–14: Oggi reads the selected day before
                          // any editor. Create stays in the shell's + Crea.
                          if (editorial)
                            AnnaEditorialTodayOverview(
                              store: widget.store,
                              selectedDate: day,
                              hideDetails: widget.store.preferences.hideHomeDetails,
                              onOpenDiary: _openSelectedDay,
                              onOpenWeek: () {
                                // Same week selection as the existing
                                // WeeklyReviewHomeCard, no new workflow.
                                final now = DateTime.now();
                                final current = wrMonday(now);
                                final review = now.weekday == DateTime.monday
                                    ? DateTime(current.year, current.month,
                                        current.day - 7)
                                    : current;
                                final plan = now.weekday == DateTime.sunday
                                    ? DateTime(current.year, current.month,
                                        current.day + 7)
                                    : current;
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => WeeklyReviewScreen(
                                      store: widget.store,
                                      reviewWeek: review,
                                      planWeek: plan,
                                      initialStep:
                                          now.weekday != DateTime.sunday &&
                                                  now.weekday != DateTime.monday
                                              ? 2
                                              : 0,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            AnnaMotionStagger(
                              key: const ValueKey<String>('v108-today-summary'),
                              order: 0,
                              child: _TodayCompactSummary(snapshot: snapshot),
                            ),
                          // Keep memories immediately BELOW "Il mio diario".
                          // Recalls are still canonical and shown only when
                          // there is genuine, authorized journal history.
                          if (editorial &&
                              (memoryRecall.onThisDay.isNotEmpty ||
                                  memoryRecall.sameMonthPastYears.isNotEmpty)) ...[
                            _DayMemoryRecallCard(
                              store: widget.store,
                              anchor: day,
                              memories: memoryRecall.onThisDay.isNotEmpty
                                  ? memoryRecall.onThisDay
                                  : memoryRecall.sameMonthPastYears,
                              exactAnniversary:
                                  memoryRecall.onThisDay.isNotEmpty,
                              hideDetails:
                                  widget.store.preferences.hideHomeDetails,
                            ),
                            const SizedBox(height: 14),
                          ],
                          // Hero-first rhythm is exclusive to the Editorial Home.
                          if (editorial) ...planningCards,
                          if (isToday && (upcoming.isNotEmpty || pinnedItems.isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            _TodayFocusCard(
                              next: upcoming.isEmpty ? null : upcoming.first,
                              globalPendingTasks: widget.store.pendingUnifiedTaskCount,
                              inboxCount: widget.store.activeInboxEntries.length,
                              hideDetails: widget.store.preferences.hideHomeDetails,
                              onOpenNext: upcoming.isEmpty
                                  ? null
                                  : () => openUnifiedAgendaEntry(
                                        context,
                                        widget.store,
                                        upcoming.first,
                                      ),
                              onOpenInbox: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => InboxScreen(store: widget.store),
                                ),
                              ),
                            ),
                          ],
                          if (isToday && pinnedItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Column(
                              key: const ValueKey<String>('today-pinned-section'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionTitle(strings.v100Pinned),
                                const SizedBox(height: 8),
                                ...pinnedItems.take(3).map((item) => EventTile(
                                  store: widget.store,
                                  item: item,
                                  compact: true,
                                  hideDetails: widget.store.preferences.hideHomeDetails,
                                )),
                              ],
                            ),
                          ],
                          if (isToday &&
                              widget.store.agendaContentFilter !=
                                  AgendaContentFilter.sharedOnly) ...[
                            const SizedBox(height: 12),
                            TodayCatchUpCard(
                              store: widget.store,
                              hideDetails: widget.store.preferences.hideHomeDetails,
                            ),
                          ],
                          if (isToday && snapshot.journal.mood != null) ...[
                            const SizedBox(height: AnnaDesignTokens.spaceSm),
                            _TodayWellbeingCard(
                              key: const ValueKey<String>('today-wellbeing-card'),
                              store: widget.store,
                              date: day,
                            ),
                          ],
                          AnnaMotionStagger(
                            key: const ValueKey<String>('v108-today-diary'),
                            order: 2,
                            child: _TodayCompactDiaryPreview(
                              store: widget.store,
                              snapshot: snapshot,
                              hideDetails: widget.store.preferences.hideHomeDetails,
                            ),
                          ),
                        ] else ...[
                          AnnaJournalSectionHeading(title: strings.diary),
                          const SizedBox(height: AnnaDesignTokens.spaceSm),
                          JournalEditor(store: widget.store, date: day),
                          const SizedBox(height: 12),
                          _DayLifeOverviewCard(snapshot: snapshot, hideDetails: false),
                          if (isToday) ...[
                            const SizedBox(height: 14),
                            _TodayWellbeingCard(
                              key: const ValueKey<String>('today-wellbeing-card'),
                              store: widget.store,
                              date: day,
                            ),
                          ],
                        ],
                        const SizedBox(height: 14),
                        if (!editorial &&
                            (memoryRecall.onThisDay.isNotEmpty ||
                                memoryRecall.sameMonthPastYears.isNotEmpty)) ...[
                          _DayMemoryRecallCard(
                            store: widget.store,
                            anchor: day,
                            memories: memoryRecall.onThisDay.isNotEmpty
                                ? memoryRecall.onThisDay
                                : memoryRecall.sameMonthPastYears,
                            exactAnniversary: memoryRecall.onThisDay.isNotEmpty,
                            hideDetails: widget.embedded &&
                                widget.store.preferences.hideHomeDetails,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (isToday) ...[
                          const SizedBox(height: AnnaDesignTokens.spaceLg),
                          DailyRitualCard(
                            store: widget.store,
                            date: day,
                          ),
                        ],
                        if (widget.embedded && isToday) ...[
                          const SizedBox(height: 12),
                          TodayTomorrowCard(
                            store: widget.store,
                            hideDetails: widget.store.preferences.hideHomeDetails,
                          ),
                        ],
                        if (!widget.embedded && snapshot.lifeEntries.isNotEmpty) ...[
                          const SizedBox(height: AnnaDesignTokens.spaceLg),
                          _DayLifeStream(snapshot: snapshot, store: widget.store),
                        ],
                        const SizedBox(height: 14),
                        // The embedded Home no longer duplicates the hourly
                        // timeline: "Impegni" opens its dedicated page.
                        // Standalone day detail retains its legacy affordance.
                        if (!widget.embedded)
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
                        ])
                          organic
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: content,
                                )
                              : content,
                          ];
                          if (!organic) {
                            // Classic and the non-Organic editorial variant
                            // retain their original scroll behavior.
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(
                                20, 14, 20, 110,
                              ),
                              children: pageContent,
                            );
                          }
                          return CustomScrollView(
                            key: const ValueKey<String>(
                              'organic-pastel-collapsing-scroll',
                            ),
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: AnnaOrganicPastelHeroSliverDelegate(
                                  topInset:
                                      MediaQuery.viewPaddingOf(context).top,
                                  toolbar: AnnaTodayEditorialGreetingToolbar(
                                    activeInShell: widget.activeInShell,
                                    greeting: approvedTodayGreeting(
                                      strings.languageCode,
                                      widget.store.preferences.displayName,
                                      DateTime.now().hour,
                                    ),
                                    calendarTooltip: strings.navCalendar,
                                    classicTooltip: annaEditorialTodayModeLabel(
                                      strings.languageCode,
                                      returnToClassic: true,
                                    ),
                                    onOpenCalendar: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => CalendarHubScreen(
                                          store: widget.store,
                                        ),
                                      ),
                                    ),
                                    onReturnToClassic: () =>
                                        unawaited(_setEditorialMode(false)),
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.only(bottom: 110),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate(pageContent),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

    final organic = AnnaOrganicPastel.enabled(context);
    return Container(
      padding: EdgeInsets.all(organic ? 17 : 15),
      decoration: BoxDecoration(
        color: organic
            ? AnnaOrganicPastel.surface(context)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(organic ? 23 : 20),
        border: Border.all(
          color: organic
              ? AnnaEditorialColors.of(context).border
              : scheme.outlineVariant,
        ),
        boxShadow: organic
            ? [
                BoxShadow(
                  color: AnnaEditorialColors.of(context).shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
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
                  style: organic
                       ? AnnaJournalTypography.editorial(context, size: 18)
                       : const TextStyle(fontWeight: FontWeight.w800),
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

/// DF-08–12: concise, real-data day overview with one empty-day state.
class _TodayCompactSummary extends StatelessWidget {
  final DayHubSnapshot snapshot;

  const _TodayCompactSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    if (snapshot.isEmpty) {
      return Padding(
        key: const ValueKey<String>('ui5-today-empty'),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 30,
              color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(strings.d3('ui5NoMemoriesDay'),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }
    final summary = <({IconData icon, String label, String value})>[
      if (snapshot.agenda.isNotEmpty || snapshot.birthdays.isNotEmpty)
        (
          icon: Icons.event_outlined,
          label: strings.d3('ui5Commitments'),
          value: '${snapshot.agenda.length + snapshot.birthdays.length}',
        ),
      if (snapshot.workouts.isNotEmpty)
        (
          icon: Icons.directions_run_outlined,
          label: strings.d3('ui5Activities'),
          value: '${snapshot.workouts.length}',
        ),
      if (snapshot.journal.mood != null)
        (
          icon: Icons.favorite_border,
          label: strings.d3('ui5Wellbeing'),
          value: strings.d3('ui5Recorded'),
        ),
    ];
    return Wrap(
      key: const ValueKey<String>('ui5-today-summary'),
      spacing: 8,
      runSpacing: 8,
      children: summary.map((item) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 98, minHeight: 54),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 17,
                  color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: Theme.of(context).textTheme.labelSmall),
                    Text(item.value,
                      style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

/// DF-13/14: a read-only selected-day diary summary, NOT a second composer.
class _TodayCompactDiaryPreview extends StatelessWidget {
  final AgendaStore store;
  final DayHubSnapshot snapshot;
  final bool hideDetails;

  const _TodayCompactDiaryPreview({
    required this.store,
    required this.snapshot,
    this.hideDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = snapshot.journal.blocks
        .where((block) => !block.archived)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (blocks.isEmpty && !snapshot.hasJournalContent) {
      return const SizedBox.shrink();
    }
    final strings = AnnaStrings.of(context);
    void openDiary() {
      Navigator.push(context, MaterialPageRoute<void>(
        builder: (_) => PlannerScreen(
          store: store, initialDate: snapshot.date),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        key: const ValueKey<String>('ui5-today-diary-preview'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: AnnaJournalSectionHeading(
                title: strings.d3('ui5DayDiary'))),
              TextButton(
                onPressed: openDiary,
                child: Text(strings.d3('ui5ShowAll')),
              ),
            ],
          ),
          for (final block in blocks.take(2))
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Icon(switch (block.type) {
                  DiaryBlockType.note => Icons.sticky_note_2_outlined,
                  DiaryBlockType.sketch => Icons.draw_outlined,
                  DiaryBlockType.photo => Icons.photo_outlined,
                  DiaryBlockType.voice => Icons.mic_none_outlined,
                }),
                title: Text(hideDetails
                    ? '•••'
                    : store.diaryBlockDisplayTitle(block, strings: strings),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: openDiary,
              ),
            ),
          if (blocks.isEmpty)
            Card(child: ListTile(
              title: Text(hideDetails
                  ? '•••'
                  : snapshot.journal.note.trim().isNotEmpty
                      ? snapshot.journal.note.trim()
                      : strings.diary,
                maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: openDiary,
            )),
        ],
      ),
    );
  }
}

/// DF-19/20: only one compact, real memory teaser in Oggi. Full anniversary
/// carousel, year chips and fallback navigation live inside Ricordi → Per te.
class _DayMemoryRecallCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime anchor;
  final List<DiaryBlockReference> memories;
  final bool exactAnniversary;
  final bool hideDetails;

  const _DayMemoryRecallCard({
    required this.store,
    required this.anchor,
    required this.memories,
    this.exactAnniversary = true,
    this.hideDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();
    final memory = memories.first;
    final strings = AnnaStrings.of(context);
    final years = anchor.year - memory.date.year;
    final date = DateFormat(
      'd MMMM yyyy', AnnaStrings.intlLocale(context)).format(memory.date);
    final title = store.diaryBlockDisplayTitle(
      memory.block, strings: strings);
    final block = memory.block;
    final preview = !hideDetails &&
        block.type == DiaryBlockType.photo && block.hasPhotoMedia
        ? DiaryMediaImage(
            assetId: block.mediaThumbnailAssetId.isNotEmpty
                ? block.mediaThumbnailAssetId : block.mediaAssetId,
            fallbackBase64: block.imageBase64,
            cacheWidth: 150,
          )
        : !hideDetails &&
            block.type == DiaryBlockType.sketch && block.pages.isNotEmpty
            ? DiarySketchPagePreview(page: block.pages.first)
            : Center(child: Icon(switch (block.type) {
                DiaryBlockType.note => Icons.sticky_note_2_outlined,
                DiaryBlockType.sketch => Icons.draw_outlined,
                DiaryBlockType.photo => Icons.photo_outlined,
                DiaryBlockType.voice => Icons.mic_none_outlined,
              }, color: Theme.of(context).colorScheme.primary));
    if (AnnaOrganicPastel.enabled(context)) {
      final ageLabel = years == 1
          ? strings.d3('ui5OneYearAgo')
          : strings.d3Format('ui5YearsAgo', {'years': years});
      final dateLine = exactAnniversary ? '$ageLabel · $date' : date;
      return Column(
        key: const ValueKey<String>('ui5-today-memory-teaser'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 9),
            child: Text(
              strings.d3('ui5MemoryTeaser'),
              style: AnnaJournalTypography.editorial(context, size: 18)
                  .copyWith(color: AnnaOrganicPastel.text(context)),
            ),
          ),
          AnnaOrganicPaperSurface(
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DiaryMemoriesScreen(store: store),
              ),
            ),
            semanticLabel: strings.d3('ui5MemoryTeaser'),
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 80,
                    height: 72,
                    child: ColoredBox(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF364D42)
                          : AnnaOrganicPastel.peach,
                      child: preview,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hideDetails ? '•••' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AnnaJournalTypography.editorial(
                          context,
                          size: 16,
                        ).copyWith(color: AnnaOrganicPastel.text(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hideDetails ? '•••' : dateLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : AnnaOrganicPastel.quietInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : AnnaOrganicPastel.oliveInk,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey<String>('ui5-today-memory-teaser'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnaJournalSectionHeading(title: strings.d3('ui5MemoryTeaser')),
        const SizedBox(height: 7),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => DiaryMemoriesScreen(store: store),
            )),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      width: 64, height: 64,
                      child: preview,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hideDetails ? '•••' : title, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(exactAnniversary
                          ? '${years == 1 ? strings.d3('ui5OneYearAgo') : strings.d3Format('ui5YearsAgo', {'years': years})} · $date'
                          : date,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2),
                    ],
                  )),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  final UnifiedAgendaEntry? next;
  final int globalPendingTasks;
  final int inboxCount;
  final bool hideDetails;
  final VoidCallback? onOpenNext;
  final VoidCallback onOpenInbox;

  const _TodayFocusCard({
    required this.next,
    required this.globalPendingTasks,
    required this.inboxCount,
    required this.hideDetails,
    required this.onOpenNext,
    required this.onOpenInbox,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final nextText = next == null
        ? strings.v100NoUpcoming
        : hideDetails
            ? strings.v100NextScheduled
            : '${DateFormat('EEE d MMM', AnnaStrings.intlLocale(context)).format(next!.date)} · '
                '${formatTime(next!.start!)} · ${next!.title}'
                '${next!.isShared ? ' · ${strings.d3('sharedSpace')}' : ''}';

    return Semantics(
      identifier: 'today-focus-card',
      container: true,
      child: Container(
        key: const ValueKey<String>('today-focus-card'),
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnnaVisualDomain.today.softSurface(scheme),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.v100TodayBrief,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpenNext,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined, color: scheme.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      nextText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (onOpenNext != null) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          if (globalPendingTasks > 0 || inboxCount > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (globalPendingTasks > 0)
                  _MiniPill(
                    icon: Icons.task_alt_outlined,
                    text: strings.v100OpenTasks(globalPendingTasks),
                  ),
                if (inboxCount > 0)
                  ActionChip(
                    avatar: const Icon(Icons.inbox_outlined, size: 17),
                    label: Text(strings.v100InboxCount(inboxCount)),
                    onPressed: onOpenInbox,
                  ),
              ],
            ),
          ],
          ],
        ),
      ),
    );
  }
}

class _TodayWellbeingCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime date;

  const _TodayWellbeingCard({
    super.key,
    required this.store,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final journal = store.journal(date);
    final totalHabits = store.habits.length;
    final doneHabits = journal.completedHabitIds
        .where((id) => store.habits.any((habit) => habit.id == id))
        .length;
    final gratitudeCount = journal.gratitude.length.clamp(0, 3);
    final accent = context.accentSurface;

    return Semantics(
      identifier: 'today-wellbeing-card',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: accent.gradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.chipBackground,
                shape: BoxShape.circle,
              ),
              child: Text(
                journal.mood?.emoji ?? '♡',
                style: TextStyle(
                  color: accent.foreground,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.mood == null
                        ? AnnaStrings.of(context).v100HowDayGoing
                        : AnnaStrings.of(context).v100MoodToday(journal.mood!),
                    style: TextStyle(
                      color: accent.foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (store.preferences.isModuleEnabled(AppModule.habits))
                        Text(
                          totalHabits == 0
                              ? AnnaStrings.of(context).v100NoHabits
                              : AnnaStrings.of(context)
                                  .v100HabitsProgress(
                                    doneHabits,
                                    totalHabits,
                                  ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: accent.secondaryForeground,
                                  ),
                        ),
                      Text(
                        AnnaStrings.of(context)
                            .v100GratitudeProgress(gratitudeCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accent.secondaryForeground,
                            ),
                      ),
                      Text(
                        journal.blocks.isEmpty
                            ? AnnaStrings.of(context).v100NoMemory
                            : AnnaStrings.of(context)
                                .v100MemoryCount(journal.blocks.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accent.secondaryForeground,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final bool hideDetails;

  const _DayLifeOverviewCard({
    required this.snapshot,
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
        color: AnnaVisualDomain.calendar.softSurface(scheme),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AnnaStrings.of(context).d3('dayMoments'),
                  style: const TextStyle(
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AnnaStrings.of(context).d3('noDayMoments'),
              ),
            )
          else
            ...entries.map(
              (entry) {
                final data = _dayLifePresentation(
                  entry,
                  snapshot.date,
                  AnnaStrings.of(context),
                );
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
  final bool organicStyle;

  const _TimelineHint({
    required this.eventCount,
    this.organicStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: organicStyle
          ? const ValueKey<String>('commitments-organic-hint')
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: organicStyle ? 16 : 12,
        vertical: organicStyle ? 13 : 9,
      ),
      decoration: BoxDecoration(
        color: organicStyle
            ? AnnaOrganicPastel.surface(context)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(organicStyle ? 19 : 16),
        border: organicStyle
            ? Border.all(
                color: scheme.outlineVariant.withValues(alpha: .66),
              )
            : null,
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

/// Dedicated hourly commitments view opened from the Organic Home shortcut.
/// Owns no records or editor: it reuses the canonical private appointment
/// projection and the exact same DayTimeline gestures/create/edit callbacks.
class AnnaCommitmentsTimelineScreen extends StatefulWidget {
  final AgendaStore store;
  final DateTime? initialDate;

  const AnnaCommitmentsTimelineScreen({
    super.key,
    required this.store,
    this.initialDate,
  });

  @override
  State<AnnaCommitmentsTimelineScreen> createState() =>
      _AnnaCommitmentsTimelineScreenState();
}

class _AnnaCommitmentsTimelineScreenState
    extends State<AnnaCommitmentsTimelineScreen> {
  late DateTime _selected;
  late final ScrollController _timelineScroll;
  // N18-03: Journal opens on the compact canonical agenda; the existing
  // complete 24-hour timeline remains explicitly available. Classic still
  // opens on the original timeline, without a new persistence preference.
  bool _showTimeline = false;

  @override
  void initState() {
    super.initState();
    final source = widget.initialDate ?? DateTime.now();
    _selected = DateTime(source.year, source.month, source.day);
    // Open on the useful working-day portion. The original 00:00–24:00
    // timeline remains fully scrollable and no events are filtered by hour.
    _timelineScroll = ScrollController(
      initialScrollOffset: DayTimeline.offsetForMinutes(7 * 60),
    );
    // This screen also projects Android calendar items in its compact list.
    // Initialize/load the selected civil-day window just as PlannerScreen
    // does; otherwise navigation may show a false empty state for days not
    // previously requested by another route.
    unawaited(
      ExternalCalendarService.instance.initialize().then(
        (_) => _loadSelectedCalendarDay(_selected),
      ),
    );
  }

  Future<void> _loadSelectedCalendarDay(DateTime value) {
    final start = DateTime(value.year, value.month, value.day - 1);
    final end = DateTime(value.year, value.month, value.day + 2);
    return ExternalCalendarService.instance.loadRange(start, end);
  }

  @override
  void dispose() {
    _timelineScroll.dispose();
    super.dispose();
  }

  void _selectDay(DateTime selected) {
    final date = DateTime(selected.year, selected.month, selected.day);
    setState(() => _selected = date);
    unawaited(_loadSelectedCalendarDay(date));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final organic = AnnaOrganicPastel.enabled(context);
    return Scaffold(
      key: const ValueKey<String>('commitments-hourly-timeline-screen'),
      backgroundColor: organic
          ? (Theme.of(context).brightness == Brightness.dark
              ? AnnaEditorialColors.of(context).canvas
              : AnnaOrganicPastel.canvas)
          : null,
      appBar: AppBar(
        title: Text(
          strings.d3('ui5Commitments'),
          style: organic
              ? AnnaJournalTypography.editorial(context, size: 25)
              : null,
        ),
        actions: [
          IconButton(
            key: const ValueKey<String>('commitments-today'),
            tooltip: strings.navToday,
            onPressed: () => _selectDay(DateTime.now()),
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        // The list uses the same authorized unified day projection as Calendar,
        // including shared and already-loaded external entries.
        animation: Listenable.merge([
          widget.store.agendaRevision,
          widget.store.sharedRevision,
          ExternalCalendarService.instance,
        ]),
        builder: (context, _) {
          final snapshot = widget.store.dayHubSnapshot(_selected);
          final timedPrivate = snapshot.agenda
              .where((entry) =>
                  entry.type == ItemType.appointment &&
                  entry.start != null &&
                  entry.isPrivate)
              .map((entry) => entry.privateItem!)
              .toList();
          return Column(
            children: [
              if (organic)
                _AnnaCommitmentsOrganicHeader(
                  selected: _selected,
                  eventCount: timedPrivate.length,
                  onSelected: _selectDay,
                )
              else
                _TodaySingleDateNavigator(
                  selected: _selected,
                  onSelected: _selectDay,
                ),
              if (organic)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 3, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AnnaOrganicJournalFilterPill(
                          semanticsId: 'commitments-view-list',
                          label: switch (strings.languageCode) {
                            'it' => 'Elenco',
                            'es' => 'Lista',
                            'fr' => 'Liste',
                            'pt' => 'Lista',
                            _ => 'List',
                          },
                          icon: Icons.view_list_rounded,
                          selected: !_showTimeline,
                          onTap: () => setState(() => _showTimeline = false),
                        ),
                        AnnaOrganicJournalFilterPill(
                          semanticsId: 'commitments-view-timeline',
                          label: strings.hourlyTimeline,
                          icon: Icons.schedule_outlined,
                          selected: _showTimeline,
                          onTap: () => setState(() => _showTimeline = true),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: organic && !_showTimeline
                    ? ListView(
                        key: const ValueKey<String>(
                          'commitments-organic-compact-list',
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 7, 16, 28),
                        children: [
                          AnnaEditorialSectionHeading(
                            title: strings.d3('ui5Commitments'),
                          ),
                          // A list-first view must retain the canonical
                          // task/appointment capture affordance previously
                          // available through hourly timeline tap gestures.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const ValueKey<String>(
                                'commitments-list-create',
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: () => _showQuickCapture(
                                context,
                                widget.store,
                                captureDate: _selected,
                                entryPoint: UnifiedCaptureEntryPoint.day,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(strings.capture),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (snapshot.agenda.isEmpty)
                            AnnaOrganicCalendarEmptyAgenda(
                              label: strings.noCommitments,
                            )
                          else
                            for (final entry in snapshot.agenda)
                              UnifiedAgendaTile(
                                store: widget.store,
                                entry: entry,
                                compact: true,
                              ),
                        ],
                      )
                    : SingleChildScrollView(
                  key: const ValueKey<String>(
                    'commitments-hourly-scroll',
                  ),
                  controller: _timelineScroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AnnaDesignTokens.readingContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TimelineHint(
                            eventCount: timedPrivate.length,
                            organicStyle: organic,
                          ),
                          const SizedBox(height: 12),
                          DayTimeline(
                            key: const ValueKey<String>(
                              'commitments-canonical-day-timeline',
                            ),
                            date: _selected,
                            events: timedPrivate,
                            store: widget.store,
                            organicStyle: organic,
                            onChanged: () {
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


/// Premium header for the dedicated Impegni route. The date controls are the
/// canonical civil-day navigator; the count refers ONLY to timed private
/// appointments, never to external/shared items or all tasks.
class _AnnaCommitmentsOrganicHeader extends StatelessWidget {
  final DateTime selected;
  final int eventCount;
  final ValueChanged<DateTime> onSelected;

  const _AnnaCommitmentsOrganicHeader({
    required this.selected,
    required this.eventCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final language = AnnaStrings.of(context).languageCode;
    final (eyebrow, heading, singularLabel, pluralLabel) =
        switch (language) {
      'en' => ('YOUR DAY', 'One hour at a time',
          'personal appointment', 'personal appointments'),
      'es' => ('TU DÍA', 'Cada hora cuenta',
          'cita personal', 'citas personales'),
      'fr' => ('VOTRE JOURNÉE', 'Chaque heure compte',
          'rendez-vous personnel', 'rendez-vous personnels'),
      'pt' => ('O SEU DIA', 'Cada hora conta',
          'compromisso pessoal', 'compromissos pessoais'),
      _ => ('LA TUA GIORNATA', 'Ogni ora conta',
          'appuntamento personale', 'appuntamenti personali'),
    };
    final base = AnnaOrganicPastel.surface(context);
    final accent = scheme.primary;
    final ink = AnnaOrganicPastel.text(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AnnaDesignTokens.readingContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            key: const ValueKey<String>('commitments-organic-header'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(base, accent, dark ? .13 : .09)!,
                  Color.lerp(base, scheme.tertiaryContainer, dark ? .15 : .24)!,
                  base,
                ],
              ),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .6),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                  color: scheme.shadow.withValues(alpha: dark ? .10 : .045),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 41,
                          height: 41,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: dark ? .24 : .13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: ink,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              Text(
                                heading,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AnnaJournalTypography.editorial(
                                  context,
                                  size: 21,
                                ).copyWith(color: ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Keep the existing accessible 48dp day arrows and
                  // unchanged date localization/motion behavior.
                  _TodaySingleDateNavigator(
                    selected: selected,
                    onSelected: onSelected,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        key: const ValueKey<String>(
                          'commitments-private-count',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(
                            alpha: dark ? .65 : .86,
                          ),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: .5),
                          ),
                        ),
                        child: Text(
                          '$eventCount ${eventCount == 1 ? singularLabel : pluralLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DayTimeline extends StatelessWidget {
  final DateTime date;
  final List<AgendaItem> events;
  final AgendaStore store;
  final VoidCallback onChanged;
  // Only the dedicated Impegni screen opts in; Calendar/Classic are untouched.
  final bool organicStyle;

  const DayTimeline({
    super.key,
    required this.date,
    required this.events,
    required this.store,
    required this.onChanged,
    this.organicStyle = false,
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
          key: organicStyle
              ? const ValueKey<String>('commitments-organic-hour-grid')
              : null,
          decoration: BoxDecoration(
            color: organicStyle
                ? AnnaOrganicPastel.surface(context)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(organicStyle ? 22 : 24),
            border: Border.all(
              color: organicStyle
                  ? Theme.of(context)
                      .colorScheme.outlineVariant.withValues(alpha: .62)
                  : Theme.of(context).colorScheme.outlineVariant,
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
                      organicStyle: organicStyle,
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
    final scheme = Theme.of(context).colorScheme;
    final background = Color.alphaBlend(
      base.withValues(alpha: organicStyle ? .11 : .16),
      organicStyle ? AnnaOrganicPastel.surface(context) : scheme.surface,
    );
    // On one-hour slots accessibility text can exceed the fixed 74dp
    // timeline cell. Preserve the real title and time by dropping only
    // secondary category/notes at high text scale; never shrink font size.
    final textScale =
        MediaQuery.textScalerOf(context).scale(13) / 13;
    final compactForText = organicStyle &&
        (height < 68 * textScale || placement.laneCount > 2);
    final showTime = !organicStyle ||
        !compactForText ||
        height >= 36 + 20 * textScale;
    final showNote = !organicStyle ||
        (!compactForText && height >= 110 * textScale);

    return Positioned(
      top: top + 2,
      left: left,
      width: laneWidth,
      height: max(1.0, height - 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(organicStyle ? 17 : 14),
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
              // Keep scaled title + time within 60-minute slots without
              // clipping or reducing the user's accessibility text size.
              vertical: compactForText ? 3 : 7,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(organicStyle ? 17 : 14),
              border: Border.all(
                color: base.withValues(alpha: organicStyle ? .23 : .55),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: organicStyle ? 10 : 4,
                  offset: Offset(0, organicStyle ? 3 : 2),
                  color: scheme.shadow.withValues(
                    alpha: organicStyle ? .055 : .07,
                  ),
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
                      if (placement.laneCount <= 2 && !compactForText)
                        Row(
                          children: [
                            Icon(
                              event.category.icon,
                              size: 13,
                              color: organicStyle
                                  ? scheme.onSurfaceVariant
                                  : base,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                AnnaStrings.of(context).editorCategoryLabel(event.category),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: organicStyle
                                      ? scheme.onSurfaceVariant
                                      : base,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Text(
                        event.title,
                        maxLines: compactForText || height < 58 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: organicStyle ? scheme.onSurface : null,
                          fontSize: placement.laneCount > 2 ? 11 : 13,
                        ),
                      ),
                      if (height >= 52 && showTime)
                        Text(
                          event.end == null
                              ? formatTime(start)
                              : '${formatTime(start)} – ${formatTime(event.end!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: placement.laneCount > 2 ? 9 : 11,
                            color: organicStyle
                                ? scheme.onSurfaceVariant
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (height >= 82 &&
                          showNote &&
                          placement.laneCount <= 2 &&
                          event.note.trim().isNotEmpty)
                        Text(
                          event.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: organicStyle
                                ? scheme.onSurfaceVariant
                                : null,
                          ),
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
    final highlight = organicStyle
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFFE14F7A);
    return Positioned(
      key: organicStyle
          ? const ValueKey<String>('commitments-organic-now-indicator')
          : null,
      top: organicStyle ? top - 10 : top,
      left: organicStyle ? 5 : timeColumnWidth - 3,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            if (organicStyle)
              Container(
                height: 23,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  formatTime(TimeOfDay.fromDateTime(now)),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              )
            else
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFE14F7A),
                  shape: BoxShape.circle,
                ),
              ),
            if (organicStyle)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: highlight,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Container(
                height: organicStyle ? 1.5 : 2,
                color: highlight.withValues(
                  alpha: organicStyle ? .72 : 1,
                ),
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
  final bool organicStyle;

  _TimelinePainter({
    required this.color,
    required this.textColor,
    this.organicStyle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullPaint = Paint()
      ..color = organicStyle ? color.withValues(alpha: .62) : color
      ..strokeWidth = organicStyle ? .8 : 1;
    final halfPaint = Paint()
      ..color = color.withValues(alpha: organicStyle ? .17 : .35)
      ..strokeWidth = organicStyle ? .7 : 1;

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
            // Headless Flutter's default test font is Ahem (black bars).
            // Use the same bundled Manrope asset as Anna's Diary, so
            // hour labels are visually truthful in CI and on devices.
            fontFamily: organicStyle ? 'Manrope' : null,
            fontSize: organicStyle ? 11 : 10.5,
            fontWeight: organicStyle
                ? FontWeight.w700
                : FontWeight.w600,
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
    return oldDelegate.color != color ||
        oldDelegate.textColor != textColor ||
        oldDelegate.organicStyle != organicStyle;
  }
}

