part of '../../main.dart';

class PrivateVaultHomeCard extends StatefulWidget {
  final AgendaStore store;

  const PrivateVaultHomeCard({
    super.key,
    required this.store,
  });

  @override
  State<PrivateVaultHomeCard> createState() => _PrivateVaultHomeCardState();
}

class _PrivateVaultHomeCardState extends State<PrivateVaultHomeCard> {
  final vault = PrivateVaultService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(vault.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vault,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final configured = vault.configured;
        return Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PrivateVaultScreen(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.lock_person_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cassaforte privata',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          configured
                              ? 'Cifrata sul dispositivo · accesso protetto'
                              : 'Crea uno spazio locale cifrato solo per te',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    configured
                        ? Icons.verified_user_outlined
                        : Icons.chevron_right,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PrivateVaultScreen extends StatefulWidget {
  const PrivateVaultScreen({super.key});

  @override
  State<PrivateVaultScreen> createState() => _PrivateVaultScreenState();
}

class _PrivateVaultScreenState extends State<PrivateVaultScreen>
    with WidgetsBindingObserver {
  final vault = PrivateVaultService.instance;
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = true;
  bool busy = false;
  bool biometricSupported = false;
  bool enableBiometric = true;
  bool obscurePassword = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(vault.setSecureScreen(true));
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await vault.initialize();
    if (!kIsWeb) {
      try {
        final auth = LocalAuthentication();
        final supported = await auth.isDeviceSupported();
        final canCheck = await auth.canCheckBiometrics;
        biometricSupported = supported && canCheck;
      } catch (_) {
        biometricSupported = false;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      vault.lock();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    vault.lock();
    unawaited(vault.setSecureScreen(false));
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    final password = passwordController.text;
    if (password.length < 8) {
      setState(() => errorText = 'Usa almeno 8 caratteri.');
      return;
    }
    if (password != confirmController.text) {
      setState(() => errorText = 'Le password non coincidono.');
      return;
    }

    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await vault.setup(
        password: password,
        enableBiometric: enableBiometric && biometricSupported,
      );
      passwordController.clear();
      confirmController.clear();
      if (mounted) setState(() {});
    } on FormatException catch (error) {
      if (mounted) setState(() => errorText = error.message.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => errorText =
              'Non è stato possibile creare la cassaforte. Riprova.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _unlockPassword() async {
    if (passwordController.text.isEmpty) return;
    setState(() {
      busy = true;
      errorText = null;
    });
    final ok = await vault.unlockWithPassword(passwordController.text);
    passwordController.clear();
    if (!mounted) return;
    setState(() {
      busy = false;
      if (!ok) errorText = 'Password non corretta.';
    });
  }

  Future<void> _unlockBiometric() async {
    if (!biometricSupported || !vault.biometricAvailable) return;
    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      final auth = LocalAuthentication();
      final authenticated = await auth.authenticate(
        localizedReason: 'Sblocca la cassaforte privata di Anna\'s Diary',
      );
      if (!authenticated) return;
      final ok = await vault.unlockWithBiometricKey();
      if (!ok && mounted) {
        setState(
          () => errorText =
              'Sblocco biometrico non disponibile. Usa la password.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => errorText =
              'Biometria non disponibile. Usa la password.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _showEditor([PrivateVaultEntry? entry]) async {
    final title = TextEditingController(text: entry?.title ?? '');
    final body = TextEditingController(text: entry?.body ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry == null ? 'Nuovo contenuto privato' : 'Modifica'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                minLines: 5,
                maxLines: 12,
                maxLength: 12000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Contenuto privato',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await vault.upsert(
          id: entry?.id,
          title: title.text,
          body: body.text,
        );
      } on FormatException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message.toString())),
          );
        }
      }
    }
    title.dispose();
    body.dispose();
  }

  Future<void> _delete(PrivateVaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare dalla cassaforte?'),
        content: Text(
          entry.title.isEmpty
              ? 'Il contenuto verrà eliminato definitivamente.'
              : '“${entry.title}” verrà eliminato definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vault.delete(entry.id);
    }
  }

