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
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
          Text(strings.v100ExploreIntro),
          const SizedBox(height: 16),
          NavigationCard(
            icon: Icons.shopping_cart_outlined,
            title: strings.v100Shopping,
            subtitle: store.activeShoppingItems.isEmpty
                ? strings.v100ShoppingEmpty
                : strings.v100ShoppingPending(store.activeShoppingItems.length),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShoppingListScreen(store: store)),
            ),
          ),
          const SizedBox(height: 12),
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
              MaterialPageRoute(builder: (_) => WorkoutScreen(store: store)),
            ),
          ),
          const SizedBox(height: 12),
          NavigationCard(
            icon: Icons.photo_library_outlined,
            title: strings.v100MyMemories,
            subtitle: strings.v100MemoriesSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DiaryMemoriesScreen(store: store)),
            ),
          ),
          const SizedBox(height: 12),
          NavigationCard(
            icon: Icons.people_outline,
            title: strings.v100ImportantPeople,
            subtitle: strings.v100PeopleSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PeopleScreen(store: store)),
            ),
          ),
          const SizedBox(height: 12),
          NavigationCard(
            icon: Icons.hub_outlined,
            title: strings.lifeEcosystemTitle,
            subtitle: strings.lifeEcosystemSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LifeEcosystemScreen(store: store)),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
