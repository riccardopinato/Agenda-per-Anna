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
