part of '../../main.dart';

// DS6 approved visual-only copy, localized for all five app languages.
String ds6MoreHeading(String code) => switch (code) {
  'en' => 'Your little world.',
  'es' => 'Todo tu mundo.',
  'fr' => 'Tout ton univers.',
  'pt' => 'Todo o teu mundo.',
  _ => 'Tutto il tuo mondo.',
};

String ds6MoreKicker(String code) => switch (code) {
  'en' => 'YOUR SPACE, YOUR WAY',
  'es' => 'TU ESPACIO, A TU MANERA',
  'fr' => 'TON ESPACE, À TA FAÇON',
  'pt' => 'O TEU ESPAÇO, À TUA MANEIRA',
  _ => 'IL TUO SPAZIO, A MODO TUO',
};

String ds6MoreIntro(String code) => switch (code) {
  'en' => 'Everything in its place, without losing what matters.',
  'es' => 'Todo en su lugar, sin perder lo importante.',
  'fr' => 'Chaque chose à sa place, sans perdre l’essentiel.',
  'pt' => 'Tudo no seu lugar, sem perder o que importa.',
  _ => 'Ogni cosa al suo posto, senza perdere ciò che conta.',
};

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
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

  Widget _sectionCard({
    required bool editorial,
    required AnnaVisualDomain domain,
    required Widget child,
  }) {
    if (!editorial) return AnnaJournalCard(domain: domain, child: child);
    return AnnaEditorialSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: child,
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
        AnnaEditorialTodayMode.enabled,
      ]),
      builder: (context, _) {
        final prefs = store.preferences;
        final editorial = AnnaEditorialTodayMode.enabled.value;
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
                  if (editorial) ...[
                    AnnaEditorialHeader(
                      title: ds6MoreHeading(strings.languageCode),
                      eyebrow: ds6MoreKicker(strings.languageCode),
                      subtitle: ds6MoreIntro(strings.languageCode),
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceLg),
                    AnnaEditorialSurface(
                      key: const ValueKey<String>('ds6-more-profile'),
                      tone: AnnaEditorialSurfaceTone.featured,
                      semanticLabel: strings.settings,
                      onTap: () => _open(context, SettingsScreen(store: store)),
                      child: Row(
                        children: [
                          Container(
                            width: 49, height: 49,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AnnaEditorialColors.of(context).quiet,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: AnnaEditorialColors.of(context).accent,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              prefs.displayName.trim().isEmpty
                                  ? approvedHolderNamePlaceholder(strings.languageCode)
                                  : prefs.displayName.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AnnaJournalTypography.editorial(context, size: 21),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: AnnaEditorialColors.of(context).accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceLg),
                  ],
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
                  Qw2FavoritesSection(
                    key: ValueKey('qw2-favorites-${store.activeAccountId ?? 'guest'}'),
                    store: store,
                  ),
                  editorial
                      ? AnnaEditorialSectionHeading(title: strings.d3('moreQuickAccess'))
                      : AnnaJournalSectionHeading(title: strings.d3('moreQuickAccess')),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  _sectionCard(
                    editorial: editorial,
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
                  editorial
                      ? AnnaEditorialSectionHeading(title: strings.d3('moreYourSpace'))
                      : AnnaJournalSectionHeading(title: strings.d3('moreYourSpace')),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  if (prefs.isModuleEnabled(AppModule.privateVault)) ...[
                    _sectionCard(
                    editorial: editorial,
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
                  if (prefs.isModuleEnabled(AppModule.memories)) ...[
                    _sectionCard(
                    editorial: editorial,
                    domain: AnnaVisualDomain.memories,
                      child: _tile(
                        id: 'more-future-letters',
                        domain: AnnaVisualDomain.memories,
                        icon: Icons.mark_email_unread_outlined,
                        title: futureLetterTitle(strings),
                        onTap: () => _open(
                          context,
                          PersonalFutureLettersScreen(store: store),
                        ),
                      ),
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceSm),
                  ],
                  _sectionCard(
                    editorial: editorial,
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
                  editorial
                      ? AnnaEditorialSectionHeading(title: strings.d3('moreDataAndApp'))
                      : AnnaJournalSectionHeading(title: strings.d3('moreDataAndApp')),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  _sectionCard(
                    editorial: editorial,
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
