part of '../../main.dart';

String approvedHolderNamePlaceholder(String code) => switch (code) {
  'en' => 'Enter your name',
  'es' => 'Introduce tu nombre',
  'fr' => 'Saisissez votre prénom',
  'pt' => 'Insere o teu nome',
  _ => 'Inserisci il tuo nome',
};

class SettingsHubScreen extends StatelessWidget {
  final AgendaStore store;

  const SettingsHubScreen({
    super.key,
    required this.store,
  });

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
            ),
          ),
        ),
      ),
    );
  }
}
