part of '../../main.dart';

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
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Icon(icon)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.settings,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AnnaDesignTokens.spaceMd,
          AnnaDesignTokens.spaceXs,
          AnnaDesignTokens.spaceMd,
          AnnaDesignTokens.spaceXl,
        ),
        children: [
          SimpleCard(
            child: Text(
              strings.d3('settingsHubIntro'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AnnaDesignTokens.spaceLg),
          SectionTitle(strings.d3('personalizationTitle')),
          const SizedBox(height: AnnaDesignTokens.spaceSm),
          SimpleCard(
            child: Column(
              children: [
                _tile(
                  id: 'settings-hub-personalization',
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
                  icon: Icons.tune_rounded,
                  title: strings.d3('settingsPreferencesPrivacy'),
                  subtitle: strings.d3('settingsPreferencesPrivacySubtitle'),
                  onTap: () => _open(
                    context,
                    SettingsScreen(store: store),
                  ),
                ),
                const Divider(height: 1),
                _tile(
                  id: 'settings-hub-premium',
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
              ],
            ),
          ),
          const SizedBox(height: AnnaDesignTokens.spaceLg),
          SectionTitle(strings.v100DataSection),
          const SizedBox(height: AnnaDesignTokens.spaceSm),
          SimpleCard(
            child: Column(
              children: [
                _tile(
                  id: 'settings-hub-account',
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
                  id: 'settings-hub-backup',
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
    );
  }
}
