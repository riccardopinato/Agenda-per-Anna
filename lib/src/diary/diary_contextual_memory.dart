part of '../../main.dart';

/// Source-only contextual recall: no inferred emotions, searches, cloud push,
/// Vault, credentials, health/cycle domain or background notifications.
class ContextualMemoryPick {
  const ContextualMemoryPick(this.reference, this.reason);
  final DiaryBlockReference reference;
  /// 'anniversary', 'person' or 'place', all directly backed by saved fields.
  final String reason;
}

abstract final class ContextualMemorySelector {
  static const _excludedExplicitTags = <String>{
    'health', 'salute', 'santé', 'salud', 'saúde', 'medical', 'medico',
    'médical', 'cycle', 'ciclo', 'ciclo mestruale', 'period', 'periodo',
    'menstruation', 'password', 'passwords', 'vault', 'cassaforte',
  };

  /// Takes only diary references already authorized by the caller.
  /// Never converts linked shared/health/credential data into suggestions.
  static List<ContextualMemoryPick> choose({
    required Iterable<DiaryBlockReference> authorizedPrivateMemories,
    required DateTime today,
    Set<String> excludedIds = const {},
    Set<String>? authorizedPersonIds,
    int limit = 2,
  }) {
    if (limit <= 0) return const [];
    final anchor = DateTime(today.year, today.month, today.day);
    final source = authorizedPrivateMemories.where((reference) {
      final block = reference.block;
      if (block.id.trim().isEmpty || block.archived ||
          excludedIds.contains(block.id) ||
          block.tags.contains(futureLetterTag) ||
          !reference.date.isBefore(anchor) ||
          block.tags.any((tag) =>
              _excludedExplicitTags.contains(tag.trim().toLowerCase()))) {
        return false;
      }
      final anniversary = reference.date.year < anchor.year &&
          reference.date.month == anchor.month &&
          reference.date.day == anchor.day;
      final linkedPerson = block.personIds.any((id) =>
          authorizedPersonIds == null || authorizedPersonIds.contains(id));
      final linked = linkedPerson ||
          block.places.any((place) => place.normalizedName.isNotEmpty);
      return anniversary || linked;
    }).toList(growable: false)
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return a.block.id.compareTo(b.block.id);
      });

    final buckets = <String, List<DiaryBlockReference>>{
      'anniversary': [],
      'person': [],
      'place': [],
    };
    final sourceSeen = <String>{};
    for (final record in source) {
      if (!sourceSeen.add(record.block.id)) continue;
      final anniversary = record.date.year < anchor.year &&
          record.date.month == anchor.month &&
          record.date.day == anchor.day;
      final linkedPerson = record.block.personIds.any((id) =>
          authorizedPersonIds == null || authorizedPersonIds.contains(id));
      final reason = anniversary
          ? 'anniversary'
          : linkedPerson ? 'person' : 'place';
      buckets[reason]!.add(record);
    }
    final result = <ContextualMemoryPick>[];
    final taken = <String>{};
    final maxPicks = limit.clamp(0, 2).toInt();
    // One of each provenance first: deterministic diversity, not sentiment AI.
    for (final category in const ['anniversary', 'person', 'place']) {
      if (result.length >= maxPicks) break;
      final records = buckets[category]!;
      if (records.isEmpty) continue;
      final record = records.first;
      taken.add(record.block.id);
      result.add(ContextualMemoryPick(record, category));
    }
    if (result.length < maxPicks) {
      for (final category in const ['anniversary', 'person', 'place']) {
        for (final record in buckets[category]!) {
          if (result.length >= maxPicks) break;
          if (!taken.add(record.block.id)) continue;
          result.add(ContextualMemoryPick(record, category));
        }
      }
    }
    return List.unmodifiable(result);
  }
}

/// Optional in-page suggestions. No external notification, write to diary,
/// cloud sync, search indexing or background worker is ever created.
class ContextualMemoryPanel extends StatefulWidget {
  const ContextualMemoryPanel({
    super.key,
    required this.store,
    required this.authorizedPrivateMemories,
    required this.onOpen,
  });

  final AgendaStore store;
  final Iterable<DiaryBlockReference> authorizedPrivateMemories;
  final ValueChanged<DiaryBlockReference> onOpen;

  @override
  State<ContextualMemoryPanel> createState() => _ContextualMemoryPanelState();
}

