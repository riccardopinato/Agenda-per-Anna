part of '../main.dart';

class YearReviewMonthSnapshot {
  final int month;
  final List<DiaryBlockReference> memories;
  final List<LifeArchiveEntry> lifeEntries;

  const YearReviewMonthSnapshot({
    required this.month,
    required this.memories,
    required this.lifeEntries,
  });

  int get memoryCount => memories.length;
  int get agendaCount =>
      lifeEntries.where((entry) => entry.kind == LifeArchiveKind.agenda).length;
  int get workoutCount =>
      lifeEntries.where((entry) => entry.kind == LifeArchiveKind.workout).length;
  int get lifeCount => lifeEntries.length;
  bool get hasStory => memories.isNotEmpty || lifeEntries.isNotEmpty;
}

class YearReviewSnapshot {
  final int year;
  final List<YearReviewMonthSnapshot> months;
  final List<DiaryBlockReference> highlights;
  final List<MemoryRecallFacet> people;
  final List<MemoryRecallFacet> places;

  const YearReviewSnapshot({
    required this.year,
    required this.months,
    required this.highlights,
    required this.people,
    required this.places,
  });

  int get memoryCount =>
      months.fold<int>(0, (sum, month) => sum + month.memoryCount);
  int get lifeCount =>
      months.fold<int>(0, (sum, month) => sum + month.lifeCount);
  int get workoutCount =>
      months.fold<int>(0, (sum, month) => sum + month.workoutCount);
  int get activeMonths => months.where((month) => month.hasStory).length;
}

extension AgendaStoreYearReview on AgendaStore {
  YearReviewSnapshot yearReviewSnapshot(
    int year, {
    AnnaStrings? strings,
  }) {
    final labels = strings ?? const AnnaStrings('en');
    final memories = memoryReferences()
        .where((reference) => reference.date.year == year)
        .toList(growable: false);

    final life = lifeArchiveEntries(
      through: DateTime(year, 12, 31, 23, 59, 59, 999),
      strings: labels,
    )
        .where((entry) => entry.date.year == year && !entry.archived)
        .toList(growable: false);

    final months = <YearReviewMonthSnapshot>[
      for (var month = 1; month <= 12; month++)
        YearReviewMonthSnapshot(
          month: month,
          memories: List.unmodifiable(
            memories.where((reference) => reference.date.month == month),
          ),
          lifeEntries: List.unmodifiable(
            life.where((entry) => entry.date.month == month),
          ),
        ),
    ];

    final highlights = <DiaryBlockReference>[];
    for (final month in months.reversed) {
      if (month.memories.isEmpty) continue;
      DiaryBlockReference? chosen;
      for (final reference in month.memories) {
        if (reference.block.type == DiaryBlockType.photo) {
          chosen = reference;
          break;
        }
      }
      chosen ??= month.memories.first;
      highlights.add(chosen);
      if (highlights.length >= 6) break;
    }

    final personCounts = <String, int>{};
    final placeCounts = <String, int>{};
    final placeLabels = <String, String>{};

    for (final reference in memories) {
      for (final personId in reference.block.personIds.toSet()) {
        if (!people.any((person) => person.id == personId)) continue;
        personCounts[personId] = (personCounts[personId] ?? 0) + 1;
      }
      final seenPlaces = <String>{};
      for (final place in reference.block.places) {
        final key = place.normalizedName;
        final label = place.name.trim();
        if (key.isEmpty || label.isEmpty || !seenPlaces.add(key)) continue;
        placeLabels.putIfAbsent(key, () => label);
        placeCounts[key] = (placeCounts[key] ?? 0) + 1;
      }
    }

    final recurringPeople = personCounts.entries
        .map((entry) {
          final person = people.firstWhere((person) => person.id == entry.key);
          return MemoryRecallFacet(
            kind: MemoryRecallFacetKind.person,
            id: entry.key,
            label: person.name,
            count: entry.value,
          );
        })
        .toList(growable: false)
      ..sort((a, b) {
        final count = b.count.compareTo(a.count);
        if (count != 0) return count;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    final recurringPlaces = placeCounts.entries
        .map(
          (entry) => MemoryRecallFacet(
            kind: MemoryRecallFacetKind.place,
            id: entry.key,
            label: placeLabels[entry.key] ?? entry.key,
            count: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final count = b.count.compareTo(a.count);
        if (count != 0) return count;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    return YearReviewSnapshot(
      year: year,
      months: List.unmodifiable(months),
      highlights: List.unmodifiable(highlights),
      people: List.unmodifiable(recurringPeople.take(6)),
      places: List.unmodifiable(recurringPlaces.take(6)),
    );
  }
}

extension AnnaStringsV105B2 on AnnaStrings {
  String get v105YearReview => _pick(
        en: 'Year in Review',
        it: 'Il tuo anno',
        es: 'Tu año',
        fr: 'Ton année',
        pt: 'O teu ano',
      );

  String get v105YearReviewSubtitle => _pick(
        en: 'A deterministic look back across diary and life activity.',
        it: 'Uno sguardo deterministico a diario e attività della tua vita.',
        es: 'Un repaso determinista de tu diario y tu actividad.',
        fr: 'Un regard déterministe sur ton journal et ta vie.',
        pt: 'Uma retrospetiva determinística do diário e da tua vida.',
      );

  String get v105Highlights => _pick(
        en: 'Highlights',
        it: 'Momenti in evidenza',
        es: 'Momentos destacados',
        fr: 'Moments forts',
        pt: 'Destaques',
      );

  String get v105RecurringPeople => _pick(
        en: 'People in your year',
        it: 'Persone del tuo anno',
        es: 'Personas de tu año',
        fr: 'Personnes de ton année',
        pt: 'Pessoas do teu ano',
      );

  String get v105RecurringPlaces => _pick(
        en: 'Places in your year',
        it: 'Luoghi del tuo anno',
        es: 'Lugares de tu año',
        fr: 'Lieux de ton année',
        pt: 'Lugares do teu ano',
      );

  String get v105ActiveMonths => _pick(
        en: 'Active months',
        it: 'Mesi vissuti',
        es: 'Meses activos',
        fr: 'Mois actifs',
        pt: 'Meses ativos',
      );

  String get v105LifeMoments => _pick(
        en: 'Life moments',
        it: 'Momenti di vita',
        es: 'Momentos de vida',
        fr: 'Moments de vie',
        pt: 'Momentos de vida',
      );

  String get v105OpenMonth => _pick(
        en: 'Open month',
        it: 'Apri mese',
        es: 'Abrir mes',
        fr: 'Ouvrir le mois',
        pt: 'Abrir mês',
      );

  String v105MemoriesCount(int count) => _pick(
        en: '$count memories',
        it: '$count ricordi',
        es: '$count recuerdos',
        fr: '$count souvenirs',
        pt: '$count memórias',
      );

  String v105LifeCount(int count) => _pick(
        en: '$count life entries',
        it: '$count elementi di vita',
        es: '$count elementos de vida',
        fr: '$count éléments de vie',
        pt: '$count elementos de vida',
      );
}
