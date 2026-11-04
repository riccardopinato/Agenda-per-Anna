// Deterministic LOCAL-ONLY correspondence suggestions for Anna's Diary.
// No persistence, cloud upload, automated merging or event writes.
// Source calendar ID + source event ID are kept separate from local canonical IDs.
import 'two_phase_flutter_client.dart';

enum GcalDiaryContextKind { appointment, diaryNote }

class GcalDiaryLocalContext {
  final String id;
  final String title;
  final DateTime day;
  final DateTime? startTime;
  final GcalDiaryContextKind kind;

  const GcalDiaryLocalContext({
    required this.id,required this.title,required this.day,
    required this.kind,this.startTime,
  });
}

enum GcalDiaryMatchLevel { exactTimeAndTitle, sameDayAndTitle }

class GcalDiaryMatchSuggestion {
  final GcalDiaryLocalContext local;
  final GcalDiaryMatchLevel level;
  final bool ambiguous;
  const GcalDiaryMatchSuggestion(this.local,this.level,this.ambiguous);
}

String _normalizeTitle(String text) => text
  .trim()
  .toLowerCase()
  .replaceAll(RegExp(r'[^a-z0-9à-ÿ]+'), ' ')
  .replaceAll(RegExp(r'\s+'), ' ')
  .trim();

bool _sameDay(DateTime left,DateTime right)=>
    left.year==right.year&&left.month==right.month&&left.day==right.day;

/// Candidate matches are suggestions, NEVER equivalence assertions.
/// No event is copied, imported, deleted or modified; no diary note is sent
/// to Google or Supabase to perform the comparison.
List<GcalDiaryMatchSuggestion> googleDiarySuggestions(
  GcalStageEvent google,List<GcalDiaryLocalContext> localEntries,
) {
  final eventDay=google.start.toLocal();
  final normalized=_normalizeTitle(google.title);
  if(normalized.isEmpty||normalized=='senza titolo')return const [];
  final candidates=<({GcalDiaryLocalContext entry,GcalDiaryMatchLevel level})>[];
  final seen=<String>{};
  for(final local in localEntries){
    if(!seen.add('${local.kind.name}:${local.id}') ||
       !_sameDay(eventDay,local.day)||
       _normalizeTitle(local.title)!=normalized){continue;}
    final at=local.startTime;
    final timeMatch=!google.allDay&&at!=null&&
      at.toLocal().difference(eventDay).abs()<=const Duration(minutes:15);
    candidates.add((
      entry:local,
      level:timeMatch?GcalDiaryMatchLevel.exactTimeAndTitle:
        GcalDiaryMatchLevel.sameDayAndTitle,
    ));
  }
  candidates.sort((a,b){
    final aRank=a.level==GcalDiaryMatchLevel.exactTimeAndTitle?0:1;
    final bRank=b.level==GcalDiaryMatchLevel.exactTimeAndTitle?0:1;
    final diff=aRank.compareTo(bRank);
    return diff!=0?diff:a.entry.id.compareTo(b.entry.id);
  });
  final ambiguous=candidates.length>1;
  return List.unmodifiable(candidates.map((candidate)=>
    GcalDiaryMatchSuggestion(candidate.entry,candidate.level,ambiguous)));
}