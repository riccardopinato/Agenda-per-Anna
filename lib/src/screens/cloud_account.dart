part of '../../main.dart';

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
  bool busy = false;

  String _stateLabel(CloudConnectionState state) => switch (state) {
        CloudConnectionState.disabled => 'Cloud non configurato',
        CloudConnectionState.initializing => 'Connessione...',
        CloudConnectionState.signedOut => 'Sessione non attiva',
        CloudConnectionState.syncing => 'Sincronizzazione...',
        CloudConnectionState.synced => 'Sincronizzato',
        CloudConnectionState.error => 'Errore di sincronizzazione',
      };

  IconData _stateIcon(CloudConnectionState state) => switch (state) {
        CloudConnectionState.disabled => Icons.cloud_off_outlined,
        CloudConnectionState.initializing => Icons.hourglass_top,
        CloudConnectionState.signedOut => Icons.person_off_outlined,
        CloudConnectionState.syncing => Icons.sync,
        CloudConnectionState.synced => Icons.cloud_done_outlined,
        CloudConnectionState.error => Icons.cloud_off,
      };

  Future<void> _syncNow() async {
    setState(() => busy = true);
    try {
      await widget.store.syncAllCloud();
      final cloud = CloudSyncService.instance;
      if (cloud.state == CloudConnectionState.error) {
        _message(cloud.userFacingError);
      } else if (widget.store.totalPendingCloudChanges > 0) {
        _message(
          'I dati locali sono al sicuro: '
          '${widget.store.totalPendingCloudChanges} modifiche restano in attesa di rete.',
        );
      } else {
        _message('Agenda e Noi ♡ completamente sincronizzati.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Disconnettere l’account?'),
            content: const Text(
              'I dati dell’account restano archiviati sul dispositivo, ma Anna’s Diary '
              'tornerà alla schermata di accesso finché non effettui di nuovo il login.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Disconnetti'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => busy = true);
    try {
      await widget.store.createLocalSnapshot(
        label: 'Prima della disconnessione account',
      );
      await PushNotificationService.instance.unregisterCurrentToken();
      await CloudSyncService.instance.signOut();
      await widget.store.activateCloudAccount(null);
      if (mounted) Navigator.pop(context);
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
      animation: Listenable.merge([
        cloud,
        widget.store.syncRevision,
        widget.store.accountRevision,
      ]),
      builder: (context, _) {
        final avatar = cloud.avatarUrl;
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
                    Icon(_stateIcon(cloud.state), size: 32),
                    const SizedBox(height: 10),
                    Text(
                      _stateLabel(cloud.state),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Lo stesso account identifica agenda privata, dispositivi e '
                      'partecipazione agli spazi Noi ♡.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                      leading: CircleAvatar(
                        foregroundImage:
                            avatar == null ? null : NetworkImage(avatar),
                        child: avatar == null
                            ? const Icon(Icons.person_outline)
                            : null,
                      ),
                      title: Text(
                        cloud.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(cloud.email ?? 'Account Google'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sync_outlined),
                      title: const Text('Modifiche in attesa'),
                      trailing: Text(
                        '${widget.store.totalPendingCloudChanges}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (widget.store.totalPendingCloudChanges > 0)
                      Text(
                        '${widget.store.pendingCloudChanges} private · '
                        '${widget.store.pendingSharedChangeCount} Noi ♡',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ||
                                cloud.state == CloudConnectionState.syncing
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
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sincronizzazione continua',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Le modifiche vengono salvate prima sul dispositivo.\n'
                      '• Se manca Internet, restano in coda senza perdere dati.\n'
                      '• Realtime aggiorna Noi ♡ mentre l’app è attiva.\n'
                      '• Push e riconciliazione al ritorno nell’app coprono il background.\n'
                      '• Agenda privata e Noi ♡ restano separati a livello dati.',
                    ),
                    if (cloud.lastSyncAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Ultimo sync: ${DateFormat('d MMM, HH:mm', 'it_IT').format(cloud.lastSyncAt!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
