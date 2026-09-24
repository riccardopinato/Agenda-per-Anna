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

  Future<void> _syncNow() async {
    setState(() => busy = true);
    try {
      await widget.store.syncAllCloud();
      final cloud = CloudSyncService.instance;
      if (!mounted) return;
      if (cloud.state == CloudConnectionState.error) {
        _message(cloud.userFacingError);
      } else if (widget.store.totalPendingCloudChanges > 0) {
        _message(
          'I dati locali sono al sicuro: '
          '${widget.store.totalPendingCloudChanges} modifiche restano in attesa di rete.',
        );
      } else {
        _message('Agenda e Noi ♡ sono sincronizzati.');
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
              'I dati dell’account resteranno archiviati sul dispositivo, '
              'ma per riaprirli sarà necessario accedere di nuovo.',
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
        final pending = widget.store.totalPendingCloudChanges;

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
                          .withValues(alpha: 0.78),
                      Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundImage:
                          avatar == null ? null : NetworkImage(avatar),
                      child: avatar == null
                          ? const Icon(Icons.person_outline, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cloud.displayName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (cloud.email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              cloud.email!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(_stateIcon(cloud.state), size: 18),
                              const SizedBox(width: 6),
                              Text(_stateLabel(cloud.state)),
                            ],
                          ),
                        ],
                      ),
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
                      'Sincronizzazione automatica',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'L’account resta collegato. I dati privati e Noi ♡ '
                      'si riallineano in tempo reale quando l’app è aperta, '
                      'al ritorno online, alla riapertura e periodicamente.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          pending == 0
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_upload_outlined,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pending == 0
                                ? 'Nessuna modifica in attesa'
                                : '$pending modifiche in attesa di rete',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : _syncNow,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: const Text('Sincronizza ora'),
                      ),
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
                      'Noi ♡',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Non serve un secondo login: Noi ♡ usa automaticamente '
                      'questa stessa identità e continua a sincronizzare gli '
                      'spazi a cui sei collegato.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SharedSpaceHubScreen(store: widget.store),
                        ),
                      ),
                      icon: const Icon(Icons.favorite_outline),
                      label: const Text('Apri Noi ♡'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: busy ? null : _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Disconnetti account'),
              ),
            ],
          ),
        );
      },
    );
  }
}
