part of '../main.dart';

/// Derived daily-use helpers: no second agenda owner or persisted flags.
DateTime quickWinTomorrow(DateTime now) =>
    DateTime(now.year, now.month, now.day + 1);

List<AgendaItem> overduePrivateTasks(
    Iterable<AgendaItem> items, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final overdue = items.where((item) =>
      item.type == ItemType.task &&
      !item.done &&
      item.date.isBefore(today)).toList();
  overdue.sort((a, b) {
    final dateOrder = b.date.compareTo(a.date);
    return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
  });
  return List<AgendaItem>.unmodifiable(overdue);
}

bool canPostponeTask(AgendaItem item) =>
    item.type == ItemType.task && !item.done && !item.isRecurring;

/// Re-read the canonical entity at action time; never move a recurring
/// occurrence by editing its civil day outside the recurrence engine.
Future<bool> postponePrivateTask(
    AgendaStore store, String id, DateTime now,
    {required String? accountAtOpen}) async {
  if (store.activeAccountId != accountAtOpen) return false;
  AgendaItem? current;
  for (final item in store.items) {
    if (item.id == id) {
      current = item;
      break;
    }
  }
  if (current == null || !canPostponeTask(current)) return false;
  final tomorrow = quickWinTomorrow(now);
  if (AgendaStore.sameDay(current.date, tomorrow)) return false;
  await store.upsert(current.copyWith(date: tomorrow));
  return true;
}

String quickWinText(AnnaStrings strings, String key) {
  const labels = <String, List<String>>{
    'duplicateDate': ['Duplicate and choose date', 'Duplica e scegli la data', 'Duplicar y elegir fecha', 'Dupliquer et choisir la date', 'Duplicar e escolher a data'],
    'postpone': ['Move to tomorrow', 'Rimanda a domani', 'Pasar a mañana', 'Reporter à demain', 'Adiar para amanhã'],
    'postponed': ['Task moved to tomorrow', 'Attività spostata a domani', 'Tarea pasada a mañana', 'Tâche reportée à demain', 'Tarefa adiada para amanhã'],
    'postponeFailed': ['Could not move this task. Try again.', 'Impossibile spostare l’attività. Riprova.', 'No se pudo mover la tarea.', 'Impossible de déplacer la tâche.', 'Não foi possível adiar a tarefa.'],
    'overdue': ['To catch up', 'Da recuperare', 'Pendiente de recuperar', 'À rattraper', 'Por recuperar'],
    'overdueCount': ['Overdue tasks', 'Attività in sospeso', 'Tareas pendientes', 'Tâches en retard', 'Tarefas em atraso'],
    'tomorrow': ['Tomorrow', 'Domani', 'Mañana', 'Demain', 'Amanhã'],
    'tomorrowEmpty': ['No commitments yet', 'Nessun impegno previsto', 'Todavía sin compromisos', 'Pas encore de rendez-vous', 'Sem compromissos previstos'],
    'tomorrowOpen': ['Open tomorrow', 'Apri domani', 'Abrir mañana', 'Ouvrir demain', 'Abrir amanhã'],
    'tomorrowMore': ['See all', 'Vedi tutti', 'Ver todos', 'Tout voir', 'Ver todos'],
    'conflictTitle': ['Overlapping appointments', 'Appuntamenti sovrapposti', 'Citas solapadas', 'Rendez-vous qui se chevauchent', 'Compromissos sobrepostos'],
    'conflictIntro': ['This time overlaps with:', 'Questo orario si sovrappone a:', 'Este horario coincide con:', 'Cet horaire chevauche :', 'Este horário coincide com:'],
    'conflictReview': ['Review time', 'Rivedi orario', 'Revisar hora', 'Revoir l’horaire', 'Rever horário'],
    'conflictSave': ['Save anyway', 'Salva comunque', 'Guardar de todos modos', 'Enregistrer quand même', 'Guardar na mesma'],
    'conflictPartial': ['Only visible, authorized calendars are checked. External calendar data may be incomplete.', 'Sono controllati solo i calendari visibili e autorizzati. I dati esterni potrebbero essere incompleti.', 'Solo se comprueban calendarios visibles y autorizados. Los datos externos pueden ser parciales.', 'Seuls les calendriers autorisés et visibles sont vérifiés. Les données externes peuvent être incomplètes.', 'Só são verificados calendários visíveis e autorizados. Dados externos podem estar incompletos.'],
    'conflictSeries': ['Other occurrences in this series are not checked.', 'Le altre occorrenze della serie non vengono controllate.', 'No se comprueban otras repeticiones.', 'Les autres occurrences ne sont pas vérifiées.', 'As restantes repetições não são verificadas.'],
  };
  final index = switch (strings.languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
  };
  return labels[key]![index];
}

Future<void> showPostponeTask(
    BuildContext context, AgendaStore store, AgendaItem item) async {
  final account = store.activeAccountId;
  try {
    final moved = await postponePrivateTask(
      store, item.id, DateTime.now(), accountAtOpen: account);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(quickWinText(AnnaStrings.of(context),
            moved ? 'postponed' : 'postponeFailed')),
      ));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(quickWinText(AnnaStrings.of(context), 'postponeFailed')),
      ));
    }
  }
}

