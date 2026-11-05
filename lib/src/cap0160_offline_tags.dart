part of '../main.dart';

/// CAP-0160: local, deterministic sparse TF-IDF. No model, I/O or writes.
/// Source documents are supplied only by the currently active private store.
class Cap0160ScopeChanged implements Exception {
  const Cap0160ScopeChanged();

  @override
  String toString() => 'CAP-0160: account scope changed before Save';
}

class Cap0160PrivateDocument {
  const Cap0160PrivateDocument({required this.id, required this.text});
  final String id;
  final String text;
}

class Cap0160TagSuggestion {
  const Cap0160TagSuggestion(this.tag, this.score, this.reason);
  final String tag;
  final double score;
  final String reason;
}

abstract final class Cap0160TagSuggester {
  static const maxCorpusDocs = 512;
  static const maxTextChars = 4000;
  static const maxSuggestionCount = 4;

  // Hand-authored, bounded function-word lists for Anna's actual 5 locales.
  static const _stopwords = <String, String>{
    'it': 'alla alle anche ancora avere che chi come con cosa dal dalla delle '
        'degli dopo dove essere fatto fra gli il in io la le lo ma mi mio '
        'molto nei nel nella non noi nostro o per perché piu più poi quale '
        'quando questo questa questi quello se sei senza si sì sono stato '
        'sua suo su sul tra un una uno voi oggi domani ieri',
    'en': 'about after again all also am an and are as at be because been '
        'before but by can could did do does for from had has have he her '
        'here him his how i if in into is it its me my no not of on or our '
        'she so some than that the their them there these they this those '
        'through to too us was we were what when where which while who '
        'why will with would you your today tomorrow yesterday',
    'es': 'algo algunos antes asi así aunque cada como con cuando de del desde '
        'donde el ella ellas ellos en entre era eres es esa ese eso esta '
        'este esto estos fue ha hay hasta la las le les lo los mas más '
        'me mi mis muy no nos o para pero por porque que quien se ser '
        'si sí sin sobre son su sus te tiene todo tu un una unos y yo hoy',
    'fr': 'ainsi alors aussi autre aux avec avant car ce ces cet cette chez '
        'comme dans de des du elle elles en encore est et être eux fait il '
        'ils je la le les leur leurs lui mais mes moi mon ne nos notre nous '
        'ou où par pas pour pourquoi quand que quel quelle qui sa se ses '
        'si son sont sur ta te tes ton tout tu un une vous votre vos',
    'pt': 'ainda algo algumas alguns antes ao aos as até com como da das de '
        'dela deles depois desde do dos e é ela elas ele eles em entre '
        'era essa esse esta este estou eu foi há hoje isso isto já lhe '
        'mais mas me meu minha muito na nas nem no nos nossa nosso o os '
        'ou para pela pelo por porque que quem se sem seu sua são ser '
        'sim sobre também tem ter tu um uma uns vocês',
  };
  static final _words = RegExp(r'[\p{L}\p{M}]+', unicode: true);
  static final _urls = RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false);
  static final _emails = RegExp(
    r'[\p{L}\p{M}\p{N}._%+-]+@[\p{L}\p{M}\p{N}.-]+\.[\p{L}]{2,}',
    unicode: true,
    caseSensitive: false,
  );

  static List<String> _tokens(String text, Set<String> stop) {
    final bounded = text.length <= maxTextChars
        ? text : text.substring(0, maxTextChars);
    // Strip complete addresses first. If the 4000-unit cutoff falls
    // anywhere inside a non-whitespace token (including exactly before '@'),
    // drop that entire trailing token rather than exposing a partial email,
    // URL or keyword in the inline suggestions.
    var clean = bounded.replaceAll(_urls, ' ').replaceAll(_emails, ' ');
    if (bounded.length < text.length &&
        bounded.isNotEmpty &&
        !RegExp(r'\s').hasMatch(bounded[bounded.length - 1]) &&
        !RegExp(r'\s').hasMatch(text[maxTextChars])) {
      clean = clean.replaceFirst(RegExp(r'\S+$'), ' ');
    }
    return _words.allMatches(clean)
        .map((match) => match.group(0)!.toLowerCase())
        .where((term) => term.runes.length >= 4 &&
            term.runes.length <= 32 && !stop.contains(term))
        .take(600).toList(growable: false);
  }

  static List<Cap0160TagSuggestion> propose({
    required String text,
    required String languageCode,
    required Iterable<Cap0160PrivateDocument> authorizedPrivateCorpus,
    Iterable<String> currentTags = const [],
    bool scopeReady = false,
    bool sharedOnly = false,
  }) {
    if (!scopeReady || sharedOnly || text.trim().isEmpty) return const [];
    final stopwordText = _stopwords[languageCode];
    if (stopwordText == null) return const []; // Unknown locale: fail closed.
    final stop = stopwordText.split(' ').toSet();
    final tokens = _tokens(text, stop);
    if (tokens.isEmpty) return const [];
    final frequency = <String, int>{};
    for (final word in tokens) {
      frequency.update(word, (count) => count + 1, ifAbsent: () => 1);
    }
    final candidates = frequency.keys.toSet();
    final df = <String, int>{};
    var documents = 0;
    var scanned = 0;
    final seenIds = <String>{};
    final iterator = authorizedPrivateCorpus.iterator;
    while (scanned < maxCorpusDocs && iterator.moveNext()) {
      scanned++;
      final document = iterator.current;
      if (document.id.trim().isEmpty || !seenIds.add(document.id)) {
        continue;
      }
      documents++;
      for (final word in _tokens(document.text, stop).toSet()) {
        if (candidates.contains(word)) {
          df.update(word, (count) => count + 1, ifAbsent: () => 1);
        }
      }
    }
    final excluded = currentTags.map(organizationTagComparisonKey).toSet();
    final result = <Cap0160TagSuggestion>[];
    for (final word in candidates) {
      if (excluded.contains(organizationTagComparisonKey(word))) continue;
      final tf = 1 + log(frequency[word]!);
      final idf = documents == 0
          ? 1.0 : log((documents + 1) / ((df[word] ?? 0) + 1)) + 1;
      result.add(Cap0160TagSuggestion(
        word, tf * idf, documents == 0 ? 'text_frequency' : 'tf_idf',
      ));
    }
    result.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score == 0 ? a.tag.compareTo(b.tag) : score;
    });
    return List<Cap0160TagSuggestion>.unmodifiable(
      result.take(maxSuggestionCount),
    );
  }

  /// No shared-space, Vault, credentials or other account profiles are read.
  static List<Cap0160TagSuggestion> forInbox(
    AgendaStore store, InboxEntry entry, String languageCode, {
    bool inlineFastPath = false,
  }) {
    if (!store.entryScopeReady ||
        store.agendaContentFilter == AgendaContentFilter.sharedOnly ||
        entry.archived ||
        !store.inbox.any((item) => item.id == entry.id &&
            !item.archived && item.text == entry.text)) {
      return const [];
    }
    return propose(
      text: entry.text,
      languageCode: languageCode,
      currentTags: entry.tags,
      scopeReady: true,
      // Cards only rank words in this note. Deep TF-IDF across the
      // authorized corpus remains available when the editor opens, but never
      // repeats up to 512 document scans for each visible Inbox card.
      authorizedPrivateCorpus: inlineFastPath
          ? const <Cap0160PrivateDocument>[]
          : store.inbox
              .where((item) => !item.archived && item.id != entry.id)
              .map((item) => Cap0160PrivateDocument(
                    id: item.id, text: item.text,
                  )),
    );
  }

  static List<Cap0160TagSuggestion> forDiary(
    AgendaStore store, DateTime day, DiaryBlock block, String languageCode, {
    bool inlineFastPath = false,
  }) {
    if (!store.entryScopeReady ||
        store.agendaContentFilter == AgendaContentFilter.sharedOnly ||
        block.archived ||
        !store.journal(day).blocks.any((item) => item.id == block.id &&
            !item.archived && item.text == block.text)) {
      return const [];
    }
    return propose(
      text: block.text,
      languageCode: languageCode,
      currentTags: block.tags,
      scopeReady: true,
      // Eager Diary card rendering must be O(note length), not
      // O(visible notes * 512 private documents).
      authorizedPrivateCorpus: inlineFastPath
          ? const <Cap0160PrivateDocument>[]
          : store.journals.entries.expand((entry) =>
              entry.value.blocks.where((item) =>
                  !item.archived && item.id != block.id).map((item) =>
                      Cap0160PrivateDocument(
                        id: '${entry.key}/${item.id}',
                        text: item.text,
                      ))),
    );
  }
}

/// A dialog opened before switching profiles must never save to another
/// profile, including a switch A -> B -> A during the same dialog lifetime.
class Cap0160TagEditGuard {
  Cap0160TagEditGuard(this.store)
      : accountId = store.activeAccountId,
        epoch = store.accountScopeEpoch;
  final AgendaStore store;
  final String? accountId;
  final int epoch;
  bool get isCurrent =>
      store.entryScopeReady &&
      store.agendaContentFilter != AgendaContentFilter.sharedOnly &&
      store.activeAccountId == accountId &&
      store.accountScopeEpoch == epoch;
}
