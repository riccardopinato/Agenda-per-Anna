part of '../main.dart';

/// Quick Wins 2 uses only account-scoped local UI preferences. No schema,
/// cloud synchronization, content history or sensitive user text is persisted.
class Qw2UiSettings {
  static String _key(AgendaStore store, String suffix) =>
      'qw2_${suffix}_${store.activeAccountId ?? 'guest'}';

  static List<String> normalizeFavorites(
    Iterable<String> values,
    Set<String> available,
  ) {
    final result = <String>[];
    for (final value in values) {
      if (available.contains(value) && !result.contains(value)) {
        result.add(value);
      }
      if (result.length >= 3) break;
    }
    return result;
  }

  static Future<List<String>> loadFavorites(AgendaStore store) async {
    final key = _key(store, 'moreFavorites');
    final prefs = await SharedPreferences.getInstance();
    final allowed = AppModule.values
        .where((module) => store.preferences.isModuleEnabled(module))
        .map((module) => module.name)
        .toSet();
    return normalizeFavorites(prefs.getStringList(key) ?? const [], allowed);
  }

  static Future<void> saveFavorites(
      AgendaStore store, List<String> selected) async {
    final key = _key(store, 'moreFavorites');
    final allowed = AppModule.values
        .where((module) => store.preferences.isModuleEnabled(module))
        .map((module) => module.name)
        .toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        key, normalizeFavorites(selected, allowed));
  }

  static Future<Map<String, int>> captureCounts(AgendaStore store) async {
    final key = _key(store, 'captureCounts');
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString(key) ?? '{}');
      if (raw is! Map) return {};
      final counts = <String, int>{};
      for (final entry in raw.entries) {
        if (entry.key is String && entry.value is int &&
            entry.value >= 0 && entry.value <= 100000) {
          counts[entry.key as String] = entry.value as int;
        }
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  static Future<void> recordCaptureChoice(
      AgendaStore store, String action, String? accountAtSelection) async {
    if (store.activeAccountId != accountAtSelection) return;
    final key = _key(store, 'captureCounts');
    final prefs = await SharedPreferences.getInstance();
    if (store.activeAccountId != accountAtSelection) return;
    final counts = await captureCounts(store);
    counts[action] = ((counts[action] ?? 0) + 1).clamp(0, 100000);
    // Never persist content, titles, dates or IDs of captured records.
    await prefs.setString(key, jsonEncode(counts));
  }
}

List<T> qw2RankCaptureActions<T>(
  List<T> actions,
  Map<String, int> counts,
  String Function(T) id,
) {
  final indexed = actions.asMap().entries.toList();
  indexed.sort((a, b) {
    final difference =
        (counts[id(b.value)] ?? 0).compareTo(counts[id(a.value)] ?? 0);
    return difference != 0 ? difference : a.key.compareTo(b.key);
  });
  return indexed.map((entry) => entry.value).toList(growable: false);
}

String quickWins2Copy(String language, String key) {
  const copy = <String, List<String>>{
    'inboxEvent': ['Turn into appointment', 'Converti in appuntamento', 'Convertir en cita', 'Transformer en rendez-vous', 'Converter em compromisso'],
    'inboxEventSaved': ['Appointment saved', 'Appuntamento salvato', 'Cita guardada', 'Rendez-vous enregistré', 'Compromisso guardado'],
    'moreFavorites': ['Favorites', 'Preferiti', 'Favoritos', 'Favoris', 'Favoritos'],
    'chooseFavorites': ['Choose up to three shortcuts', 'Scegli fino a tre scorciatoie', 'Elige hasta tres accesos', 'Choisissez trois raccourcis maximum', 'Escolhe até três atalhos'],
    'editFavorites': ['Edit favorites', 'Modifica preferiti', 'Editar favoritos', 'Modifier les favoris', 'Editar favoritos'],
    'settingsSearch': ['Find a setting', 'Cerca un’impostazione', 'Buscar un ajuste', 'Rechercher un réglage', 'Procurar uma definição'],
    'settingsNoMatch': ['No matching settings', 'Nessuna impostazione trovata', 'Ningún ajuste encontrado', 'Aucun réglage trouvé', 'Nenhuma definição encontrada'],
  };
  final index = switch (language) {
    'it' => 1,
    'es' => 2,
    'fr' => 3,
    'pt' => 4,
    _ => 0,
  };
  return copy[key]![index];
}


/// An optional three-item pin strip over existing Explore destinations.
/// No private Vault/Cycle quick entry is exposed here.
class Qw2FavoritesSection extends StatefulWidget {
  final AgendaStore store;
  const Qw2FavoritesSection({super.key, required this.store});

