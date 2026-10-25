part of '../../main.dart';

class MoreScreen extends StatelessWidget {
  final AgendaStore store;

  const MoreScreen({
    super.key,
    required this.store,
  });

  Widget _tile({
    required String id,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
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
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        store.inboxRevision,
        store.sharedRevision,
        store.settingsRevision,
        store.backupRevision,
      ]),
      builder: (context, _) {
        final prefs = store.preferences;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.navMore,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                key: const ValueKey<String>('more-search-action'),
                tooltip: strings.search,
                onPressed: () => _open(
                  context,
                  PersonalSearchConnectionsScreen(store: store),
                ),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AnnaDesignTokens.spaceMd,
              AnnaDesignTokens.spaceXs,
              AnnaDesignTokens.spaceMd,
              AnnaDesignTokens.spaceXl,
            ),
            children: [
              _HomeSyncStatusCard(store: store),
              if (store.hasStorageWarnings) ...[
                const SizedBox(height: AnnaDesignTokens.spaceSm),
                SimpleCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: AnnaDesignTokens.spaceSm),
                      Expanded(
                        child: Text(strings.v100StorageWarning),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceLg),
              ],
              SectionTitle(strings.v100Explore),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              SimpleCard(
                child: Column(
                  children: [
                    _tile(
                      id: 'more-search',
                      icon: Icons.search,
                      title: strings.search,
                      onTap: () => _open(
                        context,
                        PersonalSearchConnectionsScreen(store: store),
                      ),
                    ),
                    const Divider(height: 1),
                    _tile(
                      id: 'more-inbox',
                      icon: Icons.inbox_outlined,
                      title: strings.inbox,
                      trailing: store.activeInboxEntries.isEmpty
                          ? const Icon(Icons.chevron_right)
                          : Badge(
                              label: Text(
                                '${store.activeInboxEntries.length}',
                              ),
                              child: const Icon(Icons.chevron_right),
                            ),
                      onTap: () =>
                          _open(context, InboxScreen(store: store)),
                    ),
                    const Divider(height: 1),
                    _tile(
                      id: 'more-explore',
                      icon: Icons.apps_outlined,
                      title: strings.v100Explore,
                      subtitle: strings.v100ExploreIntro,
                      onTap: () =>
                          _open(context, ExploreScreen(store: store)),
                    ),
                    const Divider(height: 1),
                    _tile(
                      id: 'more-personalize',
                      icon: Icons.tune_outlined,
                      title: strings.d3('personalizationTitle'),
                      subtitle:
                          strings.d3('personalizationSettingsSubtitle'),
                      onTap: () => _open(
                        context,
                        PersonalizationScreen(store: store),
                      ),
                    ),
                    if (prefs.isModuleEnabled(AppModule.sharedSpace)) ...[
                      const Divider(height: 1),
                      _tile(
                        id: 'more-shared',
                        icon: Icons.favorite_outline,
                        title: 'Noi ♡',
                        subtitle:
                            strings.d3('personalizationSharedSpaceSubtitle'),
                        trailing: store.totalSharedUnreadCount <= 0
                            ? const Icon(Icons.chevron_right)
                            : Badge(
                                label: Text(
                                  store.totalSharedUnreadCount > 99
                                      ? '99+'
                                      : '${store.totalSharedUnreadCount}',
                                ),
                                child: const Icon(Icons.chevron_right),
                              ),
                        onTap: () => _open(
                          context,
                          SharedSpaceHubScreen(store: store),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
              SectionTitle(strings.settings),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              SimpleCard(
                child: Column(
                  children: [
                    _tile(
                      id: 'more-archive',
                      icon: Icons.inventory_2_outlined,
                      title: strings.archive,
                      onTap: () =>
                          _open(context, ArchiveScreen(store: store)),
                    ),
                    const Divider(height: 1),
                    _tile(
                      id: 'more-backup',
                      icon: Icons.backup_outlined,
                      title: strings.backup,
                      onTap: () =>
                          _open(context, BackupScreen(store: store)),
                    ),
                    const Divider(height: 1),
                    _tile(
                      id: 'more-cloud',
                      icon: Icons.cloud_outlined,
                      title: strings.cloud,
                      onTap: () =>
                          _open(context, CloudAccountScreen(store: store)),
                    ),
                    const Divider(height: 1),
                    _tile(
                      id: 'more-settings',
                      icon: Icons.settings_outlined,
                      title: strings.settings,
                      onTap: () =>
                          _open(context, SettingsScreen(store: store)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
