part of '../main.dart';

class MainShell extends StatefulWidget {
  final AgendaStore store;
  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.store.preferences.startTab.index;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(store: widget.store),
      CalendarScreen(store: widget.store),
      WeekScreen(store: widget.store),
      PlannerScreen(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Mese'),
          NavigationDestination(icon: Icon(Icons.view_week_outlined), label: 'Settimana'),
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Oggi'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AgendaStore store;
  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final today = store.unifiedForDay(now);
        final upcoming = store.unifiedUpcoming(now);
        final pendingTasks = store.pendingUnifiedTaskCount;
        final pinnedItems =
            store.agendaContentFilter == AgendaContentFilter.sharedOnly
                ? <AgendaItem>[]
                : store.items.where((e) => e.pinned).toList();
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(context, store),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi'),
          ),
          appBar: AppBar(
            title: Text(
              'Agenda per ${store.preferences.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerca',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Inbox',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InboxScreen(store: store),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: store.inbox.isNotEmpty,
                  label: Text('${store.inbox.length}'),
                  child: const Icon(Icons.inbox_outlined),
                ),
              ),
              IconButton(
                tooltip: 'Archivio',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArchiveScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
              IconButton(
                tooltip: 'Backup',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BackupScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.backup_outlined),
              ),
              IconButton(
                tooltip: 'Noi',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedSpaceHubScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.favorite_outline),
              ),
              IconButton(
                tooltip: 'Cloud',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CloudAccountScreen(store: store),
                  ),
                ),
                icon: AnimatedBuilder(
                  animation: CloudSyncService.instance,
                  builder: (context, _) {
                    final cloud = CloudSyncService.instance;
                    final icon = !cloud.configured
                        ? Icons.cloud_off_outlined
                        : cloud.state == CloudConnectionState.syncing
                            ? Icons.sync
                            : cloud.signedIn
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_outlined;
                    return Icon(icon);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Impostazioni',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE4EC), Color(0xFFF0E8FF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cap(DateFormat('EEEE d MMMM', 'it_IT').format(now)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.preferences.showDailyQuote
                          ? _dailyQuote(now).$1
                          : 'Ciao ${store.preferences.displayName} ♡',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.preferences.showDailyQuote
                          ? _dailyQuote(now).$2
                          : 'Questa è la tua pagina di oggi.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AgendaContentFilterBar(store: store),
              const SizedBox(height: 10),
              _HomeSyncStatusCard(store: store),
              if (store.hasStorageWarnings) ...[
                const SizedBox(height: 12),
                SimpleCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Una parte dell’archivio locale non è leggibile. '
                          'Agenda la mantiene intatta invece di sovrascriverla. '
                          'Puoi usare Backup e ripristino per recuperare una copia valida.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _HomeFocusCard(
                next: upcoming.isEmpty ? null : upcoming.first,
                pendingTasks: pendingTasks,
                inboxCount: store.inbox.length,
                hideDetails: store.preferences.hideHomeDetails,
                onOpenNext: upcoming.isEmpty
                    ? null
                    : () => openUnifiedAgendaEntry(
                          context,
                          store,
                          upcoming.first,
                        ),
                onOpenInbox: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InboxScreen(store: store),
                  ),
                ),
              ),
              if (pinnedItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionTitle('Fissati'),
                const SizedBox(height: 10),
                ...pinnedItems.take(3).map(
                      (e) => EventTile(
                        store: store,
                        item: e,
                        compact: true,
                        hideDetails: store.preferences.hideHomeDetails,
                      ),
                    ),
              ],
              const SizedBox(height: 24),
              const SectionTitle('Oggi'),
              const SizedBox(height: 10),
              if (today.isEmpty)
                const SimpleCard(child: Text('Nessun impegno per oggi.'))
              else
                ...today.take(5).map(
                  (e) => UnifiedAgendaTile(
                    store: store,
                    entry: e,
                    hideDetails: store.preferences.hideHomeDetails,
                  ),
                ),
              const SizedBox(height: 14),
              _TodayWellbeingCard(store: store, date: now),
              const SizedBox(height: 24),
              const SectionTitle('La mia agenda'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: NavigationCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Il mio mese',
                      subtitle: 'Obiettivi, idee e budget',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MonthScreen(store: store)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NavigationCard(
                      icon: Icons.insights_outlined,
                      title: 'Il mio anno',
                      subtitle: 'Ricordi e progressi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => YearScreen(store: store)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showQuickCapture(
  BuildContext context,
  AgendaStore store,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          const ListTile(
            title: Text(
              'Cattura veloce',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('Aggiungi senza interrompere quello che stai facendo.'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.sticky_note_2_outlined),
            ),
            title: const Text('Nota veloce'),
            subtitle: const Text('Finisce nell’Inbox, da sistemare dopo.'),
            onTap: () => Navigator.pop(sheetContext, 'note'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.check_circle_outline),
            ),
            title: const Text('Attività'),
            subtitle: const Text('Crea subito una cosa da fare.'),
            onTap: () => Navigator.pop(sheetContext, 'task'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.event_outlined),
            ),
            title: const Text('Appuntamento'),
            subtitle: const Text('Apri il modulo evento di oggi.'),
            onTap: () => Navigator.pop(sheetContext, 'event'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == 'note') {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nota veloce'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Scrivi al volo...',
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
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await store.addInboxEntry(value);
    }
    return;
  }

  await openUnifiedItemComposer(
    context,
    store,
    DateTime.now(),
    initialType: action == 'task' ? ItemType.task : ItemType.appointment,
  );
}

class _HomeSyncStatusCard extends StatelessWidget {
  final AgendaStore store;

