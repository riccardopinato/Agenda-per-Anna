part of '../main.dart';

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
                itemBuilder: (_) => [
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
              const SizedBox(width: 8),
              Text(
                AnnaStrings.of(context).d3('monthFromMe'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
              const SizedBox(width: 8),
              Text(
                AnnaStrings.of(context).d3('monthOpening'),
                style: const TextStyle(
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
              prefixIcon: const Icon(Icons.text_fields_outlined),
              border: const OutlineInputBorder(),
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
              prefixIcon: const Icon(Icons.spa_outlined),
              border: const OutlineInputBorder(),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AnnaStrings.of(context).d3('monthIdeas'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AnnaStrings.of(context).d3('monthIdeasSubtitle'),
                      style: const TextStyle(fontSize: 12),
                    ),
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

  Future<void> _openMemory(DiaryBlockReference reference) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlannerScreen(
          store: widget.store,
          initialDate: reference.date,
        ),
      ),
    );
  }

  Future<void> _openMonth(int month) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MonthScreen(
          store: widget.store,
          initialMonth: DateTime(year, month),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.store.journalRevision,
        widget.store.planningRevision,
        widget.store.agendaRevision,
        widget.store.workoutRevision,
      ]),
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final review = widget.store.yearReviewSnapshot(
          year,
          strings: strings,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.v105YearReview,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Semantics(
            identifier: 'year-review-surface',
            container: true,
            child: ListView(
              key: const ValueKey<String>('year-review-surface'),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
              Semantics(
                identifier: 'year-review-year-selector',
                container: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const ValueKey<String>('year-review-prev'),
                      onPressed: () => setState(() => year--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '$year',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      key: const ValueKey<String>('year-review-next'),
                      onPressed: () => setState(() => year++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.v105YearReviewSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 170,
                    child: StatCard(
                      icon: Icons.favorite_outline,
                      title: strings.memories,
                      value: review.memoryCount.toString(),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: StatCard(
                      icon: Icons.auto_awesome_outlined,
                      title: strings.v105LifeMoments,
                      value: review.lifeCount.toString(),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: StatCard(
                      icon: Icons.sports_outlined,
                      title: strings.workout,
                      value: review.workoutCount.toString(),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: StatCard(
                      icon: Icons.calendar_view_month_outlined,
                      title: strings.v105ActiveMonths,
                      value: '${review.activeMonths}/12',
                    ),
                  ),
                ],
              ),
              if (review.highlights.isNotEmpty) ...[
                const SizedBox(height: 26),
                SectionTitle(strings.v105Highlights),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < review.highlights.length; i++) ...[
                        ListTile(
                          key: ValueKey<String>(
                            'year-review-highlight-${review.highlights[i].block.id}',
                          ),
                          leading: const Icon(Icons.auto_awesome_outlined),
                          title: Text(
                            widget.store.diaryBlockDisplayTitle(
                              review.highlights[i].block,
                              strings: strings,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat(
                              'd MMMM yyyy',
                              AnnaStrings.intlLocale(context),
                            ).format(review.highlights[i].date),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openMemory(review.highlights[i]),
                        ),
                        if (i != review.highlights.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ],
              if (review.people.isNotEmpty) ...[
                const SizedBox(height: 24),
                SectionTitle(strings.v105RecurringPeople),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final person in review.people)
                      Chip(
                        avatar: const Icon(Icons.person_outline, size: 18),
                        label: Text(
                          '${person.label} · ${person.count}',
                        ),
                      ),
                  ],
                ),
              ],
              if (review.places.isNotEmpty) ...[
                const SizedBox(height: 24),
                SectionTitle(strings.v105RecurringPlaces),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final place in review.places)
                      Chip(
                        avatar: const Icon(Icons.place_outlined, size: 18),
                        label: Text(
                          '${place.label} · ${place.count}',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              SectionTitle(strings.d3('plannerTwelveMonths')),
              const SizedBox(height: 10),
              for (final month in review.months) ...[
                _YearReviewMonthCard(
                  year: year,
                  snapshot: month,
                  onOpen: () => _openMonth(month.month),
                ),
                const SizedBox(height: 9),
              ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _YearReviewMonthCard extends StatelessWidget {
  final int year;
  final YearReviewMonthSnapshot snapshot;
  final VoidCallback onOpen;

  const _YearReviewMonthCard({
    required this.year,
    required this.snapshot,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final monthLabel = _cap(
      DateFormat(
        'MMMM',
        AnnaStrings.intlLocale(context),
      ).format(DateTime(year, snapshot.month)),
    );

    return Semantics(
      identifier: 'year-review-month-${snapshot.month}',
      button: true,
      label:
          '$monthLabel, ${strings.v105MemoriesCount(snapshot.memoryCount)}, '
          '${strings.v105LifeCount(snapshot.lifeCount)}',
      child: Card(
        color: snapshot.hasStory
            ? scheme.primaryContainer.withValues(alpha: 0.24)
            : scheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                SizedBox(
                  width: 94,
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: snapshot.hasStory
                      ? Text(
                          [
                            strings.v105MemoriesCount(snapshot.memoryCount),
                            strings.v105LifeCount(snapshot.lifeCount),
                            if (snapshot.workoutCount > 0)
                              '${snapshot.workoutCount} · ${strings.workout}',
                          ].join('  •  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : Text(
                          strings.d3PlannerNotWrittenYet,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                ),
                Tooltip(
                  message: strings.v105OpenMonth,
                  child: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
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
            subtitle: Text(quickWinText(AnnaStrings.of(context), 'duplicateDate')),
            onTap: () => Navigator.pop(context, 'duplicate'),
          ),
          if (canPostponeTask(item))
            ListTile(
              key: const ValueKey('quick-wins-postpone-action'),
              leading: const Icon(Icons.redo_outlined),
              title: Text(quickWinText(AnnaStrings.of(context), 'postpone')),
              onTap: () => Navigator.pop(context, 'postpone'),
            ),
          if (canPrepareEvent(item))
            ListTile(
              key: const ValueKey<String>('v107-event-preparation-action'),
              leading: const Icon(Icons.checklist_outlined),
              title: Text(AnnaStrings.of(context).d3('v107PrepTitle')),
              onTap: () => Navigator.pop(context, 'prepareEvent'),
            ),
          if (canCaptureEventMemory(item, DateTime.now()))
            ListTile(
              key: const ValueKey<String>('v107-event-to-memory-action'),
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(AnnaStrings.of(context).d3('v107EventMemoryAction')),
              onTap: () => Navigator.pop(context, 'eventMemory'),
            ),
          ListTile(
            leading: Icon(
              item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(
              item.pinned
                  ? AnnaStrings.of(context).unpin
                  : AnnaStrings.of(context).pin,
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
  } else if (action == 'duplicate' && context.mounted) {
    await openItemEditor(context, store, item.date, duplicateOf: item);
  } else if (action == 'postpone' && context.mounted) {
    await showPostponeTask(context, store, item);
  } else if (action == 'prepareEvent' && context.mounted) {
    await openEventPreparation(context, store, item);
  } else if (action == 'eventMemory' && context.mounted) {
    await openEventMemoryDraft(context, store, item);
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
