part of '../main.dart';

/// Ordered, derived view of the *existing* personal search, not a second index.
enum ApprovedSearchSort { newest, oldest, alphabetical }

/// Labels follow the five language codes supported by Anna's Diary.
String approvedSearchOrderTitle(String code) => switch (code) {
  'en' => 'Sort by',
  'es' => 'Ordenar',
  'fr' => 'Trier',
  'pt' => 'Ordenar',
  _ => 'Ordina',
};

String approvedSearchReasonTitle(String code) => switch (code) {
  'en' => 'Match in',
  'es' => 'Coincidencia en',
  'fr' => 'Correspondance dans',
  'pt' => 'Correspondência em',
  _ => 'Corrispondenza in',
};

extension ApprovedSearchSortUi on ApprovedSearchSort {
  String approvedLabel(String code) => switch (this) {
    ApprovedSearchSort.alphabetical => 'A–Z',
    ApprovedSearchSort.newest => switch (code) {
      'en' => 'Newest', 'es' => 'Más recientes',
      'fr' => 'Plus récents', 'pt' => 'Mais recentes',
      _ => 'Più recenti',
    },
    ApprovedSearchSort.oldest => switch (code) {
      'en' => 'Oldest', 'es' => 'Más antiguos',
      'fr' => 'Plus anciens', 'pt' => 'Mais antigos',
      _ => 'Meno recenti',
    },
  };
}


extension ApprovedSearchPolicy on AgendaStore {
  List<PersonalSearchHit> approvedPersonalSearch(
    String query, {
    Set<PersonalSearchKind>? kinds,
    bool includeArchived = false,
    String languageCode = 'it',
    ApprovedSearchSort sort = ApprovedSearchSort.newest,
  }) {
    final hits = personalSearch(
      query,
      kinds: kinds,
      includeArchived: includeArchived,
      languageCode: languageCode,
    );
    if (query.trim().runes.length == 1) {
      final letter = query.trim().toLowerCase();
      hits.removeWhere((hit) => !hit.title.toLowerCase().contains(letter));
    }
    hits.sort((a, b) {
      if (sort == ApprovedSearchSort.alphabetical) {
        final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (byTitle != 0) return byTitle;
      } else {
        final byDate = sort == ApprovedSearchSort.oldest
            ? a.date.compareTo(b.date)
            : b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
      }
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
    });
    return hits;
  }

  /// Only reveals values the original search is already allowed to index.
  /// Never looks inside the Private Vault.
  String? approvedSearchMatchEvidence(PersonalSearchHit hit, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < 2 ||
        (hit.title + ' ' + hit.subtitle).toLowerCase().contains(trimmed)) {
      return null;
    }
    final fields = <String>[];
    if (hit.agendaItem != null) {
      fields.add(hit.agendaItem!.note);
    }
    if (hit.inboxId != null) {
      for (final item in inbox) {
        if (item.id != hit.inboxId) continue;
        fields.add(item.text);
        fields.addAll(item.tags.map((tag) => '#'+tag));
        break;
      }
    }
    if (hit.diaryBlockId != null) {
      diaryLookup: for (final journal in journals.values) {
        for (final block in journal.blocks) {
          if (block.id != hit.diaryBlockId) continue;
          fields.add(block.text);
          fields.add(block.ocrText);
          fields.addAll(block.tags.map((tag) => '#'+tag));
          fields.addAll(block.places.map((place) => place.name));
          fields.addAll(block.pages
              .expand((page) => page.textElements)
              .map((element) => element.text));
          break diaryLookup;
        }
      }
    }
    if (hit.id.startsWith('journal:')) {
      final journal = journals[hit.id.substring(8)];
      if (journal != null) {
        fields.add(journal.note);
        fields.add(journal.beautiful);
        fields.addAll(journal.gratitude);
      }
    }
    if (hit.personId != null) {
      for (final person in people) {
        if (person.id == hit.personId) {
          fields.add(person.relationship);
          fields.add(person.note);
          break;
        }
      }
    }
    final tokens = trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final evidence = <String>[];
    final pending = tokens.toSet();
    for (final field in fields) {
      final text = field.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty) continue;
      final found = pending.where((token) => text.toLowerCase().contains(token)).toList();
      if (found.isEmpty) continue;
      pending.removeAll(found);
      evidence.add(text.length > 90 ? text.substring(0, 90) + '…' : text);
      if (pending.isEmpty || evidence.length == 3) break;
    }
    return evidence.isEmpty ? null : evidence.join(' · ');
  }
}
