part of '../../main.dart';

class ExploreScreen extends StatelessWidget {
  final AgendaStore store;
  const ExploreScreen({super.key, required this.store});

  // Share the same routes and callbacks with Classic. Only the journal
  // presentation changes; no secondary navigation or persistence owner.
  Widget _navigationEntry(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    if (!AnnaOrganicPastel.enabled(context)) {
      return NavigationCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      );
    }
    final domain = icon == Icons.favorite_outline
        ? AnnaVisualDomain.memories
        : icon == Icons.lock_person_outlined
            ? AnnaVisualDomain.vault
            : AnnaVisualDomain.people;
    return AnnaOrganicPaperSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: AnnaOrganicJournalRow(
        identifier: 'explore-journal-${icon.codePoint}',
        icon: icon,
        domain: domain,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }

  Widget _emptySurface(BuildContext context, {required Widget child}) =>
      AnnaOrganicPastel.enabled(context)
          ? AnnaOrganicPaperSurface(child: child)
          : SimpleCard(child: child);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AnnaEditorialTodayMode.enabled,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final organic = AnnaOrganicPastel.enabled(context);
        return Scaffold(
      backgroundColor: organic ? AnnaEditorialColors.of(context).canvas : null,
      appBar: AppBar(
        backgroundColor: organic ? AnnaEditorialColors.of(context).canvas : null,
        surfaceTintColor: organic ? Colors.transparent : null,
        scrolledUnderElevation: 0,
        title: Text(
          strings.v100Explore,
          style: organic
              ? AnnaJournalTypography.editorial(context, size: 27)
              : const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          store.shoppingRevision,
          store.workoutRevision,
          store.settingsRevision,
        ]),
        builder: (context, _) {
          final prefs = store.preferences;
          final modules = <Widget>[];

          void addModule(AppModule module, Widget card) {
            if (!prefs.isModuleEnabled(module)) return;
            if (modules.isNotEmpty) modules.add(const SizedBox(height: 12));
            modules.add(card);
          }

          addModule(
            AppModule.shopping,
            _navigationEntry(
              context,
              icon: Icons.shopping_cart_outlined,
              title: strings.v100Shopping,
              subtitle: store.activeShoppingItems.isEmpty
                  ? strings.v100ShoppingEmpty
                  : strings.v100ShoppingPending(
                      store.activeShoppingItems.length,
                    ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShoppingListScreen(store: store),
                ),
              ),
            ),
          );
          addModule(
            AppModule.workout,
            _navigationEntry(
              context,
              icon: Icons.sports_outlined,
              title: strings.v100Workout,
              subtitle: store.workoutSessions.isEmpty
                  ? strings.v100WorkoutEmpty
                  : strings.v100WorkoutSummary(
                      store.workoutSessions.length,
                      store.workoutPlans.length,
                    ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutScreen(store: store),
                ),
              ),
            ),
          );
          addModule(
            AppModule.people,
            _navigationEntry(
              context,
              icon: Icons.people_outline,
              title: strings.v100ImportantPeople,
              subtitle: strings.v100PeopleSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PeopleScreen(store: store),
                ),
              ),
            ),
          );
          addModule(
            AppModule.habits,
            _navigationEntry(
              context,
              icon: Icons.check_circle_outline,
              title: strings.d3('personalizationHabits'),
              subtitle: strings.d3('personalizationHabitsSubtitle'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlannerScreen(
                    store: store,
                    initialDate: DateTime.now(),
                  ),
                ),
              ),
            ),
          );
          addModule(
            AppModule.sharedSpace,
            _navigationEntry(
              context,
              icon: Icons.favorite_outline,
              title: strings.d3('sharedSpace'),
              subtitle: strings.d3('personalizationSharedSpaceSubtitle'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SharedSpaceHubScreen(store: store),
                ),
              ),
            ),
          );
          addModule(
            AppModule.privateVault,
            _navigationEntry(
              context,
              icon: Icons.lock_person_outlined,
              title: strings.v100PrivateVault,
              subtitle: strings.v100PrivateVaultDescription,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PrivateVaultScreen(store: store),
                ),
              ),
            ),
          );
          addModule(
            AppModule.ecosystem,
            _navigationEntry(
              context,
              icon: Icons.hub_outlined,
              title: strings.lifeEcosystemTitle,
              subtitle: strings.lifeEcosystemSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LifeEcosystemScreen(store: store),
                ),
              ),
            ),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                strings.v100ExploreIntro,
                style: organic
                    ? TextStyle(color: AnnaEditorialColors.of(context).mutedInk)
                    : null,
              ),
              const SizedBox(height: 16),
              if (modules.isEmpty)
                _emptySurface(context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.d3('personalizationExploreEmpty'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(strings.d3('personalizationExploreEmptySubtitle')),
                    ],
                  ),
                )
              else
                ...modules,
              const SizedBox(height: 16),
              _navigationEntry(
              context,
                icon: Icons.tune,
                title: strings.d3('personalizationTitle'),
                subtitle: strings.d3('personalizationSettingsSubtitle'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalizationScreen(store: store),
                  ),
                ),
              ),
            ],
          );
        },
      ),
        );
      },
    );
  }
}