class _ContextualMemoryPanelState extends State<ContextualMemoryPanel> {
  bool _loaded = false;
  bool _enabled = false;
  int _snoozedThrough = 0;
  final Set<String> _excluded = <String>{};
  final Set<String> _dailySelected = <String>{};
  int _dailySelectedDay = 0;
  bool _selecting = false;
  String? _observedScope;
  int? _observedEpoch;

  String get _scopeKey => 'anna_contextual_memory_v1_${sha256.convert(
        utf8.encode(widget.store.activeAccountId ?? 'local'),
      )}';

  String _digestFor(String id) =>
      sha256.convert(utf8.encode('$_scopeKey:$id')).toString();

  @override
  void initState() {
    super.initState();
    _observedScope = _scopeKey;
    _observedEpoch = widget.store.accountScopeEpoch;
    _load();
  }

  @override
  void didUpdateWidget(covariant ContextualMemoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_observedScope != _scopeKey ||
        _observedEpoch != widget.store.accountScopeEpoch) {
      _observedScope = _scopeKey;
      _observedEpoch = widget.store.accountScopeEpoch;
      _loaded = false;
      _enabled = false;
      _snoozedThrough = 0;
      _excluded.clear();
      _dailySelected.clear();
      _dailySelectedDay = 0;
      _load();
    }
  }

  Future<void> _load() async {
    final key = _scopeKey;
    final epoch = widget.store.accountScopeEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || !widget.store.entryScopeReady ||
          key != _scopeKey || epoch != widget.store.accountScopeEpoch) {
        return;
      }
      setState(() {
        _enabled = prefs.getBool('${key}_enabled') ?? false;
        _snoozedThrough = prefs.getInt('${key}_snoozed') ?? 0;
        _excluded
          ..clear()
          ..addAll(prefs.getStringList('${key}_excluded') ?? const []);
        _dailySelectedDay = prefs.getInt('${key}_selected_day') ?? 0;
        _dailySelected
          ..clear()
          ..addAll(prefs.getStringList('${key}_selected_hashes') ?? const []);
        _loaded = true;
      });
      if (_enabled) unawaited(_ensureDailyPicks());
    } catch (_) {
      // If preference loading fails, do not surface private suggestions.
    }
  }

  /// The first two suggestions seen on a civil day are persisted as
  /// account-scoped digests. Excluding one cannot introduce a third suggestion,
  /// and switching a search/person filter cannot refill the day's quota.
  Future<void> _ensureDailyPicks() async {
    if (!mounted || !_loaded || !_enabled || _selecting ||
        !widget.store.entryScopeReady ||
        _observedScope != _scopeKey ||
        _observedEpoch != widget.store.accountScopeEpoch ||
        widget.store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return;
    }
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    if (_dailySelectedDay == today || _snoozedThrough > today) return;
    _selecting = true;
    final key = _scopeKey;
    final epoch = widget.store.accountScopeEpoch;
    try {
      final eligible = widget.authorizedPrivateMemories.toList(growable: false);
      final chosen = ContextualMemorySelector.choose(
        authorizedPrivateMemories: eligible,
        today: now,
        excludedIds: eligible
            .where((item) => _excluded.contains(_digestFor(item.block.id)))
            .map((item) => item.block.id).toSet(),
        authorizedPersonIds:
            widget.store.people.map((person) => person.id).toSet(),
      );
      final hashes = chosen
          .map((item) => _digestFor(item.reference.block.id))
          .toSet();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || !widget.store.entryScopeReady ||
          _scopeKey != key || widget.store.accountScopeEpoch != epoch ||
          !_enabled) return;
      if (!await prefs.setStringList(
        '${key}_selected_hashes', hashes.toList(growable: false),
      )) {
        throw StateError('Cannot persist daily selection');
      }
      if (!await prefs.setInt('${key}_selected_day', today)) {
        throw StateError('Cannot persist selection day');
      }
      if (!mounted || !widget.store.entryScopeReady ||
          _scopeKey != key || widget.store.accountScopeEpoch != epoch) return;
      setState(() {
        _dailySelectedDay = today;
        _dailySelected..clear()..addAll(hashes);
      });
    } catch (_) {
      // Never display a private suggestion until its daily quota is durable.
    } finally {
      _selecting = false;
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    if (!widget.store.entryScopeReady ||
        _observedEpoch != widget.store.accountScopeEpoch ||
        widget.store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return;
    }
    final key = _scopeKey;
    final epoch = widget.store.accountScopeEpoch;
    final previous = _enabled;
    setState(() => _enabled = enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_scopeKey != key ||
          widget.store.accountScopeEpoch != epoch ||
          !widget.store.entryScopeReady) return;
      if (!await prefs.setBool('${key}_enabled', enabled)) {
        throw StateError('Recall opt-in not saved');
      }
      if (enabled) await _ensureDailyPicks();
    } catch (_) {
      if (mounted && _scopeKey == key &&
          widget.store.accountScopeEpoch == epoch) {
        setState(() => _enabled = previous);
      }
    }
  }

  Future<void> _snooze(bool pause) async {
    if (!widget.store.entryScopeReady ||
        _observedEpoch != widget.store.accountScopeEpoch ||
        widget.store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return;
    }
    final key = _scopeKey;
    final epoch = widget.store.accountScopeEpoch;
    final previous = _snoozedThrough;
    final now = DateTime.now();
    final until = DateTime(now.year, now.month, now.day + 7);
    final choice = pause
        ? until.year * 10000 + until.month * 100 + until.day : 0;
    setState(() => _snoozedThrough = choice);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_scopeKey != key ||
          widget.store.accountScopeEpoch != epoch ||
          !widget.store.entryScopeReady) return;
      if (!await prefs.setInt('${key}_snoozed', choice)) {
        throw StateError('Recall snooze not saved');
      }
      if (!pause) await _ensureDailyPicks();
    } catch (_) {
      if (mounted && _scopeKey == key &&
          widget.store.accountScopeEpoch == epoch) {
        setState(() => _snoozedThrough = previous);
      }
    }
  }

  Future<void> _neverSuggest(String blockId) async {
    if (!widget.store.entryScopeReady ||
        _observedEpoch != widget.store.accountScopeEpoch ||
        widget.store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return;
    }
    final key = _scopeKey;
    final epoch = widget.store.accountScopeEpoch;
    final hashed = _digestFor(blockId);
    final previous = Set<String>.from(_excluded);
    setState(() {
      _excluded.remove(hashed);
      _excluded.add(hashed);
      // Never evict an earlier "never suggest" choice without explicit reset.
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_scopeKey != key ||
          widget.store.accountScopeEpoch != epoch ||
          !widget.store.entryScopeReady) return;
      if (!await prefs.setStringList(
        '${key}_excluded', _excluded.toList(growable: false),
      )) {
        throw StateError('Recall exclusion not saved');
      }
    } catch (_) {
      if (mounted && _scopeKey == key &&
          widget.store.accountScopeEpoch == epoch) {
        setState(() => _excluded..clear()..addAll(previous));
      }
    }
  }

  Future<void> _resetExcluded() async {
    if (!widget.store.entryScopeReady ||
        _observedEpoch != widget.store.accountScopeEpoch ||
        widget.store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return;
    }
    final key = _scopeKey;
    final epoch = widget.store.accountScopeEpoch;
    final previous = Set<String>.from(_excluded);
    setState(() => _excluded.clear());
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_scopeKey != key ||
          widget.store.accountScopeEpoch != epoch ||
          !widget.store.entryScopeReady) return;
      if (!await prefs.remove('${key}_excluded')) {
        throw StateError('Recall exclusions not cleared');
      }
    } catch (_) {
      if (mounted && _scopeKey == key &&
          widget.store.accountScopeEpoch == epoch) {
        setState(() => _excluded.addAll(previous));
      }
    }
  }

  String _copy(String lang, String key) {
    const dictionary = <String, List<String>>{
      'title': ['Contextual memories', 'Ricordi contestuali',
        'Recuerdos contextuales', 'Souvenirs contextuels',
        'Memórias contextuais'],
      'enable': ['Suggest up to two saved memories per day', 
        'Suggerisci al massimo due ricordi salvati al giorno',
        'Sugerir hasta dos recuerdos guardados al día',
        'Suggérer jusqu’à deux souvenirs enregistrés par jour',
        'Sugerir até duas memórias guardadas por dia'],
      'scope': ['Only this private diary, with explicit dates, people or places.',
        'Solo questo diario privato: date, persone o luoghi salvati.',
        'Solo este diario privado: fechas, personas o lugares guardados.',
        'Ce journal privé uniquement : dates, personnes ou lieux enregistrés.',
        'Apenas este diário privado: datas, pessoas ou locais guardados.'],
      'anniversary': ['Same date in a past year', 'Stessa data in un anno passato',
        'Misma fecha de un año anterior', 'Même date une année passée',
        'Mesma data num ano anterior'],
      'person': ['Person linked by you', 'Persona collegata da te',
        'Persona vinculada por ti', 'Personne liée par vos soins',
        'Pessoa associada por ti'],
      'place': ['Place saved by you', 'Luogo salvato da te',
        'Lugar guardado por ti', 'Lieu enregistré par vos soins',
        'Local guardado por ti'],
      'fromDate': [
        'Saved on', 'Salvato il', 'Guardado el', 'Enregistré le',
        'Guardado em',
      ],
      'never': ['Never suggest this memory', 'Non suggerire più questo ricordo',
        'No volver a sugerir este recuerdo', 'Ne plus proposer ce souvenir',
        'Não voltar a sugerir esta memória'],
      'snooze': ['Pause for 7 days', 'Sospendi per 7 giorni',
        'Pausar 7 días', 'Suspendre pour 7 jours', 'Pausar por 7 dias'],
      'resume': ['Resume suggestions', 'Riattiva i suggerimenti',
        'Reanudar sugerencias', 'Reprendre les suggestions',
        'Retomar sugestões'],
      'reset': ['Restore excluded memories', 'Ripristina ricordi esclusi',
        'Restaurar recuerdos excluidos', 'Restaurer les souvenirs exclus',
        'Restaurar memórias excluídas'],
    };
    final index = switch (lang) {
      'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
    };
    return dictionary[key]![index];
  }

  @override
  Widget build(BuildContext context) {
    // Never expose private recaps while the agenda explicitly shows shared
    // records only, or across a pending account-scope transition.
    if (!_loaded || !widget.store.entryScopeReady ||
        _observedScope != _scopeKey ||
        _observedEpoch != widget.store.accountScopeEpoch ||
        widget.store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    final paused = _snoozedThrough > today;
    if (_enabled && !paused && _dailySelectedDay != today && !_selecting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_ensureDailyPicks());
      });
    }
    final candidates = _enabled && !paused && _dailySelectedDay == today
        ? ContextualMemorySelector.choose(
            authorizedPrivateMemories: widget.authorizedPrivateMemories
                .where((reference) => _dailySelected
                    .contains(_digestFor(reference.block.id))),
            today: now,
            excludedIds: widget.authorizedPrivateMemories
                .where((reference) =>
                    _excluded.contains(_digestFor(reference.block.id)))
                .map((reference) => reference.block.id).toSet(),
            authorizedPersonIds:
                widget.store.people.map((person) => person.id).toSet(),
          )
        : const <ContextualMemoryPick>[];
    final lang = AnnaStrings.of(context).languageCode;
    return Card(
      key: const ValueKey('contextual-memory-optin-panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              key: const ValueKey('contextual-memory-optin'),
              contentPadding: EdgeInsets.zero,
              title: Text(_copy(lang, 'title')),
              subtitle: Text(_copy(lang, 'enable')),
              value: _enabled,
              onChanged: _setEnabled,
            ),
            Text(_copy(lang, 'scope'),
              style: Theme.of(context).textTheme.bodySmall),
            if (_enabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('contextual-memory-snooze'),
                  onPressed: () => _snooze(!paused),
                  icon: Icon(paused ? Icons.play_arrow : Icons.snooze),
                  label: Text(_copy(lang, paused ? 'resume' : 'snooze')),
                ),
              ),
            for (final pick in candidates)
              ListTile(
                key: ValueKey<String>(
                  'contextual-memory-${pick.reference.block.id}'),
                // Do not render diary text or photo captions in a suggestion.
                // Only the explicit source date is disclosed after opt-in.
                title: Text(
                  '${_copy(lang, 'fromDate')} '
                  '${DateFormat('d MMM yyyy',
                    AnnaStrings.intlLocale(context)).format(pick.reference.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_copy(lang, pick.reason)),
                leading: const Icon(Icons.auto_stories_outlined),
                onTap: () => widget.onOpen(pick.reference),
                trailing: IconButton(
                  tooltip: _copy(lang, 'never'),
                  icon: const Icon(Icons.visibility_off_outlined),
                  onPressed: () => _neverSuggest(pick.reference.block.id),
                ),
              ),
            if (_excluded.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('contextual-memory-reset-excluded'),
                  onPressed: _resetExcluded,
                  child: Text(_copy(lang, 'reset')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
