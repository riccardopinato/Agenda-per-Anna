part of '../../main.dart';

const _homePastelForeground = Color(0xFF35282D);
const _homePastelSecondary = Color(0xFF67545D);

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
    final strings = AnnaStrings.of(context);
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: strings.navMonth,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week_outlined),
            selectedIcon: const Icon(Icons.view_week),
            label: strings.navWeek,
          ),
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: strings.navToday,
          ),
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
    final strings = AnnaStrings.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        store.agendaRevision,
        store.journalRevision,
        store.planningRevision,
        store.sharedRevision,
        store.inboxRevision,
        store.shoppingRevision,
        store.workoutRevision,
        store.settingsRevision,
        store.backupRevision,
        ExternalCalendarService.instance,
      ]),
      builder: (context, _) {
        unawaited(HomeWidgetBridge.instance.sync(store));
        final upcoming = store.unifiedUpcoming(now);
        final briefing = store.dayHubSnapshot(now);
        final birthdayPreview = store.upcomingBirthdays(from: now, limit: 1);
        final nextBirthday =
            birthdayPreview.isEmpty ? null : birthdayPreview.first;
        final pendingTasks = store.pendingUnifiedTaskCount;
        final displayName = store.preferences.displayName.trim();
        final pinnedItems =
            store.agendaContentFilter == AgendaContentFilter.sharedOnly
                ? <AgendaItem>[]
                : store.items.where((e) => e.pinned).toList();
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(context, store),
            icon: const Icon(Icons.add),
            label: Text(strings.add),
          ),
          appBar: AppBar(
            title: Text(
              displayName.isEmpty ? strings.myAgenda : strings.agendaFor(displayName),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: strings.search,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalSearchConnectionsScreen(store: store),
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
                tooltip: strings.archive,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArchiveScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
              IconButton(
                tooltip: strings.backup,
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
                tooltip: strings.cloud,
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
                tooltip: strings.settings,
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
                      _cap(
                        DateFormat(
                          'EEEE d MMMM',
                          AnnaStrings.intlLocale(context),
                        ).format(now),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _homePastelForeground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.preferences.showDailyQuote
                          ? _dailyQuote(now).$1
                          : strings.hello(displayName),
                      style: const TextStyle(
                        color: _homePastelForeground,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.preferences.showDailyQuote
                          ? _dailyQuote(now).$2
                          : strings.todayPage,
                      style: const TextStyle(
                        color: _homePastelSecondary,
                      ),
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
              _DayLifeOverviewCard(
                snapshot: briefing,
                hideDetails: store.preferences.hideHomeDetails,
                onOpenDay: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlannerScreen(
                      store: store,
                      initialDate: now,
                    ),
                  ),
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
                icon: Icons.shopping_cart_outlined,
                title: 'Lista della spesa',
                subtitle: store.activeShoppingItems.isEmpty
                    ? 'Privata o condivisa in Noi ♡'
                    : '${store.activeShoppingItems.length} da comprare · privata o Noi ♡',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShoppingListScreen(store: store),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NavigationCard(
                icon: Icons.sports_outlined,
                title: 'Allenamento',
                subtitle: store.workoutSessions.isEmpty
                    ? 'Sessioni multisport e schede'
                    : '${store.workoutSessions.length} sessioni · ${store.workoutPlans.length} schede',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutScreen(store: store),
                  ),
                ),
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
              const SizedBox(height: 12),
              NavigationCard(
                icon: Icons.hub_outlined,
                title: strings.lifeEcosystemTitle,
                subtitle: strings.lifeEcosystemSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LifeEcosystemScreen(store: store),
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

Future<void> _handleIncomingShareCapture(
  BuildContext context,
  AgendaStore store,
  IncomingShareCapture capture,
) async {
  final preview = capture.text.trim();
  final destination = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Icon(
                capture.hasImage
                    ? Icons.photo_outlined
                    : Icons.ios_share_outlined,
              ),
            ),
            title: Text(
              capture.hasImage
                  ? 'Foto condivisa con Anna\'s Diary'
                  : 'Contenuto condiviso con Anna\'s Diary',
            ),
            subtitle: preview.isEmpty
                ? const Text('Scegli dove salvarlo.')
                : Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (!capture.hasImage)
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Salva in Inbox'),
              subtitle: const Text('Da organizzare in un secondo momento.'),
              onTap: () => Navigator.pop(sheetContext, 'inbox'),
            ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Salva nel diario di oggi'),
            subtitle: Text(
              capture.hasImage
                  ? 'Importa la foto come ricordo del giorno.'
                  : 'Crea una normale nota del diario.',
            ),
            onTap: () => Navigator.pop(sheetContext, 'diary'),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Annulla'),
            onTap: () => Navigator.pop(sheetContext, 'cancel'),
          ),
        ],
      ),
    ),
  );

  if (destination == null || destination == 'cancel') {
    if (capture.hasImage) {
      await ShareCaptureService.instance.discardImage(capture.imageToken);
    }
    return;
  }

  if (!context.mounted) {
    if (capture.hasImage) {
      await ShareCaptureService.instance.discardImage(capture.imageToken);
    }
    return;
  }

  final day = _normalizeUnifiedCaptureDay(DateTime.now());

  if (destination == 'inbox') {
    if (preview.isNotEmpty) {
      await _saveUnifiedCaptureText(
        store,
        day,
        preview,
        toInbox: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenuto condiviso salvato in Inbox.')),
        );
      }
    }
    return;
  }

  if (!capture.hasImage) {
    final text = await showDiaryNoteEditor(
      context,
      initialText: preview,
    );
    if (text == null || text.trim().isEmpty) return;
    await _saveUnifiedCaptureText(store, day, text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contenuto aggiunto al diario di oggi.')),
      );
    }
    return;
  }

  final rawBytes = await ShareCaptureService.instance.consumeImageBytes(
    capture.imageToken,
  );
  if (rawBytes == null || rawBytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non riesco a leggere la foto condivisa.')),
      );
    }
    return;
  }

  final imageBytes = await _compressDiaryImageBytes(rawBytes);
  if (!context.mounted) return;
  final caption = await showDiaryCaptionEditor(
    context,
    initialText: preview,
    adding: true,
  );
  if (caption == null) return;

  await _saveUnifiedCapturePhoto(
    store,
    day,
    imageBytes,
    caption: caption,
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto condivisa salvata nel diario di oggi.')),
    );
  }
}

