part of '../../main.dart';

String approvedHolderNamePlaceholder(String code) => switch (code) {
  'en' => 'Enter your name',
  'es' => 'Introduce tu nombre',
  'fr' => 'Saisissez votre prénom',
  'pt' => 'Insere o teu nome',
  _ => 'Inserisci il tuo nome',
};

class SettingsHubScreen extends StatefulWidget {
  final AgendaStore store;
  const SettingsHubScreen({super.key, required this.store});

  @override
  State<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends State<SettingsHubScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  AgendaStore get store => widget.store;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String section, String title, String? subtitle) {
    if (_query.isEmpty) return true;
    final aliases = switch (section) {
      'name' => 'nome name profile profilo',
      'appearance' => 'colori colors colori tema theme hsv palette sfondo',
      'personalization' => 'moduli modules funzioni features',
      'privacy' => 'privacy pin biometria biometric notifiche notifications '
          'promemoria reminder alerts sicurezza security',
      'premium' => 'premium pro abbonamento subscription',
      'account' => 'account sync cloud login accesso google',
      'calendar' => 'calendario calendar sincronizzazione',
      'capability' => 'permessi permissions health diagnostica notifiche',
      'backup' => 'backup restore export archivio esportazione ripristino',
      _ => '',
    };
    final haystack = '$title ${subtitle ?? ''} $aliases'.toLowerCase();
    return haystack.contains(_query);
  }

  void _open(BuildContext context, Widget screen) {
    unawaited(AnnaFeedback.selection());
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _tile({
    required String id,
    required IconData icon,
    required AnnaVisualDomain domain,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      identifier: id,
      button: true,
      label: title,
      onTap: onTap,
      excludeSemantics: true,
      child: ListTile(
        key: ValueKey<String>(id),
        contentPadding: const EdgeInsets.symmetric(
          vertical: AnnaDesignTokens.space2xs,
        ),
        leading: AnnaPastelIcon(icon: icon, domain: domain),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        PremiumEntitlementService.instance,
        store.settingsRevision,
      ]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 78,
          title: Text(
            strings.settings,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AnnaDesignTokens.compactContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AnnaDesignTokens.spaceMd,
                AnnaDesignTokens.spaceXs,
                AnnaDesignTokens.spaceMd,
                AnnaDesignTokens.spaceXl,
              ),
              children: [
                TextField(
                  key: const ValueKey('qw2-settings-search'),
                  controller: _search,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: quickWins2Copy(
                        strings.languageCode, 'settingsSearch'),
                    suffixIcon: _query.isEmpty ? null : IconButton(
                      tooltip: strings.v100ClearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceSm),
                if (_query.isNotEmpty) ...[
                  if (_matches('name', strings.settings, null))
                    _tile(
                      id: 'settings-hub-edit-name',
                      domain: AnnaVisualDomain.people,
                      icon: Icons.edit_outlined,
                      title: approvedHolderNamePlaceholder(strings.languageCode),
                      onTap: () => _open(
                          context, SettingsScreen(store: store)),
                    ),
                  if (_matches('appearance',
                      strings.d3('appearanceColorsTitle'),
                      strings.d3('appearanceColorsIntro')))
                    _tile(
                      id: 'settings-hub-appearance',
                      domain: AnnaVisualDomain.people,
                      icon: Icons.palette_outlined,
                      title: strings.d3('appearanceColorsTitle'),
                      subtitle: strings.d3('appearanceColorsIntro'),
                      onTap: () => _open(
                          context, AppearanceColorsScreen(store: store)),
                    ),
                  if (_matches('personalization',
                      strings.d3('personalizationTitle'),
                      strings.d3('personalizationSettingsSubtitle')))
                    _tile(
                      id: 'settings-hub-personalization',
                      domain: AnnaVisualDomain.people,
                      icon: Icons.tune_outlined,
                      title: strings.d3('personalizationTitle'),
                      onTap: () => _open(
                          context, PersonalizationScreen(store: store)),
                    ),
                  if (_matches('privacy',
                      strings.d3('settingsPreferencesPrivacy'),
                      strings.d3('settingsPreferencesPrivacySubtitle')))
                    _tile(
                      id: 'settings-hub-preferences-privacy',
                      domain: AnnaVisualDomain.vault,
                      icon: Icons.security_outlined,
                      title: strings.d3('settingsPreferencesPrivacy'),
                      subtitle: strings.d3('settingsPreferencesPrivacySubtitle'),
                      onTap: () => _open(
                          context, SettingsScreen(store: store)),
                    ),
                  if (_matches('premium', strings.premiumTitle,
                      strings.premiumSettingsDescription))
                    _tile(
                      id: 'qw2-search-premium',
                      domain: AnnaVisualDomain.memories,
                      icon: Icons.workspace_premium_outlined,
                      title: strings.premiumTitle,
                      onTap: () => _open(context, const PremiumScreen()),
                    ),
                  if (_matches('account', strings.v100AccountSync,
                      strings.v100AccountSyncDescription))
                    _tile(
                      id: 'settings-hub-account',
                      domain: AnnaVisualDomain.ecosystem,
                      icon: Icons.cloud_outlined,
                      title: strings.v100AccountSync,
                      onTap: () => _open(
                          context, CloudAccountScreen(store: store)),
                    ),
                  if (_matches('calendar',
                      androidSyncCopy(strings, 'title'),
                      androidSyncCopy(strings, 'intro')))
                    _tile(
                      id: 'settings-hub-android-calendar-sync',
                      domain: AnnaVisualDomain.ecosystem,
                      icon: Icons.event_repeat_outlined,
                      title: androidSyncCopy(strings, 'title'),
                      onTap: () => _open(context,
                          AndroidCalendarSyncSettingsScreen(store: store)),
                    ),
                  if (_matches('capability',
                      capabilityHealthCopy(strings.languageCode, 'title'),
                      capabilityHealthCopy(strings.languageCode, 'intro')))
                    _tile(
                      id: 'settings-hub-capability-health',
                      domain: AnnaVisualDomain.ecosystem,
                      icon: Icons.health_and_safety_outlined,
                      title: capabilityHealthCopy(strings.languageCode, 'title'),
                      onTap: () => _open(context,
                          CapabilityHealthScreen(store: store)),
                    ),
                  if (_matches('backup', strings.v100BackupRestore,
                      strings.v100BackupRestoreDescription))
                    _tile(
                      id: 'settings-hub-backup',
                      domain: AnnaVisualDomain.vault,
                      icon: Icons.backup_outlined,
                      title: strings.v100BackupRestore,
                      onTap: () => _open(
                          context, BackupScreen(store: store)),
                    ),
                  if (![
                    _matches('name', strings.settings, null),
                    _matches('appearance', strings.d3('appearanceColorsTitle'),
                        strings.d3('appearanceColorsIntro')),
                    _matches('personalization', strings.d3('personalizationTitle'),
                        strings.d3('personalizationSettingsSubtitle')),
                    _matches('privacy', strings.d3('settingsPreferencesPrivacy'),
                        strings.d3('settingsPreferencesPrivacySubtitle')),
                    _matches('premium', strings.premiumTitle,
                        strings.premiumSettingsDescription),
                    _matches('account', strings.v100AccountSync,
                        strings.v100AccountSyncDescription),
                    _matches('calendar', androidSyncCopy(strings, 'title'),
                        androidSyncCopy(strings, 'intro')),
                    _matches('capability',
                        capabilityHealthCopy(strings.languageCode, 'title'),
                        capabilityHealthCopy(strings.languageCode, 'intro')),
                    _matches('backup', strings.v100BackupRestore,
                        strings.v100BackupRestoreDescription),
                  ].contains(true))
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(quickWins2Copy(
                          strings.languageCode, 'settingsNoMatch')),
                    ),
                ] else ...[
                AnnaJournalCard(
                  domain: AnnaVisualDomain.people,
                  child: Text(
                    strings.d3('settingsHubIntro'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceSm),
                Semantics(
                  identifier: 'settings-hub-edit-name',
                  button: true,
                  child: SimpleCard(
                    child: ListTile(
                      key: const ValueKey<String>('settings-hub-edit-name'),
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(
                        store.preferences.displayName.trim().isEmpty
                            ? approvedHolderNamePlaceholder(strings.languageCode)
                            : store.preferences.displayName.trim(),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(
                        context,
                        SettingsScreen(store: store),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceLg),
                AnnaJournalSectionHeading(
                  title: strings.d3('personalizationTitle'),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceSm),
                SimpleCard(
                  child: Column(
                    children: [
                      _tile(
                        id: 'settings-hub-appearance',
                        domain: AnnaVisualDomain.people,
                        icon: Icons.palette_outlined,
                        title: strings.d3('appearanceColorsTitle'),
                        subtitle: strings.d3('appearanceColorsIntro'),
                        onTap: () => _open(
                          context,
                          AppearanceColorsScreen(store: store),
                        ),
                      ),
                      const Divider(height: 1),
                      _tile(
                        id: 'settings-hub-personalization',
                        domain: AnnaVisualDomain.people,
                        icon: Icons.tune_outlined,
                        title: strings.d3('personalizationTitle'),
                        subtitle: strings.d3('personalizationSettingsSubtitle'),
                        onTap: () => _open(
                          context,
                          PersonalizationScreen(store: store),
                        ),
                      ),
                      const Divider(height: 1),
                      _tile(
                        id: 'settings-hub-preferences-privacy',
                        domain: AnnaVisualDomain.vault,
                        icon: Icons.tune_rounded,
                        title: strings.d3('settingsPreferencesPrivacy'),
                        subtitle: strings.d3('settingsPreferencesPrivacySubtitle'),
                        onTap: () => _open(
                          context,
                          SettingsScreen(store: store),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceLg),
                AnnaJournalSectionHeading(
                  title: strings.v100DataSection,
                ),
                const SizedBox(height: AnnaDesignTokens.spaceSm),
                SimpleCard(
                  child: Column(
                    children: [
                      _tile(
                        id: 'settings-hub-premium',
                        domain: AnnaVisualDomain.memories,
                        icon: Icons.workspace_premium_outlined,
                        title: strings.premiumTitle,
                        subtitle: PremiumEntitlementService.instance.paidEntitlement
                            ? strings.premiumActiveDescription
                            : strings.premiumSettingsDescription,
                        onTap: () => _open(
                          context,
                          const PremiumScreen(),
                        ),
                      ),
                      const Divider(height: 1),
                      _tile(
                        id: 'settings-hub-account',
                        domain: AnnaVisualDomain.ecosystem,
                        icon: Icons.cloud_outlined,
                        title: strings.v100AccountSync,
                        subtitle: strings.v100AccountSyncDescription,
                        onTap: () => _open(
                          context,
                          CloudAccountScreen(store: store),
                        ),
                      ),
                      const Divider(height: 1),
                      _tile(
                        id: 'settings-hub-android-calendar-sync',
                        domain: AnnaVisualDomain.ecosystem,
                        icon: Icons.event_repeat_outlined,
                        title: androidSyncCopy(strings, 'title'),
                        subtitle: androidSyncCopy(strings, 'intro'),
                        onTap: () => _open(
                          context,
                          AndroidCalendarSyncSettingsScreen(store: store),
                        ),
                      ),
                      const Divider(height: 1),
                      _tile(
                        id: 'settings-hub-capability-health',
                        domain: AnnaVisualDomain.ecosystem,
                        icon: Icons.health_and_safety_outlined,
                        title: capabilityHealthCopy(strings.languageCode, 'title'),
                        subtitle: capabilityHealthCopy(strings.languageCode, 'intro'),
                        onTap: () => _open(
                          context,
                          CapabilityHealthScreen(store: store),
                        ),
                      ),
                      const Divider(height: 1),
                      _tile(
                        id: 'settings-hub-backup',
                        domain: AnnaVisualDomain.vault,
                        icon: Icons.backup_outlined,
                        title: strings.v100BackupRestore,
                        subtitle: strings.v100BackupRestoreDescription,
                        onTap: () => _open(
                          context,
                          BackupScreen(store: store),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
