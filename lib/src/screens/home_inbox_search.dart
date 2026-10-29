part of '../../main.dart';

class MainShell extends StatefulWidget {
  final AgendaStore store;
  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index;
  DateTime _calendarCaptureDate = DateTime.now();
  bool _createPressed = false;

  Future<void> _openCentralCreate() async {
    if (_createPressed) return;
    unawaited(AnnaFeedback.selection());
    setState(() => _createPressed = true);
    final animate = AnnaDesignTokens.animationsEnabled(context);
    if (animate) await Future<void>.delayed(const Duration(milliseconds: 135));
    if (!mounted) return;
    setState(() => _createPressed = false);
    await showUnifiedCapture(
      context,
      widget.store,
      initialDate: index == StartTab.calendar.index
          ? _calendarCaptureDate
          : DateTime.now(),
      entryPoint: index == StartTab.calendar.index
          ? UnifiedCaptureEntryPoint.month
          : UnifiedCaptureEntryPoint.home,
    );
  }

  Widget _centralCreateButton(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    final animate = AnnaDesignTokens.animationsEnabled(context);
    return Semantics(
      identifier: 'main-nav-create',
      button: true,
      child: Tooltip(
        message: AnnaStrings.of(context).capture,
        child: AnimatedScale(
          scale: _createPressed && animate ? 0.93 : 1.0,
          duration: animate ? const Duration(milliseconds: 190) : Duration.zero,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: animate ? const Duration(milliseconds: 190) : Duration.zero,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: _createPressed ? 0.30 : 0.16),
                  blurRadius: _createPressed ? 26 : 15,
                  spreadRadius: _createPressed ? 5 : 2,
                ),
              ],
            ),
            child: Material(
              color: color,
              shape: const CircleBorder(),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey<String>('main-nav-create'),
                onTap: _openCentralCreate,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Icon(Icons.add, color: scheme.onPrimary, size: 31),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    index = widget.store.preferences.startTab.index;

    if (kIsWeb) {
      final query = Uri.base.queryParameters;
      if (query['today'] == '1') {
        index = StartTab.today.index;
      }
      if (query['capture'] == '1') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            _showQuickCapture(
              context,
              widget.store,
              entryPoint: UnifiedCaptureEntryPoint.external,
            ),
          );
        });
      }
    }
  }

  void _selectDestination(int value) {
    if (value == index) return;
    setState(() => index = value);
  }

  List<Widget> _pages() => <Widget>[
        PlannerScreen(store: widget.store, embedded: true),
        CalendarHubScreen(
          store: widget.store,
          onSelectedDateChanged: (date) => _calendarCaptureDate = date,
        ),
        DiaryMemoriesScreen(store: widget.store),
        MoreScreen(store: widget.store),
      ];

  Widget _bottomDestination({
    required String semanticsId,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) =>
      Semantics(
        identifier: semanticsId,
        container: true,
        child: NavigationDestination(
          key: ValueKey<String>(semanticsId),
          icon: Icon(icon),
          selectedIcon: Icon(selectedIcon),
          label: label,
        ),
      );

  List<Widget> _bottomDestinations(AnnaStrings strings) => <Widget>[
        _bottomDestination(
          semanticsId: 'main-nav-today',
          label: strings.navToday,
          icon: Icons.today_outlined,
          selectedIcon: Icons.today,
        ),
        _bottomDestination(
          semanticsId: 'main-nav-calendar',
          label: strings.navCalendar,
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
        ),
        _bottomDestination(
          semanticsId: 'main-nav-memories',
          label: strings.navMemories,
          icon: Icons.photo_library_outlined,
          selectedIcon: Icons.photo_library,
        ),
        _bottomDestination(
          semanticsId: 'main-nav-more',
          label: strings.navMore,
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
        ),
      ];

  List<NavigationRailDestination> _railDestinations(AnnaStrings strings) =>
      <NavigationRailDestination>[
        NavigationRailDestination(
          icon: const Icon(
            Icons.today_outlined,
            key: ValueKey<String>('main-rail-today'),
          ),
          selectedIcon: const Icon(Icons.today),
          label: Text(strings.navToday),
        ),
        NavigationRailDestination(
          icon: const Icon(
            Icons.calendar_month_outlined,
            key: ValueKey<String>('main-rail-calendar'),
          ),
          selectedIcon: const Icon(Icons.calendar_month),
          label: Text(strings.navCalendar),
        ),
        NavigationRailDestination(
          icon: const Icon(
            Icons.photo_library_outlined,
            key: ValueKey<String>('main-rail-memories'),
          ),
          selectedIcon: const Icon(Icons.photo_library),
          label: Text(strings.navMemories),
        ),
        NavigationRailDestination(
          icon: const Icon(
            Icons.grid_view_outlined,
            key: ValueKey<String>('main-rail-more'),
          ),
          selectedIcon: const Icon(Icons.grid_view_rounded),
          label: Text(strings.navMore),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final pages = _pages();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail =
            AnnaResponsiveShellPolicy.useRail(constraints.maxWidth);
        final extended =
            AnnaResponsiveShellPolicy.extendRail(constraints.maxWidth);
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: Row(
            children: [
              Offstage(
                offstage: !useRail,
                child: SafeArea(
                  child: NavigationRail(
                    key: const ValueKey<String>('main-navigation-rail'),
                    selectedIndex: index,
                    onDestinationSelected: _selectDestination,
                    extended: extended,
                    labelType:
                        extended ? null : NavigationRailLabelType.all,
                    minWidth: 76,
                    minExtendedWidth: 220,
                    backgroundColor: scheme.surface,
                    indicatorColor:
                        Theme.of(context).navigationBarTheme.indicatorColor ??
                            scheme.primaryContainer,
                    destinations: _railDestinations(strings),
                  ),
                ),
              ),
              SizedBox(
                width: useRail ? 1 : 0,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              Expanded(
                key: const ValueKey<String>('main-shell-content'),
                child: IndexedStack(index: index, children: pages),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : SizedBox(
                  height: 96 + MediaQuery.paddingOf(context).bottom,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        top: 13,
                        child: NavigationBar(
                          selectedIndex: index,
                          onDestinationSelected: _selectDestination,
                          destinations: _bottomDestinations(strings),
                        ),
                      ),
                      Positioned(
                        top: -14,
                        left: 0,
                        right: 0,
                        child: Center(child: _centralCreateButton(context)),
                      ),
                    ],
                  ),
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
                  ? AnnaStrings.of(context).v100SharedPhotoTitle
                  : AnnaStrings.of(context).v100SharedContentTitle,
            ),
            subtitle: preview.isEmpty
                ? Text(AnnaStrings.of(context).v100ChooseDestination)
                : Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (!capture.hasImage)
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(AnnaStrings.of(context).v100SaveInbox),
              subtitle: Text(AnnaStrings.of(context).v100OrganizeLater),
              onTap: () => Navigator.pop(sheetContext, 'inbox'),
            ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: Text(AnnaStrings.of(context).v100SaveTodayDiary),
            subtitle: Text(
              capture.hasImage
                  ? AnnaStrings.of(context).v100SharedPhotoDiaryDescription
                  : AnnaStrings.of(context).v100SharedTextDiaryDescription,
            ),
            onTap: () => Navigator.pop(sheetContext, 'diary'),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(AnnaStrings.of(context).cancel),
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
          SnackBar(content: Text(AnnaStrings.of(context).v100SharedSavedInbox)),
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
        SnackBar(content: Text(AnnaStrings.of(context).v100SharedSavedDiary)),
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
        SnackBar(content: Text(AnnaStrings.of(context).v100SharedPhotoReadFailed)),
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
      SnackBar(content: Text(AnnaStrings.of(context).v100SharedPhotoSaved)),
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

class _SyncAttentionCard extends StatelessWidget {
  final AgendaStore store;

  const _SyncAttentionCard({required this.store});

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
        final sharedError = store.hasSharedSyncError;

        final intentionalLocalOnly = store.activeAccountId == null &&
            !cloud.signedIn &&
            pending == 0 &&
            !sharedError;
        final healthyCloud = cloud.signedIn &&
            cloud.state == CloudConnectionState.synced &&
            pending == 0 &&
            !sharedError;

        if (intentionalLocalOnly || healthyCloud) {
          return const SizedBox.shrink();
        }

        IconData icon;
        String title;
        String subtitle;

        if (!cloud.configured) {
          icon = Icons.cloud_off_outlined;
          title = AnnaStrings.of(context).v100DeviceOnly;
          subtitle = AnnaStrings.of(context).v100CloudNotConfigured;
        } else if (!cloud.signedIn) {
          icon = Icons.cloud_outlined;
          title = AnnaStrings.of(context).v100CloudDisconnected;
          subtitle = AnnaStrings.of(context).v100OfflineStillWorks;
        } else if (cloud.state == CloudConnectionState.syncing ||
            cloud.state == CloudConnectionState.initializing) {
          icon = Icons.sync;
          title = AnnaStrings.of(context).v100Syncing;
          subtitle = pending == 0
              ? AnnaStrings.of(context).v100CheckingChanges
              : AnnaStrings.of(context).v100PendingSafeQueue(pending);
        } else if (cloud.state == CloudConnectionState.error) {
          icon = Icons.cloud_off_outlined;
          title = pending == 0
              ? AnnaStrings.of(context).v100CloudTemporarilyUnavailable
              : AnnaStrings.of(context).v100OfflineDataSafe;
          subtitle = pending == 0
              ? AnnaStrings.of(context).v100RetrySyncLater
              : AnnaStrings.of(context).v100PendingWhenOnline(pending);
        } else if (sharedError) {
          icon = Icons.sync_problem_outlined;
          title = AnnaStrings.of(context).v100NoiNeedsResync;
          subtitle = pending == 0
              ? AnnaStrings.of(context).v100SharedSyncRetry
              : AnnaStrings.of(context).v100PendingLocalRetry(pending);
        } else if (pending > 0) {
          icon = Icons.cloud_upload_outlined;
          title = AnnaStrings.of(context).v100PendingChanges(pending);
          subtitle = AnnaStrings.of(context).v100PendingStayLocal;
        } else {
          icon = Icons.cloud_outlined;
          title = AnnaStrings.of(context).v100CloudDisconnected;
          subtitle = AnnaStrings.of(context).v100OfflineStillWorks;
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Material(
            key: const ValueKey<String>('sync-attention'),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
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
          ),
        );
      },
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
    final text = store.notesBridgeTextForInbox(
      entry,
      strings: AnnaStrings.of(context),
    );
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
        final allEntries = widget.store.lifeArchiveEntries(strings: strings);
        final entries = widget.store.lifeArchiveEntries(
          query: searchController.text,
          kind: filter,
          strings: strings,
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