/// Appears only on Oggi and only for the private agenda scope.
class TodayCatchUpCard extends StatelessWidget {
  final AgendaStore store;
  final bool hideDetails;
  const TodayCatchUpCard({
    super.key, required this.store, required this.hideDetails,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = overduePrivateTasks(store.items, DateTime.now());
    if (overdue.isEmpty) return const SizedBox.shrink();
    final strings = AnnaStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('daily-quick-wins-overdue'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.assignment_late_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(quickWinText(strings, 'overdue'),
                style: Theme.of(context).textTheme.titleMedium)),
            Text('${overdue.length}', style: Theme.of(context).textTheme.titleSmall),
          ]),
          Text(quickWinText(strings, 'overdueCount'),
              style: Theme.of(context).textTheme.bodySmall),
          for (final item in overdue.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(hideDetails
                  ? strings.d3('editor_hiddenContent')
                  : item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(DateFormat('d MMM', AnnaStrings.intlLocale(context))
                  .format(item.date)),
              onTap: () => openItemEditor(context, store, item.date,
                  existing: item),
              trailing: canPostponeTask(item)
                  ? IconButton(
                      key: ValueKey('overdue-tomorrow-${item.id}'),
                      tooltip: quickWinText(strings, 'postpone'),
                      onPressed: () => showPostponeTask(context, store, item),
                      icon: const Icon(Icons.redo_outlined),
                    )
                  : const Icon(Icons.chevron_right),
            ),
          if (overdue.length > 3)
            TextButton(
              onPressed: () => _showAllOverdueTasks(context, store, hideDetails),
              child: Text(quickWinText(strings, 'tomorrowMore')),
            ),
        ]),
      ),
    );
  }
}

Future<void> _showAllOverdueTasks(
    BuildContext context, AgendaStore store, bool hideDetails) async {
  await showModalBottomSheet<void>(
    context: context, showDragHandle: true, isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.65,
        child: AnimatedBuilder(
          animation: Listenable.merge([store.agendaRevision, store.accountRevision]),
          builder: (ctx, _) {
            final overdue = overduePrivateTasks(store.items, DateTime.now());
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(quickWinText(AnnaStrings.of(ctx), 'overdue'),
                    style: Theme.of(ctx).textTheme.titleLarge),
                for (final item in overdue)
                  ListTile(
                    title: Text(hideDetails
                        ? AnnaStrings.of(ctx).d3('editor_hiddenContent')
                        : item.title),
                    subtitle: Text(DateFormat('d MMM yyyy',
                        AnnaStrings.intlLocale(ctx)).format(item.date)),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (context.mounted) {
                        await openItemEditor(context, store, item.date,
                            existing: item);
                      }
                    },
                    trailing: canPostponeTask(item) ? IconButton(
                      tooltip: quickWinText(AnnaStrings.of(ctx), 'postpone'),
                      icon: const Icon(Icons.redo_outlined),
                      onPressed: () => showPostponeTask(ctx, store, item),
                    ) : null,
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class TodayTomorrowCard extends StatelessWidget {
  final AgendaStore store;
  final bool hideDetails;
  const TodayTomorrowCard({
    super.key, required this.store, required this.hideDetails,
  });

  @override
  Widget build(BuildContext context) {
    final day = quickWinTomorrow(DateTime.now());
    final entries = store.unifiedForDay(day)
        .where((entry) => entry.type == ItemType.appointment || !entry.done)
        .toList()
      ..sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
    final strings = AnnaStrings.of(context);
    return Card(
      key: const ValueKey('daily-quick-wins-tomorrow'),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => PlannerScreen(store: store, initialDate: day))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.wb_twilight_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(quickWinText(strings, 'tomorrow'),
                  style: Theme.of(context).textTheme.titleMedium)),
              Tooltip(message: quickWinText(strings, 'tomorrowOpen'),
                  child: const Icon(Icons.chevron_right)),
            ]),
            const SizedBox(height: 5),
            if (entries.isEmpty)
              Text(quickWinText(strings, 'tomorrowEmpty'))
            else
              for (final entry in entries.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    hideDetails
                        ? strings.d3('editor_hiddenContent')
                        : '${entry.start == null ? '' : '${formatTime(entry.start!)} · '}${entry.title}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
            if (entries.length > 3)
              Text(quickWinText(strings, 'tomorrowMore'),
                  style: Theme.of(context).textTheme.labelMedium),
          ]),
        ),
      ),
    );
  }
}

Future<bool> confirmAppointmentOverlap(
  BuildContext context, AgendaStore store, AgendaItem candidate, {
  bool recurring = false,
}) async {
  if (candidate.type != ItemType.appointment) return true;
  final ext = ExternalCalendarService.instance;
  final d = candidate.date;
  final from = DateTime(d.year, d.month, d.day - 1);
  final until = DateTime(d.year, d.month, d.day + 2);
  try {
    await ext.initialize();
    if (ext.supported && ext.enabled) {
      await ext.refreshStatus();
      if (ext.permissionGranted && !ext.coversRange(from, until)) {
        await ext.loadRange(from, until);
      }
    }
  } catch (_) {
    // An unavailable optional external calendar cannot block local editing.
  }
  if (!context.mounted) return false;
  final conflicts = findAppointmentConflicts(
    candidate: candidate,
    visibleEntries: visibleEntriesForCalendarFreeSlots(
      store, d, externalReady: ext.coversRange(from, until),
    ),
  );
  if (conflicts.isEmpty) return true;
  final strings = AnnaStrings.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('quick-wins-overlap-dialog'),
      title: Text(quickWinText(strings, 'conflictTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quickWinText(strings, 'conflictIntro')),
            const SizedBox(height: 8),
            for (final clash in conflicts.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• ${clash.title}'),
              ),
            const SizedBox(height: 8),
            Text(quickWinText(strings, 'conflictPartial'),
              style: Theme.of(dialogContext).textTheme.bodySmall),
            if (recurring)
              Text(quickWinText(strings, 'conflictSeries'),
                style: Theme.of(dialogContext).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(quickWinText(strings, 'conflictReview')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(quickWinText(strings, 'conflictSave')),
        ),
      ],
    ),
  );
  return result ?? false;
}
