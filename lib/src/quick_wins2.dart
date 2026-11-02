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