  Future<void> _destroyVault() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina cassaforte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tutti i contenuti cifrati verranno eliminati definitivamente. '
              'Inserisci la password della cassaforte per confermare.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Password cassaforte',
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
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text),
            child: const Text('Elimina definitivamente'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return;

    final ok = await vault.unlockWithPassword(password);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password non corretta.')),
        );
      }
      return;
    }
    await vault.destroy();
    if (mounted) {
      setState(() {
        passwordController.clear();
        confirmController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vault,
      builder: (context, _) {
        if (loading || !vault.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!vault.configured) return _buildSetup(context);
        if (!vault.unlocked) return _buildLocked(context);
        return _buildUnlocked(context);
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cassaforte privata')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: const Icon(Icons.lock_person_outlined, size: 30),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Uno spazio solo tuo',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I contenuti della cassaforte vengono cifrati prima di '
                        'essere salvati sul dispositivo. Non entrano nel cloud, '
                        'in Noi ♡, nella ricerca o nei backup normali.',
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        enabled: !busy,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Password cassaforte',
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        enabled: !busy,
                        onSubmitted: (_) => busy ? null : _setup(),
                        decoration: InputDecoration(
                          labelText: 'Ripeti password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: errorText,
                        ),
                      ),
                      if (biometricSupported) ...[
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: enableBiometric,
                          onChanged: busy
                              ? null
                              : (value) =>
                                  setState(() => enableBiometric = value),
                          title: const Text('Sblocco con impronta/biometria'),
                          subtitle: const Text(
                            'La password resta sempre disponibile come recupero.',
                          ),
                          secondary: const Icon(Icons.fingerprint),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: busy ? null : _setup,
                          icon: const Icon(Icons.shield_outlined),
                          label: Text(
                            busy ? 'Creazione…' : 'Crea cassaforte',
                          ),
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
  }

  Widget _buildLocked(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cassaforte privata'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'destroy') unawaited(_destroyVault());
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'destroy',
                child: Text('Elimina cassaforte'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 44,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cassaforte bloccata',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Il contenuto resta cifrato finché non la sblocchi.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !busy,
                    autofocus: !vault.biometricAvailable,
                    onSubmitted: (_) => busy ? null : _unlockPassword(),
                    decoration: InputDecoration(
                      labelText: 'Password cassaforte',
                      prefixIcon: const Icon(Icons.password_outlined),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _unlockPassword,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Sblocca'),
                    ),
                  ),
                  if (biometricSupported && vault.biometricAvailable) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _unlockBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Usa impronta/biometria'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlocked(BuildContext context) {
    final entries = vault.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cassaforte privata'),
        actions: [
          if (biometricSupported && !vault.biometricAvailable)
            IconButton(
              tooltip: 'Attiva biometria',
              onPressed: () async {
                final ok = await vault.enableBiometricForCurrentKey();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Sblocco biometrico attivato.'
                          : 'Biometria non disponibile.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fingerprint),
            ),
          IconButton(
            tooltip: 'Blocca adesso',
            onPressed: () {
              vault.lock();
              setState(() {});
            },
            icon: const Icon(Icons.lock_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'destroy') unawaited(_destroyVault());
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'destroy',
                child: Text('Elimina cassaforte'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo'),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 58),
                    SizedBox(height: 14),
                    Text(
                      'La cassaforte è vuota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aggiungi note e informazioni che vuoi tenere separate dal resto dell’app.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.lock_outline),
                    ),
                    title: Text(
                      entry.title.isEmpty ? 'Contenuto privato' : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      entry.body.isEmpty
                          ? DateFormat('d MMM yyyy · HH:mm', 'it_IT')
                              .format(entry.updatedAt)
                          : entry.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showEditor(entry),
                    trailing: IconButton(
                      tooltip: 'Elimina',
                      onPressed: () => _delete(entry),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
