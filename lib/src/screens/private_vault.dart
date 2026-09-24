part of '../../main.dart';

class PrivateVaultScreen extends StatefulWidget {
  final String scope;

  const PrivateVaultScreen({
    super.key,
    required this.scope,
  });

  @override
  State<PrivateVaultScreen> createState() => _PrivateVaultScreenState();
}

class _PrivateVaultScreenState extends State<PrivateVaultScreen>
    with WidgetsBindingObserver {
  final PrivateVaultService vault = PrivateVaultService.instance;
  final setupSecretController = TextEditingController();
  final setupConfirmController = TextEditingController();
  final unlockController = TextEditingController();

  bool preparing = true;
  bool busy = false;
  bool biometricAvailable = false;
  bool requestBiometricsOnSetup = true;
  bool obscureSecret = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.delayed(Duration.zero, _prepare);
  }

  @override
  void didUpdateWidget(covariant PrivateVaultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) {
      Future<void>.delayed(Duration.zero, _prepare);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      vault.lock();
    }
  }

  Future<void> _prepare() async {
    if (mounted) {
      setState(() {
        preparing = true;
        errorText = null;
      });
    }
    await vault.selectScope(widget.scope);
    final canUseBiometrics = await vault.canUseBiometrics();
    if (!mounted) return;
    setState(() {
      biometricAvailable = canUseBiometrics;
      requestBiometricsOnSetup = canUseBiometrics;
      preparing = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    vault.lock();
    setupSecretController.dispose();
    setupConfirmController.dispose();
    unlockController.dispose();
    super.dispose();
  }

  void _setError(String? value) {
    if (!mounted) return;
    setState(() => errorText = value);
  }

  Future<void> _setup() async {
    final secret = setupSecretController.text;
    final validation = PrivateVaultService.validateSecret(secret);
    if (validation != null) {
      _setError(validation);
      return;
    }
    if (secret.trim() != setupConfirmController.text.trim()) {
      _setError('Le due password non coincidono.');
      return;
    }

    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await vault.setupVault(
        secret,
        enableBiometrics:
            biometricAvailable && requestBiometricsOnSetup,
      );
      setupSecretController.clear();
      setupConfirmController.clear();
    } on FormatException catch (error) {
      _setError(error.message.toString());
    } catch (_) {
      _setError('Non è stato possibile creare la cassaforte.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _unlockWithSecret() async {
    if (unlockController.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await vault.unlockWithSecret(unlockController.text);
      unlockController.clear();
    } on VaultUnlockException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Impossibile sbloccare la cassaforte.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      busy = true;
      errorText = null;
    });
    final unlocked = await vault.unlockWithBiometrics();
    if (!unlocked) {
      _setError(
        'Sblocco biometrico non riuscito. Usa il codice/password della cassaforte.',
      );
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _editEntry([VaultEntry? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');

    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 18,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Nuovo elemento privato' : 'Modifica elemento',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                minLines: 5,
                maxLines: 12,
                maxLength: 10000,
                decoration: const InputDecoration(
                  labelText: 'Contenuto',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        (
                          titleController.text,
                          bodyController.text,
                        ),
                      ),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Salva cifrato'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    titleController.dispose();
    bodyController.dispose();
    if (result == null || !mounted) return;

    try {
      await vault.upsertEntry(
        existing: existing,
        title: result.$1,
        body: result.$2,
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    }
  }

  Future<void> _deleteEntry(VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare questo elemento?'),
            content: Text(
              entry.title.isEmpty
                  ? 'Il contenuto verrà rimosso definitivamente dalla cassaforte.'
                  : '“${entry.title}” verrà rimosso definitivamente dalla cassaforte.',
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
        ) ??
        false;
    if (confirmed) await vault.deleteEntry(entry.id);
  }

  Future<void> _showSettings() async {
    if (!vault.unlocked) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: CircleAvatar(child: Icon(Icons.shield_outlined)),
                title: Text(
                  'Sicurezza cassaforte',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Il contenuto resta cifrato sul dispositivo e non entra nel backup standard.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Cambia codice/password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _changeSecret();
                },
              ),
              if (biometricAvailable)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Sblocco con impronta/biometria'),
                  subtitle: const Text(
                    'La chiave resta protetta dal Keystore Android.',
                  ),
                  value: vault.biometricEnabled,
                  onChanged: (enabled) async {
                    Navigator.pop(sheetContext);
                    await _toggleBiometrics(enabled);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Elimina cassaforte',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _destroyVault();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    setState(() {
      busy = true;
      errorText = null;
    });
    try {
      await vault.setBiometricEnabled(enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Sblocco biometrico attivato.'
                : 'Sblocco biometrico disattivato.',
          ),
        ),
      );
    } on VaultUnlockException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Non è stato possibile aggiornare la biometria.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _changeSecret() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambia codice/password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Codice/password attuale',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nuovo codice/password',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ripeti nuovo codice/password',
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
              if (next.text.trim() != confirm.text.trim()) return;
              Navigator.pop(
                dialogContext,
                (current.text, next.text),
              );
            },
            child: const Text('Aggiorna'),
          ),
        ],
      ),
    );

    current.dispose();
    next.dispose();
    confirm.dispose();
    if (values == null) return;

    try {
      await vault.changeSecret(values.$1, values.$2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codice/password aggiornato.')),
      );
    } on FormatException catch (error) {
      _setError(error.message.toString());
    } on VaultUnlockException catch (error) {
      _setError(error.message);
    }
  }

  Future<void> _destroyVault() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare la cassaforte?'),
            content: const Text(
              'Tutti i contenuti cifrati verranno eliminati definitivamente da questo dispositivo. Questa operazione non è annullabile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina tutto'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await vault.destroyVault();
    setupSecretController.clear();
    setupConfirmController.clear();
    unlockController.clear();
    _setError(null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vault,
      builder: (context, _) {
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) vault.lock();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Cassaforte privata',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                if (vault.unlocked) ...[
                  IconButton(
                    tooltip: 'Sicurezza',
                    onPressed: busy ? null : _showSettings,
                    icon: const Icon(Icons.shield_outlined),
                  ),
                  IconButton(
                    tooltip: 'Blocca',
                    onPressed: () => vault.lock(),
                    icon: const Icon(Icons.lock_outline),
                  ),
                ],
              ],
            ),
            floatingActionButton: vault.unlocked
                ? FloatingActionButton.extended(
                    onPressed: busy ? null : () => _editEntry(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuovo'),
                  )
                : null,
            body: preparing || vault.loading
                ? const Center(child: CircularProgressIndicator())
                : vault.storageError != null
                    ? _VaultStorageError(message: vault.storageError!)
                    : !vault.configured
                        ? _buildSetup(context)
                        : !vault.unlocked
                            ? _buildLocked(context)
                            : _buildUnlocked(context),
          ),
        );
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.lock_person_outlined,
              size: 42,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Crea la tua cassaforte',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        const SizedBox(height: 8),
        const Text(
          'Note e informazioni sensibili vengono cifrate con AES-256-GCM e restano solo su questo dispositivo. Non vengono sincronizzate con Noi ♡ o con il cloud.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: setupSecretController,
          obscureText: obscureSecret,
          enabled: !busy,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'PIN o password privata',
            prefixIcon: const Icon(Icons.password_outlined),
            suffixIcon: IconButton(
              onPressed: () => setState(() => obscureSecret = !obscureSecret),
              icon: Icon(
                obscureSecret
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: setupConfirmController,
          obscureText: obscureSecret,
          enabled: !busy,
          onSubmitted: (_) => busy ? null : _setup(),
          decoration: const InputDecoration(
            labelText: 'Ripeti PIN/password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        if (biometricAvailable) ...[
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Usa anche impronta/biometria'),
            subtitle: const Text(
              'Dopo il primo accesso potrai sbloccare più velocemente.',
            ),
            value: requestBiometricsOnSetup,
            onChanged: busy
                ? null
                : (value) =>
                    setState(() => requestBiometricsOnSetup = value),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: TextStyle(color: scheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: busy ? null : _setup,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock),
          label: const Text('Crea cassaforte cifrata'),
        ),
        const SizedBox(height: 14),
        const _VaultSecurityNotice(),
      ],
    );
  }

  Widget _buildLocked(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 42),
        const Icon(Icons.lock_rounded, size: 72),
        const SizedBox(height: 18),
        const Text(
          'Cassaforte bloccata',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        const SizedBox(height: 8),
        const Text(
          'I contenuti non vengono decifrati finché non ti autentichi.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        TextField(
          controller: unlockController,
          obscureText: true,
          enabled: !busy,
          autofocus: !vault.biometricEnabled,
          onSubmitted: (_) => busy ? null : _unlockWithSecret(),
          decoration: const InputDecoration(
            labelText: 'PIN o password privata',
            prefixIcon: Icon(Icons.password_outlined),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: TextStyle(color: scheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : _unlockWithSecret,
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Sblocca'),
        ),
        if (vault.biometricEnabled && biometricAvailable) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : _unlockWithBiometrics,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Usa impronta/biometria'),
          ),
        ],
        const SizedBox(height: 18),
        const _VaultSecurityNotice(),
      ],
    );
  }

  Widget _buildUnlocked(BuildContext context) {
    final entries = vault.entries;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFEDE7F6)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              CircleAvatar(child: Icon(Icons.verified_user_outlined)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sbloccata solo in memoria',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Si blocca uscendo dalla sezione o mandando l’app in background.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 54, horizontal: 20),
            child: Column(
              children: [
                Icon(Icons.note_add_outlined, size: 52),
                SizedBox(height: 14),
                Text(
                  'La cassaforte è vuota',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                SizedBox(height: 6),
                Text(
                  'Aggiungi password, codici, pensieri o qualsiasi informazione che vuoi tenere separata dal resto dell’agenda.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  leading: const CircleAvatar(
                    child: Icon(Icons.note_alt_outlined),
                  ),
                  title: Text(
                    entry.title.isEmpty ? 'Nota privata' : entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        'Aggiornato ${DateFormat('d MMM, HH:mm', 'it_IT').format(entry.updatedAt.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () => _editEntry(entry),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editEntry(entry);
                      } else if (value == 'delete') {
                        _deleteEntry(entry);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifica'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Elimina'),
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

class _VaultSecurityNotice extends StatelessWidget {
  const _VaultSecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.phonelink_lock_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Solo locale • cifratura autenticata • esclusa dal cloud, da Noi ♡ e dai backup standard.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultStorageError extends StatelessWidget {
  final String message;

  const _VaultStorageError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Cassaforte non leggibile',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
