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
    required AnnaVisualDomain domain,
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
      child: SizedBox(
        height: 58,
        child: ListTile(
        key: ValueKey<String>(id),
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: AnnaPastelIcon(icon: icon, domain: domain),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
        ),
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
            toolbarHeight: 78,
            title: Text(
              strings.navMore,
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
                  AnnaDesignTokens.journalPageGutter,
                  AnnaDesignTokens.spaceXs,
                  AnnaDesignTokens.journalPageGutter,
                  AnnaDesignTokens.spaceXl,
                ),
                children: [
                  _SyncAttentionCard(store: store),
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
                  AnnaJournalSectionHeading(
                    title: strings.d3('moreQuickAccess'),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  AnnaJournalCard(
                    domain: AnnaVisualDomain.today,
                    child: Column(
                      children: [
                        _tile(
                          id: 'more-search',
                          domain: AnnaVisualDomain.today,
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
                          domain: AnnaVisualDomain.today,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceLg),
                  AnnaJournalSectionHeading(
                    title: strings.d3('moreYourSpace'),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  if (prefs.isModuleEnabled(AppModule.sharedSpace)) ...[
                    AnnaJournalCard(
                      domain: AnnaVisualDomain.shared,
                      child: _tile(
                        id: 'more-shared',
                        domain: AnnaVisualDomain.shared,
                        icon: Icons.favorite_outline,
                        title: strings.d3('sharedSpace'),
                        subtitle: 'Noi ♡ · ${strings.d3('personalizationSharedSpaceSubtitle')}',
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
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceSm),
                  ],
                  if (prefs.isModuleEnabled(AppModule.privateVault)) ...[
                    AnnaJournalCard(
                      domain: AnnaVisualDomain.vault,
                      child: _tile(
                        id: 'more-private-vault',
                        domain: AnnaVisualDomain.vault,
                        icon: Icons.lock_person_outlined,
                        title: strings.v100PrivateVault,
                        subtitle: strings.v100PrivateVaultDescription,
                        onTap: () => _open(
                          context,
                          PrivateVaultScreen(store: store),
                        ),
                      ),
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceSm),
                  ],
                  AnnaJournalCard(
                    domain: AnnaVisualDomain.people,
                    child: _tile(
                      id: 'more-explore',
                      domain: AnnaVisualDomain.people,
                      icon: Icons.apps_outlined,
                      title: strings.v100Explore,
                      subtitle: strings.v100ExploreIntro,
                      onTap: () => _open(
                        context,
                        ExploreScreen(store: store),
                      ),
                    ),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceLg),
                  AnnaJournalSectionHeading(
                    title: strings.d3('moreDataAndApp'),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  AnnaJournalCard(
                    domain: AnnaVisualDomain.ecosystem,
                    child: Column(
                      children: [
                        _tile(
                          id: 'more-archive',
                          domain: AnnaVisualDomain.memories,
                          icon: Icons.inventory_2_outlined,
                          title: strings.archive,
                          onTap: () =>
                              _open(context, ArchiveScreen(store: store)),
                        ),
                        const Divider(height: 1),
                        _tile(
                          id: 'more-backup',
                          domain: AnnaVisualDomain.vault,
                          icon: Icons.backup_outlined,
                          title: strings.backup,
                          onTap: () =>
                              _open(context, BackupScreen(store: store)),
                        ),
                        const Divider(height: 1),
                        _tile(
                          id: 'more-cloud',
                          domain: AnnaVisualDomain.ecosystem,
                          icon: Icons.cloud_outlined,
                          title: strings.cloud,
                          onTap: () =>
                              _open(context, CloudAccountScreen(store: store)),
                        ),
                        const Divider(height: 1),
                        _tile(
                          id: 'more-settings',
                          domain: AnnaVisualDomain.ecosystem,
                          icon: Icons.settings_outlined,
                          title: strings.settings,
                          onTap: () =>
                              _open(context, SettingsHubScreen(store: store)),
                        ),
                      ],
                    ),
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
