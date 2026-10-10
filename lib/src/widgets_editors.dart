part of '../main.dart';

class EventTile extends StatelessWidget {
  final AgendaStore store;
  final AgendaItem item;
  final bool compact;
  final bool hideDetails;

  const EventTile({
    super.key,
    required this.store,
    required this.item,
    this.compact = false,
    this.hideDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.category.color;
    final timeText = item.start == null
        ? (item.type == ItemType.task ? AnnaStrings.of(context).d3('editor_toDo') : AnnaStrings.of(context).d3('editor_allDay'))
        : '${formatTime(item.start!)}'
            '${item.end == null ? '' : ' – ${formatTime(item.end!)}'}';

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.only(
          left: compact ? 10 : 12,
          right: compact ? 4 : 8,
        ),
        leading: item.type == ItemType.task
            ? Checkbox(
                value: item.done,
                activeColor: color,
                onChanged: (_) => store.toggle(item.id),
              )
            : CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                foregroundColor: color,
                child: Icon(item.category.icon),
              ),
        title: Text(
          hideDetails ? AnnaStrings.of(context).d3('editor_hiddenContent') : item.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: item.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Wrap(
          spacing: 7,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(timeText),
            Text(
              AnnaStrings.of(context).editorCategoryLabel(item.category),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            if (item.pinned)
              Icon(
                Icons.push_pin,
                size: 14,
                color: color,
              ),
            if (item.reminderMinutesBefore != null ||
                item.secondaryReminderMinutesBefore != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  if (item.reminderMinutesBefore != null &&
                      item.secondaryReminderMinutesBefore != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      '2',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        onTap: () =>
            openItemEditor(context, store, item.date, existing: item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: AnnaStrings.of(context).lifeBridgeCopyPayload,
              onPressed: () => copyLifeBridgePayload(
                context,
                store.exportLifeBridgeAgendaItem(item),
              ),
              icon: const Icon(Icons.hub_outlined),
            ),
            IconButton(
              tooltip: AnnaStrings.of(context).d3('editor_actions'),
              onPressed: () => _showAgendaItemActions(context, store, item),
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEditor extends StatefulWidget {
  final AgendaStore store;
  final DateTime date;
  const JournalEditor({super.key, required this.store, required this.date});

  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late TextEditingController beautiful;
  late TextEditingController note;
  late List<TextEditingController> gratitude;
  DayMood? mood;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JournalEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AgendaStore.sameDay(oldWidget.date, widget.date)) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    final j = widget.store.journal(widget.date);
    beautiful = TextEditingController(text: j.beautiful);
    note = TextEditingController(text: j.note);
    mood = j.mood;
    gratitude = List.generate(
      3,
      (index) => TextEditingController(
        text: index < j.gratitude.length ? j.gratitude[index] : '',
      ),
    );
  }

  void _disposeControllers() {
    beautiful.dispose();
    note.dispose();
    for (final controller in gratitude) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _save() async {
    final current = widget.store.journal(widget.date);
    await widget.store.saveJournal(
      widget.date,
      current.copyWith(
        beautiful: beautiful.text.trim(),
        note: note.text.trim(),
        mood: mood,
        clearMood: mood == null,
        gratitude: gratitude
            .map((controller) => controller.text.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AnnaStrings.of(context).d3('editor_daySaved')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AnnaStrings.of(context).d3('editor_newHabit')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AnnaStrings.of(context).d3('editor_habitHint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(AnnaStrings.of(context).add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await widget.store.addHabit(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.store.journal(widget.date);
    final completed = journal.completedHabitIds;
    final habits = widget.store.habits;

    return Column(
      children: [
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AnnaStrings.of(context).d3('editor_howFeel'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DayMood.values.map((value) {
                  final selected = mood == value;
                  return ChoiceChip(
                    selected: selected,
                    selectedColor: value.color.withValues(alpha: 0.18),
                    avatar: Text(
                      value.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    label: Text(AnnaStrings.of(context).editorMoodLabel(value)),
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? value.color : null,
                    ),
                    onSelected: (_) => setState(() {
                      mood = selected ? null : value;
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AnnaStrings.of(context).d3('editor_threeGoodThings'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 5),
              Text(
                AnnaStrings.of(context).d3('editor_gratitudeSubtitle'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ...gratitude.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      prefixIcon: Center(
                        widthFactor: 1,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      hintText: entry.key == 0
                          ? AnnaStrings.of(context).d3('editor_oneGoodThing')
                          : AnnaStrings.of(context).d3('editor_anotherMoment'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: beautiful,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: AnnaStrings.of(context).d3('editor_momentRemember'),
                  hintText: AnnaStrings.of(context).d3('editor_momentHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AnnaStrings.of(context).d3('editor_myHabits'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AnnaStrings.of(context).d3('editor_addHabit'),
                    onPressed: _addHabit,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (habits.isEmpty)
                Text(AnnaStrings.of(context).d3('editor_habitEmpty'))
              else
                ...habits.map(
                  (habit) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: completed.contains(habit.id),
                    title: Text(habit.name),
                    secondary: Icon(
                      completed.contains(habit.id)
                          ? Icons.auto_awesome
                          : Icons.radio_button_unchecked,
                      color: completed.contains(habit.id)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onChanged: (_) =>
                        widget.store.toggleHabit(widget.date, habit.id),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ),
              if (habits.isNotEmpty) ...[
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (sheetContext) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                title: Text(
                                  AnnaStrings.of(context).d3('editor_manageHabits'),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              ...habits.map(
                                (habit) => ListTile(
                                  title: Text(habit.name),
                                  trailing:
                                      const Icon(Icons.delete_outline),
                                  onTap: () =>
                                      Navigator.pop(sheetContext, habit.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (selected != null) {
                        await widget.store.removeHabit(selected);
                      }
                    },
                    icon: const Icon(Icons.tune),
                    label: Text(AnnaStrings.of(context).d3('editor_manage')),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        DiaryMemoryCard(
          store: widget.store,
          date: widget.date,
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AnnaStrings.of(context).d3('editor_thoughtsNotes'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AnnaStrings.of(context).d3('editor_writeRemember'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(AnnaStrings.of(context).d3('editor_saveMyDay')),
                ),
              ),
              if (widget.store.journals.containsKey(
                AgendaStore.dateKey(widget.date),
              )) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(
                                AnnaStrings.of(context).d3('editor_moveDayTrashTitle'),
                              ),
                              content: Text(
                                AnnaStrings.of(context).d3('editor_moveDayTrashBody'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text(AnnaStrings.of(context).cancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: Text(AnnaStrings.of(context).d3('editor_moveDayTrash')),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (!confirmed || !mounted) return;
                      final movedMessage = AnnaStrings.of(context)
                          .d3('editor_dayMovedTrash');
                      final moved =
                          await widget.store.moveJournalToTrash(widget.date);
                      if (!moved || !mounted) return;
                      beautiful.clear();
                      note.clear();
                      for (final controller in gratitude) {
                        controller.clear();
                      }
                      setState(() => mood = null);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(movedMessage),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(AnnaStrings.of(context).d3('editor_moveDayTrash')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class MonthTextCard extends StatefulWidget {
  final String title;
  final String initial;
  final ValueChanged<String> onSave;
  const MonthTextCard({super.key, required this.title, required this.initial, required this.onSave});

  @override
  State<MonthTextCard> createState() => _MonthTextCardState();
}

class _MonthTextCardState extends State<MonthTextCard> {
  late final TextEditingController c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SimpleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(controller: c, minLines: 3, maxLines: 5),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => widget.onSave(c.text.trim()), child: Text(AnnaStrings.of(context).save))),
          ],
        ),
      );
}

class MonthlyListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final ValueChanged<List<String>> onChange;
  const MonthlyListCard({super.key, required this.title, required this.items, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
              IconButton(
                onPressed: () async {
                  final c = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AnnaStrings.of(context).d3Format('editor_addTo', {'title': title})),
                      content: TextField(controller: c, autofocus: true),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(AnnaStrings.of(context).cancel)),
                        FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: Text(AnnaStrings.of(context).add)),
                      ],
                    ),
                  );
                  c.dispose();
                  if (value != null && value.isNotEmpty) {
                    onChange([...items, value]);
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (items.isEmpty)
            Text(AnnaStrings.of(context).d3('editor_noItems'))
          else
            ...items.asMap().entries.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      final copy = [...items]..removeAt(entry.key);
                      onChange(copy);
                    },
                  ),
                )),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final MonthlyData data;
  final int spentCents;
  final ValueChanged<MonthlyData> onSave;
  const BudgetCard({super.key, required this.data, required this.spentCents, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final remaining = data.budgetCents - spentCents;
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AnnaStrings.of(context).d3('editor_monthBudget'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: MoneyBox(label: AnnaStrings.of(context).d3('editor_budget'), value: money(context, data.budgetCents))),
              const SizedBox(width: 8),
              Expanded(child: MoneyBox(label: AnnaStrings.of(context).d3('editor_spent'), value: money(context, spentCents))),
              const SizedBox(width: 8),
              Expanded(child: MoneyBox(label: AnnaStrings.of(context).d3('editor_remaining'), value: money(context, remaining))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final c = TextEditingController(text: (data.budgetCents / 100).toStringAsFixed(2));
                    final v = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AnnaStrings.of(context).d3('editor_setBudget')),
                        content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text(AnnaStrings.of(context).cancel)),
                          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(AnnaStrings.of(context).save)),
                        ],
                      ),
                    );
                    c.dispose();
                    final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (d != null) onSave(data.copyWith(budgetCents: (d * 100).round()));
                  },
                  child: Text(AnnaStrings.of(context).d3('editor_budget')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final amount = TextEditingController();
                    final note = TextEditingController();
                    String category = 'Altro';
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setLocal) => AlertDialog(
                          title: Text(AnnaStrings.of(context).d3('editor_newExpense')),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: AnnaStrings.of(context).d3('editor_amount'))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: category,
                                  items: const ['Cibo', 'Casa', 'Salute', 'Shopping', 'Trasporti', 'Svago', 'Regali', 'Altro']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setLocal(() => category = v ?? 'Altro'),
                                ),
                                const SizedBox(height: 8),
                                TextField(controller: note, decoration: InputDecoration(labelText: AnnaStrings.of(context).v100Note)),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AnnaStrings.of(context).cancel)),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AnnaStrings.of(context).add)),
                          ],
                        ),
                      ),
                    );
                    final amountText = amount.text;
                    final noteText = note.text;
                    amount.dispose();
                    note.dispose();
                    if (ok != true) return;
                    final d = double.tryParse(amountText.replaceAll(',', '.'));
                    if (d == null || d <= 0) return;
                    final expense = ExpenseEntry(
                      id: const Uuid().v4(),
                      cents: (d * 100).round(),
                      category: category,
                      note: noteText.trim(),
                      date: DateTime.now(),
                    );
                    onSave(data.copyWith(expenses: [...data.expenses, expense]));
                  },
                  child: Text(AnnaStrings.of(context).d3('editor_expense')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClosingMonthCard extends StatefulWidget {
  final MonthlyData data;
  final ValueChanged<MonthlyData> onSave;

  const ClosingMonthCard({
    super.key,
    required this.data,
    required this.onSave,
  });

  @override
  State<ClosingMonthCard> createState() => _ClosingMonthCardState();
}

class _ClosingMonthCardState extends State<ClosingMonthCard> {
  late final TextEditingController best =
      TextEditingController(text: widget.data.bestMoment);
  late final TextEditingController lesson =
      TextEditingController(text: widget.data.lesson);
  late final TextEditingController challenge =
      TextEditingController(text: widget.data.challenge);
  late final TextEditingController nextMonth =
      TextEditingController(text: widget.data.nextMonth);
  late final TextEditingController reflection =
      TextEditingController(text: widget.data.reflection);

  @override
  void dispose() {
    best.dispose();
    lesson.dispose();
    challenge.dispose();
    nextMonth.dispose();
    reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spent = widget.data.expenses
        .fold<int>(0, (sum, item) => sum + item.cents);
    final remaining = widget.data.budgetCents - spent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8EDFF), Color(0xFFFFF2F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nights_stay_outlined),
              const SizedBox(width: 8),
              Text(
                AnnaStrings.of(context).d3('editor_monthClosing'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AnnaStrings.of(context).d3('editor_pauseBeforeMonth'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.flag_outlined,
                text: AnnaStrings.of(context).d3Format('goalsCount', {'count': widget.data.goals.length}),
              ),
              _MiniPill(
                icon: Icons.receipt_long_outlined,
                text: '${AnnaStrings.of(context).d3('editor_spent')} ${money(context, spent)}',
              ),
              if (widget.data.budgetCents > 0)
                _MiniPill(
                  icon: Icons.savings_outlined,
                  text: '${AnnaStrings.of(context).d3('editor_remaining')} ${money(context, remaining)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: best,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('editor_bestMoment'),
              prefixIcon: const Icon(Icons.favorite_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: challenge,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('editor_hardestThing'),
              prefixIcon: const Icon(Icons.trending_up_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: lesson,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('editor_whatLearned'),
              prefixIcon: const Icon(Icons.lightbulb_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('editor_howMonthWent'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nextMonth,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AnnaStrings.of(context).d3('editor_carryNext'),
              prefixIcon: const Icon(Icons.arrow_forward_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.favorite_outline),
              onPressed: () => widget.onSave(
                widget.data.copyWith(
                  bestMoment: best.text.trim(),
                  lesson: lesson.text.trim(),
                  challenge: challenge.text.trim(),
                  nextMonth: nextMonth.text.trim(),
                  reflection: reflection.text.trim(),
                ),
              ),
              label: Text(AnnaStrings.of(context).d3('editor_closeSaveMonth')),
            ),
          ),
        ],
      ),
    );
  }
}

class DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  const DateStrip({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (i) => addCivilDays(selected, i - 3),
    );
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final d = dates[i];
          final active = AgendaStore.sameDay(d, selected);
          return InkWell(
            onTap: () => onSelected(d),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 54,
              decoration: BoxDecoration(
                color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE', AnnaStrings.intlLocale(context)).format(d).substring(0, 2).toUpperCase(),
                      style: TextStyle(fontSize: 11, color: active ? Theme.of(context).colorScheme.onPrimary : null)),
                  const SizedBox(height: 4),
                  Text('${d.day}',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: active ? Theme.of(context).colorScheme.onPrimary : null)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const NavigationCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800));
}

class SimpleCard extends StatelessWidget {
  final Widget child;
  const SimpleCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      );
}

class MoneyBox extends StatelessWidget {
  final String label;
  final String value;
  const MoneyBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            FittedBox(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const StatCard({super.key, required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => SimpleCard(
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      );
}

Future<void> openItemEditor(
  BuildContext context,
  AgendaStore store,
  DateTime initialDate, {
  TimeOfDay? initialTime,
  ItemType? initialType,
  AgendaItem? existing,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  DateTime date = existing?.date ?? initialDate;
  TimeOfDay? start = existing?.start ?? initialTime;
  TimeOfDay? end = existing?.end ??
      (start == null
          ? null
          : _timePlusMinutes(
              start,
              store.preferences.defaultEventMinutes,
            ));
  ItemType type = existing?.type ?? initialType ?? ItemType.appointment;
  AgendaCategory category =
      existing?.category ?? store.preferences.defaultCategory;
  int primaryReminder = existing == null
      ? (store.preferences.defaultPrimaryReminder ?? -1)
      : (existing.reminderMinutesBefore ?? -1);
  int secondaryReminder = existing == null
      ? (store.preferences.defaultSecondaryReminder ?? -1)
      : (existing.secondaryReminderMinutesBefore ?? -1);
  RecurrenceRule recurrence =
      existing?.recurrenceRule ?? RecurrenceRule.none;
  int recurrenceCount =
      existing?.isRecurring == true ? max(2, existing!.recurrenceCount) : 4;
  RecurringEditScope recurringEditScope = RecurringEditScope.single;

  AgendaItem buildItem({
    required String id,
    required DateTime itemDate,
    bool done = false,
    bool pinned = false,
  }) {
    return AgendaItem(
      id: id,
      title: title.text.trim(),
      note: note.text.trim(),
      date: DateTime(itemDate.year, itemDate.month, itemDate.day),
      type: type,
      category: category,
      reminderMinutesBefore:
          start == null || primaryReminder < 0 ? null : primaryReminder,
      secondaryReminderMinutesBefore:
          start == null || secondaryReminder < 0 ? null : secondaryReminder,
      start: start,
      end: type == ItemType.task ? null : end,
      done: done,
      pinned: pinned,
      recurrenceRule: existing?.recurrenceRule ?? RecurrenceRule.none,
      recurrenceSeriesId: existing?.recurrenceSeriesId,
      recurrenceIndex: existing?.recurrenceIndex ?? 0,
      recurrenceCount: existing?.recurrenceCount ?? 1,
    );
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) => Container(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        existing == null ? AnnaStrings.of(context).d3('editor_addToDay') : AnnaStrings.of(context).edit,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (existing != null)
                      IconButton.filledTonal(
                        tooltip: AnnaStrings.of(context).d3('editor_duplicate'),
                        onPressed: () async {
                          final t = title.text.trim();
                          if (t.isEmpty) return;
                          await store.upsert(
                            buildItem(
                              id: const Uuid().v4(),
                              itemDate: date,
                            ).copyWith(clearRecurrence: true),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.content_copy_outlined),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedButton<ItemType>(
                  segments: [
                    ButtonSegment(
                      value: ItemType.appointment,
                      label: Text(AnnaStrings.of(context).appointment),
                      icon: const Icon(Icons.event_outlined),
                    ),
                    ButtonSegment(
                      value: ItemType.task,
                      label: Text(AnnaStrings.of(context).d3('editor_toDo')),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setLocal(() => type = v.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  autofocus: existing == null,
                  decoration: InputDecoration(
                    labelText: AnnaStrings.of(context).d3('editor_title'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AnnaStrings.of(context).d3('editor_notes'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AnnaStrings.of(context).d3('editor_category'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: AgendaCategory.values.map((value) {
                    final active = category == value;
                    return ChoiceChip(
                      selected: active,
                      avatar: Icon(
                        value.icon,
                        size: 17,
                        color: active ? Colors.white : value.color,
                      ),
                      label: Text(AnnaStrings.of(context).editorCategoryLabel(value)),
                      selectedColor: value.color,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setLocal(() => category = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(date),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2040),
                    );
                    if (picked != null) setLocal(() => date = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    start == null ? AnnaStrings.of(context).d3('editor_noTime') : formatTime(start!),
                  ),
                  trailing: start == null
                      ? null
                      : IconButton(
                          onPressed: () => setLocal(() {
                            start = null;
                            end = null;
                            primaryReminder = -1;
                            secondaryReminder = -1;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setLocal(() {
                        start = picked;
                        end ??= _timePlusMinutes(
                          picked,
                          store.preferences.defaultEventMinutes,
                        );
                      });
                    }
                  },
                ),
                if (start != null && type == ItemType.appointment)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timelapse_outlined),
                    title: Text(
                      end == null ? AnnaStrings.of(context).d3('editor_endTime') : formatTime(end!),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end ?? start!,
                      );
                      if (picked != null) setLocal(() => end = picked);
                    },
                  ),
                if (start != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: primaryReminder,
                          decoration: InputDecoration(
                            labelText: AnnaStrings.of(context).d3('editor_reminder1'),
                            prefixIcon:
                                const Icon(Icons.notifications_none_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: _reminderMenuItems(AnnaStrings.of(context)),
                          onChanged: (value) => setLocal(() {
                            primaryReminder = value ?? -1;
                            if (secondaryReminder == primaryReminder) {
                              secondaryReminder = -1;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: secondaryReminder,
                          decoration: InputDecoration(
                            labelText: AnnaStrings.of(context).d3('editor_reminder2'),
                            prefixIcon:
                                const Icon(Icons.add_alert_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: _reminderMenuItems(AnnaStrings.of(context)),
                          onChanged: (value) => setLocal(() {
                            secondaryReminder = value ?? -1;
                            if (secondaryReminder == primaryReminder) {
                              secondaryReminder = -1;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    AnnaStrings.of(context).d3('editor_twoRemindersHint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  AnnaStrings.of(context).d3('editor_repeat'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: RecurrenceRule.values.map((value) {
                    return ChoiceChip(
                      selected: recurrence == value,
                      avatar: Icon(value.icon, size: 17),
                      label: Text(AnnaStrings.of(context).editorRecurrenceLabel(value)),
                      onSelected: existing?.isRecurring == true
                          ? null
                          : (_) => setLocal(() => recurrence = value),
                    );
                  }).toList(),
                ),
                if (existing?.isRecurring == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    AnnaStrings.of(context).d3Format(
                      'editor_seriesSummary',
                      {
                        'count': existing!.recurrenceCount,
                        'rule': AnnaStrings.of(context).editorRecurrenceLabel(existing.recurrenceRule),
                      },
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AnnaStrings.of(context).d3('editor_applyEditTo'),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<RecurringEditScope>(
                    segments: RecurringEditScope.values
                        .map(
                          (scope) => ButtonSegment<RecurringEditScope>(
                            value: scope,
                            label: Text(AnnaStrings.of(context).editorScopeShort(scope)),
                          ),
                        )
                        .toList(),
                    selected: {recurringEditScope},
                    onSelectionChanged: (value) => setLocal(
                      () => recurringEditScope = value.first,
                    ),
                  ),
                ] else if (recurrence != RecurrenceRule.none) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.repeat),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AnnaStrings.of(context).d3Format(
                            'editor_occurrencesTotal',
                            {'count': recurrenceCount},
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: recurrenceCount.toDouble(),
                    min: 2,
                    max: 60,
                    divisions: 58,
                    label: recurrenceCount.toString(),
                    onChanged: (value) =>
                        setLocal(() => recurrenceCount = value.round()),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (existing != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (existing.isRecurring) {
                              await store.deleteRecurringOccurrence(
                                existing,
                                scope: recurringEditScope,
                              );
                            } else {
                              await store.deleteItem(existing.id);
                            }
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          label: Text(AnnaStrings.of(context).delete),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          final t = title.text.trim();
                          if (t.isEmpty) return;

                          final base = buildItem(
                            id: existing?.id ?? const Uuid().v4(),
                            itemDate: date,
                            done: existing?.done ?? false,
                            pinned: existing?.pinned ?? false,
                          );
                          if (existing?.isRecurring == true) {
                            await store.updateRecurringOccurrence(
                              base,
                              scope: recurringEditScope,
                            );
                          } else if (recurrence == RecurrenceRule.none) {
                            await store.upsert(
                              base.copyWith(clearRecurrence: true),
                            );
                          } else {
                            await store.createRecurringSeries(
                              template: base,
                              rule: recurrence,
                              count: recurrenceCount,
                            );
                          }

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        label: Text(
                          recurrence == RecurrenceRule.none
                              ? AnnaStrings.of(context).save
                              : AnnaStrings.of(context).d3('editor_saveSeries'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  title.dispose();
  note.dispose();
}

List<DropdownMenuItem<int>> _reminderMenuItems(AnnaStrings strings) => [
  DropdownMenuItem(value: -1, child: Text(strings.d3('editor_noReminderOption'))),
  DropdownMenuItem(value: 0, child: Text(strings.d3('editor_atTime'))),
  DropdownMenuItem(value: 10, child: Text(strings.d3('editor_tenBefore'))),
  DropdownMenuItem(value: 30, child: Text(strings.d3('editor_thirtyBefore'))),
  DropdownMenuItem(value: 60, child: Text(strings.d3('editor_hourBefore'))),
  DropdownMenuItem(value: 120, child: Text(strings.d3('editor_twoHoursBefore'))),
  DropdownMenuItem(value: 1440, child: Text(strings.d3('editor_dayBefore'))),
];

(String, String) _dailyQuote(DateTime date, AnnaStrings strings) {
  final start = DateTime(date.year, 1, 1);
  final dayOfYear = date.difference(start).inDays;
  final quotes = strings.editorPositiveQuotes;
  return quotes[dayOfYear % quotes.length];
}

String _monthPhrase(int month, AnnaStrings strings) =>
    strings.editorMonthPhrase(month);

DateTime addCivilDays(DateTime date, int days) {
  final noon = DateTime(date.year, date.month, date.day, 12);
  final shifted = DateTime(noon.year, noon.month, noon.day + days, 12);
  return DateTime(shifted.year, shifted.month, shifted.day);
}

DateTime mondayOf(DateTime d) {
  final n = DateTime(d.year, d.month, d.day);
  return addCivilDays(n, -(n.weekday - 1));
}

TimeOfDay _timePlusMinutes(TimeOfDay start, int minutes) {
  final total = (start.hour * 60 + start.minute + minutes).clamp(0, 1439);
  return TimeOfDay(
    hour: total ~/ 60,
    minute: total % 60,
  );
}

String _derivePinHash(String pin, String salt) {
  List<int> bytes = utf8.encode('$salt:$pin');
  for (var i = 0; i < 25000; i++) {
    bytes = sha256.convert(bytes).bytes;
  }
  return base64UrlEncode(bytes);
}

String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String money(BuildContext context, int cents) => NumberFormat.currency(
      locale: AnnaStrings.intlLocale(context),
      symbol: '€',
    ).format(cents / 100);

String _cap(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
