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

enum _VaultSection { notes, passwords }

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
  _VaultSection section = _VaultSection.notes;
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
    if (password.length < 12) {
      setState(
        () => errorText = AnnaStrings.of(context).vaultPasswordTooShort,
      );
      return;
    }
    if (password != confirmController.text) {
      setState(
        () => errorText = AnnaStrings.of(context).vaultPasswordsDoNotMatch,
      );
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
      unawaited(SharedPasswordService.instance.refreshAllAvailableSpacesSafe());
      if (mounted) setState(() {});
    } on FormatException catch (error) {
      if (mounted) setState(() => errorText = error.message.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => errorText =
              AnnaStrings.of(context).vaultCreateFailed,
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
      if (!ok) errorText = AnnaStrings.of(context).vaultIncorrectPassword;
    });
    if (ok) {
      unawaited(SharedPasswordService.instance.refreshAllAvailableSpacesSafe());
    }
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
        localizedReason: AnnaStrings.of(context).vaultUnlockReason,
      );
      if (!authenticated) return;
      final ok = await vault.unlockWithBiometricKey();
      if (!ok && mounted) {
        setState(
          () => errorText =
              AnnaStrings.of(context).vaultBiometricUnavailableUsePassword,
        );
      } else if (ok) {
        unawaited(SharedPasswordService.instance.refreshAllAvailableSpacesSafe());
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => errorText =
              AnnaStrings.of(context).vaultBiometricUnavailableUsePassword,
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
        title: Text(
          entry == null ? strings.vaultNewPrivateContent : strings.edit,
        ),
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
                  labelText: strings.vaultPrivateTitleField,
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
                  labelText: strings.vaultPrivateContentField,
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
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.save),
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


  Future<void> _showCredentialEditor([PrivateVaultEntry? entry]) async {
    final strings = AnnaStrings.of(context);
    final serviceController =
        TextEditingController(text: entry?.service ?? '');
    final usernameController =
        TextEditingController(text: entry?.username ?? '');
    final emailController = TextEditingController(text: entry?.email ?? '');
    final credentialPasswordController =
        TextEditingController(text: entry?.password ?? '');
    final notesController = TextEditingController(text: entry?.notes ?? '');
    var revealPassword = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            entry == null
                ? strings.vaultNewPassword
                : strings.vaultEditPassword,
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
                        labelText: strings.vaultServiceName,
                        hintText: strings.vaultServiceHint,
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
                        labelText: strings.vaultUsername,
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
                        labelText: strings.vaultEmail,
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: credentialPasswordController,
                      obscureText: !revealPassword,
                      autofillHints: const [AutofillHints.password],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: strings.vaultPasswordField,
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: IconButton(
                          tooltip: revealPassword
                              ? strings.vaultHidePassword
                              : strings.vaultShowPassword,
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
                        labelText: strings.vaultNotes,
                        hintText: strings.vaultPasswordNotesHint,
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
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        if (entry?.isSharedCredential == true) {
          await SharedPasswordService.instance.upsertCredential(
            spaceId: entry!.sharedSpaceId,
            credentialId: entry.sharedCredentialId,
            service: serviceController.text,
            username: usernameController.text,
            email: emailController.text,
            password: credentialPasswordController.text,
            notes: notesController.text,
            expectedRevision: entry.sharedRevision,
          );
        } else {
          await vault.upsertCredential(
            id: entry?.id,
            service: serviceController.text,
            username: usernameController.text,
            email: emailController.text,
            password: credentialPasswordController.text,
            notes: notesController.text,
          );
        }
      } on FormatException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message.toString())),
          );
        }
      } on SharedPasswordConflictException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AnnaStrings.of(context).sharedPasswordsConflict,
              ),
            ),
          );
        }
        unawaited(
          SharedPasswordService.instance.refreshAllAvailableSpacesSafe(),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.vaultSharedUpdateFailed),
            ),
          );
        }
      }
    }

    serviceController.clear();
    usernameController.clear();
    emailController.clear();
    credentialPasswordController.clear();
    notesController.clear();
    serviceController.dispose();
    usernameController.dispose();
    emailController.dispose();
    credentialPasswordController.dispose();
    notesController.dispose();
  }

  Future<void> _copySensitive(String value, String fieldLabel) async {
    if (value.isEmpty) return;
    final strings = AnnaStrings.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.vaultCopiedToClipboard(fieldLabel))),
      );
    }

    unawaited(
      Future<void>.delayed(const Duration(seconds: 30), () async {
        try {
          final current = await Clipboard.getData('text/plain');
          if (current?.text == value) {
            await Clipboard.setData(const ClipboardData(text: ''));
          }
        } catch (_) {
          // Clipboard cleanup is best effort and must never block the Vault.
        }
      }),
    );
  }

  Future<void> _showCredentialDetails(PrivateVaultEntry entry) async {
    final strings = AnnaStrings.of(context);
    var revealPassword = false;

    final edit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Widget fieldRow({
            required String label,
            required String value,
            bool secret = false,
          }) {
            final display = value.isEmpty
                ? strings.vaultNoValue
                : secret && !revealPassword
                    ? '••••••••'
                    : value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                label,
                style: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              subtitle: SelectableText(display),
              trailing: value.isEmpty
                  ? null
                  : Wrap(
                      spacing: 2,
                      children: [
                        if (secret)
                          IconButton(
                            tooltip: revealPassword
                                ? strings.vaultHidePassword
                                : strings.vaultShowPassword,
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
                          tooltip: strings.vaultCopy,
                          onPressed: () => unawaited(
                            _copySensitive(value, label),
                          ),
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ],
                    ),
            );
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  entry.isSharedCredential
                      ? Icons.favorite_outline
                      : Icons.key_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.service,
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
                    fieldRow(
                      label: strings.vaultUsername,
                      value: entry.username,
                    ),
                    fieldRow(
                      label: strings.vaultEmail,
                      value: entry.email,
                    ),
                    fieldRow(
                      label: strings.vaultPasswordField,
                      value: entry.password,
                      secret: true,
                    ),
                    if (entry.notes.isNotEmpty)
                      fieldRow(
                        label: strings.vaultNotes,
                        value: entry.notes,
                      ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(
                        strings.passwordUpdatedAt(
                          DateFormat(
                            'd MMMM yyyy · HH:mm',
                            AnnaStrings.intlLocale(context),
                          ).format(entry.updatedAt),
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
                child: Text(strings.close),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.edit_outlined),
                label: Text(strings.edit),
              ),
            ],
          );
        },
      ),
    );

    if (edit == true && mounted) {
      await _showCredentialEditor(entry);
    }
  }

  Future<void> _delete(PrivateVaultEntry entry) async {
    final strings = AnnaStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          entry.isCredential
              ? strings.vaultCredentialDeleteQuestion
              : strings.vaultDeletePrivateQuestion,
        ),
        content: Text(
          entry.isCredential
              ? strings.vaultCredentialDeleteDescription(entry.service)
              : entry.title.isEmpty
                  ? strings.vaultDeletePrivateDescription
                  : strings.vaultDeletePrivateNamed(entry.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        if (entry.isSharedCredential) {
          await SharedPasswordService.instance.deleteCredential(
            spaceId: entry.sharedSpaceId,
            credentialId: entry.sharedCredentialId,
            expectedRevision: entry.sharedRevision,
          );
        } else {
          await vault.delete(entry.id);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.vaultSharedDeleteFailed),
            ),
          );
        }
      }
    }
  }

  Future<void> _destroyVault() async {
    final strings = AnnaStrings.of(context);
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.vaultDeleteVault),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.vaultDestroyDescription),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: strings.vaultPasswordLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text),
            child: Text(strings.deletePermanently),
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
          SnackBar(content: Text(strings.vaultIncorrectPassword)),
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
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(strings.vaultTitle)),
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
                      Text(
                        strings.vaultSetupTitle,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(strings.vaultSetupDescription),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        enabled: !busy,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: strings.vaultPasswordLabel,
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
                          labelText: strings.vaultRepeatPassword,
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
                          title: Text(strings.vaultBiometricUnlock),
                          subtitle: Text(
                            strings.vaultBiometricRecoveryDescription,
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
                            busy ? strings.vaultCreating : strings.vaultCreate,
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
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.vaultTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'destroy') unawaited(_destroyVault());
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'destroy',
                child: Text(strings.vaultDeleteVault),
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
                  Text(
                    strings.vaultLocked,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    strings.vaultLockedDescription,
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
                      labelText: strings.vaultPasswordLabel,
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
                      label: Text(strings.vaultUnlock),
                    ),
                  ),
                  if (biometricSupported && vault.biometricAvailable) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _unlockBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(strings.vaultUseBiometric),
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
    final strings = AnnaStrings.of(context);
    final passwordMode = section == _VaultSection.passwords;
    final entries =
        passwordMode ? vault.credentialEntries : vault.noteEntries;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.vaultTitle),
        actions: [
          if (biometricSupported && !vault.biometricAvailable)
            IconButton(
              tooltip: strings.vaultEnableBiometric,
              onPressed: () async {
                final ok = await vault.enableBiometricForCurrentKey();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? strings.vaultBiometricEnabled
                          : strings.vaultBiometricUnavailable,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fingerprint),
            ),
          IconButton(
            tooltip: strings.vaultLockNow,
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
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'destroy',
                child: Text(strings.vaultDeleteVault),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: passwordMode
            ? () => _showCredentialEditor()
            : () => _showEditor(),
        icon: Icon(passwordMode ? Icons.key_outlined : Icons.add),
        label: Text(
          passwordMode
              ? strings.vaultNewPassword
              : strings.vaultNewPrivateNote,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_VaultSection>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<_VaultSection>(
                    value: _VaultSection.notes,
                    icon: const Icon(Icons.note_alt_outlined),
                    label: Text(strings.vaultPrivateNotes),
                  ),
                  ButtonSegment<_VaultSection>(
                    value: _VaultSection.passwords,
                    icon: const Icon(Icons.password_outlined),
                    label: Text(strings.vaultPasswords),
                  ),
                ],
                selected: {section},
                onSelectionChanged: (selected) {
                  if (selected.isEmpty) return;
                  setState(() => section = selected.first);
                },
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            passwordMode
                                ? Icons.key_off_outlined
                                : Icons.shield_outlined,
                            size: 58,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            passwordMode
                                ? strings.vaultNoPasswords
                                : strings.vaultEmpty,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            passwordMode
                                ? strings.vaultNoPasswordsDescription
                                : strings.vaultEmptyDescription,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry.isCredential) {
                        final details = [
                          if (entry.username.isNotEmpty) entry.username,
                          if (entry.email.isNotEmpty) entry.email,
                        ];
                        final subtitle = details.isNotEmpty
                            ? details.join(' · ')
                            : DateFormat(
                                'd MMM yyyy · HH:mm',
                                AnnaStrings.intlLocale(context),
                              ).format(entry.updatedAt);
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              child: Icon(
                                entry.isSharedCredential
                                    ? Icons.favorite_outline
                                    : Icons.key_outlined,
                              ),
                            ),
                            title: Text(
                              entry.service,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              entry.isSharedCredential
                                  ? 'Noi ♡ · $subtitle'
                                  : subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _showCredentialDetails(entry),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  unawaited(_showCredentialEditor(entry));
                                } else if (value == 'delete') {
                                  unawaited(_delete(entry));
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(strings.edit),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(strings.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

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
                            entry.title.isEmpty
                                ? 'Contenuto privato'
                                : entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            entry.body.isEmpty
                                ? DateFormat(
                                    'd MMM yyyy · HH:mm',
                                    AnnaStrings.intlLocale(context),
                                  ).format(entry.updatedAt)
                                : entry.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showEditor(entry),
                          trailing: IconButton(
                            tooltip: strings.delete,
                            onPressed: () => _delete(entry),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

}
