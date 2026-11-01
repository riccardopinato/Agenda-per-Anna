part of '../main.dart';

/// B2: derived calendar interval; never a stored item or promise of availability.
class CalendarFreeSlot {
  final DateTime start;
  final DateTime end;
  const CalendarFreeSlot(this.start, this.end);
  Duration get duration => end.difference(start);
}

/// Computes gaps after intersecting and merging overlapping visible appointments.
List<CalendarFreeSlot> findCalendarFreeSlots({
  required DateTime day,
  required Iterable<UnifiedAgendaEntry> visibleEntries,
  required int startHour,
  required int endHour,
  required int minimumMinutes,
}) {
  if (startHour < 0 || startHour > 23 || endHour < 0 ||
      endHour > 23 || minimumMinutes < 1 || minimumMinutes > 1440) {
    return const <CalendarFreeSlot>[];
  }
  final from = DateTime(day.year, day.month, day.day, startHour);
  final until = DateTime(day.year, day.month,
      day.day + (endHour <= startHour ? 1 : 0), endHour);
  if (!until.isAfter(from)) return const <CalendarFreeSlot>[];
  final busy = <CalendarFreeSlot>[];
  final seen = <String>{};
  for (final item in visibleEntries) {
    if (item.type != ItemType.appointment) continue;
    final identity = item.isExternal ? 'external:${item.id}' :
        item.isShared ? 'shared:${item.space?.id}:${item.id}' : 'private:${item.id}';
    if (!seen.add(identity)) continue;
    DateTime first;
    DateTime last;
    final external = item.externalEvent;
    if (external != null) {
      first = external.start;
      last = external.end;
      if (external.allDay && !last.isAfter(first)) {
        last = DateTime(first.year, first.month, first.day + 1);
      }
    } else if (item.start == null) {
      // An untimed appointment has no safely known start or end.
      first = DateTime(item.date.year, item.date.month, item.date.day);
      last = DateTime(item.date.year, item.date.month, item.date.day + 1);
    } else {
      final clock = item.start!;
      first = DateTime(item.date.year, item.date.month, item.date.day,
          clock.hour, clock.minute);
      if (item.end == null) {
        // Never invent a duration; conservatively busy until midnight.
        last = DateTime(item.date.year, item.date.month, item.date.day + 1);
      } else {
        final endClock = item.end!;
        final crossesMidnight = endClock.hour * 60 + endClock.minute <=
            clock.hour * 60 + clock.minute;
        last = DateTime(item.date.year, item.date.month,
            item.date.day + (crossesMidnight ? 1 : 0),
            endClock.hour, endClock.minute);
      }
    }
    if (!last.isAfter(first)) continue;
    first = first.isBefore(from) ? from : first;
    last = last.isAfter(until) ? until : last;
    if (last.isAfter(first)) busy.add(CalendarFreeSlot(first, last));
  }
  busy.sort((a, b) {
    final compare = a.start.compareTo(b.start);
    return compare != 0 ? compare : a.end.compareTo(b.end);
  });
  final free = <CalendarFreeSlot>[];
  var cursor = from;
  for (final interval in busy) {
    if (interval.start.isAfter(cursor)) {
      final gap = CalendarFreeSlot(cursor, interval.start);
      if (gap.duration.inMinutes >= minimumMinutes) free.add(gap);
    }
    if (interval.end.isAfter(cursor)) cursor = interval.end;
    if (!cursor.isBefore(until)) break;
  }
  if (until.isAfter(cursor)) {
    final gap = CalendarFreeSlot(cursor, until);
    if (gap.duration.inMinutes >= minimumMinutes) free.add(gap);
  }
  return List<CalendarFreeSlot>.unmodifiable(free);
}

/// Uses the same authorized AgendaStore view as Calendar, including its
/// private/shared filter. Only permitted, opted-in external overlay is added.
List<UnifiedAgendaEntry> visibleEntriesForCalendarFreeSlots(
    AgendaStore store, DateTime day, {required bool externalReady}) {
  final entries = <UnifiedAgendaEntry>[];
  for (final offset in const [-1, 0, 1]) {
    final target = DateTime(day.year, day.month, day.day + offset);
    entries.addAll(store.unifiedForDay(target));
    if (externalReady && store.agendaContentFilter == AgendaContentFilter.all) {
      entries.addAll(ExternalCalendarService.instance.eventsForDay(target)
          .where((event) => !isOwnedAndroidCalendarDuplicate(store, event))
          .map(UnifiedAgendaEntry.external));
    }
  }
  return entries;
}

