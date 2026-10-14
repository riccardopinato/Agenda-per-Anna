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
        actions: [
          Semantics(
            identifier: 'explore_personalize',
            button: true,
            child: IconButton(
              tooltip: strings.v101PersonalizeTitle,
              icon: const Icon(Icons.tune_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PersonalizationScreen(store: store),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          store.shoppingRevision,
          store.workoutRevision,
          store.settingsRevision,
        ]),
        builder: (context, _) {
          final prefs = store.preferences;
          final cards = <Widget>[];

          void addCard(Widget card) {
            if (cards.isNotEmpty) {
              cards.add(const SizedBox(height: 12));
            }
            cards.add(card);
          }

          if (prefs.isModuleEnabled(AppModule.shopping)) {
            addCard(
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
                  MaterialPageRoute<void>(
                    builder: (_) => ShoppingListScreen(store: store),
                  ),
                ),
              ),
            );
          }

          if (prefs.isModuleEnabled(AppModule.workout)) {
            addCard(
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
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutScreen(store: store),
                  ),
                ),
              ),
            );
          }

          if (prefs.isModuleEnabled(AppModule.memories)) {
            addCard(
              NavigationCard(
                icon: Icons.photo_library_outlined,
                title: strings.v100MyMemories,
                subtitle: strings.v100MemoriesSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DiaryMemoriesScreen(store: store),
                  ),
                ),
              ),
            );
          }

          if (prefs.isModuleEnabled(AppModule.people)) {
            addCard(
              NavigationCard(
                icon: Icons.people_outline,
                title: strings.v100ImportantPeople,
                subtitle: strings.v100PeopleSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PeopleScreen(store: store),
                  ),
                ),
              ),
            );
          }

          if (prefs.isModuleEnabled(AppModule.ecosystem)) {
            addCard(
              NavigationCard(
                icon: Icons.hub_outlined,
                title: strings.lifeEcosystemTitle,
                subtitle: strings.lifeEcosystemSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LifeEcosystemScreen(store: store),
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(strings.v101ExplorePersonalizedIntro),
              const SizedBox(height: 16),
              if (cards.isEmpty)
                SimpleCard(
                  child: Column(
                    children: [
                      const Icon(Icons.tune_outlined, size: 34),
                      const SizedBox(height: 10),
                      Text(
                        strings.v101NothingEnabledTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.v101NothingEnabledSubtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PersonalizationScreen(store: store),
                          ),
                        ),
                        icon: const Icon(Icons.tune_outlined),
                        label: Text(strings.v101PersonalizeTitle),
                      ),
                    ],
                  ),
                )
              else
                ...cards,
            ],
          );
        },
      ),
    );
  }
}