  @override
  State<Qw2FavoritesSection> createState() => _Qw2FavoritesSectionState();
}

class _Qw2FavoritesSectionState extends State<Qw2FavoritesSection> {
  List<String> _favorites = const [];
  static const _options = <AppModule>[
    AppModule.sharedSpace,
    AppModule.shopping,
    AppModule.workout,
    AppModule.people,
    AppModule.habits,
    AppModule.memories,
    AppModule.ecosystem,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accountAtStart = widget.store.activeAccountId;
    final current = await Qw2UiSettings.loadFavorites(widget.store);
    if (!mounted || widget.store.activeAccountId != accountAtStart) return;
    setState(() => _favorites = current);
  }

  String _title(AnnaStrings strings, AppModule module) => switch (module) {
    AppModule.sharedSpace => strings.d3('sharedSpace'),
    AppModule.shopping => strings.v100Shopping,
    AppModule.workout => strings.v100Workout,
    AppModule.people => strings.v100ImportantPeople,
    AppModule.habits => strings.d3('personalizationHabits'),
    AppModule.memories => strings.v100MyMemories,
    AppModule.ecosystem => strings.lifeEcosystemTitle,
    _ => '',
  };

  IconData _icon(AppModule module) => switch (module) {
    AppModule.sharedSpace => Icons.favorite_outline,
    AppModule.shopping => Icons.shopping_cart_outlined,
    AppModule.workout => Icons.sports_outlined,
    AppModule.people => Icons.people_outline,
    AppModule.habits => Icons.check_circle_outline,
    AppModule.memories => Icons.photo_library_outlined,
    AppModule.ecosystem => Icons.hub_outlined,
    _ => Icons.star_outline,
  };

  Widget _destination(AppModule module) => switch (module) {
    AppModule.sharedSpace => SharedSpaceHubScreen(store: widget.store),
    AppModule.shopping => ShoppingListScreen(store: widget.store),
    AppModule.workout => WorkoutScreen(store: widget.store),
    AppModule.people => PeopleScreen(store: widget.store),
    AppModule.habits => PlannerScreen(
        store: widget.store, initialDate: DateTime.now()),
    AppModule.memories => DiaryMemoriesScreen(store: widget.store),
    AppModule.ecosystem => LifeEcosystemScreen(store: widget.store),
    _ => ExploreScreen(store: widget.store),
  };

  Future<void> _edit() async {
    final store = widget.store;
    final account = store.activeAccountId;
    final enabled = _options.where(store.preferences.isModuleEnabled).toList();
    final selected = <String>[..._favorites]
      ..removeWhere((id) => !enabled.any((module) => module.name == id));
    final language = AnnaStrings.of(context).languageCode;
    final changed = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(quickWins2Copy(language, 'chooseFavorites'),
                    style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final module in enabled)
                  CheckboxListTile(
                    key: ValueKey('qw2-favorite-choice-${module.name}'),
                    title: Text(_title(AnnaStrings.of(sheetContext), module)),
                    secondary: Icon(_icon(module)),
                    value: selected.contains(module.name),
                    onChanged: (value) => update(() {
                      if (value == true && selected.length < 3) {
                        selected.add(module.name);
                      } else if (value == false) {
                        selected.remove(module.name);
                      }
                    }),
                  ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(List<String>.from(selected)),
                  child: Text(AnnaStrings.of(sheetContext).save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (changed == null || !mounted || store.activeAccountId != account) {
      return;
    }
    await Qw2UiSettings.saveFavorites(store, changed);
    if (!mounted || store.activeAccountId != account) return;
    setState(() => _favorites = changed);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final strings = AnnaStrings.of(context);
    final visible = <AppModule>[];
    for (final id in _favorites) {
      for (final module in _options) {
        if (module.name == id &&
            store.preferences.isModuleEnabled(module) &&
            !visible.contains(module)) {
          visible.add(module);
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AnnaJournalSectionHeading(
                title: quickWins2Copy(strings.languageCode, 'moreFavorites')),
            ),
            IconButton(
              key: const ValueKey('qw2-favorite-edit'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: quickWins2Copy(strings.languageCode, 'editFavorites'),
              onPressed: _edit,
            ),
          ],
        ),
        if (visible.isNotEmpty)
          AnnaJournalCard(
            domain: AnnaVisualDomain.today,
            child: Column(
              children: [
                for (final module in visible)
                  ListTile(
                    key: ValueKey('qw2-favorite-${module.name}'),
                    leading: Icon(_icon(module)),
                    title: Text(_title(strings, module)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _destination(module),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AnnaDesignTokens.spaceSm),
      ],
    );
  }
}