String calendarFreeSlotLabel(AnnaStrings s, String key) {
  const translations = <String, List<String>>{
    'open': ['Find free time', 'Trova orari liberi', 'Buscar huecos libres', 'Trouver un créneau', 'Encontrar horários livres'],
    'title': ['Free times in visible calendars', 'Orari liberi nei calendari visibili', 'Huecos en calendarios visibles', 'Créneaux des calendriers visibles', 'Horários livres nos calendários visíveis'],
    'window': ['Time window', 'Fascia oraria', 'Franja horaria', 'Plage horaire', 'Janela horária'],
    'duration': ['Minimum duration', 'Durata minima', 'Duración mínima', 'Durée minimale', 'Duração mínima'],
    'work': ['Working hours 09–18', 'Orario di lavoro 09–18', 'Horario laboral 09–18', 'Heures de travail 09–18', 'Horário de trabalho 09–18'],
    'empty': ['No free slot in this window.', 'Nessuno slot libero nella fascia scelta.', 'No hay huecos libres.', 'Aucun créneau disponible.', 'Nenhum intervalo livre.'],
    'partial': ['Partial results: the external calendar is unavailable, unselected, denied or not fully loaded.', 'Risultati parziali: calendario esterno non disponibile, non selezionato, senza permesso o non aggiornato.', 'Resultados parciales: calendario externo no disponible o no actualizado.', 'Résultats partiels : calendrier externe indisponible ou non actualisé.', 'Resultados parciais: calendário externo indisponível ou desatualizado.'],
    'scope': ['Only authorized visible appointments count. Tasks do not block time. Untimed appointments block all day; missing end times block until midnight.', 'Contano solo gli appuntamenti visibili e autorizzati. Le attività non occupano tempo. Appuntamenti senza orario: giornata intera; senza fine: fino a mezzanotte.', 'Solo citas visibles y autorizadas. Tareas no bloquean; citas sin hora ocupan todo el día.', 'Seuls les rendez-vous autorisés comptent. Les tâches ne bloquent pas ; sans heure, la journée est occupée.', 'Apenas compromissos autorizados contam. Tarefas não bloqueiam; sem hora, o dia fica ocupado.'],
    'confirm': ['Selecting a slot opens the existing editor. Nothing is saved until confirmation. Review the ending time.', 'La scelta apre l’editor esistente. Nessun salvataggio senza conferma. Verifica l’ora di fine.', 'Elegir un hueco abre el editor; nada se guarda sin confirmar. Revisa el fin.', 'Le choix ouvre l’éditeur. Rien n’est enregistré sans confirmation. Vérifiez l’heure de fin.', 'A escolha abre o editor. Nada é guardado sem confirmar. Verifique a hora final.'],
    'stale': ['The calendar changed. Review updated free times before continuing.', 'Il calendario è cambiato. Rivedi gli orari disponibili prima di continuare.', 'El calendario ha cambiado. Revisa los nuevos horarios.', 'Le calendrier a changé. Vérifiez les créneaux à nouveau.', 'O calendário mudou. Reveja os horários disponíveis.'],
    'account': ['Account changed. Close and reopen free times.', 'Account cambiato. Chiudi e riapri gli orari liberi.', 'Cuenta cambiada. Cierra y vuelve a abrir.', 'Compte changé. Fermez et rouvrez les créneaux.', 'Conta alterada. Feche e volte a abrir.'],
  };
  final i = switch (s.languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
  };
  return translations[key]![i];
}

