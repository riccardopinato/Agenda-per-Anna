part of '../../main.dart';

/// Source-only path for an optional first-party private diary note.
/// No UI currently invokes [TwelveWeeksDraftWriter.saveConfirmed].
class TwelveWeeksDraftPlan {
  const TwelveWeeksDraftPlan({
    required this.week,
    required this.title,
    required this.chapterTitle,
    required this.prompt,
    this.intention = '',
    this.includeReview = true,
  });

  final int week; // one-based chapter, 1..12
  final String title;
  final String chapterTitle;
  final String prompt;
  final String intention;
  final bool includeReview;

  String prepareText() {
    final cleanTitle = title.trim();
    final chapter = chapterTitle.trim();
    final question = prompt.trim();
    final goal = intention.trim();
    if (week < 1 || week > 12 || cleanTitle.isEmpty ||
        cleanTitle.length > 90 || cleanTitle.contains('\n') ||
        chapter.isEmpty || chapter.length > 180 ||
        chapter.contains('\n') || question.isEmpty ||
        question.length > 300 || question.contains('\n') ||
        goal.length > 300) {
      throw const FormatException('twelve_weeks_invalid_draft');
    }
    final body = [
      '# $cleanTitle',
      '',
      '## Settimana $week — $chapter',
      '',
      question,
      if (goal.isNotEmpty) ...['', '## Intenzione personale', goal],
      if (includeReview) ...['', '## Riflessione settimanale', ''],
    ].join('\n');
    if (body.length > 1600) {
      throw const FormatException('twelve_weeks_draft_too_large');
    }
    return body;
  }
}

/// A deliberately unconnected transactional adapter. It must not be invoked
/// from the prototype before product/rights admission and full account QA.
/// Uses AgendaStore.saveJournal as the sole durable writer, and a stable
/// client-generated request ID as the persisted idempotency receipt.
abstract final class TwelveWeeksDraftWriter {
  static final Set<String> _inFlight = <String>{};
  static final _requestIdPattern = RegExp(r'^[a-zA-Z0-9_-]{8,64}$');

  static Future<DiaryBlock?> saveConfirmed(
    AgendaStore store,
    DateTime day,
    TwelveWeeksDraftPlan draft, {
    required bool userConfirmed,
    required String requestId,
    required Cap0160TagEditGuard scopeGuard,
  }) async {
    if (!userConfirmed || !_requestIdPattern.hasMatch(requestId) ||
        !scopeGuard.isCurrent || !store.entryScopeReady ||
        store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return null;
    }

    final body = draft.prepareText(); // validate before touching the store
    final target = DateTime(day.year, day.month, day.day);
    final id = 'twelve_weeks_v1_$requestId';
    final inFlightKey = '${identityHashCode(store)}:${scopeGuard.epoch}:$id';
    if (!_inFlight.add(inFlightKey)) return null;
    try {
      if (!scopeGuard.isCurrent) return null;
      final journal = store.journal(target);
      // A receipt belongs to one user and one civil date. Search the entire
      // currently loaded profile, not just the requested day: replaying the
      // same request on another day must never create a duplicate block ID.
      final targetKey = dateKey(target);
      for (final entry in store.journals.entries) {
        for (final existing in entry.value.blocks) {
          if (existing.id != id) continue;
          if (!scopeGuard.isCurrent || entry.key != targetKey) return null;
          // Same date + same original request = existing record. Edited
          // content or a date mismatch must never be overwritten.
          return existing.text == body ? existing : null;
        }
        if (!scopeGuard.isCurrent) return null;
      }
      if (!scopeGuard.isCurrent) return null;
      final block = DiaryBlock(
        id: id,
        type: DiaryBlockType.note,
        createdAt: DateTime.now(),
        text: body,
        tags: const <String>['reflection'],
      );
      await store.saveJournal(
        target,
        journal.copyWith(blocks: [...journal.blocks, block]),
        scopeGuard: scopeGuard,
      );
      return scopeGuard.isCurrent ? block : null;
    } on Cap0160ScopeChanged {
      return null;
    } finally {
      _inFlight.remove(inFlightKey);
    }
  }
}
