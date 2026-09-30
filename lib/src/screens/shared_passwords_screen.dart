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
        title: Text(AnnaStrings.of(context).sharedPasswordsConnect),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AnnaStrings.of(context).sharedPasswordsPairingInputDescription,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: AnnaStrings.of(context).sharedPasswordsSecurityCode,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(AnnaStrings.of(context).sharedPasswordsEnterCode),
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
      _message(AnnaStrings.of(context).sharedPasswordsInvalidCode);
      return;
    }
    await _refresh();
  }

  Future<void> _showPairingCode() async {
    final keyUnavailable =
        AnnaStrings.of(context).sharedPasswordsKeyUnavailable;
    try {
      final code = await service.createPairingCode(widget.space.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AnnaStrings.of(context).sharedPasswordsPairingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AnnaStrings.of(context).sharedPasswordsPairingDescription,
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
                      SnackBar(
                        content: Text(
                          AnnaStrings.of(context).sharedPasswordsCodeCopied,
                        ),
                      ),
                    );
                  }
                  unawaited(
                    Future<void>.delayed(
                      const Duration(seconds: 60),
                      () async {
                        try {
                          final current =
                              await Clipboard.getData('text/plain');
                          if (current?.text == code) {
                            await Clipboard.setData(
                              const ClipboardData(text: ''),
                            );
                          }
                        } catch (_) {}
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(AnnaStrings.of(context).sharedPasswordsCopyCode),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AnnaStrings.of(context).close),
            ),
          ],
        ),
      );
    } catch (_) {
      _message(keyUnavailable);
    }
  }

  Future<void> _showRecoveryBackup() async {
    final strings = AnnaStrings.of(context);
    final password = TextEditingController();
    final confirm = TextEditingController();
    final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.sharedPasswordsRecoveryBackup),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.sharedPasswordsRecoveryDescription),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: strings.sharedPasswordsRecoveryPassword,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.vaultRepeatPassword,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.sharedPasswordsCreateRecovery),
              ),
            ],
          ),
        ) ??
        false;

    if (!accepted) {
      password.clear();
      confirm.clear();
      password.dispose();
      confirm.dispose();
      return;
    }
    if (password.text != confirm.text) {
      _message(strings.vaultPasswordsDoNotMatch);
      password.clear();
      confirm.clear();
      password.dispose();
      confirm.dispose();
      return;
    }

    try {
      final package = await service.createRecoveryPackage(
        spaceId: widget.space.id,
        recoveryPassword: password.text,
      );
      password.clear();
      confirm.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.sharedPasswordsRecoveryPackage),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(package),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: package));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(strings.sharedPasswordsRecoveryCopied),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: Text(strings.vaultCopy),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.close),
            ),
          ],
        ),
      );
    } on FormatException catch (error) {
      _message(error.message.toString());
    } catch (_) {
      _message(strings.sharedPasswordsKeyUnavailable);
    } finally {
      password.clear();
      confirm.clear();
      password.dispose();
      confirm.dispose();
    }
  }

  Future<void> _importRecoveryBackup() async {
    final strings = AnnaStrings.of(context);
    final package = TextEditingController();
    final password = TextEditingController();
    final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.sharedPasswordsImportRecovery),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: package,
                    minLines: 3,
                    maxLines: 6,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: strings.sharedPasswordsRecoveryPackage,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.sharedPasswordsRecoveryPassword,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.sharedPasswordsImportRecovery),
              ),
            ],
          ),
        ) ??
        false;

    if (!accepted) {
      package.clear();
      password.clear();
      package.dispose();
      password.dispose();
      return;
    }

    setState(() => loading = true);
    final ok = await service.importRecoveryPackage(
      spaceId: widget.space.id,
      package: package.text.trim(),
      recoveryPassword: password.text,
    );
    package.clear();
    password.clear();
    package.dispose();
    password.dispose();
    if (!mounted) return;
    if (!ok) {
      setState(() => loading = false);
      _message(strings.sharedPasswordsRecoveryInvalid);
      return;
    }
    await _refresh();
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
                ? AnnaStrings.of(context).sharedPasswordNew
                : AnnaStrings.of(context).sharedPasswordEdit,
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
                      decoration: InputDecoration(
                        labelText: AnnaStrings.of(context).vaultServiceName,
                        hintText: AnnaStrings.of(context).vaultServiceHint,
                        prefixIcon: const Icon(Icons.apps_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      maxLength: 320,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: AnnaStrings.of(context).vaultUsername,
                        prefixIcon: const Icon(Icons.person_outline),
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
                      decoration: InputDecoration(
                        labelText: AnnaStrings.of(context).vaultEmail,
                        prefixIcon: const Icon(Icons.alternate_email),
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
                        labelText: AnnaStrings.of(context).vaultPasswordField,
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: IconButton(
                          tooltip: revealPassword
                              ? AnnaStrings.of(context).vaultHidePassword
                              : AnnaStrings.of(context).vaultShowPassword,
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
                      decoration: InputDecoration(
                        labelText: AnnaStrings.of(context).vaultNotes,
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes_outlined),
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
              child: Text(AnnaStrings.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AnnaStrings.of(context).save),
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
          expectedRevision: existing?.revision ?? 0,
        );
        await _refresh(silent: true);
      } on FormatException catch (error) {
        _message(error.message.toString());
      } on SharedPasswordConflictException {
        _message(AnnaStrings.of(context).sharedPasswordsConflict);
        await _refresh(silent: true);
      } catch (_) {
        _message(AnnaStrings.of(context).sharedPasswordsSaveFailed);
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
            title: Text(AnnaStrings.of(context).sharedPasswordsDeleteQuestion),
            content: Text(
              AnnaStrings.of(context)
                  .sharedPasswordsDeleteDescription(credential.service),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AnnaStrings.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(AnnaStrings.of(context).deletePermanently),
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
        expectedRevision: credential.revision,
      );
      await _refresh(silent: true);
    } on SharedPasswordConflictException {
      _message(AnnaStrings.of(context).sharedPasswordsConflict);
      await _refresh(silent: true);
    } catch (_) {
      _message(AnnaStrings.of(context).sharedPasswordsDeleteFailed);
    }
  }

  Future<void> _copySensitive(String value, String label) async {
    if (value.isEmpty) return;
    final copiedMessage =
        AnnaStrings.of(context).vaultCopiedToClipboard(label);
    await Clipboard.setData(ClipboardData(text: value));
    _message(copiedMessage);
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
                                ? AnnaStrings.of(context).vaultHidePassword
                                : AnnaStrings.of(context).vaultShowPassword,
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
                          tooltip: AnnaStrings.of(context).vaultCopy,
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
                    field(AnnaStrings.of(context).vaultUsername, credential.username),
                    field(AnnaStrings.of(context).vaultEmail, credential.email),
                    field(AnnaStrings.of(context).vaultPasswordField, credential.password, secret: true),
                    if (credential.notes.isNotEmpty)
                      field(AnnaStrings.of(context).vaultNotes, credential.notes),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline),
                      title: Text(AnnaStrings.of(context).sharedPasswordsE2ee),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(
                        AnnaStrings.of(context).passwordUpdatedAt(
                          DateFormat(
                            'd MMMM yyyy · HH:mm',
                            AnnaStrings.intlLocale(context),
                          ).format(credential.updatedAt),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AnnaStrings.of(context).close),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.edit_outlined),
                label: Text(AnnaStrings.of(context).edit),
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
                    ? AnnaStrings.of(context).sharedPasswordsVaultRequired
                    : AnnaStrings.of(context).vaultConfigure,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AnnaStrings.of(context).sharedPasswordsVaultDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openVault,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(
                  vault.configured
                      ? AnnaStrings.of(context).vaultUnlock
                      : AnnaStrings.of(context).vaultOpen,
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
              Text(
                AnnaStrings.of(context).sharedPasswordsConnect,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AnnaStrings.of(context).sharedPasswordsConnectDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _importPairingCode,
                icon: const Icon(Icons.link_outlined),
                label: Text(AnnaStrings.of(context).sharedPasswordsEnterCode),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _importRecoveryBackup,
                icon: const Icon(Icons.settings_backup_restore_outlined),
                label: Text(
                  AnnaStrings.of(context).sharedPasswordsImportRecovery,
                ),
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
            title: Text(
              AnnaStrings.of(context).sharedPasswords,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (vault.unlocked &&
                  keyReady &&
                  widget.space.isOwner &&
                  CloudSyncService.instance.signedIn)
                IconButton(
                  tooltip: AnnaStrings.of(context).sharedPasswordsShareKey,
                  onPressed: _showPairingCode,
                  icon: const Icon(Icons.vpn_key_outlined),
                ),
              if (vault.unlocked &&
                  keyReady &&
                  widget.space.isOwner &&
                  CloudSyncService.instance.signedIn)
                IconButton(
                  tooltip:
                      AnnaStrings.of(context).sharedPasswordsRecoveryBackup,
                  onPressed: _showRecoveryBackup,
                  icon: const Icon(Icons.health_and_safety_outlined),
                ),
              IconButton(
                tooltip: AnnaStrings.of(context).refresh,
                onPressed: loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: keyReady
              ? FloatingActionButton.extended(
                  onPressed: () => _showEditor(),
                  icon: const Icon(Icons.add),
                  label: Text(AnnaStrings.of(context).sharedPasswordNew),
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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.security_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AnnaStrings.of(context)
                                            .sharedPasswordsE2eeBanner,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (kIsWeb) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                        .withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          AnnaStrings.of(context)
                                              .vaultWebSecurityWarning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 50),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.password_outlined, size: 56),
                                      const SizedBox(height: 12),
                                      Text(
                                        AnnaStrings.of(context).sharedPasswordsEmpty,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AnnaStrings.of(context)
                                            .sharedPasswordsEmptyDescription,
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
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text(
                                              AnnaStrings.of(context).edit,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              AnnaStrings.of(context).delete,
                                            ),
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
