part of '../../main.dart';

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
      animation: Listenable.merge([
        store.agendaRevision,
        store.journalRevision,
        store.planningRevision,
        store.sharedRevision,
        store.inboxRevision,
        store.settingsRevision,
        store.backupRevision,
      ]),
      builder: (context, _) {
        final today = store.unifiedForDay(now);
        final upcoming = store.unifiedUpcoming(now);
        final briefing = store.dayHubSnapshot(now);
        final birthdayPreview = store.upcomingBirthdays(from: now, limit: 1);
        final nextBirthday =
            birthdayPreview.isEmpty ? null : birthdayPreview.first;
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
                tooltip: store.totalSharedUnreadCount > 0
                    ? 'Noi ♡ · ${store.totalSharedUnreadCount} novità'
                    : 'Noi ♡',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedSpaceHubScreen(store: store),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: store.totalSharedUnreadCount > 0,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  label: Text(
                    store.totalSharedUnreadCount > 99
                        ? '99+'
                        : '${store.totalSharedUnreadCount}',
                  ),
                  child: Icon(
                    store.totalSharedUnreadCount > 0
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: store.totalSharedUnreadCount > 0
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
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
              PrivateVaultHomeCard(store: store),
              const SizedBox(height: 12),
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
                briefing: briefing,
                nextBirthday: nextBirthday,
                globalPendingTasks: pendingTasks,
                inboxCount: store.inbox.length,
                hideDetails: store.preferences.hideHomeDetails,
                onOpenNext: upcoming.isEmpty
                    ? null
                    : () => openUnifiedAgendaEntry(
                          context,
                          store,
                          upcoming.first,
                        ),
                onOpenDay: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlannerScreen(
                      store: store,
                      initialDate: now,
                    ),
                  ),
                ),
                onOpenBirthdays: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BirthdaysScreen(store: store),
                  ),
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
              const SizedBox(height: 12),
              NavigationCard(
                icon: Icons.photo_library_outlined,
                title: 'I miei ricordi',
                subtitle: 'Note, foto e sketch del diario',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryMemoriesScreen(store: store),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NavigationCard(
                icon: Icons.people_outline,
                title: 'Persone importanti',
                subtitle: 'Relazioni, compleanni e ricordi collegati',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PeopleScreen(store: store),
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
              child: Icon(Icons.auto_stories_outlined),
            ),
            title: const Text('Diario di oggi'),
            subtitle: const Text('Aggiungi una nota, una foto o uno sketch.'),
            onTap: () => Navigator.pop(sheetContext, 'diary'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.mic_none_outlined),
            ),
            title: const Text('Nota vocale'),
            subtitle: const Text('Registra subito un audio nel diario di oggi.'),
            onTap: () => Navigator.pop(sheetContext, 'voice'),
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
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.cake_outlined),
            ),
            title: const Text('Compleanno'),
            subtitle: const Text('Salva una ricorrenza personale annuale.'),
            onTap: () => Navigator.pop(sheetContext, 'birthday'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_add_alt_1_outlined),
            ),
            title: const Text('Persona importante'),
            subtitle: const Text('Salva una relazione personale da ricordare.'),
            onTap: () => Navigator.pop(sheetContext, 'person'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == 'diary') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlannerScreen(
          store: store,
          initialDate: DateTime.now(),
        ),
      ),
    );
    return;
  }

  if (action == 'voice') {
    final capture = await captureVoiceClip(context);
    if (capture == null || !context.mounted) return;

    final caption = await showDiaryCaptionEditor(
      context,
      adding: true,
    );
    if (caption == null) return;

    final assetId = await MediaAssetStore.instance.put(capture.bytes);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final journal = store.journal(day);
    await store.saveJournal(
      day,
      journal.copyWith(
        blocks: [
          ...journal.blocks,
          DiaryBlock(
            id: const Uuid().v4(),
            type: DiaryBlockType.voice,
            createdAt: now,
            text: caption,
            mediaAssetId: assetId,
            audioDurationMs: capture.durationMs,
            audioMimeType: capture.mimeType,
          ),
        ],
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota vocale salvata nel diario di oggi.')),
      );
    }
    return;
  }

  if (action == 'birthday') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BirthdaysScreen(store: store),
      ),
    );
    return;
  }

  if (action == 'person') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeopleScreen(
          store: store,
          startAdding: true,
        ),
      ),
    );
    return;
  }

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
      animation: Listenable.merge([
        CloudSyncService.instance,
        store.syncRevision,
      ]),
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
        } else if (store.hasSharedSyncError) {
          icon = Icons.sync_problem_outlined;
          title = 'Noi ♡ da risincronizzare';
          subtitle = pending == 0
              ? 'L’ultima sincronizzazione condivisa non è riuscita. Riproverò automaticamente.'
              : '$pending modifiche restano al sicuro sul dispositivo e verranno ritentate.';
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
  final DayHubSnapshot briefing;
  final BirthdayOccurrence? nextBirthday;
  final int globalPendingTasks;
  final int inboxCount;
  final bool hideDetails;
  final VoidCallback? onOpenNext;
  final VoidCallback onOpenDay;
  final VoidCallback onOpenBirthdays;
  final VoidCallback onOpenInbox;

  const _HomeFocusCard({
    required this.next,
    required this.briefing,
    required this.nextBirthday,
    required this.globalPendingTasks,
    required this.inboxCount,
    required this.hideDetails,
    required this.onOpenNext,
    required this.onOpenDay,
    required this.onOpenBirthdays,
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

    String birthdayText;
    if (nextBirthday == null) {
      birthdayText = 'Nessun compleanno salvato';
    } else if (AgendaStore.sameDay(nextBirthday!.date, briefing.date)) {
      birthdayText = 'Oggi · ${nextBirthday!.birthday.name} 🎂';
    } else {
      birthdayText =
          '${DateFormat('d MMM', 'it_IT').format(nextBirthday!.date)} · '
          '${nextBirthday!.birthday.name}';
    }

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Oggi in breve',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
              TextButton(
                onPressed: onOpenDay,
                child: const Text('Apri giornata'),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpenBirthdays,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined, color: scheme.tertiary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      birthdayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.today_outlined,
                text: '${briefing.appointmentCount} impegni oggi',
              ),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: '${briefing.pendingTaskCount} da fare oggi',
              ),
              _MiniPill(
                icon: briefing.hasJournalContent
                    ? Icons.auto_stories
                    : Icons.auto_stories_outlined,
                text: briefing.hasJournalContent
                    ? 'Diario iniziato'
                    : 'Diario da iniziare',
              ),
              if (globalPendingTasks > briefing.pendingTaskCount)
                _MiniPill(
                  icon: Icons.task_alt_outlined,
                  text: '$globalPendingTasks task aperti',
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

  Future<void> _editTags(
    BuildContext context,
    InboxEntry entry,
  ) async {
    final tags = await showOrganizationTagsEditor(
      context,
      initialTags: entry.tags,
      suggestions: store.organizationTags,
    );
    if (tags == null) return;
    await store.setInboxTags(entry.id, tags);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.inboxRevision,
      builder: (context, _) {
        final entries = [...store.activeInboxEntries]
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
                          [
                            DateFormat(
                              'd MMM, HH:mm',
                              'it_IT',
                            ).format(entry.createdAt),
                            if (entry.tags.isNotEmpty)
                              entry.tags.map((tag) => '#$tag').join(' · '),
                          ].join(' · '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'pin') {
                              await store.toggleInboxPinned(entry.id);
                            } else if (value == 'tags') {
                              await _editTags(context, entry);
                            } else if (value == 'archive') {
                              await store.toggleInboxArchived(entry.id);
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
                              value: 'tags',
                              child: Text('Tag'),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Text('Archivia'),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlannerScreen(
              store: store,
              initialDate: date,
            ),
          ),
        ),
        child: Ink(
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
                    Text(
                      journal.blocks.isEmpty
                          ? 'Nessun ricordo'
                          : '${journal.blocks.length} ricordi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
          ),
        ),
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
    return AnimatedBuilder(
      animation: Listenable.merge([
        store.inboxRevision,
        store.journalRevision,
        store.planningRevision,
      ]),
      builder: (context, _) {
        final months = _months();
        final archivedInbox = [...store.archivedInboxEntries]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final archivedBlocks = <({DateTime date, DiaryBlock block})>[];
        for (final entry in store.journals.entries) {
          final date = DateTime.tryParse(entry.key);
          if (date == null) continue;
          for (final block in entry.value.blocks) {
            if (block.archived) {
              archivedBlocks.add((date: date, block: block));
            }
          }
        }
        archivedBlocks.sort(
          (a, b) => b.block.createdAt.compareTo(a.block.createdAt),
        );

        final empty = months.isEmpty &&
            archivedInbox.isEmpty &&
            archivedBlocks.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Archivio',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Cestino',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrashScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: empty
              ? const Center(child: Text('L’archivio è ancora vuoto.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
                  children: [
                    if (archivedInbox.isNotEmpty) ...[
                      const SectionTitle('Inbox archiviata'),
                      const SizedBox(height: 8),
                      ...archivedInbox.map(
                        (entry) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(entry.text),
                            subtitle: Text(
                              [
                                DateFormat('d MMM, HH:mm', 'it_IT')
                                    .format(entry.createdAt),
                                if (entry.tags.isNotEmpty)
                                  entry.tags.map((tag) => '#$tag').join(' · '),
                              ].join(' · '),
                            ),
                            trailing: IconButton(
                              tooltip: 'Ripristina in Inbox',
                              icon: const Icon(Icons.unarchive_outlined),
                              onPressed: () =>
                                  store.toggleInboxArchived(entry.id),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (archivedBlocks.isNotEmpty) ...[
                      const SectionTitle('Ricordi archiviati'),
                      const SizedBox(height: 8),
                      ...archivedBlocks.map(
                        (record) => Card(
                          child: ListTile(
                            leading: Icon(
                              switch (record.block.type) {
                                DiaryBlockType.note =>
                                  Icons.sticky_note_2_outlined,
                                DiaryBlockType.photo => Icons.photo_outlined,
                                DiaryBlockType.sketch => Icons.draw_outlined,
                                DiaryBlockType.voice => Icons.mic_none_outlined,
                              },
                            ),
                            title: Text(
                              record.block.text.trim().isEmpty
                                  ? switch (record.block.type) {
                                      DiaryBlockType.note => 'Nota',
                                      DiaryBlockType.photo => 'Foto',
                                      DiaryBlockType.sketch => 'Sketch',
                                      DiaryBlockType.voice => 'Nota vocale',
                                    }
                                  : record.block.text,
                            ),
                            subtitle: Text(
                              [
                                DateFormat('d MMMM yyyy', 'it_IT')
                                    .format(record.date),
                                if (record.block.tags.isNotEmpty)
                                  record.block.tags
                                      .map((tag) => '#$tag')
                                      .join(' · '),
                              ].join(' · '),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlannerScreen(
                                  store: store,
                                  initialDate: record.date,
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Ripristina nel diario',
                              icon: const Icon(Icons.unarchive_outlined),
                              onPressed: () => store.toggleDiaryArchived(
                                record.date,
                                record.block.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (months.isNotEmpty) ...[
                      const SectionTitle('Archivio per mese'),
                      const SizedBox(height: 8),
                      ...months.map((month) {
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Card(
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
                                  DateFormat('MMMM yyyy', 'it_IT')
                                      .format(month),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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
                          ),
                        );
                      }),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
