part of '../main.dart';

/// B1 / CAP-0002: offline deterministic parsing, without writes or network.
class NaturalEventDraft {
  final String title;
  final DateTime date;
  final TimeOfDay start;
  final int? reminderMinutesBefore;
  final RecurrenceRule recurrence;
  const NaturalEventDraft({
    required this.title,
    required this.date,
    required this.start,
    this.reminderMinutesBefore,
    this.recurrence = RecurrenceRule.none,
  });
}

NaturalEventDraft? parseNaturalEvent(String phrase, {
  required String languageCode,
  required DateTime now,
}) {
  if (!const {'en', 'it', 'es', 'fr', 'pt'}.contains(languageCode) ||
      phrase.trim().isEmpty || phrase.length > 300) return null;
  var remaining = phrase.trim().replaceAll(RegExp(r'\s+'), ' ');
  final normalized = remaining.toLowerCase();
  // Unknown explicit zones cannot safely be translated into local time.
  if (RegExp(r'\b(?:utc|gmt|cet|cest|pst|pdt|est|edt)\b',
      caseSensitive: false).hasMatch(normalized)) return null;

  final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b')
      .allMatches(remaining).toList();
  final dayFirst = RegExp(r'\b(\d{1,2})[/.](\d{1,2})[/.](\d{4})\b')
      .allMatches(remaining).toList();
  final relative = RegExp(
    r'\b(oggi|domani|today|tomorrow|hoy|mañana|aujourd.hui|demain|hoje|amanhã|amanha)\b',
    caseSensitive: false,
  ).allMatches(remaining).toList();
  if (iso.length + dayFirst.length + relative.length != 1) return null;
  late final DateTime date;
  late final String dateToken;
  if (iso.isNotEmpty || dayFirst.isNotEmpty) {
    final isIso = iso.isNotEmpty;
    final match = isIso ? iso.single : dayFirst.single;
    final year = int.parse(match.group(isIso ? 1 : 3)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(isIso ? 3 : 1)!);
    if (year < 2020 || year > 2040) return null;
    date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    dateToken = match.group(0)!;
  } else {
    dateToken = relative.single.group(0)!;
    const today = {'oggi', 'today', 'hoy', 'aujourd\'hui', 'hoje'};
    final offset = today.contains(dateToken.toLowerCase()) ? 0 : 1;
    date = DateTime(now.year, now.month, now.day + offset);
    if (date.year > 2040) return null;
  }
  // The phrase must supply a time; no guessing from user preferences.
  final prefixedPattern = RegExp(
    r'(?:^|\s)(?:alle|at|a las|à|às|as)\s+(\d{1,2})(?:[:h.](\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false,
  );
  final plainPattern = RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm)?\b',
    caseSensitive: false);
  final prefixed = prefixedPattern.allMatches(remaining).toList();
  final matches = prefixed.isNotEmpty
      ? prefixed : plainPattern.allMatches(remaining).toList();
  if (matches.length != 1) return null;
  final match = matches.single;
  var hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0') ?? -1;
  final suffix = match.group(3)?.toLowerCase();
  if (minute < 0 || minute > 59 || (suffix == null && hour > 23) ||
      (suffix != null && (hour < 1 || hour > 12))) return null;
  if (suffix != null) hour = hour % 12 + (suffix == 'pm' ? 12 : 0);
  final local = DateTime(date.year, date.month, date.day, hour, minute);
  if (local.year != date.year || local.month != date.month ||
      local.day != date.day || local.hour != hour || local.minute != minute) {
    return null; // DST spring gap.
  }
  for (final direction in const [-1, 1]) {
    final other = DateTime.fromMillisecondsSinceEpoch(
      local.millisecondsSinceEpoch + direction * 3600000);
    if (other.year == date.year && other.month == date.month &&
        other.day == date.day && other.hour == hour && other.minute == minute &&
        other.timeZoneOffset != local.timeZoneOffset) {
      return null; // DST autumn repeated civil time.
    }
  }

  final remindCue = RegExp(
    r'(?:ricordami|remind me|recuérdame|recuerdame|rappelle.moi|lembra.me)',
    caseSensitive: false);
  final reminderPattern = RegExp(
    r'(?:ricordami\s+il\s+giorno\s+prima|remind\s+me\s+the\s+day\s+before|recuérdame\s+el\s+día\s+antes|recuerdame\s+el\s+dia\s+antes|rappelle.moi\s+la\s+veille|lembra.me\s+(?:um\s+)?dia\s+antes)',
    caseSensitive: false);
  final reminders = reminderPattern.allMatches(remaining).toList();
  if (reminders.length > 1 ||
      (remindCue.hasMatch(normalized) && reminders.length != 1)) return null;

  final recurrenceCue = RegExp(
    r'\b(?:ogni|every|todos|todas|chaque|cada|tous)\b',
    caseSensitive: false);
  final daily = RegExp(
    r'(?:ogni\s+giorno|every\s+day|todos\s+los\s+días|todos\s+os\s+dias|chaque\s+jour)',
    caseSensitive: false).allMatches(remaining).toList();
  final weekly = RegExp(
    r'(?:ogni\s+settimana|every\s+week|cada\s+semana|chaque\s+semaine)',
    caseSensitive: false).allMatches(remaining).toList();
  if (daily.length + weekly.length > 1 ||
      (recurrenceCue.hasMatch(normalized) && daily.isEmpty && weekly.isEmpty)) {
    return null;
  }
  final recurrence = daily.isNotEmpty ? RecurrenceRule.daily
      : weekly.isNotEmpty ? RecurrenceRule.weekly : RecurrenceRule.none;
  remaining = remaining.replaceFirst(dateToken, ' ')
      .replaceFirst(match.group(0)!, ' ');
  if (reminders.isNotEmpty) {
    remaining = remaining.replaceFirst(reminders.single.group(0)!, ' ');
  }
  if (daily.isNotEmpty) remaining = remaining.replaceFirst(daily.single.group(0)!, ' ');
  if (weekly.isNotEmpty) remaining = remaining.replaceFirst(weekly.single.group(0)!, ' ');
  remaining = remaining.replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,;:\-]+|[\s,;:\-]+$'), '').trim();
  if (remaining.isEmpty || remaining.length > 160 ||
      remindCue.hasMatch(remaining) || recurrenceCue.hasMatch(remaining)) {
    return null;
  }
  return NaturalEventDraft(
    title: remaining,
    date: date,
    start: TimeOfDay(hour: hour, minute: minute),
    reminderMinutesBefore: reminders.isEmpty ? null : 1440,
    recurrence: recurrence,
  );
}

