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
    final prefs = store.preferences;
    final seed = prefs.effectiveSeedColor;
    final expressive = prefs.colorIntensity == AgendaColorIntensity.expressive;
    final cacheKey = '${seed.toARGB32()}:${prefs.colorIntensity.name}:${brightness.name}';
    final cached = _themeCache[cacheKey];
    if (cached != null) return cached;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;

    final theme = AnnaJournalTheme.apply(ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Keep interactive Material controls at accessible touch-target size.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: expressive
            ? Color.lerp(scheme.surfaceContainerLow, scheme.primaryContainer, dark ? 0.22 : 0.30)!
            : dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusLg),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.42 : 0.55),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusMd),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: expressive
            ? scheme.secondaryContainer
            : scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AnnaDesignTokens.radiusHero),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusMd),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusSm),
        ),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
    ));
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
    final bypassIdentity = bypassIdentityForTesting;

    return AnimatedBuilder(
      animation: Listenable.merge([
        CloudSyncService.instance,
        store.accountRevision,
        store.shellRevision,
      ]),
      builder: (context, _) {
        final cloud = CloudSyncService.instance;

        if (!store.accountScopeResolved) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final webAccountDeletionFlow = kIsWeb &&
            Uri.base.queryParameters['account'] == 'delete';

        if (!bypassIdentity) {
          if (cloud.signedIn) {
            final userId = cloud.userId;
            if (userId != null && store.activeAccountId != userId) {
              return _AccountBindingScreen(
                store: store,
                userId: userId,
              );
            }
          } else if (!webAccountDeletionFlow &&
              store.activeAccountId == null &&
              !store.localEntrySelected) {
            return UniversalIdentityScreen(store: store);
          }
        }

        if (webAccountDeletionFlow) {
          return CloudAccountScreen(store: store);
        }

        if (!store.preferences.onboardingDone) {
          return _OnboardingScreen(store: store);
        }
        return MainShell(store: store);
      },
    );
  }
}

class _OnboardingScreen extends StatefulWidget {
  final AgendaStore store;

  const _OnboardingScreen({required this.store});

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  int step = 0;
  PersonalizationPreset selectedPreset = PersonalizationPreset.life;
  bool busy = false;

  Future<void> _persistCompletion() async {
    var next = widget.store.preferences.copyWith(onboardingDone: true);
    next = next.applyPersonalizationPreset(selectedPreset);
    await widget.store.savePreferences(next);
  }

  Future<void> _finish() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await _persistCompletion();
    } finally {
      if (mounted && !widget.store.preferences.onboardingDone) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _captureFirstMoment() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await showUnifiedCapture(
        context,
        widget.store,
        entryPoint: UnifiedCaptureEntryPoint.home,
      );
      if (!mounted) return;
      await _persistCompletion();
    } finally {
      if (mounted && !widget.store.preferences.onboardingDone) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step == 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        key: const ValueKey('onboarding-back'),
                        onPressed: busy ? null : () => setState(() => step = 0),
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    )
                  else
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
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: step == 0 ? 0.5 : 1),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: AnnaDesignTokens.animationsEnabled(context)
                        ? AnnaDesignTokens.motionStandard
                        : Duration.zero,
                    child: step == 0
                        ? _buildPresetStep(context, strings)
                        : _buildFirstActionStep(context, strings),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetStep(
    BuildContext context,
    AnnaStrings strings,
  ) {
    return Column(
      key: const ValueKey('onboarding-preset-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            strings.d3('onboardingTitle'),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.d3('onboardingPresetIntro'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _OnboardingPresetCard(
          key: const ValueKey('onboarding-preset-essential'),
          semanticsId: 'onboarding_preset_essential',
          selected: selectedPreset == PersonalizationPreset.essential,
          icon: Icons.filter_alt_outlined,
          title: strings.d3('onboardingPresetEssentialTitle'),
          subtitle: strings.d3('onboardingPresetEssentialSubtitle'),
          onTap: busy
              ? null
              : () => setState(
                    () => selectedPreset = PersonalizationPreset.essential,
                  ),
        ),
        const SizedBox(height: 12),
        _OnboardingPresetCard(
          key: const ValueKey('onboarding-preset-life'),
          semanticsId: 'onboarding_preset_life',
          selected: selectedPreset == PersonalizationPreset.life,
          icon: Icons.auto_awesome_outlined,
          title: strings.d3('onboardingPresetLifeTitle'),
          subtitle: strings.d3('onboardingPresetLifeSubtitle'),
          badge: strings.d3('onboardingRecommended'),
          onTap: busy
              ? null
              : () => setState(
                    () => selectedPreset = PersonalizationPreset.life,
                  ),
        ),
        const SizedBox(height: 12),
        _OnboardingPresetCard(
          key: const ValueKey('onboarding-preset-complete'),
          semanticsId: 'onboarding_preset_complete',
          selected: selectedPreset == PersonalizationPreset.complete,
          icon: Icons.dashboard_customize_outlined,
          title: strings.d3('onboardingPresetCompleteTitle'),
          subtitle: strings.d3('onboardingPresetCompleteSubtitle'),
          onTap: busy
              ? null
              : () => setState(
                    () => selectedPreset = PersonalizationPreset.complete,
                  ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.d3('onboardingChangeLater'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Semantics(
          identifier: 'onboarding_continue',
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('onboarding-continue'),
              onPressed: busy ? null : () => setState(() => step = 1),
              icon: const Icon(Icons.arrow_forward),
              label: Text(strings.d3('onboardingContinue')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFirstActionStep(
    BuildContext context,
    AnnaStrings strings,
  ) {
    return Column(
      key: const ValueKey('onboarding-first-action-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            strings.d3('onboardingFirstActionTitle'),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          strings.d3('onboardingFirstActionSubtitle'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 26),
        Semantics(
          identifier: 'onboarding_first_capture',
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('onboarding-first-capture'),
              onPressed: busy ? null : _captureFirstMoment,
              icon: const Icon(Icons.add_circle_outline),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.d3('onboardingCaptureFirst')),
                    const SizedBox(height: 2),
                    Text(
                      strings.d3('onboardingCaptureFirstSubtitle'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          identifier: 'onboarding_open_agenda',
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('onboarding-open-agenda'),
              onPressed: busy ? null : _finish,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.today_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.d3('onboardingOpenAgenda')),
                    const SizedBox(height: 2),
                    Text(
                      strings.d3('onboardingOpenAgendaSubtitle'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPresetCard extends StatelessWidget {
  final String semanticsId;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _OnboardingPresetCard({
    super.key,
    required this.semanticsId,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final semanticLabel = badge == null
        ? '$title. $subtitle'
        : '$title. $badge. $subtitle';

    return Semantics(
      identifier: semanticsId,
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: selected ? scheme.primaryContainer : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    foregroundColor:
                        selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    child: Icon(icon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            if (badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    color: scheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
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
            ? AnnaStrings.of(context).cloudServiceError(error)
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
    final unlockReason = AnnaStrings.of(context).d3('unlockAnna');

    setState(() => authenticating = true);
    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (!supported || !canCheck) return;
      final ok = await auth.authenticate(
        localizedReason: unlockReason,
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
