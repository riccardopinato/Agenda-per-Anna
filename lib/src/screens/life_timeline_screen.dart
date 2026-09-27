part of '../../main.dart';

class LifeTimelineScreen extends StatefulWidget {
  final AgendaStore store;

  const LifeTimelineScreen({
    super.key,
    required this.store,
  });

  @override
  State<LifeTimelineScreen> createState() => _LifeTimelineScreenState();
}

class _LifeTimelineScreenState extends State<LifeTimelineScreen> {
  final searchController = TextEditingController();
  final Set<LifeMomentKind> selectedKinds = LifeMomentKind.values.toSet();
  bool includeCompletedAgenda = true;
  bool includeArchivedMemories = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<LifeMomentReference> _moments() {
    final query = searchController.text.trim();
    return widget.store
        .lifeMoments(
          includeCompletedAgenda: includeCompletedAgenda,
          includeArchivedMemories: includeArchivedMemories,
          kinds: selectedKinds,
        )
        .where(
          (moment) => widget.store.lifeMomentMatches(moment, query),
        )
        .toList();
  }

  void _toggleKind(LifeMomentKind kind) {
    setState(() {
      if (selectedKinds.contains(kind)) {
        if (selectedKinds.length > 1) selectedKinds.remove(kind);
      } else {
        selectedKinds.add(kind);
      }
    });
  }

  Future<void> _openMoment(LifeMomentReference moment) async {
    switch (moment.kind) {
      case LifeMomentKind.memory:
      case LifeMomentKind.agenda:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PlannerScreen(
              store: widget.store,
              initialDate: moment.day,
            ),
          ),
        );
        break;
      case LifeMomentKind.birthday:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => BirthdaysScreen(store: widget.store),
          ),
        );
        break;
    }
  }

  String _dayLabel(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == normalizedToday) return 'Oggi';
    if (normalized == normalizedToday.subtract(const Duration(days: 1))) {
      return 'Ieri';
    }
    if (normalized == normalizedToday.add(const Duration(days: 1))) {
      return 'Domani';
    }
    return DateFormat('EEEE d MMMM yyyy', 'it_IT').format(normalized);
  }

  Widget _momentCard(LifeMomentReference moment) {
    final theme = Theme.of(context);
    final timeText = switch (moment.kind) {
      LifeMomentKind.agenda => DateFormat('HH:mm').format(moment.dateTime),
      LifeMomentKind.memory => DateFormat('HH:mm').format(moment.dateTime),
      LifeMomentKind.birthday => '',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(moment.kind.icon),
        ),
        title: Text(
          moment.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (moment.subtitle.trim().isNotEmpty)
              Text(
                moment.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              [
                moment.kind.label,
                if (timeText.isNotEmpty) timeText,
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openMoment(moment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Momenti',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Cos’è Momenti?',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Momenti'),
                content: const Text(
                  'Una timeline unica che riunisce ciò che esiste già nel diario, nell’agenda e nei compleanni. Non crea copie dei tuoi dati: ogni elemento resta nel suo archivio originale.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.store.journalRevision,
          widget.store.planningRevision,
          widget.store.lifecycleRevision,
        ]),
        builder: (context, _) {
          final moments = _moments();
          final grouped = widget.store.lifeMomentsByDay(moments);
          final keys = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: SearchBar(
                  controller: searchController,
                  hintText: 'Cerca nei tuoi momenti...',
                  leading: const Icon(Icons.search),
                  trailing: searchController.text.isEmpty
                      ? null
                      : [
                          IconButton(
                            tooltip: 'Cancella',
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final kind in LifeMomentKind.values) ...[
                      FilterChip(
                        selected: selectedKinds.contains(kind),
                        avatar: Icon(kind.icon),
                        label: Text(kind.label),
                        onSelected: (_) => _toggleKind(kind),
                      ),
                      const SizedBox(width: 7),
                    ],
                  ],
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip(
                      selected: includeCompletedAgenda,
                      label: const Text('Agenda completata'),
                      onSelected: (value) =>
                          setState(() => includeCompletedAgenda = value),
                    ),
                    const SizedBox(width: 7),
                    FilterChip(
                      selected: includeArchivedMemories,
                      label: const Text('Ricordi archiviati'),
                      onSelected: (value) =>
                          setState(() => includeArchivedMemories = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                child: Row(
                  children: [
                    Text(
                      moments.isEmpty
                          ? 'Nessun momento'
                          : '${moments.length} momenti · ${grouped.length} giornate',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    const Icon(Icons.timeline, size: 18),
                  ],
                ),
              ),
              Expanded(
                child: moments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'I tuoi ricordi, impegni e compleanni compariranno qui senza essere duplicati.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 28),
                        itemCount: keys.length,
                        itemBuilder: (context, index) {
                          final key = keys[index];
                          final date = DateTime.parse(key);
                          final dayMoments = grouped[key] ?? const [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 12, 4, 7),
                                child: Text(
                                  _dayLabel(date),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              ...dayMoments.map(_momentCard),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