Future<void> _showQuickCapture(
  BuildContext context,
  AgendaStore store, {
  DateTime? captureDate,
  UnifiedCaptureEntryPoint entryPoint = UnifiedCaptureEntryPoint.home,
}) {
  return showUnifiedCapture(
    context,
    store,
    initialDate: captureDate,
    entryPoint: entryPoint,
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
      SnackBar(content: Text(AnnaStrings.of(context).noteConvertedTask)),
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

  Future<void> _copyToNotes(
    BuildContext context,
    InboxEntry entry,
  ) async {
    final text = store.notesBridgeTextForInbox(entry);
    await copyNotesBridgePayload(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.inboxRevision,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final entries = [...store.activeInboxEntries]
          ..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.inbox,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(
              context,
              store,
              entryPoint: UnifiedCaptureEntryPoint.inbox,
            ),
            icon: const Icon(Icons.add),
            label: Text(strings.capture),
          ),
          body: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      strings.inboxEmpty,
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
                              AnnaStrings.intlLocale(context),
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
                            } else if (value == 'notes') {
                              await _copyToNotes(context, entry);
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
                                entry.pinned ? strings.unpin : strings.pin,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'tags',
                              child: Text(strings.tags),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Text(strings.archiveAction),
                            ),
                            PopupMenuItem(
                              value: 'notes',
                              child: Text(strings.copyForNotes),
                            ),
                            PopupMenuItem(
                              value: 'task',
                              child: Text(strings.convertToTask),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(strings.delete),
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
              style: const TextStyle(
                color: _homePastelForeground,
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
                      ? 'Come sta andando la giornata?'
                      : 'Oggi: ${journal.mood!.label}',
                  style: const TextStyle(
                    color: _homePastelForeground,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _homePastelSecondary,
                          ),
                    ),
                    Text(
                      '$gratitudeCount/3 cose belle',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _homePastelSecondary,
                          ),
                    ),
                    Text(
                      journal.blocks.isEmpty
                          ? 'Nessun ricordo'
                          : '${journal.blocks.length} ricordi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _homePastelSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: _homePastelForeground,
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

class ArchiveScreen extends StatefulWidget {
  final AgendaStore store;

  const ArchiveScreen({super.key, required this.store});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController searchController = TextEditingController();
  LifeArchiveKind? filter;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DateTime> _months() {
    final keys = <String>{};

    for (final item in widget.store.items) {
      keys.add(AgendaStore.monthKey(item.date.year, item.date.month));
    }
    for (final key in widget.store.journals.keys) {
      if (key.length >= 7) keys.add(key.substring(0, 7));
    }
    for (final session in widget.store.workoutSessions) {
      keys.add(AgendaStore.monthKey(session.date.year, session.date.month));
    }
    keys.addAll(widget.store.months.keys);

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

  Map<int, List<LifeArchiveEntry>> _groupByYear(
    List<LifeArchiveEntry> entries,
  ) {
    final result = <int, List<LifeArchiveEntry>>{};
    for (final entry in entries) {
      result.putIfAbsent(entry.date.year, () => []).add(entry);
    }
    return result;
  }

  Future<void> _openEntry(LifeArchiveEntry entry) async {
    switch (entry.kind) {
      case LifeArchiveKind.diary:
        final reference = entry.diaryReference;
        if (reference == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlannerScreen(
              store: widget.store,
              initialDate: reference.date,
            ),
          ),
        );
        break;
      case LifeArchiveKind.agenda:
        final item = entry.agendaItem;
        if (item == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlannerScreen(
              store: widget.store,
              initialDate: item.date,
            ),
          ),
        );
        break;
      case LifeArchiveKind.workout:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutScreen(store: widget.store),
          ),
        );
        break;
      case LifeArchiveKind.inbox:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InboxScreen(store: widget.store),
          ),
        );
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _restoreEntry(LifeArchiveEntry entry) async {
    if (!entry.archived) return;
    switch (entry.kind) {
      case LifeArchiveKind.diary:
        final reference = entry.diaryReference;
        if (reference == null) return;
        await widget.store.toggleDiaryArchived(
          reference.date,
          reference.block.id,
        );
        break;
      case LifeArchiveKind.inbox:
        final inbox = entry.inboxEntry;
        if (inbox == null) return;
        await widget.store.toggleInboxArchived(inbox.id);
        break;
      case LifeArchiveKind.agenda:
      case LifeArchiveKind.workout:
        return;
    }
    if (mounted) setState(() {});
  }

  Widget _summaryCard(
    BuildContext context,
    List<LifeArchiveEntry> entries,
  ) {
    final strings = AnnaStrings.of(context);
    final years = entries.map((entry) => entry.date.year).toSet().length;
    int count(LifeArchiveKind kind) =>
        entries.where((entry) => entry.kind == kind).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.storyOnePlace,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entries.isEmpty
                ? strings.storyArchiveEmptyDescription
                : strings.momentsYears(entries.length, years),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: LifeArchiveKind.values.map((kind) {
                final total = count(kind);
                if (total == 0) return const SizedBox.shrink();
                return Chip(
                  avatar: Icon(kind.icon, size: 17),
                  label: Text('${strings.archiveKind(kind)} · $total'),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _entryTile(
    BuildContext context,
    LifeArchiveEntry entry,
  ) {
    final strings = AnnaStrings.of(context);
    final dateText = DateFormat(
      'd MMMM yyyy',
      AnnaStrings.intlLocale(context),
    ).format(entry.date);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        leading: CircleAvatar(
          child: Icon(entry.kind.icon, size: 20),
        ),
        title: Text(
          entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            dateText,
            if (entry.subtitle.trim().isNotEmpty) entry.subtitle.trim(),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _openEntry(entry),
        trailing: entry.archived &&
                (entry.kind == LifeArchiveKind.diary ||
                    entry.kind == LifeArchiveKind.inbox)
            ? IconButton(
                tooltip: entry.kind == LifeArchiveKind.diary
                    ? strings.restoreToDiary
                    : strings.restoreToInbox,
                onPressed: () => _restoreEntry(entry),
                icon: const Icon(Icons.unarchive_outlined),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _monthArchive(
    BuildContext context,
    List<DateTime> months,
  ) {
    if (months.isEmpty) return const SizedBox.shrink();
    final strings = AnnaStrings.of(context);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(
        strings.exploreByMonth,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(strings.monthsWithContent(months.length)),
      children: months.map((month) {
        final data = widget.store.month(month.year, month.month);
        final events = widget.store.items
            .where(
              (item) =>
                  item.date.year == month.year &&
                  item.date.month == month.month,
            )
            .length;
        final prefix =
            '${month.year}-${month.month.toString().padLeft(2, '0')}-';
        final journalDays =
            widget.store.journals.keys.where((key) => key.startsWith(prefix)).length;
        final workouts = widget.store.workoutSessions
            .where(
              (session) =>
                  session.date.year == month.year &&
                  session.date.month == month.month,
            )
            .length;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            _cap(
              DateFormat(
                'MMMM yyyy',
                AnnaStrings.intlLocale(context),
              ).format(month),
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            [
              if (events > 0) strings.commitmentsCount(events),
              if (journalDays > 0) strings.journalDaysCount(journalDays),
              if (workouts > 0) strings.workoutsCount(workouts),
              if (data.goals.isNotEmpty)
                strings.goalsCount(data.goals.length),
            ].join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MonthScreen(
                store: widget.store,
                initialMonth: month,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.store.agendaRevision,
        widget.store.inboxRevision,
        widget.store.journalRevision,
        widget.store.planningRevision,
        widget.store.workoutRevision,
      ]),
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final allEntries = widget.store.lifeArchiveEntries();
        final entries = widget.store.lifeArchiveEntries(
          query: searchController.text,
          kind: filter,
        );
        final years = _groupByYear(entries);
        final months = _months();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.lifeArchive,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: strings.trash,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrashScreen(store: widget.store),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
            children: [
              _summaryCard(context, allEntries),
              const SizedBox(height: 12),
              SearchBar(
                controller: searchController,
                hintText: strings.searchWholeStory,
                leading: const Icon(Icons.search),
                trailing: searchController.text.isEmpty
                    ? null
                    : [
                        IconButton(
                          tooltip: strings.clearSearch,
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: FilterChip(
                        selected: filter == null,
                        label: Text(strings.all),
                        avatar: const Icon(Icons.layers_outlined),
                        onSelected: (_) => setState(() => filter = null),
                      ),
                    ),
                    ...LifeArchiveKind.values.map(
                      (kind) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: FilterChip(
                          selected: filter == kind,
                          avatar: Icon(kind.icon),
                          label: Text(strings.archiveKind(kind)),
                          onSelected: (_) => setState(() => filter = kind),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    searchController.text.trim().isEmpty && filter == null
                        ? strings.archiveStillEmpty
                        : strings.noMomentMatches,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...years.entries.expand(
                  (group) => [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
                      child: Text(
                        '${group.key}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    ...group.value.map(
                      (entry) => _entryTile(context, entry),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              _monthArchive(context, months),
            ],
          ),
        );
      },
    );
  }
}

