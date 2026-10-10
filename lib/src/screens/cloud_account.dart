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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _stateLabel(CloudConnectionState state, AnnaStrings strings) =>
      switch (state) {
        CloudConnectionState.disabled => strings.d3('cloudDisabled'),
        CloudConnectionState.initializing => strings.d3('cloudConnecting'),
        CloudConnectionState.signedOut => strings.d3('cloudSignedOut'),
        CloudConnectionState.syncing => strings.d3('cloudSyncing'),
        CloudConnectionState.synced => strings.v100AllSynced,
        CloudConnectionState.error => strings.d3('cloudSyncError'),
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
      _message(AnnaStrings.of(context).d3('emailPasswordRequired'));
      return;
    }

    setState(() => busy = true);
    try {
      final cloud = CloudSyncService.instance;
      await cloud.signIn(email: email, password: password);
      await widget.store.activateCloudAccount(cloud.userId);
      await widget.store.syncAllCloud(preferRemoteOnFirstSync: true);
      await PushNotificationService.instance.registerCurrentToken();
      if (kIsWeb) {
        await WebPushService.instance.initialize(force: true);
        await widget.store.reconcileReminders();
      }
      _message(AnnaStrings.of(context).d3('connectedSynced'));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      _message(AnnaStrings.of(context).d3CloudError(CloudSyncService.instance.lastError ?? ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => busy = true);
    try {
      await CloudSyncService.instance.signInWithGoogle();
    } catch (_) {
      _message(AnnaStrings.of(context).d3CloudError(CloudSyncService.instance.lastError ?? ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _message(AnnaStrings.of(context).d3('emailRequired'));
      return;
    }

    setState(() => busy = true);
    try {
      await CloudSyncService.instance.requestPasswordReset(email);
      _message(AnnaStrings.of(context).d3('resetEmailSent'));
    } catch (_) {
      _message(
        AnnaStrings.of(context).d3CloudError(
          CloudSyncService.instance.lastError ?? '',
        ),
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
        _message(AnnaStrings.of(context).d3CloudError(cloud.lastError ?? ''));
      } else if (widget.store.totalPendingCloudChanges > 0) {
        _message(
          AnnaStrings.of(context).d3Format(
            'pendingSafe',
            {'count': widget.store.totalPendingCloudChanges},
          ),
        );
      } else {
        _message(AnnaStrings.of(context).d3('agendaSynced'));
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
      await PushNotificationService.instance.unregisterCurrentToken();
      if (kIsWeb) {
        await CloudSyncService.instance.clearWebPushReminders();
        await WebPushService.instance.disable();
      }
      await CloudSyncService.instance.signOut();
      await widget.store.activateCloudAccount(null);
      _message(AnnaStrings.of(context).d3('accountSignedOut'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final cloud = CloudSyncService.instance;
    final accountId = cloud.userId;
    if (accountId == null) return;

    final controller = TextEditingController();
    var canDelete = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(dialogContext).colorScheme.error,
            ),
            title: Text(AnnaStrings.of(dialogContext).d3('deleteAccountTitle')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AnnaStrings.of(dialogContext).d3('deleteAccountBody'),
                ),
                const SizedBox(height: 10),
                Text(
                  AnnaStrings.of(dialogContext).d3('deleteOwnerWarning'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  AnnaStrings.of(dialogContext).d3('exportBeforeDelete'),
                ),
                const SizedBox(height: 14),
                Text(AnnaStrings.of(dialogContext).d3('typeDelete')),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    final enabled = value.trim().toUpperCase() == 'DELETE';
                    if (enabled != canDelete) {
                      setDialogState(() => canDelete = enabled);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: AnnaStrings.of(dialogContext).d3('confirmation'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AnnaStrings.of(dialogContext).cancel),
              ),
              FilledButton(
                onPressed: canDelete
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: Text(AnnaStrings.of(dialogContext).d3('deleteAccountData')),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => busy = true);
    var remoteDeleted = false;
    try {
      await cloud.deleteCurrentAccount();
      remoteDeleted = true;

      await PushNotificationService.instance.unregisterCurrentToken();
      if (kIsWeb) {
        await WebPushService.instance.disable();
      }
      await widget.store.eraseLocalCloudAccount(accountId);

      _message(AnnaStrings.of(context).d3('accountDeleted'));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      _message(
        remoteDeleted
            ? AnnaStrings.of(context).d3('accountCloudDeletedLocalFailed')
            : AnnaStrings.of(context).d3CloudError(cloud.lastError ?? ''),
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
      animation: Listenable.merge([cloud, widget.store.syncRevision]),
      builder: (context, _) => AnimatedBuilder(
        animation: Listenable.merge([
          widget.store.accountRevision,
          widget.store.settingsRevision,
        ]),
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
                        const Text(
                          'Accedi al tuo account',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Google è l’accesso principale di Anna\'s Diary. '
                          'Il login email/password resta solo per gli account creati nelle versioni precedenti.',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _google,
                            icon: const Icon(Icons.login),
                            label: const Text('Continua con Google'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Account email esistente',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
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
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => busy ? null : _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: const Icon(Icons.login),
                            label: const Text('Accedi con account esistente'),
                          ),
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: busy ? null : _forgotPassword,
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: const Text('Password dimenticata?'),
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
                          leading: CircleAvatar(
                            backgroundImage: cloud.avatarUrl == null
                                ? null
                                : NetworkImage(cloud.avatarUrl!),
                            child: cloud.avatarUrl == null
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          title: Text(
                            cloud.displayName?.trim().isNotEmpty == true
                                ? cloud.displayName!
                                : (cloud.email ?? 'Account'),
                          ),
                          subtitle: Text(
                            [
                              if (cloud.displayName?.trim().isNotEmpty == true &&
                                  cloud.email != null)
                                cloud.email!,
                              cloud.lastSyncAt == null
                                  ? 'Nessuna sincronizzazione completata'
                                  : 'Ultimo sync: ${DateFormat('d MMM, HH:mm', 'it_IT').format(cloud.lastSyncAt!)}',
                            ].join('\n'),
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
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 6),
                        Text(
                          'Zona dati',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'L’eliminazione dell’account è permanente e richiede una conferma esplicita.',
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _deleteAccount,
                            icon: const Icon(Icons.delete_forever_outlined),
                            label: const Text('Elimina account e dati'),
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
