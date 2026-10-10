part of '../main.dart';

class AgendaApp extends StatelessWidget {
  final AgendaStore store;
  final bool bypassIdentityForTesting;

  const AgendaApp({
    super.key,
    required this.store,
    this.bypassIdentityForTesting = false,
  });

  static final Map<String, ThemeData> _themeCache = {};

  ThemeData _theme(Brightness brightness) {
    final palette = store.preferences.palette;
    final cacheKey = '${palette.name}:${brightness.name}';
    final cached = _themeCache[cacheKey];
    if (cached != null) return cached;

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Keep interactive Material controls at accessible touch-target size.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF151316) : const Color(0xFFFFFAFC),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: scheme.primaryContainer,
      ),
    );
    _themeCache[cacheKey] = theme;
    return theme;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.shellRevision,
      builder: (context, _) {
        final mode = switch (store.preferences.themeMode) {
          AgendaThemeMode.system => ThemeMode.system,
          AgendaThemeMode.light => ThemeMode.light,
          AgendaThemeMode.dark => ThemeMode.dark,
        };

        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Anna\'s Diary',
          locale: store.preferences.appLanguage.locale,
          supportedLocales: AnnaStrings.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, _) =>
              AnnaStrings.resolveLocale(locale),
          themeMode: mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          builder: (context, child) => FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: _AuthRecoveryGate(
              store: store,
              child: _PrivacyGate(
                store: store,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          home: AgendaRoot(
            store: store,
            bypassIdentityForTesting: bypassIdentityForTesting,
          ),
        );
      },
    );
  }
}

class AgendaRoot extends StatelessWidget {
  final AgendaStore store;
  final bool bypassIdentityForTesting;

  const AgendaRoot({
    super.key,
    required this.store,
    this.bypassIdentityForTesting = false,
  });

  @override
  Widget build(BuildContext context) {
    const integrationTest =
        bool.fromEnvironment('ANNAS_DIARY_INTEGRATION_TEST');
    final bypassIdentity =
        integrationTest || bypassIdentityForTesting;

    return AnimatedBuilder(
      animation: Listenable.merge([
        CloudSyncService.instance,
        store.accountRevision,
        store.shellRevision,
      ]),
      builder: (context, _) {
        final cloud = CloudSyncService.instance;

        if (!bypassIdentity) {
          if (!cloud.initialized &&
              cloud.state != CloudConnectionState.error) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!cloud.signedIn) {
            return UniversalIdentityScreen(store: store);
          }

          final userId = cloud.userId;
          if (userId != null &&
              (!store.accountScopeResolved ||
                  store.activeAccountId != userId)) {
            return _AccountBindingScreen(
              store: store,
              userId: userId,
            );
          }
        } else if (!store.accountScopeResolved) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!store.preferences.onboardingDone) {
          return _OnboardingScreen(store: store);
        }
        return MainShell(store: store);
      },
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  final AgendaStore store;

