part of '../../main.dart';

class ExploreScreen extends StatelessWidget {
  final AgendaStore store;
  const ExploreScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.v100Explore,
          style: const TextStyle(fontWeight: FontWeight.w800),
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
            NavigationCard(
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
            NavigationCard(
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
            NavigationCard(
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
            NavigationCard(
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
            NavigationCard(
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
            NavigationCard(
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
            NavigationCard(
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
              Text(strings.v100ExploreIntro),
              const SizedBox(height: 16),
              if (modules.isEmpty)
                SimpleCard(
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
              NavigationCard(
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
  }
}