Future<void> showCalendarFreeSlots(
    BuildContext context, AgendaStore store, DateTime day) async {
  final external = ExternalCalendarService.instance;
  await external.initialize();
  if (external.supported && external.enabled) {
    await external.refreshStatus();
    if (external.permissionGranted) {
      await external.loadRange(
        DateTime(day.year, day.month, day.day - 1),
        DateTime(day.year, day.month, day.day + 2),
      );
    }
  }
  if (!context.mounted) return;
  final accountAtOpen = store.activeAccountId;
  var startHour = 7;
  var endHour = 22;
  var minimumMinutes = 30;
  var workingHours = false;

  final picked = await showModalBottomSheet<CalendarFreeSlot>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: Listenable.merge([
        store.agendaRevision,
        store.sharedRevision,
        store.accountRevision,
        external,
      ]),
      builder: (sheetContext, _) => StatefulBuilder(
        builder: (sheetContext, change) {
        final strings = AnnaStrings.of(sheetContext);
        if (store.activeAccountId != accountAtOpen) {
          return SafeArea(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(calendarFreeSlotLabel(strings, 'account')),
          ));
        }
        final wantsExternal = store.agendaContentFilter == AgendaContentFilter.all;
        final ready = external.coversRange(
          DateTime(day.year, day.month, day.day - 1),
          DateTime(day.year, day.month, day.day + 2),
        );
        final slots = findCalendarFreeSlots(
          day: day,
          visibleEntries: visibleEntriesForCalendarFreeSlots(
              store, day, externalReady: wantsExternal && ready),
          startHour: workingHours ? 9 : startHour,
          endHour: workingHours ? 18 : endHour,
          minimumMinutes: minimumMinutes,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.72,
              child: SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(calendarFreeSlotLabel(strings, 'title'),
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                  Text(DateFormat.yMMMMEEEEd(
                    AnnaStrings.intlLocale(sheetContext)).format(day)),
                  Text(strings.unifiedFilterLabel(store.agendaContentFilter)),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(calendarFreeSlotLabel(strings, 'work')),
                    value: workingHours,
                    onChanged: (value) => change(() => workingHours = value)),
                  Text(calendarFreeSlotLabel(strings, 'window')),
                  Row(children: [
                    for (final beginning in [true, false]) ...[
                      Expanded(child: DropdownButtonFormField<int>(
                        key: ValueKey((beginning ? 'b2-start-' : 'b2-end-') +
                            workingHours.toString()),
                        isExpanded: true,
                        initialValue: workingHours
                            ? (beginning ? 9 : 18)
                            : (beginning ? startHour : endHour),
                        decoration: const InputDecoration(
                            border: OutlineInputBorder()),
                        items: [
                          for (var h = 0; h < 24; h++)
                            DropdownMenuItem<int>(value: h,
                              child: Text('${h.toString().padLeft(2, '0')}:00')),
                        ],
                        onChanged: workingHours ? null : (hour) {
                          if (hour == null) return;
                          change(() {
                            if (beginning) { startHour = hour; }
                            else { endHour = hour; }
                          });
                        },
                      )),
                      if (beginning) const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ]),
                  Row(children: [
                    Expanded(child: Text(calendarFreeSlotLabel(strings, 'duration'))),
                    DropdownButton<int>(
                      value: minimumMinutes,
                      items: [
                        for (final m in [15, 30, 45, 60, 90, 120])
                          DropdownMenuItem(value: m, child: Text('$m min')),
                      ],
                      onChanged: (m) {
                        if (m != null) change(() => minimumMinutes = m);
                      },
                    ),
                  ]),
                  if (wantsExternal && !ready)
                    Text(calendarFreeSlotLabel(strings, 'partial'),
                      key: const ValueKey('b2-partial-coverage'),
                      style: TextStyle(color:
                          Theme.of(sheetContext).colorScheme.error)),
                  Text(calendarFreeSlotLabel(strings, 'scope'),
                      style: Theme.of(sheetContext).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  slots.isEmpty
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(calendarFreeSlotLabel(strings, 'empty'))))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: slots.length,
                          itemBuilder: (_, i) {
                            final slot = slots[i];
                            return ListTile(
                              key: ValueKey('b2-slot-$i'),
                              leading: const Icon(Icons.event_available_outlined),
                              title: Text("${DateFormat('EEE HH:mm').format(slot.start)} – ${DateFormat('EEE HH:mm').format(slot.end)}"),
                              subtitle: Text('${slot.duration.inMinutes} min'),
                              onTap: () => Navigator.pop(sheetContext, slot),
                              trailing: const Icon(Icons.chevron_right),
                            );
                          }),
                  Text(calendarFreeSlotLabel(strings, 'confirm'),
                    style: Theme.of(sheetContext).textTheme.bodySmall),
                ],
              ),
              ),
            ),
          ),
        );
      },
      ),
    ),
  );
  if (picked == null || !context.mounted ||
      store.activeAccountId != accountAtOpen) { return; }
  // A subscribed calendar can change between rendering and tapping. Recheck
  // the complete suggested range before opening even the manual editor.
  if (store.agendaContentFilter == AgendaContentFilter.all &&
      external.supported && external.enabled) {
    await external.refreshStatus();
  }
  if (!context.mounted || store.activeAccountId != accountAtOpen) { return; }
  final rangeStart = DateTime(day.year, day.month, day.day - 1);
  final rangeEnd = DateTime(day.year, day.month, day.day + 2);
  final externalReady = external.coversRange(rangeStart, rangeEnd);
  final fresh = findCalendarFreeSlots(
    day: day,
    visibleEntries: visibleEntriesForCalendarFreeSlots(store, day,
      externalReady: store.agendaContentFilter == AgendaContentFilter.all &&
          externalReady),
    startHour: workingHours ? 9 : startHour,
    endHour: workingHours ? 18 : endHour,
    minimumMinutes: minimumMinutes,
  );
  final available = fresh.any((slot) =>
    !slot.start.isAfter(picked.start) && !slot.end.isBefore(picked.end));
  if (!available) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(calendarFreeSlotLabel(AnnaStrings.of(context), 'stale')),
    ));
    return;
  }
  await openUnifiedItemComposer(
    context, store,
    DateTime(picked.start.year, picked.start.month, picked.start.day),
    initialTime: TimeOfDay(
        hour: picked.start.hour, minute: picked.start.minute),
    initialType: ItemType.appointment,
  );
}
