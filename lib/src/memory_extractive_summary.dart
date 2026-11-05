part of '../main.dart';

/// Privacy-safe, deterministic extracts: every displayed quote is an exact
/// substring of a private authored diary note. Never an AI-written account.
class MemoryExtractiveQuote {
  final DiaryBlockReference source;
  final String text;
  final int start;
  final int end;
  const MemoryExtractiveQuote(this.source, this.text, this.start, this.end);
}

class MemoryExtractiveReport {
  final List<MemoryExtractiveQuote> quotes;
  final int eligibleNotes;
  final int scannedNotes;
  final bool partial;
  const MemoryExtractiveReport(
      this.quotes, this.eligibleNotes, this.scannedNotes, this.partial);
  bool get isEmpty => quotes.isEmpty;
}

class _MemorySentenceCandidate {
  final DiaryBlockReference reference;
  final String sentence;
  final int start;
  final int end;
  final List<String> terms;
  const _MemorySentenceCandidate(
      this.reference, this.sentence, this.start, this.end, this.terms);
}

const _memoryExtractiveStopWords = <String>{
  'the', 'and', 'for', 'with', 'that', 'this', 'from', 'was', 'were',
  'are', 'have', 'there', 'about', 'per', 'con', 'che', 'del',
  'della', 'delle', 'dei', 'gli', 'era', 'sono', 'oggi', 'ieri',
  'una', 'uno', 'non', 'nel', 'nella', 'anche', 'dopo', 'prima',
  'como', 'para', 'por', 'los', 'las', 'estaba', 'cuando',
  'les', 'des', 'dans', 'pour', 'avec', 'sur', 'vous',
  'nous', 'mais', 'das', 'dos', 'uma', 'isso', 'essa',
};

/// Pure computation with bounded memory/time; no cloud, storage or models.
/// Caller must supply the currently authorized private memoryReferences().
MemoryExtractiveReport memoryExtractiveReport(
  Iterable<DiaryBlockReference> references, {
  DateTime? fromInclusive,
  DateTime? toExclusive,
  String? placeKey,
  String? personId,
  int maxQuotes = 4,
  int maxDocuments = 200,
}) {
  final count = maxQuotes.clamp(0, 8).toInt();
  final budget = maxDocuments.clamp(1, 200).toInt();
  final normalizedPlace = placeKey?.trim().toLowerCase();
  final eligible = references.where((entry) {
    final block = entry.block;
    if (block.archived || block.type != DiaryBlockType.note ||
        block.text.trim().isEmpty) {
      return false;
    }
    if (normalizedPlace != null && normalizedPlace.isNotEmpty &&
        !block.places.any((p) => p.normalizedName == normalizedPlace)) {
      return false;
    }
    if (personId != null && personId.isNotEmpty &&
        !block.personIds.contains(personId)) {
      return false;
    }
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    if (fromInclusive != null && date.isBefore(fromInclusive)) return false;
    if (toExclusive != null && !date.isBefore(toExclusive)) return false;
    return true;
  }).toList(growable: false)
    ..sort((a, b) {
      final d = b.date.compareTo(a.date);
      if (d != 0) return d;
      final c = b.block.createdAt.compareTo(a.block.createdAt);
      return c != 0 ? c : a.block.id.compareTo(b.block.id);
    });

  final candidates = <_MemorySentenceCandidate>[];
  final frequency = <String, int>{};
  final unique = <String>{};
  final tokens = RegExp(r'[\p{L}\p{N}]{3,}', unicode: true);
  final sentencePattern = RegExp(r'[^.!?\n]+[.!?]?');

  var scannedNotes = 0;
  var candidateBudgetReached = false;
  for (final record in eligible.take(budget)) {
    scannedNotes++;
    final raw = record.block.text;
    final bounded = raw.length > 12000 ? raw.substring(0, 12000) : raw;
    var perNote = 0;
    for (final match in sentencePattern.allMatches(bounded)) {
      if (perNote >= 8) break;
      if (candidates.length >= 600) {
        candidateBudgetReached = true;
        break;
      }
      if (bounded.length < raw.length && match.end == bounded.length) break;
      var start = match.start;
      var end = match.end;
      while (start < end && raw[start].trim().isEmpty) { start++; }
      while (end > start && raw[end - 1].trim().isEmpty) { end--; }
      if (end - start < 12 || end - start > 600) continue;
      final sentence = raw.substring(start, end);
      final key = sentence.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (!unique.add(key)) continue;
      final words = tokens.allMatches(key)
          .map((m) => m.group(0)!)
          .where((w) => !_memoryExtractiveStopWords.contains(w))
          .take(80)
          .toList(growable: false);
      if (words.isEmpty) continue;
      candidates.add(_MemorySentenceCandidate(
          record, sentence, start, end, words));
      for (final word in words.toSet()) {
        frequency.update(word, (v) => v + 1, ifAbsent: () => 1);
      }
      perNote++;
    }
    if (candidates.length >= 600) {
      candidateBudgetReached = true;
      break;
    }
  }

  double rank(_MemorySentenceCandidate c) {
    var sum = 0.0;
    for (final word in c.terms.toSet()) {
      sum += 1 + (frequency[word] ?? 0);
    }
    return sum / (c.terms.length + 1);
  }
  candidates.sort((a, b) {
    final score = rank(b).compareTo(rank(a));
    if (score != 0) return score;
    final recent = b.reference.date.compareTo(a.reference.date);
    if (recent != 0) return recent;
    final id = a.reference.block.id.compareTo(b.reference.block.id);
    return id != 0 ? id : a.start.compareTo(b.start);
  });

  final selection = <_MemorySentenceCandidate>[];
  final selectedIds = <String>{};
  for (final c in candidates) {
    if (selection.length == count) break;
    if (selectedIds.add(c.reference.block.id)) selection.add(c);
  }
  for (final c in candidates) {
    if (selection.length == count) break;
    if (!selection.contains(c)) selection.add(c);
  }
  final quotes = selection.map((c) => MemoryExtractiveQuote(
      c.reference, c.sentence, c.start, c.end)).toList(growable: false);
  return MemoryExtractiveReport(
      List.unmodifiable(quotes), eligible.length,
      scannedNotes,
      eligible.length > budget || candidateBudgetReached);
}
