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
        ? (item.type == ItemType.task ? 'Da fare' : 'Tutto il giorno')
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
          hideDetails ? 'Contenuto nascosto' : item.title,
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
              item.category.label,
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
        trailing: IconButton(
          tooltip: 'Azioni',
          onPressed: () => _showAgendaItemActions(context, store, item),
          icon: const Icon(Icons.more_horiz),
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
        const SnackBar(
          content: Text('Giornata salvata ♡'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuova abitudine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Es. Leggere 20 minuti',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Aggiungi'),
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
              const Text(
                'Come ti senti oggi?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
                    label: Text(value.label),
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
              const Text(
                'Tre cose belle di oggi ♡',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 5),
              Text(
                'Anche piccole: qualcosa che ti ha fatto sorridere, stare bene o sentire grata.',
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
                          ? 'Una cosa bella...'
                          : 'Un altro piccolo momento...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: beautiful,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Il momento che voglio ricordare',
                  hintText: 'Quello che vorresti rileggere tra qualche mese...',
                  border: OutlineInputBorder(),
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
                  const Expanded(
                    child: Text(
                      'Le mie abitudini',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aggiungi abitudine',
                    onPressed: _addHabit,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (habits.isEmpty)
                const Text('Aggiungi una piccola abitudine da seguire.')
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
                              const ListTile(
                                title: Text(
                                  'Gestisci abitudini',
                                  style: TextStyle(fontWeight: FontWeight.w800),
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
                    label: const Text('Gestisci'),
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
              const Text(
                'Pensieri e note',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Scrivi quello che vuoi ricordare...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Salva la mia giornata'),
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
                              title: const Text(
                                'Spostare la giornata nel Cestino?',
                              ),
                              content: const Text(
                                'Diario, ricordi e stato delle abitudini di questa giornata '
                                'potranno essere ripristinati dal Cestino.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Annulla'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Sposta nel Cestino'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (!confirmed || !mounted) return;
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
                        const SnackBar(
                          content: Text('Giornata spostata nel Cestino.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sposta giornata nel Cestino'),
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
            SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => widget.onSave(c.text.trim()), child: const Text('Salva'))),
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
                      title: Text('Aggiungi a $title'),
                      content: TextField(controller: c, autofocus: true),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                        FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Aggiungi')),
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
            const Text('Nessun elemento ancora.')
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
          const Text('Budget del mese', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: MoneyBox(label: 'Budget', value: money(data.budgetCents))),
              const SizedBox(width: 8),
              Expanded(child: MoneyBox(label: 'Speso', value: money(spentCents))),
              const SizedBox(width: 8),
              Expanded(child: MoneyBox(label: 'Rimane', value: money(remaining))),
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
                        title: const Text('Imposta budget'),
                        content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Salva')),
                        ],
                      ),
                    );
                    c.dispose();
                    final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (d != null) onSave(data.copyWith(budgetCents: (d * 100).round()));
                  },
                  child: const Text('Budget'),
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
                          title: const Text('Nuova spesa'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Importo')),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: category,
                                  items: const ['Cibo', 'Casa', 'Salute', 'Shopping', 'Trasporti', 'Svago', 'Regali', 'Altro']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setLocal(() => category = v ?? 'Altro'),
                                ),
                                const SizedBox(height: 8),
                                TextField(controller: note, decoration: const InputDecoration(labelText: 'Nota')),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aggiungi')),
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
                  child: const Text('Spesa'),
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
          const Row(
            children: [
              Icon(Icons.nights_stay_outlined),
              SizedBox(width: 8),
              Text(
                'Chiusura del mese',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Fermati un momento prima di voltare pagina.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.flag_outlined,
                text: '${widget.data.goals.length} obiettivi',
              ),
              _MiniPill(
                icon: Icons.receipt_long_outlined,
                text: 'Speso ${money(spent)}',
              ),
              if (widget.data.budgetCents > 0)
                _MiniPill(
                  icon: Icons.savings_outlined,
                  text: 'Rimane ${money(remaining)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: best,
            decoration: const InputDecoration(
              labelText: 'Il momento più bello',
              prefixIcon: Icon(Icons.favorite_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: challenge,
            decoration: const InputDecoration(
              labelText: 'La cosa più difficile',
              prefixIcon: Icon(Icons.trending_up_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: lesson,
            decoration: const InputDecoration(
              labelText: 'Cosa ho imparato',
              prefixIcon: Icon(Icons.lightbulb_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Com’è andato davvero questo mese?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nextMonth,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Cosa voglio portare nel prossimo mese',
              prefixIcon: Icon(Icons.arrow_forward_outlined),
              border: OutlineInputBorder(),
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
              label: const Text('Chiudi e salva il mese'),
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
                  Text(DateFormat('EEE', 'it_IT').format(d).substring(0, 2).toUpperCase(),
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
  RecurrenceRule recurrence = RecurrenceRule.none;
  int recurrenceCount = 4;

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
                        existing == null ? 'Aggiungi alla giornata' : 'Modifica',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (existing != null)
                      IconButton.filledTonal(
                        tooltip: 'Duplica',
                        onPressed: () async {
                          final t = title.text.trim();
                          if (t.isEmpty) return;
                          await store.upsert(
                            buildItem(
                              id: const Uuid().v4(),
                              itemDate: date,
                            ),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.content_copy_outlined),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedButton<ItemType>(
                  segments: const [
                    ButtonSegment(
                      value: ItemType.appointment,
                      label: Text('Appuntamento'),
                      icon: Icon(Icons.event_outlined),
                    ),
                    ButtonSegment(
                      value: ItemType.task,
                      label: Text('Da fare'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setLocal(() => type = v.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  autofocus: existing == null,
                  decoration: const InputDecoration(
                    labelText: 'Titolo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Categoria',
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
                      label: Text(value.label),
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
                    DateFormat('d MMMM yyyy', 'it_IT').format(date),
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
                    start == null ? 'Senza orario' : formatTime(start!),
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
                      end == null ? 'Ora fine' : formatTime(end!),
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
                          decoration: const InputDecoration(
                            labelText: 'Promemoria 1',
                            prefixIcon:
                                Icon(Icons.notifications_none_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _reminderMenuItems,
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
                          decoration: const InputDecoration(
                            labelText: 'Promemoria 2',
                            prefixIcon:
                                Icon(Icons.add_alert_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _reminderMenuItems,
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
                    'Puoi impostare fino a due promemoria diversi per lo stesso impegno.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Ripeti',
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
                      label: Text(value.label),
                      onSelected: (_) =>
                          setLocal(() => recurrence = value),
                    );
                  }).toList(),
                ),
                if (recurrence != RecurrenceRule.none) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.repeat),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$recurrenceCount occorrenze totali',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: recurrenceCount.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
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
                            await store.deleteItem(existing.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          label: const Text('Elimina'),
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
                          await store.upsert(base);

                          if (recurrence != RecurrenceRule.none) {
                            for (var i = 1; i < recurrenceCount; i++) {
                              final nextDate =
                                  _recurrenceDate(date, recurrence, i);
                              await store.upsert(
                                buildItem(
                                  id: const Uuid().v4(),
                                  itemDate: nextDate,
                                ),
                              );
                            }
                          }

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        label: Text(
                          recurrence == RecurrenceRule.none
                              ? 'Salva'
                              : 'Salva serie',
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

const List<DropdownMenuItem<int>> _reminderMenuItems = [
  DropdownMenuItem(value: -1, child: Text('Nessuno')),
  DropdownMenuItem(value: 0, child: Text('All’ora')),
  DropdownMenuItem(value: 10, child: Text('10 min prima')),
  DropdownMenuItem(value: 30, child: Text('30 min prima')),
  DropdownMenuItem(value: 60, child: Text('1 ora prima')),
  DropdownMenuItem(value: 120, child: Text('2 ore prima')),
  DropdownMenuItem(value: 1440, child: Text('1 giorno prima')),
];

DateTime _recurrenceDate(
  DateTime start,
  RecurrenceRule rule,
  int offset,
) {
  switch (rule) {
    case RecurrenceRule.none:
      return start;
    case RecurrenceRule.daily:
      return addCivilDays(start, offset);
    case RecurrenceRule.weekly:
      return addCivilDays(start, 7 * offset);
    case RecurrenceRule.monthly:
      final firstOfTarget = DateTime(start.year, start.month + offset, 1);
      final lastDay = DateTime(
        firstOfTarget.year,
        firstOfTarget.month + 1,
        0,
      ).day;
      final day = start.day.clamp(1, lastDay).toInt();
      return DateTime(firstOfTarget.year, firstOfTarget.month, day);
  }
}

const _positiveQuotes = <(String, String)>[
  ('Una cosa alla volta ♡', 'Non serve fare tutto oggi. Basta iniziare da qualcosa che conta.'),
  ('Fai spazio alle cose belle', 'Anche una giornata piena può contenere un momento solo tuo.'),
  ('Non devi correre sempre', 'La costanza vale più della fretta.'),
  ('Oggi merita una pagina nuova', 'Puoi decidere cosa portare con te e cosa lasciare andare.'),
  ('Piccoli passi, grandi cambiamenti', 'Le cose importanti crescono un giorno alla volta.'),
  ('Ricordati anche di te', 'Tra tutte le cose da fare, lascia uno spazio per stare bene.'),
  ('Va bene cambiare programma', 'Un’agenda serve a sostenerti, non a metterti pressione.'),
  ('Celebra quello che funziona', 'Non aspettare solo i grandi traguardi per essere fiera di te.'),
];

(String, String) _dailyQuote(DateTime date) {
  final start = DateTime(date.year, 1, 1);
  final dayOfYear = date.difference(start).inDays;
  return _positiveQuotes[dayOfYear % _positiveQuotes.length];
}

String _monthPhrase(int month) {
  const phrases = [
    '',
    'Un inizio leggero, senza pretendere tutto subito.',
    'Coltiva ciò che vuoi vedere crescere.',
    'Lascia entrare un po’ di primavera anche nei programmi.',
    'Fai spazio alle novità.',
    'Scegli ciò che ti fa stare bene.',
    'Porta con te solo quello che serve.',
    'Più luce, più tempo per respirare.',
    'Rallenta abbastanza da ricordarti le giornate.',
    'Riparti dalle cose essenziali.',
    'Raccogli ciò che hai costruito.',
    'Proteggi il tuo tempo e le tue energie.',
    'Chiudi l’anno ricordando anche le cose belle.',
  ];
  return phrases[month.clamp(1, 12)];
}

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

String money(int cents) => NumberFormat.currency(locale: 'it_IT', symbol: '€').format(cents / 100);

String _cap(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
