part of '../../main.dart';

enum _ExtractiveScope { week, month, place, person }

String memoryExtractiveCopy(String language, String key) {
  final labels = switch (language) {
    'en' => {'title': 'From your notes', 'intro': 'Original phrases from your private diary. Nothing invented.', 'week': 'Week', 'month': 'Month', 'place': 'Place', 'person': 'Person', 'empty': 'No private note excerpts for this selection.', 'source': 'Open original', 'limited': 'Only the most recent 200 source notes were considered.'},
    'es' => {'title': 'De tus notas', 'intro': 'Frases originales de tu diario privado. Nada inventado.', 'week': 'Semana', 'month': 'Mes', 'place': 'Lugar', 'person': 'Persona', 'empty': 'No hay fragmentos para esta selección.', 'source': 'Abrir original', 'limited': 'Solo se analizaron las 200 notas más recientes.'},
    'fr' => {'title': 'Depuis vos notes', 'intro': 'Phrases originales du journal privé. Aucun texte inventé.', 'week': 'Semaine', 'month': 'Mois', 'place': 'Lieu', 'person': 'Personne', 'empty': 'Aucun extrait pour cette sélection.', 'source': 'Ouvrir l’original', 'limited': 'Seules les 200 notes les plus récentes ont été analysées.'},
    'pt' => {'title': 'Das tuas notas', 'intro': 'Frases originais do teu diário privado. Nada inventado.', 'week': 'Semana', 'month': 'Mês', 'place': 'Lugar', 'person': 'Pessoa', 'empty': 'Sem excertos para esta seleção.', 'source': 'Abrir original', 'limited': 'Só as 200 notas mais recentes foram analisadas.'},
    _ => {'title': 'Dalle tue note', 'intro': 'Frasi originali del diario privato. Nessun racconto inventato.', 'week': 'Settimana', 'month': 'Mese', 'place': 'Luogo', 'person': 'Persona', 'empty': 'Nessun estratto disponibile per questa selezione.', 'source': 'Apri originale', 'limited': 'Analizzate soltanto le ultime 200 note disponibili.'},
  };
  return labels[key] ?? key;
}

/// Read-only view over AgendaStore's canonical private diary, rebuilt after
/// account changes. This page never persists a summary or exposes shared/Vault.
class MemoryExtractiveSummaryScreen extends StatefulWidget {
  const MemoryExtractiveSummaryScreen({
    super.key,
    required this.store,
    this.personId,
  });
  final AgendaStore store;
  final String? personId;

  @override
  State<MemoryExtractiveSummaryScreen> createState() =>
      _MemoryExtractiveSummaryScreenState();
}

class _MemoryExtractiveSummaryScreenState
    extends State<MemoryExtractiveSummaryScreen> {
  _ExtractiveScope scope = _ExtractiveScope.week;
  String? selectedPlace;
  String? selectedPerson;

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final language = strings.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(memoryExtractiveCopy(language, 'title')),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.store.journalRevision,
          widget.store.accountRevision,
          widget.store.settingsRevision,
        ]),
        builder: (context, _) {
          if (!widget.store.entryScopeReady) {
            return Center(child: Text(memoryExtractiveCopy(language, 'empty')));
          }
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final places = widget.store.memoryMapSnapshot().places;
          final people = widget.store.people;
          final placeId = places.any((p) => p.key == selectedPlace)
              ? selectedPlace
              : (places.isEmpty ? null : places.first.key);
          final personId = people.any((p) => p.id == selectedPerson)
              ? selectedPerson
              : (widget.personId ?? (people.isEmpty ? null : people.first.id));
          final from = switch (scope) {
            _ExtractiveScope.week =>
              DateTime(today.year, today.month, today.day - 6),
            _ExtractiveScope.month => DateTime(today.year, today.month, 1),
            _ => null,
          };
          final to = switch (scope) {
            _ExtractiveScope.week =>
              DateTime(today.year, today.month, today.day + 1),
            _ExtractiveScope.month => DateTime(today.year, today.month + 1, 1),
            _ => null,
          };
          final noChoice =
              (scope == _ExtractiveScope.place && placeId == null) ||
              (scope == _ExtractiveScope.person && personId == null);
          final report = noChoice
              ? const MemoryExtractiveReport([], 0, 0, false)
              : memoryExtractiveReport(
                  widget.store.memoryReferences(personId: widget.personId),
                  fromInclusive: from,
                  toExclusive: to,
                  placeKey: scope == _ExtractiveScope.place ? placeId : null,
                  personId: scope == _ExtractiveScope.person
                      ? personId : widget.personId,
                );
          return ListView(
            key: const ValueKey('cap0151-extractive-screen'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              Text(memoryExtractiveCopy(language, 'intro')),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final option in _ExtractiveScope.values)
                    ChoiceChip(
                      key: ValueKey('cap0151-filter-${option.name}'),
                      label: Text(memoryExtractiveCopy(language, option.name)),
                      selected: scope == option,
                      onSelected: (_) => setState(() => scope = option),
                    ),
                ],
              ),
              if (scope == _ExtractiveScope.place && placeId != null)
                DropdownButtonFormField<String>(
                  key: ValueKey('cap0151-place-$placeId'),
                  initialValue: placeId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: memoryExtractiveCopy(language, 'place'),
                  ),
                  items: [
                    for (final place in places)
                      DropdownMenuItem(
                        value: place.key,
                        child: Text(place.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => selectedPlace = value),
                ),
              if (scope == _ExtractiveScope.person && personId != null)
                DropdownButtonFormField<String>(
                  key: ValueKey('cap0151-person-$personId'),
                  initialValue: personId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: memoryExtractiveCopy(language, 'person'),
                  ),
                  items: [
                    for (final person in people)
                      DropdownMenuItem(
                        value: person.id,
                        child: Text(person.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => selectedPerson = value),
                ),
              const SizedBox(height: 12),
              if (report.partial)
                Text(memoryExtractiveCopy(language, 'limited')),
              if (report.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text(memoryExtractiveCopy(language, 'empty')),
                )
              else
                for (final quote in report.quotes)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.format_quote_outlined),
                      title: SelectableText(quote.text),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(DateFormat('d MMM yyyy',
                          AnnaStrings.intlLocale(context)).format(
                            quote.source.date)),
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _MemoryDerivedResultsScreen(
                            store: widget.store,
                            title: memoryExtractiveCopy(language, 'source'),
                            recordsBuilder: () => widget.store
                                .memoryReferences(personId: widget.personId)
                                .where((record) =>
                                    record.block.id ==
                                        quote.source.block.id &&
                                    record.date.year ==
                                        quote.source.date.year &&
                                    record.date.month ==
                                        quote.source.date.month &&
                                    record.date.day ==
                                        quote.source.date.day)
                                .toList(growable: false),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
