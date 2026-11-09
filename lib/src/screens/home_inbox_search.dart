part of '../../main.dart';

class MainShell extends StatefulWidget {
  final AgendaStore store;
  const MainShell({super.key, required this.store});

  // Five equal mobile slots: Today, Messages, raised Create, Memories, More.
  // The page stack and desktop rail still use the original four page indices.
  static int bottomBarSlotForPage(int pageIndex) {
    assert(pageIndex >= 0 && pageIndex < 4);
    return pageIndex >= 2 ? pageIndex + 1 : pageIndex;
  }

  static int? pageForBottomBarSlot(int slotIndex) {
    assert(slotIndex >= 0 && slotIndex < 5);
    if (slotIndex == 2) return null; // Raised Create owns the middle slot.
    return slotIndex > 2 ? slotIndex - 1 : slotIndex;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index;
  bool _createPressed = false;
  bool _createReleased = false;

  Future<void> _openCentralCreate() async {
    if (_createPressed) return;
    // Avoid keeping a focused previous screen under the canonical capture.
    FocusScope.of(context).unfocus();
    unawaited(AnnaFeedback.selection());
    setState(() => _createPressed = true);
    final animate = AnnaDesignTokens.animationsEnabled(context);
    if (animate) await Future<void>.delayed(const Duration(milliseconds: 135));
    if (!mounted) return;
    if (animate) {
      setState(() => _createReleased = true);
      await Future<void>.delayed(const Duration(milliseconds: 125));
      if (!mounted) return;
    }
    setState(() {
      _createPressed = false;
      _createReleased = false;
    });
    await showUnifiedCapture(
      context,
      widget.store,
      // The calendar is now a full-screen route with its own selected-day
      // +Crea entry. The shell button uses today on its other four destinations.
      initialDate: DateTime.now(),
      entryPoint: UnifiedCaptureEntryPoint.home,
    );
  }

  Widget _centralCreateButton(
    BuildContext context, {
    bool editorial = false,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    final animate = AnnaDesignTokens.animationsEnabled(context);
    return Semantics(
      identifier: 'main-nav-create',
      button: true,
      child: Tooltip(
        message: AnnaStrings.of(context).d3('ui5Create'),
        child: AnimatedScale(
          scale: _createPressed && !_createReleased && animate ? 0.93 : 1.0,
          duration: animate ? const Duration(milliseconds: 190) : Duration.zero,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: animate ? const Duration(milliseconds: 190) : Duration.zero,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: editorial ? AnnaEditorialColors.of(context).dock : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: _createReleased && animate ? 0.38 :
                        _createPressed && animate ? 0.28 : 0.16),
                  blurRadius: _createReleased && animate ? 29 :
                      _createPressed && animate ? 24 : 15,
                  spreadRadius: _createReleased && animate ? 6 :
                      _createPressed && animate ? 4 : 2,
                ),
              ],
            ),
            padding: editorial ? const EdgeInsets.all(5) : EdgeInsets.zero,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: scheme.onPrimary, size: 25),
                      Text(
                        AnnaStrings.of(context).d3('ui5Create'),
                        maxLines: 1,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 10,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
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
    // Preserve the persisted Calendar start preference without retaining
    // Calendar as a fifth primary tab: present the original Calendar route.
    final savedCalendar = widget.store.preferences.startTab ==
        StartTab.calendar;
    index = savedCalendar
        ? StartTab.today.index
        : widget.store.preferences.startTab.index;

    if (savedCalendar &&
        (!kIsWeb ||
            (Uri.base.queryParameters['today'] != '1' &&
             Uri.base.queryParameters['capture'] != '1'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CalendarHubScreen(store: widget.store),
          ),
        );
      });
    }

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
    // IndexedStack retains other pages: release their keyboard focus before
    // offstaging the old destination so IME cannot cover the selected page.
    FocusScope.of(context).unfocus();
    setState(() => index = value);
  }

  void _selectBottomDestination(int slotIndex) {
    final pageIndex = MainShell.pageForBottomBarSlot(slotIndex);
    if (pageIndex != null) _selectDestination(pageIndex);
  }

  // Module visibility is preserved even though Messages is a permanent tab.
  Widget _messagesPage() => AnimatedBuilder(
    animation: widget.store.settingsRevision,
    builder: (context, _) {
      if (widget.store.preferences.isModuleEnabled(AppModule.sharedSpace)) {
        return SharedSpaceHubScreen(store: widget.store);
      }
      final strings = AnnaStrings.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(strings.navMessages)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 36),
                const SizedBox(height: 12),
                Text(strings.d3('personalizationSharedSpaceSubtitle'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PersonalizationScreen(store: widget.store),
                    ),
                  ),
                  icon: const Icon(Icons.tune_outlined),
                  label: Text(strings.d3('personalizationTitle')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _pages() => <Widget>[
        PlannerScreen(
          store: widget.store,
          embedded: true,
          activeInShell: index == 0,
        ),
        _messagesPage(),
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
          semanticsId: 'main-nav-messages',
          label: strings.navMessages,
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
        ),
        // A real, equal-width slot keeps the four labels evenly spaced
        // around the raised Create control, without altering M3 styling.
        const NavigationDestination(
          key: ValueKey<String>('main-nav-create-space'),
          icon: SizedBox.shrink(),
          label: '',
          enabled: false,
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
            Icons.chat_bubble_outline,
            key: ValueKey<String>('main-rail-messages'),
          ),
          selectedIcon: const Icon(Icons.chat_bubble),
          label: Text(strings.navMessages),
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
                    trailing: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Semantics(
                        identifier: 'main-rail-create',
                        button: true,
                        child: IconButton.filled(
                          tooltip: strings.d3('ui5Create'),
                          onPressed: _openCentralCreate,
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ),
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
                child: AnnaMotionReveal(
                  token: index,
                  child: IndexedStack(index: index, children: pages),
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : ValueListenableBuilder<bool>(
                  valueListenable: AnnaEditorialTodayMode.enabled,
                  builder: (context, editorial, _) {
                    if (editorial) {
                      return SizedBox(
                        key: const ValueKey<String>('main-editorial-dock'),
                        height: 42 + AnnaEditorialDockBar.heightFor(context) +
                            MediaQuery.paddingOf(context).bottom,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              top: 24,
                              child: AnnaEditorialDockBar(
                                selectedPage: index,
                                onPageSelected: _selectDestination,
                                labels: [
                                  strings.navToday,
                                  strings.navMessages,
                                  strings.navMemories,
                                  strings.navMore,
                                ],
                                icons: const [
                                  Icons.today_outlined,
                                  Icons.chat_bubble_outline,
                                  Icons.photo_library_outlined,
                                  Icons.grid_view_outlined,
                                ],
                                selectedIcons: const [
                                  Icons.today,
                                  Icons.chat_bubble,
                                  Icons.photo_library,
                                  Icons.grid_view_rounded,
                                ],
                                semanticIds: const [
                                  'main-nav-today',
                                  'main-nav-messages',
                                  'main-nav-memories',
                                  'main-nav-more',
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _centralCreateButton(
                                  context, editorial: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox(
                      height: 96 + MediaQuery.paddingOf(context).bottom,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            top: 13,
                            child: NavigationBar(
                              selectedIndex: MainShell.bottomBarSlotForPage(index),
                              onDestinationSelected: _selectBottomDestination,
                              destinations: _bottomDestinations(strings),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(child: _centralCreateButton(context)),
                          ),
                        ],
                      ),
                    );
                  },
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

/// Index mapping for the approved 8/10 pinned header without altering
/// the canonical order or persistence of any Inbox entry.
int inboxPinnedListEntryIndex(int position, int pinnedCount, int total) {
  if (pinnedCount <= 0) return position;
  if (position == 0) return -1; // In evidenza
  if (pinnedCount < total && position == pinnedCount + 1) {
    return -2; // Altre note
  }
  return position - 1 -
      (pinnedCount < total && position > pinnedCount + 1 ? 1 : 0);
}

String approvedInboxSectionTitle(String language, bool pinned) {
  final captions = switch (language) {
    'en' => ('Pinned', 'Other notes'),
    'es' => ('Destacadas', 'Otras notas'),
    'fr' => ('À la une', 'Autres notes'),
    'pt' => ('Em destaque', 'Outras notas'),
    _ => ('In evidenza', 'Altre note'),
  };
  return pinned ? captions.$1 : captions.$2;
}

class InboxScreen extends StatefulWidget {
  final AgendaStore store;
  const InboxScreen({super.key, required this.store});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  AgendaStore get store => widget.store;

  Widget _noteCard({
    required bool editorial,
    required bool pinned,
    required Widget child,
  }) {
    if (!editorial) return Card(child: child);
    return AnnaEditorialSurface(
      tone: pinned
          ? AnnaEditorialSurfaceTone.featured
          : AnnaEditorialSurfaceTone.regular,
      padding: EdgeInsets.zero,
      child: child,
    );
  }
  String? selectedCategory;
  String _noteQuery = '';
  final TextEditingController _noteSearchController = TextEditingController();

  @override
  void dispose() {
    _noteSearchController.dispose();
    super.dispose();
  }

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

  Future<void> _convertToAppointment(
    BuildContext context,
    InboxEntry entry,
  ) async {
    // The draft uses the canonical editor but cannot modify an existing
    // appointment. Cancellation leaves the Inbox record untouched.
    final accountAtOpen = store.activeAccountId;
    final draft = AgendaItem(
      id: const Uuid().v4(),
      title: entry.text,
      note: '',
      date: DateTime.now(),
      type: ItemType.appointment,
      category: store.preferences.defaultCategory,
    );
    await openItemEditor(
      context,
      store,
      draft.date,
      duplicateOf: draft,
      onSaved: (saved) async {
        if (store.activeAccountId != accountAtOpen ||
            !store.entryScopeReady) {
          return;
        }
        final unchangedInbox = store.activeInboxEntries.any(
          (candidate) =>
              candidate.id == entry.id && candidate.text == entry.text,
        );
        if (!unchangedInbox) return;
        try {
          await store.deleteInboxEntry(entry.id);
        } catch (_) {
          // The appointment is already committed. Keep the Inbox source
          // instead of pretending conversion was atomic or deleting data.
          return;
        }
      },
    );
  }

  Future<void> _editTags(
    BuildContext context,
    InboxEntry entry, {
    String? preselectedTag,
  }) async {
    final guard = Cap0160TagEditGuard(store);
    if (!guard.isCurrent) return;
    final proposals = Cap0160TagSuggester.forInbox(
      store, entry, AnnaStrings.of(context).languageCode,
    );
    // The inline chip must still be a current authorized proposal, and only
    // seeds a dialog draft: the canonical store is unchanged until Save.
    if (preselectedTag != null &&
        !Cap0160TagSuggester.forInbox(
          store, entry, AnnaStrings.of(context).languageCode,
          inlineFastPath: true,
        ).any((item) => item.tag == preselectedTag)) {
      return;
    }
    final draftTags = preselectedTag == null
        ? entry.tags
        : normalizeOrganizationTags([...entry.tags, preselectedTag]);
    final tags = await showOrganizationTagsEditor(
      context,
      initialTags: draftTags,
      suggestions: store.inboxCategoryTags,
      offlineProposals: proposals,
    );
    if (tags == null || !guard.isCurrent ||
        !store.inbox.any((current) => current.id == entry.id &&
            !current.archived && current.text == entry.text &&
            listEquals(current.tags, entry.tags))) {
      return;
    }
    try {
      await store.setInboxTags(entry.id, tags, scopeGuard: guard);
    } on Cap0160ScopeChanged {
      // Fail closed if the profile changed while the queued write waited.
      return;
    }
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

  Future<void> _renameCategory(BuildContext context, String previous) async {
    final strings = AnnaStrings.of(context);
    final input = TextEditingController(text: previous);
    try {
      final renamed = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(inboxCategoryCopy(strings.languageCode, 'rename')),
          content: TextField(
            controller: input,
            autofocus: true,
            maxLength: 48,
            decoration: InputDecoration(labelText: strings.tags),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, input.text.trim()),
              child: Text(strings.save),
            ),
          ],
        ),
      );
      if (!mounted || renamed == null || renamed.isEmpty) return;
      await store.renameInboxTag(previous, renamed);
      if (!mounted) return;
      if (selectedCategory?.toLowerCase() == previous.toLowerCase()) {
        setState(() => selectedCategory = renamed);
      }
    } finally {
      input.dispose();
    }
  }

  Future<void> _manageCategories(BuildContext context) async {
    final strings = AnnaStrings.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(inboxCategoryCopy(strings.languageCode, 'heading')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final category in store.inboxCategoryTags)
                ListTile(
                  title: Text(category),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _renameCategory(context, category);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final strings = AnnaStrings.of(context);
    final input = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(inboxCategoryCopy(strings.languageCode, 'create')),
          content: TextField(
            key: const ValueKey<String>('inbox-category-name'),
            controller: input,
            autofocus: true,
            maxLength: 48,
            decoration: InputDecoration(labelText: strings.tags),
            onSubmitted: (value) =>
                Navigator.pop(dialogContext, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, input.text.trim()),
              child: Text(strings.save),
            ),
          ],
        ),
      );
      if (!mounted || name == null || name.isEmpty) return;
      try {
        await store.createInboxCategory(name);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(inboxCategoryCopy(strings.languageCode, 'failed'))),
        );
      }
    } finally {
      input.dispose();
    }
  }

  Future<void> _addTagToNote(BuildContext context) async {
    final strings = AnnaStrings.of(context);
    final notes = store.activeInboxEntries;
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(inboxCategoryCopy(strings.languageCode, 'empty')),
      ));
      return;
    }
    final note = await showModalBottomSheet<InboxEntry>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.54,
          child: Column(
            children: [
              ListTile(
                title: Text(inboxCategoryCopy(strings.languageCode, 'choose')),
                subtitle: Text(inboxCategoryCopy(strings.languageCode, 'hint')),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(notes[index].text, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(sheetContext, notes[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (note != null && mounted) await _editTags(this.context, note);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        store.inboxRevision,
        AnnaEditorialTodayMode.enabled,
      ]),
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final editorial = AnnaEditorialTodayMode.enabled.value;
        final entries = selectedCategory == null
            ? [...store.activeInboxEntries]
            : [...store.inboxEntriesInCategory(selectedCategory!)];
        // DS6: local, authorized Inbox title/tag filtering, no new index.
        // Classic does not expose the DS6 query field: never apply a hidden
        // filter while the reversible editorial style is disabled.
        final needle = editorial ? _noteQuery.trim().toLowerCase() : '';
        if (needle.isNotEmpty) {
          entries.removeWhere((entry) =>
              !entry.text.toLowerCase().contains(needle) &&
              !entry.tags.any((tag) => tag.toLowerCase().contains(needle)));
        }
        entries.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        final categories = store.inboxCategoryTags;
        final pinnedCount = entries.where((entry) => entry.pinned).length;
        final sectionHeaders = pinnedCount == 0
            ? 0
            : pinnedCount == entries.length ? 1 : 2;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.inbox,
              style: editorial
                  ? AnnaJournalTypography.editorial(context, size: 25)
                  : const TextStyle(fontWeight: FontWeight.w900),
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Preserve search/results on landscape while the IME is visible.
              // Collapse only nonessential header/category/shortcut controls.
              final keyboardVisible =
                  MediaQuery.viewInsetsOf(context).bottom > 0;
              final compact = constraints.maxHeight < 360 && keyboardVisible;
              return Column(
                children: [
              if (editorial && constraints.maxHeight >= 380 && !compact)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: AnnaEditorialHeader(
                    title: strings.inbox,
                    eyebrow: inboxCategoryCopy(
                      strings.languageCode, 'heading'),
                  ),
                ),
              if (!compact)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        inboxCategoryCopy(strings.languageCode, 'heading'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _manageCategories(context),
                      child: Text(inboxCategoryCopy(
                          strings.languageCode, 'manage')),
                    ),
                  ],
                ),
              ),
              if (!compact)
                SizedBox(
                  height: 46,
                  child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(inboxCategoryCopy(
                            strings.languageCode, 'all')),
                        selected: selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => selectedCategory = null),
                      ),
                    ),
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text('#$category'),
                          selected: selectedCategory?.toLowerCase() ==
                              category.toLowerCase(),
                          onSelected: (_) =>
                              setState(() => selectedCategory = category),
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(inboxCategoryCopy(
                          strings.languageCode, 'create')),
                      onPressed: () => _createCategory(context),
                    ),
                    const SizedBox(width: 7),
                    ActionChip(
                      avatar: const Icon(Icons.label_outline, size: 18),
                      label: Text(inboxCategoryCopy(
                          strings.languageCode, 'choose')),
                      onPressed: () => _addTagToNote(context),
                    ),
                  ],
                ),
              ),
              if (editorial)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 3, 14, 8),
                  child: TextField(
                    key: const ValueKey<String>('ds6-inbox-search'),
                    controller: _noteSearchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: strings.search,
                      suffixIcon: needle.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey<String>('ds6-inbox-search-clear'),
                              tooltip: strings.v100ClearSearch,
                              onPressed: () {
                                _noteSearchController.clear();
                                setState(() => _noteQuery = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setState(() => _noteQuery = value),
                  ),
                ),
              // DS6 keeps archive/trash in their canonical screens, reachable
              // directly from Inbox, rather than projecting a second archive.
              if (editorial && !compact)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 7),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.archive_outlined, size: 18),
                        label: Text(strings.archive),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ArchiveScreen(store: store),
                          ),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.delete_outline, size: 18),
                        label: Text(strings.trash),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TrashScreen(store: store),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      needle.isNotEmpty || selectedCategory != null
                          ? strings.v100NoResults
                          : strings.inboxEmpty,
                      key: const ValueKey<String>('ds6-inbox-empty-state'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                  itemCount: entries.length + sectionHeaders,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entryIndex = inboxPinnedListEntryIndex(
                      index, pinnedCount, entries.length);
                    if (entryIndex < 0) {
                      return Padding(
                        key: ValueKey(entryIndex == -1
                            ? 'inbox-section-pinned'
                            : 'inbox-section-other'),
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                        child: Text(
                          approvedInboxSectionTitle(
                            strings.languageCode, entryIndex == -1),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      );
                    }
                    final entry = entries[entryIndex];
                    final proposals = Cap0160TagSuggester.forInbox(
                      store, entry, strings.languageCode,
                      inlineFastPath: true,
                    );
                    return _noteCard(
                      editorial: editorial,
                      pinned: entry.pinned,
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
                        title: Text(
                          entry.text,
                          style: editorial
                              ? AnnaJournalTypography.editorial(
                                  context, size: entry.pinned ? 21 : 18,
                                )
                              : null,
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text([
                              DateFormat(
                                'd MMM, HH:mm',
                                AnnaStrings.intlLocale(context),
                              ).format(entry.createdAt),
                              if (entry.tags.isNotEmpty)
                                entry.tags.map((tag) => '#$tag').join(' · '),
                            ].join(' · ')),
                            if (proposals.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Cap0160InlineTagSuggestions(
                                proposals: proposals,
                                languageCode: strings.languageCode,
                                onSelected: (tag) =>
                                    _editTags(context, entry, preselectedTag: tag),
                              ),
                            ],
                          ],
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
                            } else if (value == 'event') {
                              await _convertToAppointment(context, entry);
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
                              value: 'event',
                              child: Text(quickWins2Copy(
                                  strings.languageCode, 'inboxEvent')),
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
              ),
                ],
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

