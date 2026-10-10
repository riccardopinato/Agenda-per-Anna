part of '../../main.dart';

class BackupScreen extends StatefulWidget {
  final AgendaStore store;

  const BackupScreen({super.key, required this.store});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;
  DataSafetyReport? safetyReport;

  String _timestampFileName(String extension) {
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    return 'Annas-Diary_backup_$stamp.$extension';
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _exportBackup() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      final bytes = await widget.store.createBackupZip();
      widget.store.verifyBackupZip(bytes);
      final ok = await BackupFileService.instance.saveZipBackup(
        bytes: bytes,
        fileName: _timestampFileName('zip'),
        dialogTitle: strings.d3('backup_saveBackupDialog'),
      );
      _message(
        ok
            ? strings.v100BackupSaved
            : strings.v100ExportCancelled,
      );
    } catch (error) {
      _message(
        error is FormatException
            ? strings.d3BackupError(error.message.toString())
            : strings.v100BackupCreateFailed,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _exportOpenArchive() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      final bytes = await widget.store.createOpenExportZip(strings: strings);
      final ok = await BackupFileService.instance.saveOpenExportZip(
        bytes: bytes,
        fileName: _timestampFileName('zip').replaceFirst(
          'backup_',
          'open-export_',
        ),
        dialogTitle: strings.d3('backup_openExportDialog'),
      );
      _message(
        ok
            ? strings.v100OpenExportSaved
            : strings.v100OpenExportCancelled,
      );
    } catch (error) {
      _message(
        error is FormatException
            ? strings.d3BackupError(error.message.toString())
            : strings.v100OpenExportFailed,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _runSafetyAudit() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      final report = await widget.store.auditDataSafety();
      if (!mounted) return;
      setState(() => safetyReport = report);
      _message(
        report.integrityHealthy
            ? report.hasCleanupCandidates
                ? strings.v100IntegrityOrphans(report.orphanMediaIds.length)
                : strings.v100IntegrityClean
            : strings.v100IntegrityNeedsReview,
      );
    } catch (_) {
      _message(strings.v100IntegrityFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _exportReadable() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      final ok = await BackupFileService.instance.saveTextExport(
        text: widget.store.createReadableExport(strings: strings),
        fileName: _timestampFileName('txt'),
        dialogTitle: strings.d3('backup_readableExportDialog'),
      );
      _message(
        ok
            ? strings.v100ReadableExportSaved
            : strings.v100OpenExportCancelled,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _importBackup() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    PickedBackupFile? picked;
    try {
      picked = await BackupFileService.instance.pickBackup(
        dialogTitle: strings.d3('backup_chooseBackupDialog'),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }

    if (picked == null || !mounted) return;
    final selectedBackup = picked;

    String? legacyJson;
    Uint8List? zipBytes;
    BackupSummary summary;
    try {
      if (selectedBackup.isZip) {
        zipBytes = selectedBackup.bytes;
        summary = widget.store.inspectBackupZip(zipBytes);
      } else {
        legacyJson = utf8.decode(selectedBackup.bytes);
        summary = widget.store.inspectBackup(legacyJson);
      }
    } catch (error) {
      _message(
        error is FormatException
            ? strings.d3BackupError(error.message.toString())
            : strings.v100InvalidBackup,
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.v100RestoreBackupQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.v100BackupCreatedAt(
                DateFormat(
                  'd MMMM yyyy, HH:mm',
                  AnnaStrings.resolveLocale(Locale(strings.languageCode)).languageCode,
                ).format(summary.exportedAt),
              ),
            ),
            const SizedBox(height: 12),
            Text(strings.v100BackupItems(summary.itemCount)),
            Text(strings.v100BackupJournals(summary.journalCount)),
            Text(strings.v100BackupMonths(summary.monthCount)),
            Text(strings.v100BackupWeeks(summary.weekCount)),
            Text(strings.v100BackupHabits(summary.habitCount)),
            if (summary.birthdayCount > 0)
              Text(strings.v100BackupBirthdays(summary.birthdayCount)),
            if (summary.trashCount > 0)
              Text(strings.v100BackupTrash(summary.trashCount)),
            if (selectedBackup.isZip) ...[
              const SizedBox(height: 8),
              Text(
                strings.v100BackupMediaIncluded,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              strings.v100BackupSafetySnapshot,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, 'merge'),
            child: Text(strings.v100Merge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'replace'),
            child: Text(strings.v100ReplaceAll),
          ),
        ],
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'replace') {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(strings.v100ConfirmReplace),
              content: Text(
                strings.v100ConfirmReplaceDescription,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(strings.v100Restore),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    setState(() => busy = true);
    try {
      if (zipBytes != null) {
        await widget.store.restoreBackupZip(
          zipBytes,
          merge: action == 'merge',
        );
      } else {
        await widget.store.restoreBackup(
          legacyJson!,
          merge: action == 'merge',
        );
      }
      _message(
        action == 'merge'
            ? strings.v100BackupMerged
            : strings.v100BackupRestored,
      );
    } catch (_) {
      _message(strings.v100RestoreFailedSafe);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restoreSnapshot(LocalBackupSnapshot snapshot) async {
    final strings = AnnaStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.v100RestoreLocalQuestion),
            content: Text(
              '${snapshot.label}\n'
              '${DateFormat('d MMMM yyyy, HH:mm', AnnaStrings.resolveLocale(Locale(strings.languageCode)).languageCode).format(snapshot.createdAt)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.v100Restore),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => busy = true);
    try {
      await widget.store.restoreLocalSnapshot(snapshot.id);
      _message(strings.v100LocalBackupRestored);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store.backupRevision,
      builder: (context, _) {
        final snapshots = widget.store.localSnapshots;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AnnaStrings.of(context).v100BackupData,
              style: const TextStyle(fontWeight: FontWeight.w800),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 30),
                        const SizedBox(height: 10),
                        Text(
                          AnnaStrings.of(context).v100MemoriesStayYours,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          AnnaStrings.of(context).v100BackupHeroDescription,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BackupActionCard(
                    icon: Icons.save_alt_outlined,
                    title: AnnaStrings.of(context).v100CreateFullBackup,
                    subtitle: AnnaStrings.of(context).v100FullBackupDescription,
                    buttonLabel: AnnaStrings.of(context).v100SaveBackup,
                    onPressed: busy ? null : _exportBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.restore_outlined,
                    title: AnnaStrings.of(context).v100RestoreFromFile,
                    subtitle: AnnaStrings.of(context).v100RestoreFromFileDescription,
                    buttonLabel: AnnaStrings.of(context).v100ChooseBackup,
                    onPressed: busy ? null : _importBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.folder_zip_outlined,
                    title: AnnaStrings.of(context).v100OpenExport,
                    subtitle: AnnaStrings.of(context).v100OpenExportDescription,
                    buttonLabel: AnnaStrings.of(context).v100ExportArchive,
                    onPressed: busy ? null : _exportOpenArchive,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.verified_user_outlined,
                    title: AnnaStrings.of(context).v100VerifyIntegrity,
                    subtitle: AnnaStrings.of(context).v100VerifyIntegrityDescription,
                    buttonLabel: AnnaStrings.of(context).v100RunCheck,
                    onPressed: busy ? null : _runSafetyAudit,
                  ),
                  if (safetyReport != null) ...[
                    const SizedBox(height: 10),
                    _DataSafetyCard(report: safetyReport!),
                  ],
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.description_outlined,
                    title: AnnaStrings.of(context).v100ReadableExport,
                    subtitle: AnnaStrings.of(context).v100ReadableExportDescription,
                    buttonLabel: AnnaStrings.of(context).v100ExportTxt,
                    onPressed: busy ? null : _exportReadable,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AnnaStrings.of(context).v100LocalSafetyBackups,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: AnnaStrings.of(context).v100CreateLocalBackup,
                        onPressed: busy
                            ? null
                            : () => widget.store.createLocalSnapshot(),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Text(
                    AnnaStrings.of(context).v100LocalBackupsDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  if (snapshots.isEmpty)
                    SimpleCard(
                      child: Text(AnnaStrings.of(context).v100NoLocalBackups),
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
                              AnnaStrings.intlLocale(context),
                            ).format(snapshot.createdAt),
                          ),
                          onTap: busy
                              ? null
                              : () => _restoreSnapshot(snapshot),
                          trailing: IconButton(
                            tooltip: AnnaStrings.of(context).v100DeleteBackup,
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

class _DataSafetyCard extends StatelessWidget {
  final DataSafetyReport report;

  const _DataSafetyCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthy = report.integrityHealthy;
    final details = <String>[
      AnnaStrings.of(context).v100MediaReferenced(report.referencedMediaCount),
      AnnaStrings.of(context).v100MediaStored(report.storedMediaCount),
      if (report.missingMediaIds.isNotEmpty)
        AnnaStrings.of(context).v100MediaMissing(report.missingMediaIds.length),
      if (report.corruptMediaIds.isNotEmpty)
        AnnaStrings.of(context).v100MediaCorrupt(report.corruptMediaIds.length),
      if (report.orphanMediaIds.isNotEmpty)
        AnnaStrings.of(context).v100MediaOrphan(report.orphanMediaIds.length),
      if (report.unreadableStorageKeys.isNotEmpty)
        AnnaStrings.of(context).v100UnreadableStorage(report.unreadableStorageKeys.length),
      if (report.pendingCloudChanges > 0)
        AnnaStrings.of(context).v100PendingCloud(report.pendingCloudChanges),
      AnnaStrings.of(context).v100LocalSnapshotCount(report.localSnapshotCount),
    ];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              healthy ? scheme.primaryContainer : scheme.errorContainer,
          child: Icon(
            healthy ? Icons.verified_outlined : Icons.warning_amber_rounded,
            color: healthy
                ? scheme.onPrimaryContainer
                : scheme.onErrorContainer,
          ),
        ),
        title: Text(
          healthy ? AnnaStrings.of(context).v100IntegrityOk : AnnaStrings.of(context).v100IntegrityReview,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(details.join(' · ')),
      ),
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

class _NotificationSettingsCard extends StatefulWidget {
  final AgendaStore store;

  const _NotificationSettingsCard({required this.store});

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState
    extends State<_NotificationSettingsCard> {
  NotificationHealth? health;
  PushNotificationHealth? pushHealth;
  WebPushHealth? webPushHealth;
  bool busy = false;
  String? lastDiagnosticMessage;
  bool? lastDiagnosticOk;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final local = await NotificationService.instance.health();
    final push = await PushNotificationService.instance.health();
    final web = kIsWeb ? await WebPushService.instance.health() : null;
    if (!mounted) return;
    setState(() {
      health = local;
      pushHealth = push;
      webPushHealth = web;
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _requestPermissions({bool exact = false}) async {
    await _runBusy(() async {
      await NotificationService.instance.requestPermissions(
        requestExactAlarm: exact,
      );
      if (PushNotificationService.instance.configured) {
        await PushNotificationService.instance.repair();
      }
      await widget.store.reconcileReminders();
      await _refresh();
    });
  }

  Future<void> _testLocal() async {
    final strings = AnnaStrings.of(context);
    await _runBusy(() async {
      final result = await NotificationService.instance.runLocalDiagnostic();
      await _refresh();

      final message = result.ok
          ? strings.v100LocalTestOk(result.scheduledDelaySeconds)
          : [
              if (!result.permissionGranted)
                strings.v100NotificationPermissionDenied,
              if (!result.health.notificationsEnabled)
                strings.v100NotificationsSystemBlocked,
              if (!result.health.reminderChannelEnabled)
                strings.v100ReminderChannelOff,
              if (result.error != null) strings.v100Error(result.error!),
            ].join(' ');

      if (mounted) {
        setState(() {
          lastDiagnosticMessage = message;
          lastDiagnosticOk = result.ok;
        });
      }
      _snack(message);
    });
  }

  Future<void> _testPush() async {
    final strings = AnnaStrings.of(context);
    await _runBusy(() async {
      String message;
      bool ok = false;
      try {
        final result = await PushNotificationService.instance.sendSelfTest();
        await _refresh();
        final delivered = (result['delivered'] as num?)?.toInt() ?? 0;
        final devices = (result['devices'] as num?)?.toInt() ?? 0;
        final failed = (result['failed'] as num?)?.toInt() ?? 0;
        final removed =
            (result['removed_invalid_tokens'] as num?)?.toInt() ?? 0;
        ok = delivered > 0 && failed == 0;
        message = delivered > 0
            ? strings.v100FirebaseOk(delivered, devices, removed)
            : failed > 0
                ? strings.v100FirebaseFailed(failed)
                : strings.v100NoPushDelivery(devices);
      } catch (error) {
        await _refresh();
        final raw = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
        final compact = raw.length > 180 ? '${raw.substring(0, 180)}…' : raw;
        message = strings.v100FirebaseTestFailed(compact);
      }

      if (mounted) {
        setState(() {
          lastDiagnosticMessage = message;
          lastDiagnosticOk = ok;
        });
      }
      _snack(message);
    });
  }

  Future<void> _enableWebPush() async {
    final strings = AnnaStrings.of(context);
    await _runBusy(() async {
      final status = await WebPushService.instance.enable();
      if (status.ready) {
        await widget.store.reconcileReminders();
      }
      await _refresh();

      final message = status.ready
          ? strings.v100WebPushActive
          : status.isIos && !status.installedPwa
              ? strings.v100IosPwaRequired
              : status.permissionStatus == 'denied'
                  ? strings.v100BrowserPermissionDenied
                  : strings.v100WebPushNotReady(
                      status.lastError ?? strings.v100CheckPwaPermission,
                    );

      if (mounted) {
        setState(() {
          lastDiagnosticMessage = message;
          lastDiagnosticOk = status.ready;
        });
      }
      _snack(message);
    });
  }

  Future<void> _testWebPush() async {
    final strings = AnnaStrings.of(context);
    await _runBusy(() async {
      String message;
      bool ok = false;
      try {
        final result = await WebPushService.instance.sendSelfTest();
        final delivered = (result['delivered'] as num?)?.toInt() ?? 0;
        final webDelivered =
            (result['web_delivered'] as num?)?.toInt() ?? 0;
        final failed = (result['failed'] as num?)?.toInt() ?? 0;
        ok = webDelivered > 0 && failed == 0;
        message = ok
            ? strings.v100WebPushOk(webDelivered, delivered)
            : strings.v100WebPushUnconfirmed(webDelivered, failed);
      } catch (error) {
        final raw = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
        final compact = raw.length > 180 ? '${raw.substring(0, 180)}…' : raw;
        message = strings.v100WebPushTestFailed(compact);
      }
      await _refresh();
      if (mounted) {
        setState(() {
          lastDiagnosticMessage = message;
          lastDiagnosticOk = ok;
        });
      }
      _snack(message);
    });
  }

  Future<void> _openSettings() async {
    await _runBusy(() async {
      await NotificationService.instance.openSystemSettings();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await _refresh();
    });
  }

  Future<void> _repairAll() async {
    final strings = AnnaStrings.of(context);
    await _runBusy(() async {
      if (kIsWeb) {
        final status = await WebPushService.instance.enable();
        if (status.ready) {
          await widget.store.reconcileReminders();
        }
        await _refresh();
        _snack(
          status.ready
              ? strings.v100RepairWebReady
              : strings.v100RepairWebNotReady,
        );
        return;
      }

      await NotificationService.instance.initialize(force: true);
      await NotificationService.instance.requestPermissions();
      if (PushNotificationService.instance.configured) {
        await PushNotificationService.instance.repair();
      }
      await widget.store.reconcileReminders();
      await _refresh();

      final localOk = health?.reminderDeliveryReady == true;
      final push = pushHealth;
      final pushOk = push?.configured != true ||
          (push?.tokenAvailable == true &&
              push?.deviceRegistered == true &&
              health?.sharedDeliveryReady == true);
      _snack(
        localOk && pushOk
            ? strings.v100RepairReady
            : strings.v100RepairBlocked,
      );
    });
  }

  Widget _statusRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool ok,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            ok ? scheme.primaryContainer : scheme.errorContainer,
        foregroundColor:
            ok ? scheme.onPrimaryContainer : scheme.onErrorContainer,
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = health;
    final push = pushHealth;
    final web = webPushHealth;
    final enabled = local?.notificationsEnabled == true;
    final available = local?.available == true;
    final reminderChannel = local?.reminderChannelEnabled == true;
    final sharedChannel = local?.sharedChannelEnabled == true;
    final exact = local?.exactAlarmsEnabled == true;
    final pending = local?.pendingCount ?? 0;

    final pushConfigured = push?.configured == true;
    final pushReady = pushConfigured &&
        push?.tokenAvailable == true &&
        push?.deviceRegistered == true &&
        push?.permissionGranted == true &&
        enabled &&
        sharedChannel;
    final webReady = web?.ready == true;

    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AnnaStrings.of(context).v100NotificationDiagnostics,
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
            kIsWeb
                ? AnnaStrings.of(context).v100NotificationWebDescription
                : AnnaStrings.of(context).v100NotificationAndroidDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (kIsWeb)
            _statusRow(
              icon: webReady
                  ? Icons.notifications_active
                  : Icons.install_mobile_outlined,
              title: webReady
                  ? AnnaStrings.of(context).v100PwaPushActive
                  : AnnaStrings.of(context).v100PwaPushEnable,
              subtitle: web == null
                  ? AnnaStrings.of(context).v100WebDiagnosticsLoading
                  : [
                      web.isIos
                          ? (web.installedPwa
                              ? AnnaStrings.of(context).v100PwaIosInstalled
                              : AnnaStrings.of(context).v100PwaIosAddHome)
                          : AnnaStrings.of(context).v100BrowserWebPushSupported,
                      AnnaStrings.of(context).v100PermissionStatus(web.permissionStatus),
                      web.subscribed
                          ? AnnaStrings.of(context).v100BrowserSubscriptionPresent
                          : AnnaStrings.of(context).v100BrowserSubscriptionAbsent,
                      web.backendRegistered
                          ? AnnaStrings.of(context).v100SupabaseRegistered
                          : AnnaStrings.of(context).v100SupabaseNotRegistered,
                      if (web.lastError != null)
                        AnnaStrings.of(context).v100LastError(web.lastError!),
                    ].join(' · '),
              ok: webReady,
            ),
          if (!kIsWeb)
            _statusRow(
            icon: enabled
                ? Icons.notifications_active
                : Icons.notifications_off_outlined,
            title: !available
                ? AnnaStrings.of(context).v100LocalServiceNotInitialized
                : enabled
                    ? AnnaStrings.of(context).v100LocalNotificationsActive
                    : AnnaStrings.of(context).v100LocalNotificationsBlocked,
            subtitle: available
                ? [
                    AnnaStrings.of(context).v100ScheduledReminders(pending),
                    reminderChannel
                        ? AnnaStrings.of(context).v100ReminderChannelActive
                        : AnnaStrings.of(context).v100ReminderChannelBlocked,
                    if (local?.lastError != null)
                      AnnaStrings.of(context).v100LastError(local!.lastError!),
                  ].join(' · ')
                : AnnaStrings.of(context).v100LocalPluginUnavailable,
            ok: available && enabled && reminderChannel,
          ),
          if (!kIsWeb) const Divider(),
          if (!kIsWeb)
            _statusRow(
            icon: pushReady
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            title: !pushConfigured
                ? AnnaStrings.of(context).v100FirebaseNotConfigured
                : pushReady
                    ? AnnaStrings.of(context).v100NoiPushRegistered
                    : AnnaStrings.of(context).v100NoiPushRepair,
            subtitle: !pushConfigured
                ? (kIsWeb
                    ? AnnaStrings.of(context).v100FirebaseUnavailable
                    : AnnaStrings.of(context).v100FirebaseUnavailable)
                : [
                    AnnaStrings.of(context).v100PermissionStatus(push?.permissionStatus ?? '...'),
                    push?.tokenAvailable == true
                        ? AnnaStrings.of(context).v100FcmPresent
                        : AnnaStrings.of(context).v100FcmAbsent,
                    push?.signedIn == true
                        ? (push?.deviceRegistered == true
                            ? AnnaStrings.of(context).v100SupabaseRegistered
                            : AnnaStrings.of(context).v100SupabaseNotRegistered)
                        : AnnaStrings.of(context).v100CloudSignInRequired,
                    sharedChannel
                        ? AnnaStrings.of(context).v100NoiChannelActive
                        : AnnaStrings.of(context).v100NoiChannelBlocked,
                    if (push?.lastError != null)
                      AnnaStrings.of(context).v100LastError(push!.lastError!),
                  ].join(' · '),
            ok: pushReady,
          ),
          if (_isAndroid) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                exact ? Icons.alarm_on_outlined : Icons.alarm_add_outlined,
              ),
              title: Text(
                exact
                    ? AnnaStrings.of(context).v100PreciseRemindersOn
                    : AnnaStrings.of(context).v100PreciseReminders,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                exact
                    ? AnnaStrings.of(context).v100PreciseRemindersDescription
                    : AnnaStrings.of(context).v100ExactAlarmDescription,
              ),
              trailing: exact
                  ? const Icon(Icons.check_circle_outline)
                  : TextButton(
                      onPressed: busy
                          ? null
                          : () => _requestPermissions(exact: true),
                      child: Text(AnnaStrings.of(context).v100Activate),
                    ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : _repairAll,
                icon: const Icon(Icons.build_circle_outlined),
                label: Text(AnnaStrings.of(context).v100RepairNotifications),
              ),
              if (kIsWeb)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _enableWebPush,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(AnnaStrings.of(context).v100EnablePwa),
                ),
              if (kIsWeb)
                FilledButton.tonalIcon(
                  onPressed: busy || !webReady ? null : _testWebPush,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(AnnaStrings.of(context).v100TestWebPush),
                ),
              if (!kIsWeb)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _testLocal,
                  icon: const Icon(Icons.notification_add_outlined),
                  label: Text(AnnaStrings.of(context).v100FullLocalTest),
                ),
              if (!kIsWeb && pushConfigured)
                FilledButton.tonalIcon(
                  onPressed:
                      busy || push?.signedIn != true ? null : _testPush,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(AnnaStrings.of(context).v100TestFirebase),
                ),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: busy ? null : _openSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(AnnaStrings.of(context).v100SystemSettings),
                ),
            ],
          ),
          if (lastDiagnosticMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lastDiagnosticOk == true
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                lastDiagnosticMessage!,
                style: TextStyle(
                  color: lastDiagnosticOk == true
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class ExternalCalendarSettingsCard extends StatelessWidget {
  const ExternalCalendarSettingsCard({super.key});

  Future<void> _primeVisibleRange() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    final end = DateTime(now.year, now.month + 2, 1);
    await ExternalCalendarService.instance.loadRange(start, end);
  }

  void _message(BuildContext context, String value) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ExternalCalendarService.instance;
    unawaited(service.initialize());

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (!service.initialized) {
          return SimpleCard(
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AnnaStrings.of(context).v100CalendarPreparing),
                ),
              ],
            ),
          );
        }

        if (!service.supported) {
          return SimpleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AnnaStrings.of(context).v100ExternalCalendars,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(AnnaStrings.of(context).v100CalendarUnsupported),
                const SizedBox(height: 8),
                Text(
                  AnnaStrings.of(context).v100CalendarSeparation,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }

        return SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AnnaStrings.of(context).v100ExternalCalendars,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                AnnaStrings.of(context).v100ExternalCalendarsDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              if (!service.permissionGranted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: service.busy
                        ? null
                        : () async {
                            final granted = await service.requestAccess();
                            if (!context.mounted) return;
                            if (granted) {
                              await service.setEnabled(true);
                              await _primeVisibleRange();
                              if (!context.mounted) return;
                              _message(
                                context,
                                AnnaStrings.of(context).v100CalendarEnabled,
                              );
                            } else {
                              _message(
                                context,
                                AnnaStrings.of(context).v100CalendarPermissionDenied,
                              );
                            }
                          },
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(AnnaStrings.of(context).v100AllowCalendar),
                  ),
                )
              else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AnnaStrings.of(context).v100ShowExternalEvents),
                  subtitle: Text(AnnaStrings.of(context).v100ExternalOverlayDescription),
                  value: service.enabled,
                  onChanged: service.busy
                      ? null
                      : (value) async {
                          await service.setEnabled(value);
                          if (value) await _primeVisibleRange();
                        },
                ),
                if (service.calendars.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AnnaStrings.of(context).v100NoVisibleCalendars,
                    ),
                  )
                else ...[
                  const Divider(),
                  Text(
                    AnnaStrings.of(context).v100VisibleCalendars,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  ...service.calendars.map(
                    (calendar) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: service.selectedCalendarIds.contains(calendar.id),
                      title: Text(
                        calendar.name.trim().isEmpty
                            ? AnnaStrings.of(context).d3('external_calendar')
                            : calendar.name,
                      ),
                      subtitle: calendar.accountName.isEmpty
                          ? null
                          : Text(calendar.accountName),
                      secondary: Icon(
                        Icons.circle,
                        size: 16,
                        color: calendar.colorValue == null
                            ? Theme.of(context).colorScheme.primary
                            : Color(calendar.colorValue! & 0xFFFFFFFF),
                      ),
                      onChanged: service.busy
                          ? null
                          : (value) async {
                              await service.setCalendarSelected(
                                calendar.id,
                                value ?? false,
                              );
                              if (service.enabled) await _primeVisibleRange();
                            },
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: service.busy
                        ? null
                        : () async {
                            await service.refreshCalendars();
                            if (service.enabled) await _primeVisibleRange();
                          },
                    icon: const Icon(Icons.refresh),
                    label: Text(AnnaStrings.of(context).v100RefreshCalendars),
                  ),
                ),
              ],
              if (service.lastError != null) ...[
                const SizedBox(height: 8),
                Text(
                  service.lastError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (service.busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 8),
              Text(
                AnnaStrings.of(context).v100CalendarPrivacy,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
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
        displayName: value,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AnnaStrings.of(context).v100NameUpdated),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _configurePin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AnnaStrings.of(context).v100SetPin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: AnnaStrings.of(context).v100Pin,
                hintText: AnnaStrings.of(context).v100PinHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: second,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: AnnaStrings.of(context).v100RepeatPin,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
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
            child: Text(AnnaStrings.of(context).v100SavePin),
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
        SnackBar(content: Text(AnnaStrings.of(context).v100PinSet)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AnnaStrings.of(context).v100InvalidPin)),
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
            title: Text(AnnaStrings.of(context).v100ResetSettingsQuestion),
            content: Text(
              AnnaStrings.of(context).v100ResetSettingsDescription,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AnnaStrings.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(AnnaStrings.of(context).v100Restore),
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
      animation: Listenable.merge([
        widget.store.settingsRevision,
        PremiumEntitlementService.instance,
      ]),
      builder: (context, _) {
        final prefs = widget.store.preferences;
        final strings = AnnaStrings.of(context);
        final primary = prefs.defaultPrimaryReminder ?? -1;
        final secondary = prefs.defaultSecondaryReminder ?? -1;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.settings,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
            children: [
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.myAgendaSection,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: strings.name,
                        hintText: strings.enterName,
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _saveName,
                        child: Text(strings.saveName),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.workspace_premium_outlined),
                  ),
                  title: Text(
                    strings.premiumTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    PremiumEntitlementService.instance.paidEntitlement
                        ? strings.premiumActiveDescription
                        : strings.premiumSettingsDescription,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PremiumScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.language,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.languageDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppLanguage>(
                      initialValue: prefs.appLanguage,
                      decoration: InputDecoration(
                        labelText: strings.language,
                        prefixIcon: const Icon(Icons.language_outlined),
                      ),
                      items: AppLanguage.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == AppLanguage.system
                                    ? strings.systemTheme
                                    : value.nativeLabel,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        widget.store.savePreferences(
                          prefs.copyWith(appLanguage: value),
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
                    Text(
                      strings.appearance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AgendaThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: AgendaThemeMode.system,
                          label: Text(strings.systemTheme),
                          icon: const Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: AgendaThemeMode.light,
                          label: Text(strings.lightTheme),
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: AgendaThemeMode.dark,
                          label: Text(strings.darkTheme),
                          icon: const Icon(Icons.dark_mode_outlined),
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
                      strings.agendaColor,
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
                          label: Text(strings.agendaPaletteLabel(palette)),
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
                    Text(
                      strings.startupAndDay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<StartTab>(
                      initialValue: prefs.startTab,
                      decoration: InputDecoration(
                        labelText: strings.openAppOn,
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                      items: StartTab.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(strings.startTab(value)),
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
                      title: Text(strings.positiveQuote),
                      subtitle: Text(strings.positiveQuoteDescription),
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
                    Text(
                      strings.v100NewCommitments,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.v100NewCommitmentsDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AgendaCategory>(
                      initialValue: prefs.defaultCategory,
                      decoration: InputDecoration(
                        labelText: strings.v100DefaultCategory,
                        prefixIcon: const Icon(Icons.label_outline),
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
                                  Text(strings.editorCategoryLabel(value)),
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
                            strings.v100DefaultDuration(prefs.defaultEventMinutes),
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
                      decoration: InputDecoration(
                        labelText: strings.v100DefaultReminder1,
                        prefixIcon:
                            const Icon(Icons.notifications_none_outlined),
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
                      decoration: InputDecoration(
                        labelText: strings.v100DefaultReminder2,
                        prefixIcon: const Icon(Icons.add_alert_outlined),
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
              _NotificationSettingsCard(store: widget.store),
              const SizedBox(height: 12),
              const ExternalCalendarSettingsCard(),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.v100PrivacyCenter,
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
                      strings.v100PrivacyCenterDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            prefs.privacyLockEnabled
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            size: 18,
                          ),
                          label: Text(
                            prefs.privacyLockEnabled
                                ? strings.v100AppLockOn
                                : strings.v100AppLockOff,
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.visibility_off_outlined, size: 18),
                          label: Text(
                            prefs.hideHomeDetails
                                ? strings.v100HomeProtected
                                : strings.v100HomeDetailsVisible,
                          ),
                        ),
                        if (prefs.biometricUnlock && prefs.privacyLockEnabled)
                          Chip(
                            avatar: const Icon(Icons.fingerprint, size: 18),
                            label: Text(strings.v100BiometricsOn),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (prefs.pinHash == null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _configurePin,
                          icon: const Icon(Icons.pin_outlined),
                          label: Text(strings.v100SetPin),
                        ),
                      )
                    else ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.v100LockAgenda),
                        subtitle: Text(strings.v100LockAgendaDescription),
                        value: prefs.privacyLockEnabled,
                        onChanged: (value) =>
                            widget.store.savePreferences(
                          prefs.copyWith(privacyLockEnabled: value),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pin_outlined),
                        title: Text(strings.v100ChangePin),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _configurePin,
                      ),
                    ],
                    if (prefs.pinHash != null) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.v100BiometricUnlock),
                        subtitle: Text(
                          kIsWeb
                              ? strings.v100NotWeb
                              : strings.v100BiometricDescription,
                        ),
                        value: prefs.biometricUnlock,
                        onChanged: prefs.privacyLockEnabled
                            ? (value) async {
                                if (value &&
                                    !await _deviceSupportsBiometrics()) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(strings.v100BiometricUnavailable),
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
                        decoration: InputDecoration(
                          labelText: strings.v100AutoLock,
                          prefixIcon: const Icon(Icons.timer_outlined),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(strings.v100Immediately),
                          ),
                          for (final minutes in const [1, 2, 5, 15])
                            DropdownMenuItem(
                              value: minutes,
                              child: Text(strings.v100AfterMinutes(minutes)),
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
                      title: Text(strings.v100HideHomeDetails),
                      subtitle: Text(strings.v100HideHomeDetailsDescription),
                      value: prefs.hideHomeDetails,
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(hideHomeDetails: value),
                      ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_person_outlined),
                      title: Text(strings.v100PrivateVault),
                      subtitle: Text(strings.v100PrivateVaultDescription),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivateVaultScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(strings.v100BackupSafetyData),
                      subtitle: Text(strings.v100BackupSafetyDataDescription),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BackupScreen(store: widget.store),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: Text(strings.v100AccountDataRights),
                      subtitle: Text(strings.v100AccountDataRightsDescription),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CloudAccountScreen(store: widget.store),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.v100VaultAccountBoundary,
                      style: Theme.of(context).textTheme.bodySmall,
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
                      strings.v100DataSection,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(strings.v100AccountSync),
                      subtitle: Text(strings.v100AccountSyncDescription),
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
                      title: Text(strings.v100BackupRestore),
                      subtitle: Text(strings.v100BackupRestoreDescription),
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
                label: Text(strings.v100ResetDefaults),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Anna\'s Diary · v$appReleaseVersion',
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
