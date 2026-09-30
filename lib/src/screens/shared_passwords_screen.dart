part of '../../main.dart';

class SharedPasswordsScreen extends StatefulWidget {
  final SharedSpace space;

  const SharedPasswordsScreen({
    super.key,
    required this.space,
  });

  @override
  State<SharedPasswordsScreen> createState() => _SharedPasswordsScreenState();
}

class _SharedPasswordsScreenState extends State<SharedPasswordsScreen>
    with WidgetsBindingObserver {
  final SharedPasswordService service = SharedPasswordService.instance;
  final PrivateVaultService vault = PrivateVaultService.instance;

  bool loading = true;
  String? errorText;
  List<SharedPasswordCredential> credentials = const [];
  Timer? _realtimeDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(vault.setSecureScreen(true));
    unawaited(_initialize());
    _bindRealtime();
  }

  Future<void> _initialize() async {
    await vault.initialize();
    await _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      vault.lock();
      if (mounted) {
        setState(() {
          credentials = const [];
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeDebounce?.cancel();
    unawaited(
      CloudSyncService.instance.unsubscribeSharedSpace(
        spaceId: widget.space.id,
        listenerKey: 'shared-passwords',
      ),
    );
    unawaited(vault.setSecureScreen(false));
    super.dispose();
  }

  void _bindRealtime() {
    if (!CloudSyncService.instance.signedIn) return;
    CloudSyncService.instance.subscribeSharedSpace(
      spaceId: widget.space.id,
      listenerKey: 'shared-passwords',
      onChanged: () {},
      onRecordChanged: (change) {
        if (change.entityType != 'shared_credential' &&
            change.entityType != 'shared_password_key_envelope') {
          return;
        }
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(milliseconds: 180), () {
          if (mounted) unawaited(_refresh(silent: true));
        });
      },
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
        errorText = null;
      });
    }
    try {
      if (!vault.initialized) await vault.initialize();
      if (!vault.unlocked || !CloudSyncService.instance.signedIn) {
        if (mounted) {
          setState(() {
            credentials = const [];
            loading = false;
          });
        }
        return;
      }

      await service.reconcileMembership();
      if (widget.space.isOwner && !service.hasKey(widget.space.id)) {
        await service.ensureOwnerKey(widget.space.id);
      }

      final next = service.hasKey(widget.space.id)
          ? await service.refreshSpace(widget.space.id)
          : const <SharedPasswordCredential>[];
      if (mounted) {
        setState(() {
          credentials = next;
          loading = false;
          errorText = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
          errorText = error.toString();
        });
      }
    }
  }

  Future<void> _openVault() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivateVaultScreen(),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _importPairingCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collega Password Noi ♡'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Inserisci il codice di sicurezza generato dal proprietario. '
              'Serve una sola volta per ricevere la chiave E2EE.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codice di sicurezza',
                prefixIcon: Icon(Icons.key_outlined),
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
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Collega'),
          ),
        ],
      ),
    );
    controller.clear();
    controller.dispose();
    if (code == null || code.trim().isEmpty) return;

    setState(() => loading = true);
    final ok = await service.importPairingCode(
      spaceId: widget.space.id,
      code: code,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => loading = false);
      _message('Codice non valido, scaduto o già usato.');
      return;
    }
    await _refresh();
  }

  Future<void> _showPairingCode() async {
    try {
      final code = await service.createPairingCode(widget.space.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Codice Password Noi ♡'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Condividilo solo con una persona già membro di Noi ♡. '
                'Scade dopo 15 minuti e viene invalidato al primo uso.',
              ),
              const SizedBox(height: 18),
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Codice copiato negli appunti.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copia codice'),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
    } catch (_) {
      _message('Impossibile generare il codice di sicurezza.');
    }
  }

  Future<void> _showEditor([SharedPasswordCredential? existing]) async {
    final serviceController =
        TextEditingController(text: existing?.service ?? '');
    final usernameController =
        TextEditingController(text: existing?.username ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final passwordController =
        TextEditingController(text: existing?.password ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var revealPassword = false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'Nuova password condivisa'
                : 'Modifica password condivisa',
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: serviceController,
                      autofocus: true,
                      maxLength: 160,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome servizio',
                        hintText: 'Es. Netflix, Google, Amazon',
                        prefixIcon: Icon(Icons.apps_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      maxLength: 320,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Nome utente',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      maxLength: 320,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: !revealPassword,
                      autofillHints: const [AutofillHints.password],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: IconButton(
                          tooltip: revealPassword
                              ? 'Nascondi password'
                              : 'Mostra password',
                          onPressed: () => setDialogState(
                            () => revealPassword = !revealPassword,
                          ),
                          icon: Icon(
                            revealPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 7,
                      maxLength: 12000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
    );

    if (save == true) {
      try {
        await service.upsertCredential(
          spaceId: widget.space.id,
          credentialId: existing?.id,
          service: serviceController.text,
          username: usernameController.text,
          email: emailController.text,
          password: passwordController.text,
          notes: notesController.text,
        );
        await _refresh(silent: true);
      } on FormatException catch (error) {
        _message(error.message.toString());
      } catch (_) {
        _message('Salvataggio non riuscito. Controlla la connessione.');
      }
    }

    serviceController.clear();
    usernameController.clear();
    emailController.clear();
    passwordController.clear();
    notesController.clear();
    serviceController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    notesController.dispose();
  }

  Future<void> _delete(SharedPasswordCredential credential) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare la password condivisa?'),
            content: Text(
              '“${credential.service}” verrà eliminata da Noi ♡ e dalle '
              'Cassaforti private sincronizzate.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina definitivamente'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await service.deleteCredential(
        spaceId: widget.space.id,
        credentialId: credential.id,
      );
      await _refresh(silent: true);
    } catch (_) {
      _message('Eliminazione non riuscita. Controlla la connessione.');
    }
  }

  Future<void> _copySensitive(String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    _message('$label copiato. Gli appunti verranno svuotati automaticamente.');
    unawaited(
      Future<void>.delayed(const Duration(seconds: 30), () async {
        try {
          final current = await Clipboard.getData('text/plain');
          if (current?.text == value) {
            await Clipboard.setData(const ClipboardData(text: ''));
          }
        } catch (_) {}
      }),
    );
  }

  Future<void> _showDetails(SharedPasswordCredential credential) async {
    var revealPassword = false;
    final edit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Widget field(
            String label,
            String value, {
            bool secret = false,
          }) {
            final shown = value.isEmpty
                ? '—'
                : secret && !revealPassword
                    ? '••••••••'
                    : value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                label,
                style: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              subtitle: SelectableText(shown),
              trailing: value.isEmpty
                  ? null
                  : Wrap(
                      spacing: 2,
                      children: [
                        if (secret)
                          IconButton(
                            tooltip: revealPassword
                                ? 'Nascondi password'
                                : 'Mostra password',
                            onPressed: () => setDialogState(
                              () => revealPassword = !revealPassword,
                            ),
                            icon: Icon(
                              revealPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Copia',
                          onPressed: () =>
                              unawaited(_copySensitive(value, label)),
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ],
                    ),
            );
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.favorite_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    credential.service,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    field('Nome utente', credential.username),
                    field('Email', credential.email),
                    field('Password', credential.password, secret: true),
                    if (credential.notes.isNotEmpty)
                      field('Note', credential.notes),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Cifratura end-to-end'),
                      subtitle: Text(
                        'Aggiornata ${DateFormat(
                          'd MMM yyyy · HH:mm',
                          AnnaStrings.intlLocale(context),
                        ).format(credential.updatedAt)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Chiudi'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifica'),
              ),
            ],
          );
        },
      ),
    );

    if (edit == true && mounted) {
      await _showEditor(credential);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Widget _lockedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 62),
              const SizedBox(height: 14),
              Text(
                vault.configured
                    ? 'Sblocca la Cassaforte privata'
                    : 'Configura la Cassaforte privata',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Le password Noi ♡ usano la Cassaforte per custodire la chiave '
                'E2EE e la copia locale cifrata.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openVault,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(
                  vault.configured ? 'Sblocca cassaforte' : 'Apri cassaforte',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pairingBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key_off_outlined, size: 62),
              const SizedBox(height: 14),
              const Text(
                'Collega le password condivise',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Questo dispositivo è già membro di Noi ♡, ma non possiede la '
                'chiave delle password. Inserisci il codice E2EE generato dal '
                'proprietario.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _importPairingCode,
                icon: const Icon(Icons.link_outlined),
                label: const Text('Inserisci codice'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vault,
      builder: (context, _) {
        final keyReady = vault.unlocked && service.hasKey(widget.space.id);
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Password Noi ♡',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (vault.unlocked &&
                  keyReady &&
                  widget.space.isOwner &&
                  CloudSyncService.instance.signedIn)
                IconButton(
                  tooltip: 'Condividi chiave E2EE',
                  onPressed: _showPairingCode,
                  icon: const Icon(Icons.vpn_key_outlined),
                ),
              IconButton(
                tooltip: 'Aggiorna',
                onPressed: loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: keyReady
              ? FloatingActionButton.extended(
                  onPressed: () => _showEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova password'),
                )
              : null,
          body: !vault.unlocked
              ? _lockedBody()
              : !keyReady
                  ? _pairingBody()
                  : loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.security_outlined),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Cifrate end-to-end. Noi ♡ è la sorgente '
                                        'autorevole: modifiche ed eliminazioni si '
                                        'riflettono anche nella Cassaforte privata.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (errorText != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (credentials.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 50),
                                  child: Column(
                                    children: [
                                      Icon(Icons.password_outlined, size: 56),
                                      SizedBox(height: 12),
                                      Text(
                                        'Nessuna password condivisa',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Aggiungi un servizio: comparirà anche '
                                        'nella Cassaforte privata dei dispositivi '
                                        'Noi ♡ collegati.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...credentials.map(
                                  (credential) => Card(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.password_outlined),
                                      ),
                                      title: Text(
                                        credential.service,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      subtitle: Text(
                                        [
                                          if (credential.username.isNotEmpty)
                                            credential.username,
                                          if (credential.email.isNotEmpty)
                                            credential.email,
                                          '••••••••',
                                        ].join(' · '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _showDetails(credential),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            unawaited(
                                              _showEditor(credential),
                                            );
                                          } else if (value == 'delete') {
                                            unawaited(_delete(credential));
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
                            ],
                          ),
                        ),
        );
      },
    );
  }
}