  const _OnboardingScreen({required this.store});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AnnaStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 36,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                strings.d3('onboardingTitle'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.d3('onboardingDescription'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _OnboardingFeature(
                icon: Icons.bolt_outlined,
                title: strings.d3('quickCapture'),
                subtitle: strings.d3('quickCaptureSubtitle'),
              ),
              const SizedBox(height: 10),
              _OnboardingFeature(
                icon: Icons.favorite_outline,
                title: strings.d3('personalDiary'),
                subtitle: strings.d3('personalDiarySubtitle'),
              ),
              const SizedBox(height: 10),
              _OnboardingFeature(
                icon: Icons.favorite_outline,
                title: strings.d3('privateOrNoi'),
                subtitle: strings.d3('privateDefault'),
              ),
              const SizedBox(height: 10),
              _OnboardingFeature(
                icon: Icons.lock_outline,
                title: strings.d3('optionalPrivacy'),
                subtitle: strings.d3('optionalPrivacySubtitle'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => store.savePreferences(
                    store.preferences.copyWith(onboardingDone: true),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(strings.d3('start')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthRecoveryGate extends StatefulWidget {
  final AgendaStore store;
  final Widget child;

  const _AuthRecoveryGate({
    required this.store,
    required this.child,
  });

  @override
  State<_AuthRecoveryGate> createState() => _AuthRecoveryGateState();
}

class _AuthRecoveryGateState extends State<_AuthRecoveryGate> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool busy = false;
  String? errorText;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final password = passwordController.text;
    if (password.length < 8) {
      setState(() => errorText = AnnaStrings.of(context).d3('passwordMin8'));
      return;
    }
    if (password != confirmController.text) {
      setState(() => errorText = AnnaStrings.of(context).d3('passwordMismatch'));
      return;
    }

    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await CloudSyncService.instance.updateRecoveredPassword(password);
      await widget.store.handleAppResumed();
      if (!mounted) return;
      passwordController.clear();
      confirmController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AnnaStrings.of(context).d3('passwordUpdated')),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorText = error is FormatException
            ? error.message.toString()
            : AnnaStrings.of(context).d3('passwordUpdateFailed');
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CloudSyncService.instance,
      builder: (context, _) {
        if (!CloudSyncService.instance.passwordRecoveryPending) {
          return widget.child;
        }

        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            child: const Icon(Icons.password_outlined),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AnnaStrings.of(context).d3('chooseNewPassword'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AnnaStrings.of(context).d3('recoveryLinkValid'),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            enabled: !busy,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: AnnaStrings.of(context).d3('newPassword'),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: confirmController,
                            obscureText: true,
                            enabled: !busy,
                            onSubmitted: (_) => busy ? null : _savePassword(),
                            decoration: InputDecoration(
                              labelText: AnnaStrings.of(context).d3('repeatPassword'),
                              prefixIcon:
                                  const Icon(Icons.lock_reset_outlined),
                              errorText: errorText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : _savePassword,
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(AnnaStrings.of(context).d3('updatePassword')),
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
      },
    );
  }
}

class _PrivacyGate extends StatefulWidget {
  final AgendaStore store;
  final Widget child;

  const _PrivacyGate({
    required this.store,
    required this.child,
  });

  @override
  State<_PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<_PrivacyGate>
    with WidgetsBindingObserver {
  bool locked = false;
  bool authenticating = false;
  DateTime? backgroundedAt;
  final pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    locked = widget.store.preferences.privacyLockEnabled;
    if (locked && widget.store.preferences.biometricUnlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometricUnlock());
    }
  }

  @override
  void didUpdateWidget(covariant _PrivacyGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.store.preferences.privacyLockEnabled && locked) {
      setState(() => locked = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = widget.store.preferences;

    if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.handleAppResumed());
    }

    if (!prefs.privacyLockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      backgroundedAt ??= DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed && backgroundedAt != null) {
      final minutes = prefs.autoLockMinutes;
      final elapsed = DateTime.now().difference(backgroundedAt!);
      backgroundedAt = null;
      if (minutes == 0 || elapsed >= Duration(minutes: minutes)) {
        setState(() => locked = true);
        if (prefs.biometricUnlock) {
          _biometricUnlock();
        }
      }
    }
  }

  Future<void> _biometricUnlock() async {
    if (!mounted || authenticating || kIsWeb) return;
    final prefs = widget.store.preferences;
    if (!prefs.biometricUnlock || !prefs.privacyLockEnabled) return;

    setState(() => authenticating = true);
    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (!supported || !canCheck) return;
      final ok = await auth.authenticate(
        localizedReason: AnnaStrings.of(context).d3('unlockAnna'),
      );
      if (ok && mounted) {
        setState(() {
          locked = false;
          pinController.clear();
        });
      }
    } catch (_) {
      // Il PIN resta sempre disponibile come fallback.
    } finally {
      if (mounted) setState(() => authenticating = false);
    }
  }

  void _unlockWithPin() {
    if (widget.store.verifyPin(pinController.text)) {
      setState(() {
        locked = false;
        pinController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AnnaStrings.of(context).d3('incorrectPin'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.store.preferences.privacyLockEnabled || !locked) {
      return widget.child;
    }

    final prefs = widget.store.preferences;
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (overlayContext) => Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline, size: 54),
                        const SizedBox(height: 16),
                        Text(
                          AnnaStrings.of(overlayContext).d3('agendaLocked'),
                          style: Theme.of(overlayContext)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AnnaStrings.of(overlayContext).d3('enterPin'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: pinController,
                          autofocus: !prefs.biometricUnlock,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _unlockWithPin(),
                          decoration: const InputDecoration(
                            labelText: 'PIN',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _unlockWithPin,
                            child: Text(AnnaStrings.of(overlayContext).d3('unlock')),
                          ),
                        ),
                        if (prefs.biometricUnlock && !kIsWeb) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed:
                                authenticating ? null : _biometricUnlock,
                            icon: const Icon(Icons.fingerprint),
                            label: Text(
                              authenticating
                                  ? AnnaStrings.of(overlayContext).d3('verifying')
                                  : AnnaStrings.of(overlayContext).d3('useBiometric'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
