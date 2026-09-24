part of '../../main.dart';

const bool _environmentAuthGateBypass = bool.fromEnvironment(
  'ANNAS_DIARY_APPLAB_AUTH_BYPASS',
  defaultValue: false,
);

class _UniversalAuthGate extends StatefulWidget {
  final AgendaStore store;
  final Widget child;
  final bool bypass;

  const _UniversalAuthGate({
    required this.store,
    required this.child,
    this.bypass = false,
  });

  @override
  State<_UniversalAuthGate> createState() => _UniversalAuthGateState();
}

class _UniversalAuthGateState extends State<_UniversalAuthGate> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool legacyExpanded = false;
  bool activationScheduled = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _scheduleActivation() {
    final cloud = CloudSyncService.instance;
    final uid = cloud.userId;
    if (widget.bypass || _environmentAuthGateBypass ||
        !cloud.signedIn ||
        uid == null ||
        activationScheduled ||
        (widget.store.accountScopeResolved &&
            widget.store.activeAccountId == uid)) {
      return;
    }
    activationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _activateSignedInAccount();
      } finally {
        activationScheduled = false;
      }
    });
  }

  Future<void> _activateSignedInAccount() async {
    final cloud = CloudSyncService.instance;
    final uid = cloud.userId;
    if (uid == null) return;

    if (mounted) {
      setState(() {
        busy = true;
        errorText = null;
      });
    }

    try {
      await widget.store.activateCloudAccount(uid);
      await widget.store.syncAllCloud(preferRemoteOnFirstSync: true);
      await PushNotificationService.instance.registerCurrentToken();
    } catch (_) {
      if (mounted) {
        setState(() => errorText = cloud.userFacingError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _retryCloudInitialization() async {
    if (busy) return;
    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await CloudSyncService.instance.initialize();
      await widget.store.initializeCloudSync();
    } catch (_) {
      if (mounted) {
        setState(() => errorText = CloudSyncService.instance.userFacingError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await CloudSyncService.instance.signInWithGoogle();
      if (CloudSyncService.instance.signedIn) {
        await _activateSignedInAccount();
      }
    } catch (_) {
      if (mounted) {
        setState(() => errorText = CloudSyncService.instance.userFacingError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _legacySignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!email.contains('@') || password.length < 6) {
      setState(
        () => errorText = 'Inserisci email e password del vecchio account.',
      );
      return;
    }

    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await CloudSyncService.instance.signIn(email: email, password: password);
      await _activateSignedInAccount();
    } catch (_) {
      if (mounted) {
        setState(() => errorText = CloudSyncService.instance.userFacingError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (!email.contains('@')) {
      setState(
        () => errorText = 'Inserisci prima l’email del vecchio account.',
      );
      return;
    }
    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await CloudSyncService.instance.requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se l’account esiste, riceverai una mail per reimpostare la password.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => errorText = CloudSyncService.instance.userFacingError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _brandLoading(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      size: 39,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cloud = CloudSyncService.instance;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primaryContainer,
                            scheme.secondaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Icon(
                        Icons.auto_stories_outlined,
                        size: 38,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Anna’s Diary',
                    style: TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Un solo account per agenda, backup, dispositivi e Noi ♡. '
                    'Dopo il primo accesso la sessione resta memorizzata e i dati '
                    'continuano a funzionare anche offline.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: busy || !cloud.configured
                          ? null
                          : _googleSignIn,
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Continua con Google',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: TextStyle(color: scheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Il tuo account identifica anche le modifiche condivise in Noi ♡. '
                    'I contenuti privati restano separati dai contenuti condivisi.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () =>
                              setState(() => legacyExpanded = !legacyExpanded),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text(
                      legacyExpanded
                          ? 'Nascondi accesso account precedente'
                          : 'Hai già un account email/password?',
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: legacyExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: emailController,
                              enabled: !busy,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email account precedente',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: passwordController,
                              enabled: !busy,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _legacySignIn(),
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: busy ? null : _legacySignIn,
                                icon: const Icon(Icons.login),
                                label: const Text('Accedi al vecchio account'),
                              ),
                            ),
                            TextButton(
                              onPressed: busy ? null : _forgotPassword,
                              child: const Text('Password dimenticata'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bypass || _environmentAuthGateBypass) return widget.child;

    final cloud = CloudSyncService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([cloud, widget.store.accountRevision]),
      builder: (context, _) {
        if (!cloud.initialized) {
          if (cloud.state == CloudConnectionState.error &&
              widget.store.activeAccountId != null &&
              widget.store.accountScopeResolved) {
            return widget.child;
          }
          if (cloud.state == CloudConnectionState.error) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 54),
                          const SizedBox(height: 16),
                          const Text(
                            'Serve Internet per il primo accesso',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dopo aver collegato il tuo account una volta, '
                            'Anna’s Diary continuerà ad aprirsi anche offline.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: busy ? null : _retryCloudInitialization,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return _brandLoading(context, 'Preparazione del tuo account…');
        }

        if (cloud.state == CloudConnectionState.initializing) {
          return _brandLoading(context, 'Preparazione del tuo account…');
        }

        if (!cloud.signedIn) {
          return _signInScreen(context);
        }

        _scheduleActivation();
        if (!widget.store.accountScopeResolved ||
            widget.store.activeAccountId != cloud.userId ||
            busy) {
          return _brandLoading(
            context,
            'Allineamento del tuo spazio personale…',
          );
        }

        return widget.child;
      },
    );
  }
}
