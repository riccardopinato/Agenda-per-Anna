part of '../main.dart';

/// Read-only, explainable advice using the same visible agenda as Today.
class RealisticDayAdvice {
  const RealisticDayAdvice({
    required this.freeMinutes,
    required this.pendingTasks,
    required this.reasonCode,
    required this.firstFreeSlot,
  });

  final int freeMinutes;
  final int pendingTasks;
  final String reasonCode;
  final CalendarFreeSlot? firstFreeSlot;

  bool get hasPressure => reasonCode == 'VISIBLE_WINDOW_CONGESTED';
}

abstract final class RealisticDayAdvisor {
  static RealisticDayAdvice evaluate({
    required DateTime day,
    required Iterable<UnifiedAgendaEntry> visibleEntries,
    required int pendingTasks,
  }) {
    final slots = findCalendarFreeSlots(
      day: day,
      visibleEntries: visibleEntries,
      startHour: 9,
      endHour: 21,
      minimumMinutes: 1,
    );
    final minutes = slots.fold<int>(
      0,
      (sum, slot) => sum + slot.duration.inMinutes,
    );
    final candidate = slots.where(
      (slot) => slot.duration.inMinutes >= 30,
    );
    return RealisticDayAdvice(
      freeMinutes: minutes,
      pendingTasks: pendingTasks,
      firstFreeSlot: candidate.isEmpty ? null : candidate.first,
      reasonCode: pendingTasks > 0 && minutes < 90
          ? 'VISIBLE_WINDOW_CONGESTED'
          : 'VISIBLE_WINDOW_CAPACITY',
    );
  }
}

class RealisticDayCard extends StatelessWidget {
  const RealisticDayCard({
    required this.store,
    required this.snapshot,
    required this.hideDetails,
    super.key,
  });

  final AgendaStore store;
  final DayHubSnapshot snapshot;
  final bool hideDetails;

  String _localized(String lang, String key) {
    const copy = <String, List<String>>{
      'title': [
        'Plan a realistic day',
        'Organizza una giornata realistica',
        'Organiza un día realista',
        'Organisez une journée réaliste',
        'Planeie um dia realista',
      ],
      'pressure': [
        'Your visible calendar is almost full. Review commitments before '
            'planning more.',
        'Il calendario visibile è quasi pieno. Rivedi gli impegni prima '
            'di pianificare altro.',
        'El calendario visible está casi lleno. Revisa los compromisos.',
        'Le calendrier visible est presque plein. Vérifiez vos rendez-vous.',
        'O calendário visível está quase cheio. Reveja seus compromissos.',
      ],
      'capacity': [
        'Free time in the visible calendar',
        'Tempo libero nel calendario visibile',
        'Tiempo libre en el calendario visible',
        'Temps libre dans le calendrier visible',
        'Tempo livre no calendário visível',
      ],
      'scope': [
        'Estimates exclude unscheduled tasks and unavailable calendars.',
        'Stima: esclusi task non pianificati e calendari non disponibili.',
        'Estimación: no incluye tareas sin horario ni otros calendarios.',
        'Estimation : hors tâches non planifiées et calendriers indisponibles.',
        'Estimativa: exclui tarefas sem horário e calendários indisponíveis.',
      ],
      'slots': [
        'Review free times',
        'Controlla gli orari',
        'Revisar horarios',
        'Voir les créneaux',
        'Ver horários',
      ],
      'prepare': [
        'Prepare appointment',
        'Prepara appuntamento',
        'Preparar cita',
        'Préparer le rendez-vous',
        'Preparar compromisso',
      ],
    };
    final index = switch (lang) {
      'it' => 1,
      'es' => 2,
      'fr' => 3,
      'pt' => 4,
      _ => 0,
    };
    return copy[key]![index];
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final advice = RealisticDayAdvisor.evaluate(
      day: snapshot.date,
      visibleEntries: snapshot.agenda,
      pendingTasks: snapshot.pendingTaskCount,
    );
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day + 3);
    final upcoming = store.agendaContentFilter == AgendaContentFilter.sharedOnly
        ? <UnifiedAgendaEntry>[]
        : store
            .unifiedUpcoming(now)
            .where((entry) =>
                entry.isPrivate &&
                entry.type == ItemType.appointment &&
                !entry.date.isBefore(DateTime(now.year, now.month, now.day)) &&
                entry.date.isBefore(cutoff) &&
                canPrepareEvent(entry.privateItem!))
            .toList(growable: false);
    final prep = upcoming.isEmpty ? null : upcoming.first.privateItem;
    if (snapshot.pendingTaskCount == 0 && prep == null) {
      return const SizedBox.shrink();
    }
    final hours = advice.freeMinutes ~/ 60;
    final minutes = advice.freeMinutes % 60;
    return Card(
      key: const ValueKey('realistic-day-advice'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localized(strings.languageCode, 'title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              advice.hasPressure
                  ? _localized(strings.languageCode, 'pressure')
                  : '${_localized(strings.languageCode, 'capacity')}: '
                      '${hours}h ${minutes}m',
            ),
            const SizedBox(height: 4),
            Text(
              _localized(strings.languageCode, 'scope'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => showCalendarFreeSlots(
                    context,
                    store,
                    snapshot.date,
                  ),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(_localized(strings.languageCode, 'slots')),
                ),
                if (prep != null)
                  TextButton.icon(
                    onPressed: () => openEventPreparation(
                      context,
                      store,
                      prep,
                    ),
                    icon: const Icon(Icons.checklist_outlined),
                    label: Text(_localized(strings.languageCode, 'prepare')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
