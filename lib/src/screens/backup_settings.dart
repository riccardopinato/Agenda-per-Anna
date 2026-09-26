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
    setState(() => busy = true);
    try {
      final bytes = await widget.store.createBackupZip();
      widget.store.verifyBackupZip(bytes);
      final ok = await BackupFileService.instance.saveZipBackup(
        bytes: bytes,
        fileName: _timestampFileName('zip'),
      );
      _message(
        ok
            ? 'Backup completo ZIP salvato.'
            : 'Salvataggio annullato o non riuscito.',
      );
    } catch (error) {
      _message(
        error is FormatException
            ? error.message.toString()
            : 'Non è stato possibile creare il backup completo.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _runSafetyAudit() async {
    setState(() => busy = true);
    try {
      final report = await widget.store.auditDataSafety();
      if (!mounted) return;
      setState(() => safetyReport = report);
      _message(
        report.integrityHealthy
            ? report.hasCleanupCandidates
                ? 'Integrità OK · ${report.orphanMediaIds.length} media non più collegati.'
                : 'Integrità locale verificata: nessun problema rilevato.'
            : 'Verifica completata: sono presenti elementi da controllare.',
      );
    } catch (_) {
      _message('Non è stato possibile completare la verifica integrità.');
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
    PickedBackupFile? picked;
    try {
      picked = await BackupFileService.instance.pickBackup();
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
            if (summary.birthdayCount > 0)
              Text('• ${summary.birthdayCount} compleanni'),
            if (summary.trashCount > 0)
              Text('• ${summary.trashCount} elementi nel Cestino'),
            if (selectedBackup.isZip) ...[
              const SizedBox(height: 8),
              const Text(
                '• Media inclusi separatamente nel pacchetto ZIP',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
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
            ? 'Backup unito ai dati presenti.'
            : 'Backup ripristinato correttamente.',
      );
    } catch (_) {
      _message(
        'Ripristino non riuscito. I dati attuali non sono stati eliminati.',
      );
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
      animation: widget.store.backupRevision,
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
                          'Il backup ZIP include dati e media separati; i vecchi backup JSON restano importabili.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BackupActionCard(
                    icon: Icons.save_alt_outlined,
                    title: 'Crea backup completo',
                    subtitle:
                        'Salva dati e media in un unico file .zip verificato, senza incorporare le foto in Base64 nel JSON.',
                    buttonLabel: 'Salva backup',
                    onPressed: busy ? null : _exportBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.restore_outlined,
                    title: 'Ripristina da file',
                    subtitle:
                        'Importa backup ZIP nuovi o JSON precedenti. Puoi unire i dati oppure sostituire tutto.',
                    buttonLabel: 'Scegli backup',
                    onPressed: busy ? null : _importBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Verifica integrità locale',
                    subtitle:
                        'Controlla media mancanti o corrotti, file non più collegati, warning dello storage e modifiche cloud ancora in attesa.',
                    buttonLabel: 'Avvia verifica',
                    onPressed: busy ? null : _runSafetyAudit,
                  ),
                  if (safetyReport != null) ...[
                    const SizedBox(height: 10),
                    _DataSafetyCard(report: safetyReport!),
                  ],
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

class _DataSafetyCard extends StatelessWidget {
  final DataSafetyReport report;

  const _DataSafetyCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthy = report.integrityHealthy;
    final details = <String>[
      '${report.referencedMediaCount} media collegati',
      '${report.storedMediaCount} media locali',
      if (report.missingMediaIds.isNotEmpty)
        '${report.missingMediaIds.length} mancanti',
      if (report.corruptMediaIds.isNotEmpty)
        '${report.corruptMediaIds.length} corrotti',
      if (report.orphanMediaIds.isNotEmpty)
        '${report.orphanMediaIds.length} non più collegati',
      if (report.unreadableStorageKeys.isNotEmpty)
        '${report.unreadableStorageKeys.length} sezioni storage non leggibili',
      if (report.pendingCloudChanges > 0)
        '${report.pendingCloudChanges} modifiche cloud in attesa',
      '${report.localSnapshotCount} backup locali',
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
          healthy ? 'Integrità dati OK' : 'Controllo dati richiesto',
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
    await _runBusy(() async {
      final result = await NotificationService.instance.runLocalDiagnostic();
      await _refresh();

      final message = result.ok
          ? 'Test locale OK: una notifica è stata inviata subito e un '
              'promemoria di controllo arriverà tra '
              '${result.scheduledDelaySeconds} secondi.'
          : [
              if (!result.permissionGranted)
                'Permesso notifiche non concesso.',
              if (!result.health.notificationsEnabled)
                'Notifiche bloccate a livello di sistema.',
              if (!result.health.reminderChannelEnabled)
                'Canale “Promemoria” disattivato nelle impostazioni Android.',
              if (result.error != null) 'Errore: ${result.error}',
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
            ? 'Firebase OK: $delivered consegna/e su $devices dispositivo/i'
                '${removed > 0 ? ' · $removed token obsoleti rimossi' : ''}.'
            : failed > 0
                ? 'Firebase ha raggiunto il backend ma $failed consegna/e '
                    'sono fallite. Controlla la diagnostica sotto.'
                : 'Backend raggiunto, ma nessuna consegna: '
                    '$devices dispositivo/i registrati.';
      } catch (error) {
        await _refresh();
        final raw = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
        final compact = raw.length > 180 ? '${raw.substring(0, 180)}…' : raw;
        message = 'Test Firebase fallito: $compact';
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
    await _runBusy(() async {
      final status = await WebPushService.instance.enable();
      if (status.ready) {
        await widget.store.reconcileReminders();
      }
      await _refresh();

      final message = status.ready
          ? 'Push PWA attive: questo dispositivo è registrato.'
          : status.isIos && !status.installedPwa
              ? 'Su iPhone apri Anna\'s Diary dalla schermata Home: '
                  'Safari non consente Web Push alla sola scheda del browser.'
              : status.permissionStatus == 'denied'
                  ? 'Permesso notifiche negato dal browser. Riattivalo '
                      'dalle impostazioni del sito/dispositivo.'
                  : 'Web Push non ancora pronta: '
                      '${status.lastError ?? 'controlla permesso e installazione PWA'}.';

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
            ? 'Web Push OK: notifica inviata a questa PWA '
                '($webDelivered consegna/e, $delivered totali).'
            : 'Test Web Push non confermato dal backend '
                '(web: $webDelivered · fallite: $failed).';
      } catch (error) {
        final raw = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
        final compact = raw.length > 180 ? '${raw.substring(0, 180)}…' : raw;
        message = 'Test Web Push fallito: $compact';
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
    await _runBusy(() async {
      if (kIsWeb) {
        final status = await WebPushService.instance.enable();
        if (status.ready) {
          await widget.store.reconcileReminders();
        }
        await _refresh();
        _snack(
          status.ready
              ? 'Riparazione completata: Web Push PWA pronta.'
              : 'Web Push non ancora pronta: verifica installazione PWA '
                  'e permesso notifiche.',
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
            ? 'Riparazione completata: notifiche pronte.'
            : 'Riparazione completata, ma almeno un permesso/canale resta '
                'bloccato. Apri “Impostazioni sistema” per il dettaglio.',
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
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifiche · diagnostica',
                  style: TextStyle(
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
                ? 'Su iPhone/PWA verifica installazione nella Home, permesso '
                    'notifiche, subscription Web Push e registrazione Supabase. '
                    'Il test invia una push reale dal backend.'
                : 'Verifica la catena completa: permesso Android, canali, '
                    'programmazione locale, token FCM, registrazione Supabase e '
                    'consegna Firebase. “Ripara notifiche” non aggira i canali '
                    'disattivati manualmente: in quel caso usa Impostazioni sistema.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (kIsWeb)
            _statusRow(
              icon: webReady
                  ? Icons.notifications_active
                  : Icons.install_mobile_outlined,
              title: webReady
                  ? 'Push PWA e promemoria attivi'
                  : 'Push PWA da attivare',
              subtitle: web == null
                  ? 'Diagnostica Web Push in caricamento...'
                  : [
                      web.isIos
                          ? (web.installedPwa
                              ? 'PWA iPhone: installata'
                              : 'PWA iPhone: aggiungi alla schermata Home')
                          : 'Browser Web Push: supportato',
                      'permesso: ${web.permissionStatus}',
                      web.subscribed
                          ? 'subscription browser: presente'
                          : 'subscription browser: assente',
                      web.backendRegistered
                          ? 'Supabase: registrata'
                          : 'Supabase: non registrata',
                      if (web.lastError != null)
                        'errore: ${web.lastError}',
                    ].join(' · '),
              ok: webReady,
            ),
          if (!kIsWeb)
            _statusRow(
            icon: enabled
                ? Icons.notifications_active
                : Icons.notifications_off_outlined,
            title: !available
                ? 'Servizio locale non inizializzato'
                : enabled
                    ? 'Notifiche locali attive'
                    : 'Notifiche locali bloccate',
            subtitle: available
                ? [
                    '$pending promemoria programmati',
                    reminderChannel
                        ? 'canale Promemoria: attivo'
                        : 'canale Promemoria: BLOCCATO',
                    if (local?.lastError != null)
                      'ultimo errore: ${local!.lastError}',
                  ].join(' · ')
                : 'Il plugin locale non è disponibile in questo momento.',
            ok: available && enabled && reminderChannel,
          ),
          if (!kIsWeb) const Divider(),
          if (!kIsWeb)
            _statusRow(
            icon: pushReady
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            title: !pushConfigured
                ? 'Push Firebase non configurate'
                : pushReady
                    ? 'Push Noi ♡ registrate'
                    : 'Push Noi ♡ da riparare',
            subtitle: !pushConfigured
                ? (kIsWeb
                    ? 'Push remote non disponibili nella PWA Web/iPhone in questa versione.'
                    : 'Questa build non contiene Firebase per la piattaforma corrente.')
                : [
                    'permesso: ${push?.permissionStatus ?? '...'}',
                    push?.tokenAvailable == true
                        ? 'token FCM: presente'
                        : 'token FCM: assente',
                    push?.signedIn == true
                        ? (push?.deviceRegistered == true
                            ? 'Supabase: registrato'
                            : 'Supabase: non registrato')
                        : 'cloud: accesso richiesto',
                    sharedChannel
                        ? 'canale Noi ♡: attivo'
                        : 'canale Noi ♡: BLOCCATO',
                    if (push?.lastError != null)
                      'errore: ${push!.lastError}',
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
                exact ? 'Promemoria precisi attivi' : 'Promemoria precisi',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                exact
                    ? 'Android può mostrare i promemoria all’orario previsto.'
                    : 'Consenti “Sveglie e promemoria” per ridurre i ritardi.',
              ),
              trailing: exact
                  ? const Icon(Icons.check_circle_outline)
                  : TextButton(
                      onPressed: busy
                          ? null
                          : () => _requestPermissions(exact: true),
                      child: const Text('Attiva'),
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
                label: const Text('Ripara notifiche'),
              ),
              if (kIsWeb)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _enableWebPush,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Attiva PWA'),
                ),
              if (kIsWeb)
                FilledButton.tonalIcon(
                  onPressed: busy || !webReady ? null : _testWebPush,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Test Web Push'),
                ),
              if (!kIsWeb)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _testLocal,
                  icon: const Icon(Icons.notification_add_outlined),
                  label: const Text('Test locale completo'),
                ),
              if (!kIsWeb && pushConfigured)
                FilledButton.tonalIcon(
                  onPressed:
                      busy || push?.signedIn != true ? null : _testPush,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Test Firebase'),
                ),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: busy ? null : _openSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Impostazioni sistema'),
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
      animation: widget.store.settingsRevision,
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
              _NotificationSettingsCard(store: widget.store),
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
