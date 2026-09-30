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
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => vault.noteUserActivity(),
      child: AnimatedBuilder(
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
      ),
    );
  }

  Widget _vaultWebSecurityWarning(
    BuildContext context,
    AnnaStrings strings,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: strings.vaultWebSecurityWarning,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.vaultWebSecurityWarning,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
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
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        _vaultWebSecurityWarning(context, strings),
                      ],
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
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    _vaultWebSecurityWarning(context, strings),
                  ],
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
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _vaultWebSecurityWarning(context, strings),
            ),
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
