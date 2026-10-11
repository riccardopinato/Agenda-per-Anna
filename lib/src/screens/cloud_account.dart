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
    final strings = AnnaStrings.of(context);
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _message(strings.d3('emailPasswordRequired'));
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
      _message(strings.d3('connectedSynced'));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      _message(strings.d3CloudError(CloudSyncService.instance.lastError ?? ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _google() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      await CloudSyncService.instance.signInWithGoogle();
    } catch (_) {
      _message(strings.d3CloudError(CloudSyncService.instance.lastError ?? ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final strings = AnnaStrings.of(context);
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _message(strings.d3('emailRequired'));
      return;
    }

    setState(() => busy = true);
    try {
      await CloudSyncService.instance.requestPasswordReset(email);
      _message(strings.d3('resetEmailSent'));
    } catch (_) {
      _message(
        strings.d3CloudError(
          CloudSyncService.instance.lastError ?? '',
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _syncNow() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      await widget.store.syncAllCloud();
      final cloud = CloudSyncService.instance;
      if (cloud.state == CloudConnectionState.error) {
        _message(strings.d3CloudError(cloud.lastError ?? ''));
      } else if (widget.store.totalPendingCloudChanges > 0) {
        _message(
          strings.d3Format(
            'pendingSafe',
            {'count': widget.store.totalPendingCloudChanges},
          ),
        );
      } else {
        _message(strings.d3('agendaSynced'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    final strings = AnnaStrings.of(context);
    setState(() => busy = true);
    try {
      await widget.store.createLocalSnapshot(
        label: '@snapshot:before_sign_out',
      );
      await PushNotificationService.instance.unregisterCurrentToken();
      if (kIsWeb) {
        await CloudSyncService.instance.clearWebPushReminders();
        await WebPushService.instance.disable();
      }
      await CloudSyncService.instance.signOut();
      await widget.store.activateCloudAccount(null);
      _message(strings.d3('accountSignedOut'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final cloud = CloudSyncService.instance;
    final accountId = cloud.userId;
    if (accountId == null) return;
    final strings = AnnaStrings.of(context);

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

      _message(strings.d3('accountDeleted'));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      _message(
        remoteDeleted
            ? strings.d3('accountCloudDeletedLocalFailed')
            : strings.d3CloudError(cloud.lastError ?? ''),
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
    final strings = AnnaStrings.of(context);

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
              title: Text(
                strings.d3('accountAndSync'),
                style: const TextStyle(fontWeight: FontWeight.w900),
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
                        _stateLabel(cloud.state, strings),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cloud.signedIn
                            ? strings.d3('cloudConnectedDescription')
                            : strings.d3('cloudSignedOutDescription'),
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
                        Text(
                          strings.d3('cloudReadyNotConnected'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.d3('cloudBuildNoCredentials'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.d3('sharedPrepared'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
                          strings.d3('signInAccount'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(strings.d3('googlePrimary')),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _google,
                            icon: const Icon(Icons.login),
                            label: Text(strings.d3('continueGoogle')),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          strings.d3('existingEmailAccount'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: AnnaStrings.of(context).vaultEmail,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => busy ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: strings.d3('password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: const Icon(Icons.login),
                            label: Text(strings.d3('existingAccount')),
                          ),
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: busy ? null : _forgotPassword,
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: Text(strings.d3('forgotPassword')),
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
                        Text(
                          strings.d3('myAccount'),
                          style: const TextStyle(
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
                                : (cloud.email ?? strings.d3('account')),
                          ),
                          subtitle: Text(
                            [
                              if (cloud.displayName?.trim().isNotEmpty == true &&
                                  cloud.email != null)
                                cloud.email!,
                              cloud.lastSyncAt == null
                                  ? strings.d3('noCompletedSync')
                                  : strings.d3Format(
                                      'lastSync',
                                      {
                                        'value': DateFormat(
                                          'd MMM, HH:mm',
                                          AnnaStrings.intlLocale(context),
                                        ).format(cloud.lastSyncAt!),
                                      },
                                    ),
                            ].join('\n'),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sync_outlined),
                          title: Text(strings.d3('pendingChanges')),
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
                            '${widget.store.pendingCloudChanges} ${strings.d3('privateLabel')} · '
                            '${widget.store.pendingSharedChangeCount} ${strings.d3('sharedLabel')}',
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
                            label: Text(strings.d3('syncNow')),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _signOut,
                            icon: const Icon(Icons.logout),
                            label: Text(strings.d3('disconnectAccount')),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 6),
                        Text(
                          strings.d3('dataZone'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(strings.d3('deletePermanentNote')),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _deleteAccount,
                            icon: const Icon(Icons.delete_forever_outlined),
                            label: Text(strings.d3('deleteAccountData')),
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
                      Text(
                        strings.d3('howItWorks'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(strings.d3('localFirstHow')),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people_outline),
                            const SizedBox(width: 10),
                            Expanded(child: Text(strings.d3('privateDefaultCloud'))),
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
