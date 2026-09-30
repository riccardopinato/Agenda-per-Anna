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

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Password Noi ♡',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
