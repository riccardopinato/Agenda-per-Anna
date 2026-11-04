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

/// CAP-0152: bounded, local fuzzy search after the existing source/visibility
/// policy. No index is persisted and no private Vault content is introduced.
int annaFuzzyEditDistance(String left, String right, {int maxEdits = 2}) {
  if ((left.length - right.length).abs() > maxEdits) return maxEdits + 1;
  var previous = List<int>.generate(right.length + 1, (i) => i);
  for (var i = 1; i <= left.length; i++) {
    final current = List<int>.filled(right.length + 1, 0);
    current[0] = i;
    var best = current[0];
    for (var j = 1; j <= right.length; j++) {
      final substitution = left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1)
          ? 0 : 1;
      final replace = previous[j - 1] + substitution;
      final insert = current[j - 1] + 1;
      final delete = previous[j] + 1;
      current[j] = [replace, insert, delete].reduce((a, b) => a < b ? a : b);
      if (current[j] < best) best = current[j];
    }
    if (best > maxEdits) return maxEdits + 1;
    previous = current;
  }
  return previous.last;
}

int? annaFuzzyTitleDistance(String query, String title) {
  final tokens = query.toLowerCase()
      .split(RegExp(r'\\s+')).where((t) => t.length >= 2).toList();
  if (tokens.isEmpty || tokens.length > 6 || query.length > 80) return null;
  final words = RegExp(r'[\\p{L}\\p{N}]+', unicode: true)
      .allMatches(title.toLowerCase())
      .map((m) => m.group(0)!)
      .where((w) => w.length >= 2 && w.length <= 48)
      .take(120)
      .toList(growable: false);
  if (words.isEmpty) return null;
  var total = 0;
  for (final token in tokens) {
    final allowance = token.length < 5 ? 1 : 2;
    var best = allowance + 1;
    for (final word in words) {
      if (token == word) { best = 0; break; }
      if (word.length > 48 || token.length > 48) continue;
      final d = annaFuzzyEditDistance(token, word, maxEdits: allowance);
      if (d < best) best = d;
      if (best == 0) break;
    }
    if (best > allowance) return null;
    total += best;
  }
  return total == 0 ? null : total; // exact title belongs to original search.
}

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
    // Only a fallback when the canonical query has zero authorized matches.
    // The same source retriever owns exclusions, account scope and kinds.
    if (hits.isEmpty && query.trim().length >= 3 && query.length <= 80) {
      final needle = query.trim().toLowerCase();
      final terms = needle.split(RegExp(r'\\s+'));
      if (terms.length <= 6 && terms.every((t) => t.length >= 2)) {
        final anchors = <String>{
          if (terms.first.isNotEmpty) terms.first.substring(0, 1),
          if (terms.first.length > 1) terms.first.substring(1, 2),
        };
        final candidates = <String, PersonalSearchHit>{};
        var tooMany = false;
        for (final anchor in anchors) {
          for (final hit in personalSearch(
            anchor,
            kinds: kinds,
            includeArchived: includeArchived,
            languageCode: languageCode,
          )) {
            candidates.putIfAbsent('${hit.kind.name}:${hit.id}', () => hit);
            if (candidates.length > 5000) { tooMany = true; break; }
          }
          if (tooMany) break;
        }
        if (!tooMany) {
          final near = <({PersonalSearchHit hit, int edits})>[];
          for (final hit in candidates.values) {
            final distance = annaFuzzyTitleDistance(needle, hit.title);
            if (distance == null) continue;
            near.add((hit: hit, edits: distance));
          }
          near.sort((a, b) {
            final score = a.edits.compareTo(b.edits);
            if (score != 0) return score;
            final date = b.hit.date.compareTo(a.hit.date);
            if (date != 0) return date;
            return a.hit.id.compareTo(b.hit.id);
          });
          hits.addAll(near.take(25).map((e) => e.hit));
        }
      }
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
        '${hit.title} ${hit.subtitle}'.toLowerCase().contains(trimmed)) {
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
        fields.addAll(item.tags.map((tag) => '#$tag'));
        break;
      }
    }
    if (hit.diaryBlockId != null) {
      diaryLookup: for (final journal in journals.values) {
        for (final block in journal.blocks) {
          if (block.id != hit.diaryBlockId) continue;
          fields.add(block.text);
          fields.add(block.ocrText);
          fields.addAll(block.tags.map((tag) => '#$tag'));
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
    if (hit.birthdayId != null) {
      for (final birthday in birthdays) {
        if (birthday.id != hit.birthdayId) continue;
        fields.add(birthday.name);
        fields.add(birthday.note);
        break;
      }
    }
    if (hit.kind == PersonalSearchKind.month) {
      final data = months[hit.id];
      if (data != null) {
        fields.add(data.intention);
        fields.addAll(data.goals);
        fields.addAll(data.books);
        fields.addAll(data.films);
        fields.addAll(data.hobbies);
        fields.addAll(data.wishes);
        fields.addAll(data.ideas);
        fields.add(data.monthWord);
        fields.add(data.selfCare);
        fields.add(data.bestMoment);
        fields.add(data.lesson);
        fields.add(data.challenge);
        fields.add(data.nextMonth);
        fields.add(data.reflection);
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
      // A long field may contain several search tokens far apart.
      // Every token that provides evidence must appear in a visible snippet.
      for (final token in found) {
        final position = text.toLowerCase().indexOf(token);
        if (position < 0) continue;
        final left = (position - 30).clamp(0, text.length).toInt();
        final right = (position + token.length + 55)
            .clamp(0, text.length).toInt();
        evidence.add([
          if (left > 0) '…',
          text.substring(left, right),
          if (right < text.length) '…',
        ].join());
        if (evidence.length >= 8) break;
      }
      if (pending.isEmpty || evidence.length >= 8) break;
    }
    return evidence.isEmpty ? null : evidence.join(' · ');
  }
}
