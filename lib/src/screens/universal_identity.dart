part of '../../main.dart';

class UniversalIdentityScreen extends StatefulWidget {
  final AgendaStore store;

  const UniversalIdentityScreen({
    super.key,
    required this.store,
  });

  @override
  State<UniversalIdentityScreen> createState() => _UniversalIdentityScreenState();
}

class _UniversalIdentityScreenState extends State<UniversalIdentityScreen> {
  bool busy = false;

  Future<void> _google() async {
    setState(() => busy = true);
    try {
      final cloud = CloudSyncService.instance;
      if (!cloud.initialized) {
        await cloud.initialize();
      }
      await cloud.signInWithGoogle();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CloudSyncService.instance.userFacingError)),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _retry() async {
    setState(() => busy = true);
    try {
      await CloudSyncService.instance.initialize();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSyncService.instance;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer,
                          scheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      size: 42,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Anna\'s Diary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 31,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Un solo account per agenda, backup, sincronizzazione e Noi ♡.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (cloud.state == CloudConnectionState.error &&
                      !cloud.initialized) ...[
                    SimpleCard(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 34),
                          const SizedBox(height: 8),
                          const Text(
                            'Non riesco a inizializzare l’account.',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: busy ? null : _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: busy || !cloud.configured ? null : _google,
                      icon: busy
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text(
                        'Continua con Google',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CloudAccountScreen(
                                  store: widget.store,
                                ),
                              ),
                            ),
                    child: const Text('Ho già un account email/password'),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'L’account identifica solo te. I contenuti privati restano separati da Noi ♡ e le modifiche offline vengono sincronizzate automaticamente quando torna la rete.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountBindingScreen extends StatefulWidget {
  final AgendaStore store;
  final String userId;

  const _AccountBindingScreen({
    required this.store,
    required this.userId,
  });

  @override
  State<_AccountBindingScreen> createState() => _AccountBindingScreenState();
}

class _AccountBindingScreenState extends State<_AccountBindingScreen> {
  String? error;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration.zero, _bind);
  }

  Future<void> _bind() async {
    try {
      await widget.store.activateCloudAccount(widget.userId);
      await widget.store.syncAllCloud(preferRemoteOnFirstSync: true);
      await PushNotificationService.instance.registerCurrentToken();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync_problem_outlined, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Account connesso, sincronizzazione da completare',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => error = null);
                    _bind();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Preparazione del tuo spazio…'),
          ],
        ),
      ),
    );
  }
}