  const _HomeSyncStatusCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CloudSyncService.instance,
      builder: (context, _) {
        final cloud = CloudSyncService.instance;
        final pending = store.totalPendingCloudChanges;

        IconData icon;
        String title;
        String subtitle;

        if (!cloud.configured) {
          icon = Icons.cloud_off_outlined;
          title = 'Solo sul dispositivo';
          subtitle = 'Il cloud non è configurato in questa build.';
        } else if (!cloud.signedIn) {
          icon = Icons.cloud_outlined;
          title = 'Cloud non connesso';
          subtitle = 'L’agenda continua a funzionare offline.';
        } else if (cloud.state == CloudConnectionState.syncing) {
          icon = Icons.sync;
          title = 'Sincronizzazione in corso';
          subtitle = pending == 0
              ? 'Controllo le modifiche sui tuoi dispositivi.'
              : '$pending modifiche locali sono al sicuro in coda.';
        } else if (cloud.state == CloudConnectionState.error) {
          icon = Icons.cloud_off_outlined;
          title = pending == 0
              ? 'Cloud temporaneamente non disponibile'
              : 'Offline · dati al sicuro';
          subtitle = pending == 0
              ? 'Riproverò alla riapertura o alla prossima sincronizzazione.'
              : '$pending modifiche verranno inviate quando torna la rete.';
        } else if (pending > 0) {
          icon = Icons.cloud_upload_outlined;
          title = '$pending modifiche in attesa';
          subtitle =
              'Restano salvate sul dispositivo finché non vengono sincronizzate.';
        } else {
          icon = Icons.cloud_done_outlined;
          title = 'Tutto sincronizzato';
          subtitle = cloud.lastSyncAt == null
              ? 'Nessuna modifica in attesa.'
              : 'Ultimo controllo ${DateFormat('HH:mm', 'it_IT').format(cloud.lastSyncAt!)}.';
        }

        return Material(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CloudAccountScreen(store: store),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeFocusCard extends StatelessWidget {
  final UnifiedAgendaEntry? next;
  final int pendingTasks;
  final int inboxCount;
  final bool hideDetails;
  final VoidCallback? onOpenNext;
  final VoidCallback onOpenInbox;

  const _HomeFocusCard({
    required this.next,
    required this.pendingTasks,
    required this.inboxCount,
    required this.hideDetails,
    required this.onOpenNext,
    required this.onOpenInbox,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nextText = next == null
        ? 'Nessun appuntamento in arrivo'
        : hideDetails
            ? 'Prossimo impegno programmato'
            : '${DateFormat('EEE d MMM', 'it_IT').format(next!.date)} · '
                '${formatTime(next!.start!)} · ${next!.title}'
                '${next!.isShared ? ' · Noi ♡' : ''}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A colpo d’occhio',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: '$pendingTasks da fare',
              ),
              ActionChip(
                avatar: const Icon(Icons.inbox_outlined, size: 17),
                label: Text('$inboxCount in Inbox'),
                onPressed: onOpenInbox,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InboxScreen extends StatelessWidget {
  final AgendaStore store;

  const InboxScreen({super.key, required this.store});

  Future<void> _convertToTask(
    BuildContext context,
    InboxEntry entry,
  ) async {
    final item = AgendaItem(
      id: const Uuid().v4(),
      title: entry.text,
      note: '',
      date: DateTime.now(),
      type: ItemType.task,
      category: store.preferences.defaultCategory,
    );
    await store.upsert(item);
    await store.deleteInboxEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota trasformata in attività.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entries = [...store.inbox]
          ..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Inbox',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(context, store),
            icon: const Icon(Icons.add),
            label: const Text('Cattura'),
          ),
          body: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Qui finiranno le idee e le note catturate al volo.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(
                          14,
                          8,
                          6,
                          8,
                        ),
                        leading: Icon(
                          entry.pinned
                              ? Icons.push_pin
                              : Icons.sticky_note_2_outlined,
                        ),
                        title: Text(entry.text),
                        subtitle: Text(
                          DateFormat(
                            'd MMM, HH:mm',
                            'it_IT',
                          ).format(entry.createdAt),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'pin') {
                              await store.toggleInboxPinned(entry.id);
                            } else if (value == 'task') {
                              await _convertToTask(context, entry);
                            } else if (value == 'delete') {
                              await store.deleteInboxEntry(entry.id);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                entry.pinned ? 'Togli dai fissati' : 'Fissa',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'task',
                              child: Text('Trasforma in attività'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Elimina'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TodayWellbeingCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime date;

  const _TodayWellbeingCard({
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFF4F0FF)],
        ),
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
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Text(
              journal.mood?.emoji ?? '♡',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journal.mood == null
                      ? 'Come sta andando la giornata?'
                      : 'Oggi: ${journal.mood!.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      totalHabits == 0
                          ? 'Nessuna abitudine'
                          : '$doneHabits/$totalHabits abitudini',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$gratitudeCount/3 cose belle',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.favorite_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

enum _SearchHitType { event, journal, month }

class _SearchHit {
  final _SearchHitType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final AgendaItem? item;

  const _SearchHit({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.item,
  });
}

class SearchScreen extends StatefulWidget {
  final AgendaStore store;

  const SearchScreen({super.key, required this.store});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  AgendaCategory? category;

  List<_SearchHit> _results() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final hits = <_SearchHit>[];

    for (final item in widget.store.items) {
      if (category != null && item.category != category) continue;
      final haystack = [
        item.title,
        item.note,
        item.category.label,
        DateFormat('d MMMM yyyy', 'it_IT').format(item.date),
      ].join(' ').toLowerCase();

      if (haystack.contains(q)) {
        hits.add(
          _SearchHit(
            type: _SearchHitType.event,
            title: item.title,
            subtitle:
                '${DateFormat('d MMMM yyyy', 'it_IT').format(item.date)} · ${item.category.label}',
            date: item.date,
            item: item,
          ),
        );
      }
    }

    if (category == null) {
      for (final entry in widget.store.journals.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date == null) continue;
        final journal = entry.value;
        final haystack = [
          journal.beautiful,
          journal.note,
          ...journal.gratitude,
          journal.mood?.label ?? '',
        ].join(' ').toLowerCase();

        if (haystack.contains(q)) {
          hits.add(
            _SearchHit(
              type: _SearchHitType.journal,
              title: journal.beautiful.trim().isNotEmpty
                  ? journal.beautiful.trim()
                  : 'Diario del ${DateFormat('d MMMM', 'it_IT').format(date)}',
              subtitle:
                  'Diario · ${DateFormat('d MMMM yyyy', 'it_IT').format(date)}',
              date: date,
            ),
          );
        }
      }

      for (final entry in widget.store.months.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 2) continue;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) continue;
        final data = entry.value;
        final haystack = [
          data.intention,
          data.monthWord,
          data.selfCare,
          ...data.goals,
          ...data.books,
          ...data.films,
          ...data.hobbies,
          ...data.wishes,
          ...data.ideas,
          data.bestMoment,
          data.lesson,
          data.challenge,
          data.nextMonth,
          data.reflection,
        ].join(' ').toLowerCase();

        if (haystack.contains(q)) {
          final date = DateTime(year, month);
          hits.add(
            _SearchHit(
              type: _SearchHitType.month,
              title:
                  _cap(DateFormat('MMMM yyyy', 'it_IT').format(date)),
              subtitle: data.intention.trim().isEmpty
                  ? 'Pagina del mese'
                  : data.intention.trim(),
              date: date,
            ),
          );
        }
      }
    }

    hits.sort((a, b) => b.date.compareTo(a.date));
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cerca nell’agenda',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'Cerca appuntamenti, note, ricordi...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    selected: category == null,
                    label: const Text('Tutto'),
                    onSelected: (_) => setState(() => category = null),
                  ),
                ),
                ...AgendaCategory.values.map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      selected: category == value,
                      avatar: Icon(
                        value.icon,
                        size: 16,
                        color: value.color,
                      ),
                      label: Text(value.label),
                      onSelected: (_) => setState(() {
                        category = category == value ? null : value;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: query.trim().isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Scrivi qualcosa: i risultati compariranno mentre digiti.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : results.isEmpty
                    ? const Center(child: Text('Nessun risultato.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final hit = results[index];
                          final icon = switch (hit.type) {
                            _SearchHitType.event => Icons.event_outlined,
                            _SearchHitType.journal => Icons.menu_book_outlined,
                            _SearchHitType.month =>
                              Icons.calendar_month_outlined,
                          };

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Icon(icon)),
                              title: Text(
                                hit.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                hit.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: () async {
                                if (hit.type == _SearchHitType.event) {
                                  await openItemEditor(
                                    context,
                                    widget.store,
                                    hit.date,
                                    existing: hit.item,
                                  );
                                } else if (hit.type ==
                                    _SearchHitType.journal) {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlannerScreen(
                                        store: widget.store,
                                        initialDate: hit.date,
                                      ),
                                    ),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MonthScreen(
                                        store: widget.store,
                                        initialMonth: hit.date,
                                      ),
                                    ),
                                  );
                                }
                                if (mounted) setState(() {});
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  final AgendaStore store;

  const ArchiveScreen({super.key, required this.store});

  List<DateTime> _months() {
    final keys = <String>{};

    for (final item in store.items) {
      keys.add(AgendaStore.monthKey(item.date.year, item.date.month));
    }
    for (final key in store.journals.keys) {
      if (key.length >= 7) keys.add(key.substring(0, 7));
    }
    keys.addAll(store.months.keys);

    final months = <DateTime>[];
    for (final key in keys) {
      final parts = key.split('-');
      if (parts.length != 2) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null) {
        months.add(DateTime(year, month));
      }
    }
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final months = _months();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Archivio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: months.isEmpty
          ? const Center(child: Text('L’archivio è ancora vuoto.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
              itemCount: months.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final month = months[index];
                final data = store.month(month.year, month.month);
                final events = store.items
                    .where(
                      (e) =>
                          e.date.year == month.year &&
                          e.date.month == month.month,
                    )
                    .length;
                final prefix =
                    '${month.year}-${month.month.toString().padLeft(2, '0')}-';
                final journalDays = store.journals.keys
                    .where((key) => key.startsWith(prefix))
                    .length;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.auto_stories_outlined),
                    ),
                    title: Text(
                      _cap(
                        DateFormat('MMMM yyyy', 'it_IT').format(month),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        '$events impegni',
                        '$journalDays giorni raccontati',
                        if (data.goals.isNotEmpty)
                          '${data.goals.length} obiettivi',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MonthScreen(
                          store: store,
                          initialMonth: month,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class BackupScreen extends StatefulWidget {
  final AgendaStore store;

  const BackupScreen({super.key, required this.store});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;

  String _timestampFileName(String extension) {
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    return 'Agenda-per-Anna_backup_$stamp.$extension';
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => busy = true);
    try {
      final ok = await BackupFileService.instance.saveJsonBackup(
        json: widget.store.createBackupJson(),
        fileName: _timestampFileName('json'),
      );
      _message(
        ok
            ? 'Backup completo salvato.'
            : 'Salvataggio annullato o non riuscito.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _exportReadable() async {
    setState(() => busy = true);
    try {
      final ok = await BackupFileService.instance.saveTextExport(
        text: widget.store.createReadableExport(),
        fileName: _timestampFileName('txt'),
      );
      _message(
        ok
            ? 'Copia leggibile esportata.'
            : 'Esportazione annullata o non riuscita.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => busy = true);
    String? raw;
    try {
      raw = await BackupFileService.instance.pickJsonBackup();
    } finally {
      if (mounted) setState(() => busy = false);
    }

    if (raw == null || !mounted) return;

    BackupSummary summary;
    try {
      summary = widget.store.inspectBackup(raw);
    } catch (error) {
      _message(
        error is FormatException
            ? error.message.toString()
            : 'Il file selezionato non è un backup valido.',
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ripristinare questo backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creato il ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(summary.exportedAt)}',
            ),
            const SizedBox(height: 12),
            Text('• ${summary.itemCount} impegni e attività'),
            Text('• ${summary.journalCount} giorni di diario'),
            Text('• ${summary.monthCount} pagine mensili'),
            Text('• ${summary.weekCount} settimane'),
            Text('• ${summary.habitCount} abitudini'),
            const SizedBox(height: 14),
            const Text(
              'Prima del ripristino verrà creato automaticamente un backup locale di sicurezza.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, 'merge'),
            child: const Text('Unisci'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'replace'),
            child: const Text('Sostituisci tutto'),
          ),
        ],
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'replace') {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Conferma sostituzione'),
              content: const Text(
                'I dati attuali verranno sostituiti da quelli del backup. '
                'Potrai tornare indietro usando il backup locale creato prima del ripristino.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Ripristina'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    setState(() => busy = true);
    try {
      await widget.store.restoreBackup(
        raw,
        merge: action == 'merge',
      );
      _message(
        action == 'merge'
            ? 'Backup unito ai dati presenti.'
            : 'Backup ripristinato correttamente.',
      );
    } catch (_) {
      _message('Ripristino non riuscito. I dati attuali non sono stati eliminati.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restoreSnapshot(LocalBackupSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ripristinare questo backup locale?'),
            content: Text(
              '${snapshot.label}\n'
              '${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(snapshot.createdAt)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => busy = true);
    try {
      await widget.store.restoreLocalSnapshot(snapshot.id);
      _message('Backup locale ripristinato.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final snapshots = widget.store.localSnapshots;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Backup e dati',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFE7EF),
                          Color(0xFFF1ECFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 30),
                        SizedBox(height: 10),
                        Text(
                          'I ricordi restano tuoi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Crea una copia completa dell’agenda e conservala dove preferisci. '
                          'Il file JSON può ripristinare l’app; il TXT è pensato per essere letto.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BackupActionCard(
                    icon: Icons.save_alt_outlined,
                    title: 'Crea backup completo',
                    subtitle:
                        'Salva appuntamenti, diario, mesi, settimane, abitudini e budget in un file .json.',
                    buttonLabel: 'Salva backup',
                    onPressed: busy ? null : _exportBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.restore_outlined,
                    title: 'Ripristina da file',
                    subtitle:
                        'Importa un backup precedente. Puoi unire i dati oppure sostituire tutto.',
                    buttonLabel: 'Scegli backup',
                    onPressed: busy ? null : _importBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.description_outlined,
                    title: 'Esporta copia leggibile',
                    subtitle:
                        'Crea un file .txt con impegni, diario e pagine mensili da conservare o stampare.',
                    buttonLabel: 'Esporta TXT',
                    onPressed: busy ? null : _exportReadable,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Backup locali di sicurezza',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Crea backup locale',
                        onPressed: busy
                            ? null
                            : () => widget.store.createLocalSnapshot(),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Text(
                    'L’app conserva fino a 5 copie locali e ne crea una automaticamente circa ogni 6 ore di utilizzo. '
                    'Queste copie restano sul dispositivo e vengono perse se l’app viene disinstallata: '
                    'per una copia davvero sicura usa anche “Crea backup completo”.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  if (snapshots.isEmpty)
                    const SimpleCard(
                      child: Text('Nessun backup locale disponibile.'),
                    )
                  else
                    ...snapshots.map(
                      (snapshot) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.history),
                          ),
                          title: Text(
                            snapshot.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'd MMMM yyyy, HH:mm',
                              'it_IT',
                            ).format(snapshot.createdAt),
                          ),
                          onTap: busy
                              ? null
                              : () => _restoreSnapshot(snapshot),
                          trailing: IconButton(
                            tooltip: 'Elimina backup',
                            onPressed: busy
                                ? null
                                : () => widget.store
                                    .deleteLocalSnapshot(snapshot.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white54,
                    child: Center(
                      child: CircularProgressIndicator(),
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

class _BackupActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final AgendaStore store;

  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController nameController =
      TextEditingController(text: widget.store.preferences.displayName);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final value = nameController.text.trim();
    await widget.store.savePreferences(
      widget.store.preferences.copyWith(
        displayName: value.isEmpty ? 'Anna' : value,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nome aggiornato.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _configurePin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Imposta PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: 'Almeno 4 cifre',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: second,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Ripeti PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final a = first.text.trim();
              final b = second.text.trim();
              final validPin =
                  RegExp(r'^\d{4,8}$').hasMatch(a);
              if (!validPin || a != b) return;
              Navigator.pop(dialogContext, a);
            },
            child: const Text('Salva PIN'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    if (value == null) return;

    try {
      await widget.store.setPin(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN impostato e blocco attivato.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN non valido.')),
      );
    }
  }

  Future<bool> _deviceSupportsBiometrics() async {
    if (kIsWeb) return false;
    try {
      final auth = LocalAuthentication();
      return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ripristinare le impostazioni?'),
            content: const Text(
              'Verranno ripristinati tema, colore e valori predefiniti. '
              'Appuntamenti, diario e altri dati non verranno toccati.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await widget.store.resetPreferences();
    nameController.text = widget.store.preferences.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final prefs = widget.store.preferences;
        final primary = prefs.defaultPrimaryReminder ?? -1;
        final secondary = prefs.defaultSecondaryReminder ?? -1;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Impostazioni',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
            children: [
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'La mia agenda',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.favorite_outline),
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _saveName,
                        child: const Text('Salva nome'),
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
                    const Text(
                      'Aspetto',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AgendaThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: AgendaThemeMode.system,
                          label: Text('Sistema'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: AgendaThemeMode.light,
                          label: Text('Chiaro'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: AgendaThemeMode.dark,
                          label: Text('Scuro'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {prefs.themeMode},
                      onSelectionChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(themeMode: value.first),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Colore dell’agenda',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AgendaPalette.values.map((palette) {
                        final selected = prefs.palette == palette;
                        return ChoiceChip(
                          selected: selected,
                          avatar: CircleAvatar(
                            radius: 8,
                            backgroundColor: palette.seed,
                          ),
                          label: Text(palette.label),
                          onSelected: (_) =>
                              widget.store.savePreferences(
                            prefs.copyWith(palette: palette),
                          ),
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
                      'Avvio e Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<StartTab>(
                      initialValue: prefs.startTab,
                      decoration: const InputDecoration(
                        labelText: 'Apri l’app su',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      items: StartTab.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        widget.store.savePreferences(
                          prefs.copyWith(startTab: value),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Frase positiva del giorno'),
                      subtitle: const Text(
                        'Mostra la frase nella testata della Home.',
                      ),
                      value: prefs.showDailyQuote,
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(showDailyQuote: value),
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
                    const Text(
                      'Nuovi impegni',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Questi valori vengono proposti automaticamente quando crei un nuovo elemento.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AgendaCategory>(
                      initialValue: prefs.defaultCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria predefinita',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      items: AgendaCategory.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    value.icon,
                                    color: value.color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(value.label),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        widget.store.savePreferences(
                          prefs.copyWith(defaultCategory: value),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.timelapse_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Durata appuntamento: ${prefs.defaultEventMinutes} min',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 15,
                      max: 180,
                      divisions: 11,
                      value: prefs.defaultEventMinutes
                          .clamp(15, 180)
                          .toDouble(),
                      label: '${prefs.defaultEventMinutes} min',
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(
                          defaultEventMinutes:
                              (value / 15).round() * 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      key: ValueKey('primary-$primary'),
                      initialValue: primary,
                      decoration: const InputDecoration(
                        labelText: 'Promemoria predefinito 1',
                        prefixIcon:
                            Icon(Icons.notifications_none_outlined),
                      ),
                      items: _reminderMenuItems,
                      onChanged: (value) {
                        final minutes = value ?? -1;
                        widget.store.savePreferences(
                          prefs.copyWith(
                            defaultPrimaryReminder:
                                minutes < 0 ? null : minutes,
                            clearPrimaryReminder: minutes < 0,
                            clearSecondaryReminder:
                                minutes >= 0 && minutes == secondary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: ValueKey('secondary-$secondary-$primary'),
                      initialValue: secondary,
                      decoration: const InputDecoration(
                        labelText: 'Promemoria predefinito 2',
                        prefixIcon: Icon(Icons.add_alert_outlined),
                      ),
                      items: _reminderMenuItems,
                      onChanged: (value) {
                        final minutes = value ?? -1;
                        widget.store.savePreferences(
                          prefs.copyWith(
                            defaultSecondaryReminder:
                                minutes < 0 || minutes == primary
                                    ? null
                                    : minutes,
                            clearSecondaryReminder:
                                minutes < 0 || minutes == primary,
                          ),
                        );
                      },
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
                      'Privacy',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Proteggi l’agenda quando il telefono passa ad altre app o resta inattivo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    if (prefs.pinHash == null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _configurePin,
                          icon: const Icon(Icons.pin_outlined),
                          label: const Text('Imposta PIN'),
                        ),
                      )
                    else ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Blocca Agenda'),
                        subtitle: const Text(
                          'Richiede PIN o biometria per riaprire l’app.',
                        ),
                        value: prefs.privacyLockEnabled,
                        onChanged: (value) =>
                            widget.store.savePreferences(
                          prefs.copyWith(privacyLockEnabled: value),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pin_outlined),
                        title: const Text('Cambia PIN'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _configurePin,
                      ),
                    ],
                    if (prefs.pinHash != null) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sblocco biometrico'),
                        subtitle: const Text(
                          kIsWeb
                              ? 'Non disponibile sul web.'
                              : 'Usa impronta o riconoscimento biometrico del dispositivo.',
                        ),
                        value: prefs.biometricUnlock,
                        onChanged: prefs.privacyLockEnabled
                            ? (value) async {
                                if (value &&
                                    !await _deviceSupportsBiometrics()) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Biometria non disponibile su questo dispositivo.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await widget.store.savePreferences(
                                  prefs.copyWith(
                                    biometricUnlock: value,
                                  ),
                                );
                              }
                            : null,
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: prefs.autoLockMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Blocco automatico',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Subito'),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Dopo 1 minuto'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Dopo 2 minuti'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('Dopo 5 minuti'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('Dopo 15 minuti'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          widget.store.savePreferences(
                            prefs.copyWith(autoLockMinutes: value),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Nascondi dettagli in Home'),
                      subtitle: const Text(
                        'Mostra indicatori generici invece del titolo del prossimo impegno.',
                      ),
                      value: prefs.hideHomeDetails,
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(hideHomeDetails: value),
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
                    const Text(
                      'Dati',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_outlined),
                      title: const Text('Account e sincronizzazione'),
                      subtitle: const Text(
                        'Sincronizza l’agenda personale fra i tuoi dispositivi.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CloudAccountScreen(store: widget.store),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup e ripristino'),
                      subtitle: const Text(
                        'Esporta, importa o recupera una copia locale.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BackupScreen(store: widget.store),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Ripristina impostazioni predefinite'),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Agenda per Anna · v0.13',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SharedSpaceHubScreen extends StatefulWidget {
  final AgendaStore store;

  const SharedSpaceHubScreen({super.key, required this.store});

  @override
  State<SharedSpaceHubScreen> createState() => _SharedSpaceHubScreenState();
}

class _SharedSpaceHubScreenState extends State<SharedSpaceHubScreen> {
  bool loading = true;
  List<SharedSpace> spaces = const [];
  final Map<String, int> unreadBySpace = {};
  final Map<String, int> pendingBySpace = {};
  final Set<String> _realtimeSpaceIds = {};

  @override
  void initState() {
    super.initState();
    _loadCachedThenReload();
  }

  @override
  void dispose() {
    for (final spaceId in _realtimeSpaceIds.toList()) {
      unawaited(
        CloudSyncService.instance.unsubscribeSharedSpace(
          spaceId: spaceId,
          listenerKey: 'hub',
        ),
      );
    }
    super.dispose();
  }

  Future<void> _loadCachedThenReload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(widget.store.sharedSpacesCacheStorageKey);
    if (raw != null) {
      try {
        final cached = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .map(
              (e) => SharedSpace.fromJson(
                e,
                role: e['role'] as String? ?? 'member',
              ),
            )
            .toList();
        if (mounted) {
          setState(() {
            spaces = cached;
            loading = false;
          });
        }
        await _bindRealtime(cached);
        await _refreshIndicators(cached);
      } catch (_) {}
    }
    await _reload();
  }

  Future<void> _saveSpacesCache(List<SharedSpace> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      widget.store.sharedSpacesCacheStorageKey,
      jsonEncode(
        value
            .map(
              (space) => {
                'id': space.id,
                'owner_id': space.ownerId,
                'name': space.name,
                'role': space.role,
                'created_at': space.createdAt.toIso8601String(),
              },
            )
            .toList(),
      ),
    );
    await widget.store.refreshSharedAgendaCache();
  }

  Future<void> _bindRealtime(List<SharedSpace> value) async {
    final nextIds = value.map((space) => space.id).toSet();
    for (final oldId in _realtimeSpaceIds.difference(nextIds).toList()) {
      await CloudSyncService.instance.unsubscribeSharedSpace(
        spaceId: oldId,
        listenerKey: 'hub',
      );
      _realtimeSpaceIds.remove(oldId);
    }

    if (!CloudSyncService.instance.signedIn) return;
    for (final space in value) {
      CloudSyncService.instance.subscribeSharedSpace(
        spaceId: space.id,
        listenerKey: 'hub',
        onChanged: () {
          if (!mounted) return;
          setState(() {
            unreadBySpace[space.id] = (unreadBySpace[space.id] ?? 0) + 1;
          });
        },
      );
      _realtimeSpaceIds.add(space.id);
    }
  }

  Future<void> _refreshIndicators(List<SharedSpace> value) async {
    final next = <String, int>{};
    for (final space in value) {
      next[space.id] = await widget.store.pendingSharedChanges(space.id);
    }
    if (mounted) {
      setState(() {
        pendingBySpace
          ..clear()
          ..addAll(next);
      });
    }
  }

  Future<void> _reload() async {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final result = await cloud.listSharedSpaces();
      await _saveSpacesCache(result);
      await _bindRealtime(result);
      await _refreshIndicators(result);
      await widget.store.refreshSharedAgendaCache(pullRemote: true);
      if (mounted) {
        setState(() {
          spaces = result;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createSpace() async {
    final controller = TextEditingController(text: 'Noi ♡');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crea uno spazio condiviso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome dello spazio',
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
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    setState(() => loading = true);
    try {
      await CloudSyncService.instance.createSharedSpace(name: name);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('Impossibile creare lo spazio: $error');
    }
  }

  Future<void> _joinSpace() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collegati con un codice'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          decoration: const InputDecoration(
            labelText: 'Codice invito',
            hintText: 'Es. A1B2C3D4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().toUpperCase(),
            ),
            child: const Text('Collegati'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;

    setState(() => loading = true);
    try {
      await CloudSyncService.instance.joinSharedSpace(code);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('Codice non valido, già usato o scaduto.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSyncService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([cloud, widget.store]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Noi ♡',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (cloud.signedIn)
                IconButton(
                  tooltip: 'Aggiorna',
                  onPressed: loading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: !cloud.signedIn
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_outline, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'Uno spazio solo per voi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accedi al cloud per creare o raggiungere uno spazio condiviso. '
                            'La tua agenda personale resterà separata.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CloudAccountScreen(
                                  store: widget.store,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.cloud_outlined),
                            label: const Text('Account e sincronizzazione'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFE4EC),
                                Color(0xFFF0E8FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.favorite_outline, size: 30),
                              SizedBox(height: 10),
                              Text(
                                'Spazio condiviso',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Gli aggiornamenti arrivano in tempo reale. '
                                'Se siete offline, le modifiche restano in coda e vengono inviate dopo.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (spaces.isEmpty)
                          SimpleCard(
                            child: Column(
                              children: [
                                const Text(
                                  'Non sei ancora collegato a nessuno spazio.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _createSpace,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Crea il nostro spazio'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _joinSpace,
                                    icon: const Icon(Icons.link),
                                    label: const Text('Inserisci un codice'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          ...spaces.map(
                            (space) {
                              final unread = unreadBySpace[space.id] ?? 0;
                              final pending = pendingBySpace[space.id] ?? 0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      space.isOwner
                                          ? Icons.favorite
                                          : Icons.favorite_outline,
                                    ),
                                  ),
                                  title: Text(
                                    space.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    pending > 0
                                        ? '$pending modifiche da sincronizzare'
                                        : space.isOwner
                                            ? 'Creato da te · sincronizzato'
                                            : 'Spazio condiviso · sincronizzato',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (unread > 0)
                                        Badge(
                                          label: Text(
                                            unread > 99 ? '99+' : '$unread',
                                          ),
                                          child: const Icon(
                                            Icons.notifications_none,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onTap: () async {
                                    setState(
                                      () => unreadBySpace[space.id] = 0,
                                    );
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SharedSpaceScreen(
                                          store: widget.store,
                                          space: space,
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    setState(
                                      () => unreadBySpace[space.id] = 0,
                                    );
                                    await _reload();
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: _joinSpace,
                            icon: const Icon(Icons.link),
                            label: const Text('Collegati a un altro spazio'),
                          ),
                        ],
                      ],
                    ),
        );
      },
    );
  }
}
class SharedSpaceScreen extends StatefulWidget {
  final AgendaStore store;
  final SharedSpace space;

  const SharedSpaceScreen({
    super.key,
    required this.store,
    required this.space,
  });

  @override
  State<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends State<SharedSpaceScreen> {
  bool loading = true;
  bool realtimeConnected = false;
  List<SharedEntry> entries = [];
  Set<String> pendingIds = {};
  DateTime selected = DateTime.now();
  DateTime? lastRefreshAt;
  Timer? _realtimeDebounce;
  int _seenConflictCount = 0;

  String get _cacheKey =>
      widget.store.sharedCacheStorageKey(widget.space.id);
  String get _pendingKey =>
      widget.store.sharedPendingStorageKey(widget.space.id);

  @override
  void initState() {
    super.initState();
    _seenConflictCount = widget.store.sharedConflictCount;
    _loadCachedThenRefresh();
    _bindRealtime();
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    unawaited(
      CloudSyncService.instance.unsubscribeSharedSpace(
        spaceId: widget.space.id,
        listenerKey: 'screen',
      ),
    );
    super.dispose();
  }

  void _bindRealtime() {
    if (!CloudSyncService.instance.signedIn) return;
    CloudSyncService.instance.subscribeSharedSpace(
      spaceId: widget.space.id,
      listenerKey: 'screen',
      onChanged: () {
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
          if (mounted) unawaited(_refresh(silent: true));
        });
      },
      onConnectionChanged: (connected) {
        if (!mounted) return;
        setState(() => realtimeConnected = connected);
      },
    );
  }

  Future<void> _loadCachedThenRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      try {
        entries = (jsonDecode(raw) as List)
            .map(
              (e) => SharedEntry.fromCacheJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } catch (_) {}
    }
    await _updatePendingState();
    if (mounted) setState(() => loading = false);
    await _refresh(silent: entries.isNotEmpty);
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(entries.map((e) => e.toCacheJson()).toList()),
    );
    await widget.store.refreshSharedAgendaCache();
  }

  Future<List<SharedPendingOperation>> _loadPending() =>
      widget.store.loadSharedPendingOperations(widget.space.id);

  Future<void> _updatePendingState() async {
    final operations = await _loadPending();
    if (!mounted) return;
    setState(() {
      pendingIds = operations.map((operation) => operation.entityId).toSet();
    });
  }

  Future<void> _flushPending() async {
    final conflictsBefore = widget.store.sharedConflictCount;
    await widget.store.flushSharedPendingOperations(
      spaceId: widget.space.id,
    );
    await _updatePendingState();
    if (widget.store.sharedConflictCount > conflictsBefore &&
        widget.store.sharedConflictCount > _seenConflictCount) {
      _seenConflictCount = widget.store.sharedConflictCount;
      _message(
        'Conflitto risolto: è stata mantenuta la modifica più recente.',
      );
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn) {
      await _updatePendingState();
      if (mounted) setState(() => loading = false);
      return;
    }
    if (!silent && mounted) setState(() => loading = true);
    try {
      await _flushPending();
      final records = await cloud.pullSharedRecords(widget.space.id);
      final next = <SharedEntry>[];
      for (final record in records) {
        if (record.deletedAt != null ||
            record.entityType != 'shared_entry' ||
            record.payload == null) {
          continue;
        }
        next.add(
          SharedEntry.fromJson(
            record.payload!,
            updatedBy: record.updatedBy,
            updatedAt: record.clientUpdatedAt,
          ),
        );
      }

      final pending = await _loadPending();
      for (final operation in pending) {
        next.removeWhere((entry) => entry.id == operation.entityId);
        if (operation.action == SharedPendingAction.upsert &&
            operation.payload != null) {
          next.add(
            SharedEntry.fromJson(
              operation.payload!,
              updatedBy: cloud.userId,
              updatedAt: operation.updatedAt,
            ),
          );
        }
      }

      next.sort((a, b) {
        final date = a.date.compareTo(b.date);
        if (date != 0) return date;
        final am = a.start == null ? 0 : a.start!.hour * 60 + a.start!.minute;
        final bm = b.start == null ? 0 : b.start!.hour * 60 + b.start!.minute;
        return am.compareTo(bm);
      });
      entries = next;
      pendingIds = pending.map((operation) => operation.entityId).toSet();
      lastRefreshAt = DateTime.now();
      await _saveCache();
    } catch (_) {
      if (!silent) {
        _message(
          'Impossibile aggiornare ora. Mostro l’ultima copia disponibile.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<SharedEntry> get _selectedEntries => entries
      .where((entry) => AgendaStore.sameDay(entry.date, selected))
      .toList();

  String _editorLabel(SharedEntry entry) {
    final explicit = entry.editorName.trim();
    if (explicit.isNotEmpty) {
      if (explicit == widget.store.preferences.displayName.trim()) {
        return 'Modificato da te';
      }
      return 'Modificato da $explicit';
    }
    if (entry.updatedBy != null &&
        entry.updatedBy == CloudSyncService.instance.userId) {
      return 'Modificato da te';
    }
    if (entry.updatedBy != null) return 'Modificato dall’altra persona';
    return '';
  }

  SharedEntry _withLocalMetadata(
    SharedEntry entry,
    DateTime revision,
  ) =>
      entry.copyWith(
        editorName: widget.store.preferences.displayName.trim().isEmpty
            ? 'Utente'
            : widget.store.preferences.displayName.trim(),
        updatedBy: CloudSyncService.instance.userId,
        updatedAt: revision,
      );

  Future<void> _edit([SharedEntry? existing]) async {
    if (widget.store.activeAccountId == null) {
      _message(
        'Accedi al cloud almeno una volta per usare lo spazio condiviso.',
      );
      return;
    }

    final result = await _openSharedEntryEditor(
      context,
      initialDate: selected,
      existing: existing,
    );
    if (result == null) return;

    final revision = DateTime.now().toUtc();
    final updated = _withLocalMetadata(result, revision);
    final index = entries.indexWhere((entry) => entry.id == updated.id);
    setState(() {
      if (index < 0) {
        entries.add(updated);
      } else {
        entries[index] = updated;
      }
      pendingIds.add(updated.id);
    });
    await widget.store.enqueueSharedUpsert(
      spaceId: widget.space.id,
      entry: updated,
      updatedAt: revision,
    );
    await _saveCache();

    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
      await _refresh(silent: true);
    } else {
      _message('Salvato offline: verrà sincronizzato appena torni online.');
    }
  }

  Future<void> _toggleDone(SharedEntry entry) async {
    final revision = DateTime.now().toUtc();
    final updated = _withLocalMetadata(
      entry.copyWith(done: !entry.done),
      revision,
    );
    final index = entries.indexWhere((candidate) => candidate.id == entry.id);
    if (index >= 0) {
      setState(() {
        entries[index] = updated;
        pendingIds.add(updated.id);
      });
    }
    await widget.store.enqueueSharedUpsert(
      spaceId: widget.space.id,
      entry: updated,
      updatedAt: revision,
    );
    await _saveCache();
    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
    }
  }

  Future<void> _delete(SharedEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare dallo spazio condiviso?'),
            content: Text(entry.title),
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
    if (!confirmed) return;

    final revision = DateTime.now().toUtc();
    setState(() {
      entries.removeWhere((candidate) => candidate.id == entry.id);
      pendingIds.add(entry.id);
    });
    await widget.store.enqueueSharedDelete(
      spaceId: widget.space.id,
      entityId: entry.id,
      updatedAt: revision,
    );
    await _saveCache();
    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
      await _refresh(silent: true);
    } else {
      _message('Eliminazione salvata offline.');
    }
  }

  Future<void> _invite() async {
    try {
      final code =
          await CloudSyncService.instance.createSpaceInvite(widget.space.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Codice per collegarsi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Condividi questo codice con la persona che vuoi invitare. '
                'È valido per 24 ore e può essere usato una sola volta.',
              ),
              const SizedBox(height: 18),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
    } catch (_) {
      _message('Non è stato possibile creare il codice invito.');
    }
  }

  Future<void> _leaveOrDelete() async {
    final owner = widget.space.isOwner;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(owner ? 'Eliminare lo spazio?' : 'Lasciare lo spazio?'),
            content: Text(
              owner
                  ? 'Lo spazio e tutti i contenuti condivisi verranno eliminati per tutti.'
                  : 'Non vedrai più questo spazio, ma i tuoi dati personali non verranno toccati.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(owner ? 'Elimina' : 'Lascia'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      if (owner) {
        await CloudSyncService.instance.deleteSharedSpace(widget.space.id);
      } else {
        await CloudSyncService.instance.leaveSharedSpace(widget.space.id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_pendingKey);
      await widget.store.refreshSharedAgendaCache(pullRemote: true);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _message('Operazione non riuscita.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _syncCard(BuildContext context) {
    final cloud = CloudSyncService.instance;
    final pending = pendingIds.length;
    final scheme = Theme.of(context).colorScheme;
    final IconData icon;
    final String title;
    final String subtitle;

    if (pending > 0) {
      icon = cloud.signedIn ? Icons.sync : Icons.cloud_off_outlined;
      title = '$pending modifiche in attesa';
      subtitle = cloud.signedIn
          ? 'Invio automatico in corso.'
          : 'Sono al sicuro sul dispositivo e verranno inviate quando torni online.';
    } else if (!cloud.signedIn) {
      icon = Icons.cloud_off_outlined;
      title = 'Offline';
      subtitle = 'Puoi consultare e modificare la copia locale dello spazio.';
    } else if (realtimeConnected) {
      icon = Icons.bolt;
      title = 'Sincronizzato in tempo reale';
      subtitle = lastRefreshAt == null
          ? 'In ascolto degli aggiornamenti.'
          : 'Ultimo aggiornamento ${DateFormat('HH:mm').format(lastRefreshAt!)}.';
    } else {
      icon = Icons.cloud_done_outlined;
      title = 'Sincronizzato';
      subtitle = 'La connessione realtime si ristabilirà automaticamente.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEntries = _selectedEntries;
    return AnimatedBuilder(
      animation: Listenable.merge([
        CloudSyncService.instance,
        widget.store,
      ]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.space.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (widget.space.isOwner)
              IconButton(
                tooltip: 'Invita',
                onPressed: _invite,
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'refresh') _refresh();
                if (value == 'leave') _leaveOrDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Text('Aggiorna'),
                ),
                PopupMenuItem(
                  value: 'leave',
                  child: Text(
                    widget.space.isOwner
                        ? 'Elimina spazio'
                        : 'Lascia spazio',
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Condividi'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Noi ♡ · tutto ciò che crei qui è condiviso. '
                        'Il resto dell’agenda rimane privato.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _syncCard(context),
              const SizedBox(height: 14),
              TableCalendar<SharedEntry>(
                locale: 'it_IT',
                firstDay: DateTime(2020),
                lastDay: DateTime(2040),
                focusedDay: selected,
                selectedDayPredicate: (day) =>
                    AgendaStore.sameDay(day, selected),
                eventLoader: (day) => entries
                    .where((entry) => AgendaStore.sameDay(entry.date, day))
                    .toList(),
                onDaySelected: (day, _) => setState(() => selected = day),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 16),
              SectionTitle(
                _cap(DateFormat('EEEE d MMMM', 'it_IT').format(selected)),
              ),
              const SizedBox(height: 10),
              if (loading && entries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (dayEntries.isEmpty)
                const SimpleCard(
                  child: Text('Niente di condiviso per questo giorno.'),
                )
              else
                ...dayEntries.map(
                  (entry) {
                    final editor = _editorLabel(entry);
                    final pending = pendingIds.contains(entry.id);
                    final details = <String>[
                      if (entry.start != null) formatTime(entry.start!),
                      if (entry.note.isNotEmpty) entry.note,
                      if (editor.isNotEmpty) editor,
                      if (pending) 'In attesa di sincronizzazione',
                    ];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 9),
                      child: ListTile(
                        leading: entry.type == SharedEntryType.task
                            ? Checkbox(
                                value: entry.done,
                                onChanged: (_) => _toggleDone(entry),
                              )
                            : CircleAvatar(
                                child: Icon(entry.type.icon),
                              ),
                        title: Text(
                          entry.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            decoration: entry.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          details.join(' · '),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _edit(entry),
                        trailing: pending
                            ? const Icon(Icons.schedule_outlined)
                            : PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _edit(entry);
                                  if (value == 'delete') _delete(entry);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifica'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Elimina'),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<SharedEntry?> _openSharedEntryEditor(
  BuildContext context, {
  required DateTime initialDate,
  SharedEntry? existing,
  SharedEntryType? initialType,
  TimeOfDay? initialTime,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  var type = existing?.type ?? initialType ?? SharedEntryType.appointment;
  var date = existing?.date ?? initialDate;
  var start = existing?.start ?? initialTime;
  var end = existing?.end ??
      (start == null ? null : _timePlusMinutes(start, 60));

  final result = await showDialog<SharedEntry>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(
          existing == null ? 'Condividi qualcosa' : 'Modifica elemento',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(Icons.favorite_outline, size: 18),
                  label: Text('Visibilità: Noi ♡'),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<SharedEntryType>(
                segments: SharedEntryType.values
                    .map(
                      (value) => ButtonSegment(
                        value: value,
                        icon: Icon(value.icon),
                        label: Text(value.label),
                      ),
                    )
                    .toList(),
                selected: {type},
                onSelectionChanged: (value) =>
                    setLocal(() => type = value.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: title,
                autofocus: existing == null,
                decoration: const InputDecoration(labelText: 'Titolo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Nota'),
              ),
              const SizedBox(height: 8),
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
              if (type != SharedEntryType.note)
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
                        end ??= _timePlusMinutes(picked, 60);
                      });
                    }
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final value = title.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(
                dialogContext,
                SharedEntry(
                  id: existing?.id ?? const Uuid().v4(),
                  type: type,
                  title: value,
                  note: note.text.trim(),
                  date: date,
                  start: type == SharedEntryType.note ? null : start,
                  end: type == SharedEntryType.note ? null : end,
                  done: existing?.done ?? false,
                ),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    ),
  );

  title.dispose();
  note.dispose();
  return result;
}

class CloudAccountScreen extends StatefulWidget {
  final AgendaStore store;

  const CloudAccountScreen({
    super.key,
    required this.store,
  });

  @override
  State<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends State<CloudAccountScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool createMode = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _stateLabel(CloudConnectionState state) => switch (state) {
        CloudConnectionState.disabled => 'Cloud non configurato',
        CloudConnectionState.initializing => 'Connessione...',
        CloudConnectionState.signedOut => 'Non connesso',
        CloudConnectionState.syncing => 'Sincronizzazione...',
        CloudConnectionState.synced => 'Sincronizzato',
        CloudConnectionState.error => 'Errore di sincronizzazione',
      };

  IconData _stateIcon(CloudConnectionState state) => switch (state) {
        CloudConnectionState.disabled => Icons.cloud_off_outlined,
        CloudConnectionState.initializing => Icons.hourglass_top,
        CloudConnectionState.signedOut => Icons.cloud_outlined,
        CloudConnectionState.syncing => Icons.sync,
        CloudConnectionState.synced => Icons.cloud_done_outlined,
        CloudConnectionState.error => Icons.cloud_off,
      };

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _message('Inserisci email e una password di almeno 6 caratteri.');
      return;
    }

    setState(() => busy = true);
    try {
      final cloud = CloudSyncService.instance;
      if (createMode) {
        await cloud.signUp(email: email, password: password);
        if (!cloud.signedIn) {
          _message(
            'Account creato. Controlla la tua email per confermare l’accesso.',
          );
          return;
        }
      } else {
        await cloud.signIn(email: email, password: password);
      }

      await widget.store.activateCloudAccount(cloud.userId);
      await widget.store.syncAllCloud(preferRemoteOnFirstSync: true);
      _message('Account connesso e sincronizzato.');
    } catch (_) {
      _message(
        CloudSyncService.instance.lastError ??
            'Accesso non riuscito. Controlla i dati inseriti.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _message('Inserisci prima l’email del tuo account.');
      return;
    }

    setState(() => busy = true);
    try {
      await CloudSyncService.instance.requestPasswordReset(email);
      _message(
        'Se l’indirizzo è registrato, riceverai una mail per scegliere una nuova password.',
      );
    } catch (_) {
      _message(
        CloudSyncService.instance.lastError ??
            'Non è stato possibile inviare la mail di recupero.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => busy = true);
    try {
      await widget.store.syncAllCloud();
      final cloud = CloudSyncService.instance;
      if (cloud.state == CloudConnectionState.error) {
        _message(cloud.lastError ?? 'Sincronizzazione non riuscita.');
      } else if (widget.store.totalPendingCloudChanges > 0) {
        _message(
          'I dati locali sono al sicuro: '
          '${widget.store.totalPendingCloudChanges} modifiche restano in attesa di rete.',
        );
      } else {
        _message('Agenda completamente sincronizzata.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => busy = true);
    try {
      await widget.store.createLocalSnapshot(
        label: 'Prima della disconnessione account',
      );
      await CloudSyncService.instance.signOut();
      await widget.store.activateCloudAccount(null);
      _message(
        'Account disconnesso. I dati dell’account restano salvati sul dispositivo ma non sono più mostrati.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSyncService.instance;

    return AnimatedBuilder(
      animation: cloud,
      builder: (context, _) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Account e sincronizzazione',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.75),
                        Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _stateIcon(cloud.state),
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _stateLabel(cloud.state),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cloud.signedIn
                            ? 'La tua agenda personale può restare allineata su Android, iPhone e Web.'
                            : 'Accedi con lo stesso account sui tuoi dispositivi per ritrovare la stessa agenda personale.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (!cloud.configured)
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloud pronto, ma non ancora collegato',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Questa build non contiene ancora le credenziali del progetto Supabase. '
                          'L’app continua a funzionare completamente offline e nessun dato viene perso.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'La struttura di sincronizzazione e il database sono già predisposti anche per il futuro Spazio condiviso.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else if (!cloud.signedIn)
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          createMode ? 'Crea account' : 'Accedi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          autofillHints: createMode
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          onSubmitted: (_) => busy ? null : _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: Icon(
                              createMode
                                  ? Icons.person_add_outlined
                                  : Icons.login,
                            ),
                            label: Text(
                              createMode ? 'Crea account' : 'Accedi',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!createMode)
                          Center(
                            child: TextButton.icon(
                              onPressed: busy ? null : _forgotPassword,
                              icon: const Icon(Icons.lock_reset_outlined),
                              label: const Text('Password dimenticata?'),
                            ),
                          ),
                        Center(
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(
                                      () => createMode = !createMode,
                                    ),
                            child: Text(
                              createMode
                                  ? 'Ho già un account'
                                  : 'Crea un nuovo account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Il mio account',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(cloud.email ?? 'Account'),
                          subtitle: Text(
                            cloud.lastSyncAt == null
                                ? 'Nessuna sincronizzazione completata'
                                : 'Ultimo sync: ${DateFormat('d MMM, HH:mm', 'it_IT').format(cloud.lastSyncAt!)}',
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sync_outlined),
                          title: const Text('Modifiche in attesa'),
                          trailing: Text(
                            '${widget.store.totalPendingCloudChanges}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (widget.store.totalPendingCloudChanges > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${widget.store.pendingCloudChanges} private · '
                            '${widget.store.pendingSharedChangeCount} Noi ♡',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ||
                                    cloud.state ==
                                        CloudConnectionState.syncing
                                ? null
                                : _syncNow,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sincronizza ora'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _signOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Disconnetti account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SimpleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Come funziona',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• L’app continua a salvare prima di tutto sul dispositivo.\n'
                        '• Le modifiche vengono messe in coda anche senza Internet.\n'
                        '• Quando il cloud torna disponibile, vengono sincronizzati solo gli elementi cambiati.\n'
                        '• Agenda privata e Noi ♡ restano archivi separati, ma vengono riconciliati insieme quando torna la rete.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.people_outline),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Privato resta l’impostazione predefinita. Gli elementi Noi ♡ sono condivisi solo quando lo scegli esplicitamente.',
                              ),
                            ),
                          ],
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
    );
  }
}