String naturalEventLabel(String lang, String key) {
  const copy = <String, List<String>>{
    'action': ['From a sentence', 'Da una frase', 'Desde una frase', 'À partir d’une phrase', 'A partir de uma frase'],
    'heading': ['Create from a sentence', 'Crea da una frase', 'Crear desde una frase', 'Créer à partir d’une phrase', 'Criar a partir de uma frase'],
    'hint': ['Meeting tomorrow at 17:30', 'Dentista domani alle 17:30', 'Cita mañana a las 17:30', 'Dentiste demain à 17h30', 'Dentista amanhã às 17:30'],
    'preview': ['Preview', 'Anteprima', 'Vista previa', 'Aperçu', 'Pré-visualização'],
    'unknown': ['Not recognized. Provide a date (or today/tomorrow) and time, or use the manual editor.', 'Non riconosciuto. Indica una data (o oggi/domani) e un orario, oppure usa l’editor manuale.', 'No reconocido. Indica fecha y hora o usa el editor manual.', 'Non reconnu. Indiquez une date et une heure ou utilisez la saisie manuelle.', 'Não reconhecido. Indique uma data e hora ou use o editor manual.'],
    'use': ['Use in editor', 'Usa nell’editor', 'Usar en editor', 'Utiliser dans l’éditeur', 'Usar no editor'],
    'cancel': ['Back to manual editor', 'Torna all’editor manuale', 'Volver al editor manual', 'Retour à la saisie manuelle', 'Voltar ao editor manual'],
    'check': ['Check all fields before saving; no event has been created.', 'Controlla tutti i campi prima di salvare: nessun evento è stato creato.', 'Revisa los campos antes de guardar. No se ha creado un evento.', 'Vérifiez les champs avant d’enregistrer. Aucun événement créé.', 'Verifique todos os campos antes de guardar. Nenhum evento criado.'],
    'timezone': ['Local time zone', 'Fuso orario locale', 'Zona horaria local', 'Fuseau horaire local', 'Fuso horário local'],
  };
  final index = switch (lang) { 'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0 };
  return copy[key]![index];
}

Future<NaturalEventDraft?> showNaturalEventParser(BuildContext context) async {
  final controller = TextEditingController();
  NaturalEventDraft? parsed;
  bool unrecognized = false;
  final language = AnnaStrings.of(context).languageCode;
  try {
    return await showDialog<NaturalEventDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(naturalEventLabel(language, 'heading')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const ValueKey('b1-natural-input'),
                  controller: controller, autofocus: true, maxLines: 3, maxLength: 300,
                  onChanged: (_) => setLocal(() { parsed = null; unrecognized = false; }),
                  decoration: InputDecoration(
                    hintText: naturalEventLabel(language, 'hint'),
                    border: const OutlineInputBorder()),
                ),
                if (unrecognized) Text(naturalEventLabel(language, 'unknown'),
                    key: const ValueKey('b1-natural-unrecognized')),
                if (parsed != null) ...[
                  const SizedBox(height: 8),
                  Text(naturalEventLabel(language, 'check')),
                  const SizedBox(height: 8),
                  Text(parsed!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('d MMMM yyyy', language).format(parsed!.date)),
                  Text(formatTime(parsed!.start)),
                  Text(naturalEventLabel(language, 'timezone') + ': ' +
                    DateTime(parsed!.date.year, parsed!.date.month, parsed!.date.day,
                      parsed!.start.hour, parsed!.start.minute).timeZoneName),
                  if (parsed!.reminderMinutesBefore != null)
                    Text(AnnaStrings.of(context).d3('editor_dayBefore')),
                  if (parsed!.recurrence != RecurrenceRule.none)
                    Text(AnnaStrings.of(context).editorRecurrenceLabel(parsed!.recurrence)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(naturalEventLabel(language, 'cancel'))),
            OutlinedButton(
              onPressed: () => setLocal(() {
                parsed = parseNaturalEvent(controller.text,
                    languageCode: language, now: DateTime.now());
                unrecognized = parsed == null;
              }),
              child: Text(naturalEventLabel(language, 'preview'))),
            if (parsed != null)
              FilledButton(
                key: const ValueKey('b1-use-draft'),
                onPressed: () => Navigator.pop(dialogContext, parsed),
                child: Text(naturalEventLabel(language, 'use'))),
          ],
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}
