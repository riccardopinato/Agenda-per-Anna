part of '../main.dart';

const String _trashKey = 'trash_v1';

enum TrashEntityKind {
  item,
  diaryBlock,
  journal,
  month,
  week,
  habit,
  birthday,
  person,
  template,
  inbox,
}

extension TrashEntityKindUi on TrashEntityKind {
  String get label => switch (this) {
        TrashEntityKind.item => 'Agenda',
        TrashEntityKind.diaryBlock => 'Ricordo',
        TrashEntityKind.journal => 'Giornata',
        TrashEntityKind.month => 'Pagina mensile',
        TrashEntityKind.week => 'Pagina settimanale',
        TrashEntityKind.habit => 'Abitudine',
        TrashEntityKind.birthday => 'Compleanno',
        TrashEntityKind.person => 'Persona',
        TrashEntityKind.template => 'Modello',
        TrashEntityKind.inbox => 'Inbox',
      };

  IconData get icon => switch (this) {
        TrashEntityKind.item => Icons.event_outlined,
        TrashEntityKind.diaryBlock => Icons.auto_stories_outlined,
        TrashEntityKind.journal => Icons.menu_book_outlined,
        TrashEntityKind.month => Icons.calendar_month_outlined,
        TrashEntityKind.week => Icons.view_week_outlined,
        TrashEntityKind.habit => Icons.repeat_outlined,
        TrashEntityKind.birthday => Icons.cake_outlined,
        TrashEntityKind.person => Icons.person_outline,
        TrashEntityKind.template => Icons.copy_all_outlined,
        TrashEntityKind.inbox => Icons.inbox_outlined,
      };
}

class TrashEntry {
  final String id;
  final TrashEntityKind kind;
  final String entityId;
  final String? parentId;
  final String title;
  final DateTime deletedAt;
  final Map<String, dynamic> payload;

  const TrashEntry({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.title,
    required this.deletedAt,
    required this.payload,
    this.parentId,
  });

  String get originalKey => '${kind.name}:${parentId ?? ''}:$entityId';

  TrashEntry copyWith({Map<String, dynamic>? payload}) => TrashEntry(
        id: id,
        kind: kind,
        entityId: entityId,
        parentId: parentId,
        title: title,
        deletedAt: deletedAt,
        payload: payload ?? this.payload,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'entityId': entityId,
        'parentId': parentId,
        'title': title,
        'deletedAt': deletedAt.toUtc().toIso8601String(),
        'payload': payload,
      };

  factory TrashEntry.fromJson(Map<String, dynamic> json) => TrashEntry(
        id: json['id'] as String? ?? const Uuid().v4(),
        kind: TrashEntityKind.values.firstWhere(
          (value) => value.name == json['kind'],
          orElse: () => TrashEntityKind.item,
        ),
        entityId: json['entityId'] as String? ?? '',
        parentId: json['parentId'] as String?,
        title: json['title'] as String? ?? 'Elemento eliminato',
        deletedAt:
            DateTime.tryParse(json['deletedAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        payload: Map<String, dynamic>.from(
          json['payload'] as Map? ?? const <String, dynamic>{},
        ),
      );
}

extension AgendaStoreLifecycle on AgendaStore {
  TrashEntry _newTrashEntry({
    required TrashEntityKind kind,
    required String entityId,
    required String title,
    required Map<String, dynamic> payload,
    String? parentId,
  }) =>
      TrashEntry(
        id: const Uuid().v4(),
        kind: kind,
        entityId: entityId,
        parentId: parentId,
        title: title.trim().isEmpty ? kind.label : title.trim(),
        deletedAt: DateTime.now(),
        payload: payload,
      );

  void _putTrashInMemory(TrashEntry entry) {
    // Keep historical versions of the same logical entity. A deterministic
    // entity key (day/week/month) can be deleted, recreated and deleted again;
    // collapsing by originalKey would silently destroy an older recoverable
    // version. Only de-duplicate the exact trash record id.
    trash.removeWhere((candidate) => candidate.id == entry.id);
    trash.insert(0, entry);
  }

  Future<DiaryBlock> _localizeTrashBlock(DiaryBlock block) async {
    var next = block;
    if (next.type == DiaryBlockType.photo && next.imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(next.imageBase64);
        final mediaAssetId = await MediaAssetStore.instance.put(bytes);
        final thumbnailAssetId = await MediaAssetStore.instance.put(
          await _createMediaThumbnail(bytes),
        );
        next = next.copyWith(
          imageBase64: '',
          mediaAssetId: mediaAssetId,
          mediaThumbnailAssetId: thumbnailAssetId,
        );
      } catch (_) {}
    }

    if (next.pages.isNotEmpty) {
      final localized = await _localizeSketchPages(next.pages);
      if (localized.changed) {
        next = next.copyWith(pages: localized.pages);
      }
    }
    return next;
  }

  Future<TrashEntry> _localizeTrashEntry(TrashEntry entry) async {
    switch (entry.kind) {
      case TrashEntityKind.diaryBlock:
        final block =
            await _localizeTrashBlock(DiaryBlock.fromJson(entry.payload));
        return entry.copyWith(payload: block.toLocalJson());
      case TrashEntityKind.journal:
        final journal = DayJournal.fromJson(entry.payload);
        final blocks = <DiaryBlock>[];
        for (final block in journal.blocks) {
          blocks.add(await _localizeTrashBlock(block));
        }
        return entry.copyWith(
          payload: journal.copyWith(blocks: blocks).toLocalJson(),
        );
      case TrashEntityKind.item:
      case TrashEntityKind.month:
      case TrashEntityKind.week:
      case TrashEntityKind.habit:
      case TrashEntityKind.birthday:
      case TrashEntityKind.person:
      case TrashEntityKind.template:
      case TrashEntityKind.inbox:
        return entry;
    }
  }

  Future<Map<String, dynamic>> _portableTrashJson(TrashEntry entry) async {
    switch (entry.kind) {
      case TrashEntityKind.diaryBlock:
        final portable = await _portableJournalJson(
          DayJournal(blocks: [DiaryBlock.fromJson(entry.payload)]),
        );
        final blocks = portable['blocks'] as List? ?? const [];
        if (blocks.isNotEmpty && blocks.first is Map) {
          return entry
              .copyWith(
                payload: Map<String, dynamic>.from(blocks.first as Map),
              )
              .toJson();
        }
        return entry.toJson();
      case TrashEntityKind.journal:
        return entry
            .copyWith(
              payload:
                  await _portableJournalJson(DayJournal.fromJson(entry.payload)),
            )
            .toJson();
      case TrashEntityKind.item:
      case TrashEntityKind.month:
      case TrashEntityKind.week:
      case TrashEntityKind.habit:
      case TrashEntityKind.birthday:
      case TrashEntityKind.person:
      case TrashEntityKind.template:
      case TrashEntityKind.inbox:
        return entry.toJson();
    }
  }

  Future<bool> moveItemToTrash(String id) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final item = items[index];
    final entry = _newTrashEntry(
      kind: TrashEntityKind.item,
      entityId: item.id,
      title: item.title,
      payload: item.toJson(),
    );

    items.removeAt(index);
    _putTrashInMemory(entry);
    _invalidateDayIndex();

    await NotificationService.instance.cancel(id);
    await NotificationService.instance.cancel('$id:primary');
    await NotificationService.instance.cancel('$id:secondary');
    if (kIsWeb && CloudSyncService.instance.signedIn) {
      try {
        await CloudSyncService.instance.cancelWebPushReminder('$id:primary');
        await CloudSyncService.instance.cancelWebPushReminder('$id:secondary');
      } catch (_) {}
    }

    await _persistEntityMutations([
      (type: 'item', id: id, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyAgendaChanged();
    return true;
  }

  Future<bool> moveInboxToTrash(String id) async {
    final index = inbox.indexWhere((entry) => entry.id == id);
    if (index < 0) return false;
    final value = inbox[index];
    final entry = _newTrashEntry(
      kind: TrashEntityKind.inbox,
      entityId: value.id,
      title: value.text,
      payload: value.toJson(),
    );

    inbox.removeAt(index);
    _putTrashInMemory(entry);
    await _persistEntityMutations([
      (type: 'inbox', id: id, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyInboxChanged();
    return true;
  }

  Future<bool> movePersonToTrash(String id) async {
    final index = people.indexWhere((person) => person.id == id);
    if (index < 0) return false;
    final person = people[index];
    final entry = _newTrashEntry(
      kind: TrashEntityKind.person,
      entityId: person.id,
      title: person.name,
      payload: person.toJson(),
    );

    people.removeAt(index);
    _putTrashInMemory(entry);
    await _persistEntityMutations([
      (type: 'person', id: id, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyPlanningChanged();
    return true;
  }

  Future<bool> moveTemplateToTrash(String id) async {
    final index = templates.indexWhere((template) => template.id == id);
    if (index < 0) return false;
    final template = templates[index];
    final entry = _newTrashEntry(
      kind: TrashEntityKind.template,
      entityId: template.id,
      title: template.name,
      payload: template.toJson(),
    );

    templates.removeAt(index);
    _putTrashInMemory(entry);
    await _persistEntityMutations([
      (type: 'template', id: id, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyPlanningChanged();
    return true;
  }

  Future<bool> moveBirthdayToTrash(String id) async {
    final index = birthdays.indexWhere((birthday) => birthday.id == id);
    if (index < 0) return false;
    final birthday = birthdays[index];
    final entry = _newTrashEntry(
      kind: TrashEntityKind.birthday,
      entityId: birthday.id,
      title: birthday.name,
      payload: birthday.toJson(),
    );

    birthdays.removeAt(index);
    _putTrashInMemory(entry);
    await _cancelBirthdayReminder(id);
    await _persistEntityMutations([
      (type: 'birthday', id: id, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyPlanningChanged();
    return true;
  }

  Future<bool> moveDiaryBlockToTrash(DateTime date, String blockId) async {
    final key = AgendaStore.dateKey(date);
    final current = journals[key];
    if (current == null) return false;
    final index = current.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return false;

    final block = current.blocks[index];
    final title = block.text.trim().isNotEmpty
        ? block.text.trim()
        : switch (block.type) {
            DiaryBlockType.note => 'Nota del diario',
            DiaryBlockType.photo => 'Foto del diario',
            DiaryBlockType.sketch => 'Sketch del diario',
          };
    final entry = _newTrashEntry(
      kind: TrashEntityKind.diaryBlock,
      entityId: block.id,
      parentId: key,
      title: title,
      payload: block.toLocalJson(),
    );
    final blocks = [...current.blocks]..removeAt(index);
    final updated = current.copyWith(blocks: blocks);
    journals[key] = updated;
    _putTrashInMemory(entry);

    await _persistEntityMutations([
      (type: 'journal', id: key, payload: updated.toLocalJson(), deleted: false),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _scheduleMediaMaintenance(delay: const Duration(seconds: 1));
    _notifyJournalChanged();
    return true;
  }

  Future<bool> moveJournalToTrash(DateTime date) async {
    final key = AgendaStore.dateKey(date);
    final current = journals[key];
    if (current == null) return false;
    final entry = _newTrashEntry(
      kind: TrashEntityKind.journal,
      entityId: key,
      title: 'Diario del ${DateFormat('d MMMM yyyy', 'it_IT').format(date)}',
      payload: current.toLocalJson(),
    );
    journals.remove(key);
    _putTrashInMemory(entry);
    await _persistEntityMutations([
      (type: 'journal', id: key, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _scheduleMediaMaintenance(delay: const Duration(seconds: 1));
    _notifyJournalChanged();
    return true;
  }

  Future<bool> moveMonthToTrash(int year, int month) async {
    final key = AgendaStore.monthKey(year, month);
    final current = months[key];
    if (current == null) return false;
    final entry = _newTrashEntry(
      kind: TrashEntityKind.month,
      entityId: key,
      title: _cap(DateFormat('MMMM yyyy', 'it_IT').format(DateTime(year, month))),
      payload: current.toJson(),
    );
    months.remove(key);
    _putTrashInMemory(entry);
    await _persistEntityMutations([
      (type: 'month', id: key, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyPlanningChanged();
    return true;
  }

  Future<bool> moveWeekToTrash(DateTime anyDay) async {
    final monday = mondayOf(anyDay);
    final key = AgendaStore.dateKey(monday);
    final current = weeks[key];
    if (current == null) return false;
    final entry = _newTrashEntry(
      kind: TrashEntityKind.week,
      entityId: key,
      title:
          'Settimana del ${DateFormat('d MMMM yyyy', 'it_IT').format(monday)}',
      payload: current.toJson(),
    );
    weeks.remove(key);
    _putTrashInMemory(entry);
    await _persistEntityMutations([
      (type: 'week', id: key, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ]);
    signals.bumpLifecycle();
    _notifyPlanningChanged();
    return true;
  }

  Future<bool> moveHabitToTrash(String id) async {
    final index = habits.indexWhere((habit) => habit.id == id);
    if (index < 0) return false;
    final habit = habits[index];
    final completedJournalKeys = journals.entries
        .where((entry) => entry.value.completedHabitIds.contains(id))
        .map((entry) => entry.key)
        .toList();

    final entry = _newTrashEntry(
      kind: TrashEntityKind.habit,
      entityId: habit.id,
      title: habit.name,
      payload: {
        'habit': habit.toJson(),
        'completedJournalKeys': completedJournalKeys,
      },
    );

    habits.removeAt(index);
    _putTrashInMemory(entry);
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[
      (type: 'habit', id: id, payload: null, deleted: true),
      (type: 'trash', id: entry.id, payload: entry.toJson(), deleted: false),
    ];

    for (final key in completedJournalKeys) {
      final journal = journals[key];
      if (journal == null) continue;
      final updated = journal.copyWith(
        completedHabitIds:
            journal.completedHabitIds.where((value) => value != id).toList(),
      );
      journals[key] = updated;
      mutations.add((
        type: 'journal',
        id: key,
        payload: updated.toLocalJson(),
        deleted: false,
      ));
    }

    await _persistEntityMutations(mutations);
    signals.bumpLifecycle();
    _notifyJournalAndPlanningChanged();
    return true;
  }

  String? trashRestoreConflictReason(TrashEntry entry) {
    switch (entry.kind) {
      case TrashEntityKind.item:
        return items.any((item) => item.id == entry.entityId)
            ? 'Questo elemento è già presente nell’agenda.'
            : null;
      case TrashEntityKind.diaryBlock:
        final parentId = entry.parentId;
        if (parentId == null || parentId.isEmpty) return null;
        final current = journals[parentId];
        return current != null &&
                current.blocks.any((block) => block.id == entry.entityId)
            ? 'Questo ricordo è già presente nella giornata.'
            : null;
      case TrashEntityKind.journal:
        return journals.containsKey(entry.entityId)
            ? 'Per questa data esiste già una giornata attiva. Spostala prima nel Cestino per scegliere quale versione ripristinare.'
            : null;
      case TrashEntityKind.month:
        return months.containsKey(entry.entityId)
            ? 'Per questo mese esiste già una pagina attiva. Spostala prima nel Cestino per scegliere quale versione ripristinare.'
            : null;
      case TrashEntityKind.week:
        return weeks.containsKey(entry.entityId)
            ? 'Per questa settimana esiste già una pagina attiva. Spostala prima nel Cestino per scegliere quale versione ripristinare.'
            : null;
      case TrashEntityKind.habit:
        return habits.any((habit) => habit.id == entry.entityId)
            ? 'Questa abitudine è già attiva.'
            : null;
      case TrashEntityKind.birthday:
        return birthdays.any((birthday) => birthday.id == entry.entityId)
            ? 'Questo compleanno è già presente.'
            : null;
      case TrashEntityKind.person:
        return people.any((person) => person.id == entry.entityId)
            ? 'Questa persona è già presente.'
            : null;
      case TrashEntityKind.template:
        return templates.any((template) => template.id == entry.entityId)
            ? 'Questo modello è già presente.'
            : null;
      case TrashEntityKind.inbox:
        return inbox.any((value) => value.id == entry.entityId)
            ? 'Questa nota è già presente nell’Inbox.'
            : null;
    }
  }

  Future<bool> restoreTrashEntry(String trashId) async {
    final trashIndex = trash.indexWhere((entry) => entry.id == trashId);
    if (trashIndex < 0) return false;

    final localized = await _localizeTrashEntry(trash[trashIndex]);
    if (trashRestoreConflictReason(localized) != null) return false;
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[];
    AgendaItem? reminderItem;

    switch (localized.kind) {
      case TrashEntityKind.item:
        final value = AgendaItem.fromJson(localized.payload);
        items.removeWhere((item) => item.id == value.id);
        items.add(value);
        _invalidateDayIndex();
        mutations.add((
          type: 'item',
          id: value.id,
          payload: value.toJson(),
          deleted: false,
        ));
        reminderItem = value;
        break;
      case TrashEntityKind.birthday:
        final value = BirthdayEntry.fromJson(localized.payload);
        birthdays.removeWhere((birthday) => birthday.id == value.id);
        birthdays.add(value);
        mutations.add((
          type: 'birthday',
          id: value.id,
          payload: value.toJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.person:
        final value = PersonEntry.fromJson(localized.payload);
        people.removeWhere((person) => person.id == value.id);
        people.add(value);
        mutations.add((
          type: 'person',
          id: value.id,
          payload: value.toJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.template:
        final value = PersonalTemplate.fromJson(localized.payload);
        templates.removeWhere((template) => template.id == value.id);
        templates.add(value);
        mutations.add((
          type: 'template',
          id: value.id,
          payload: value.toJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.inbox:
        final value = InboxEntry.fromJson(localized.payload);
        inbox.removeWhere((entry) => entry.id == value.id);
        inbox.insert(0, value);
        mutations.add((
          type: 'inbox',
          id: value.id,
          payload: value.toJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.diaryBlock:
        final key = localized.parentId;
        if (key == null || key.isEmpty) return false;
        final value = DiaryBlock.fromJson(localized.payload);
        final current = journals[key] ?? const DayJournal();
        final blocks = [...current.blocks];
        if (!blocks.any((block) => block.id == value.id)) {
          blocks.add(value);
        }
        final updated = current.copyWith(blocks: blocks);
        journals[key] = updated;
        mutations.add((
          type: 'journal',
          id: key,
          payload: updated.toLocalJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.journal:
        final value = DayJournal.fromJson(localized.payload);
        journals[localized.entityId] = value;
        mutations.add((
          type: 'journal',
          id: localized.entityId,
          payload: value.toLocalJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.month:
        final value = MonthlyData.fromJson(localized.payload);
        months[localized.entityId] = value;
        mutations.add((
          type: 'month',
          id: localized.entityId,
          payload: value.toJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.week:
        final value = WeekData.fromJson(localized.payload);
        weeks[localized.entityId] = value;
        mutations.add((
          type: 'week',
          id: localized.entityId,
          payload: value.toJson(),
          deleted: false,
        ));
        break;
      case TrashEntityKind.habit:
        final rawHabit = localized.payload['habit'];
        if (rawHabit is! Map) return false;
        final value =
            HabitDefinition.fromJson(Map<String, dynamic>.from(rawHabit));
        habits.removeWhere((habit) => habit.id == value.id);
        habits.add(value);
        mutations.add((
          type: 'habit',
          id: value.id,
          payload: value.toJson(),
          deleted: false,
        ));
        final completedKeys =
            (localized.payload['completedJournalKeys'] as List? ?? const [])
                .map((value) => value.toString())
                .where((value) => value.isNotEmpty);
        for (final key in completedKeys) {
          final journal = journals[key] ?? const DayJournal();
          if (journal.completedHabitIds.contains(value.id)) continue;
          final updated = journal.copyWith(
            completedHabitIds: [...journal.completedHabitIds, value.id],
          );
          journals[key] = updated;
          mutations.add((
            type: 'journal',
            id: key,
            payload: updated.toLocalJson(),
            deleted: false,
          ));
        }
        break;
    }

    trash.removeAt(trashIndex);
    mutations.add((
      type: 'trash',
      id: localized.id,
      payload: null,
      deleted: true,
    ));
    await _persistEntityMutations(mutations);

    if (reminderItem != null) {
      await _syncReminders(reminderItem);
    }

    signals.bumpLifecycle();
    switch (localized.kind) {
      case TrashEntityKind.item:
        _notifyAgendaChanged();
        break;
      case TrashEntityKind.birthday:
        BirthdayEntry? restored;
        for (final birthday in birthdays) {
          if (birthday.id == localized.entityId) {
            restored = birthday;
            break;
          }
        }
        if (restored != null) {
          await _syncBirthdayReminder(restored);
        }
        _notifyPlanningChanged();
        break;
      case TrashEntityKind.person:
      case TrashEntityKind.template:
        _notifyPlanningChanged();
        break;
      case TrashEntityKind.inbox:
        _notifyInboxChanged();
        break;
      case TrashEntityKind.diaryBlock:
      case TrashEntityKind.journal:
        _scheduleMediaMaintenance(delay: const Duration(seconds: 1));
        _notifyJournalChanged();
        break;
      case TrashEntityKind.month:
      case TrashEntityKind.week:
        _notifyPlanningChanged();
        break;
      case TrashEntityKind.habit:
        _notifyJournalAndPlanningChanged();
        break;
    }
    return true;
  }

  Future<void> _unlinkPurgedHabits(Set<String> habitIds) async {
    if (habitIds.isEmpty) return;
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[];

    for (final entry in journals.entries.toList()) {
      if (!entry.value.completedHabitIds.any(habitIds.contains)) continue;
      final updated = entry.value.copyWith(
        completedHabitIds: entry.value.completedHabitIds
            .where((id) => !habitIds.contains(id))
            .toList(),
      );
      journals[entry.key] = updated;
      mutations.add((
        type: 'journal',
        id: entry.key,
        payload: updated.toLocalJson(),
        deleted: false,
      ));
    }

    for (var i = 0; i < trash.length; i++) {
      final entry = trash[i];
      if (entry.kind != TrashEntityKind.journal) continue;
      final journal = DayJournal.fromJson(entry.payload);
      if (!journal.completedHabitIds.any(habitIds.contains)) continue;
      final updatedJournal = journal.copyWith(
        completedHabitIds: journal.completedHabitIds
            .where((id) => !habitIds.contains(id))
            .toList(),
      );
      final updatedEntry = entry.copyWith(payload: updatedJournal.toLocalJson());
      trash[i] = updatedEntry;
      mutations.add((
        type: 'trash',
        id: updatedEntry.id,
        payload: updatedEntry.toJson(),
        deleted: false,
      ));
    }

    if (mutations.isNotEmpty) {
      await _persistEntityMutations(
        mutations,
        createAutoSnapshot: false,
      );
      _notifyJournalChanged();
    }
  }

  bool _hasLiveOrRecoverableReference(
    TrashEntityKind kind,
    String entityId,
  ) {
    switch (kind) {
      case TrashEntityKind.person:
        return people.any((person) => person.id == entityId) ||
            trash.any(
              (entry) =>
                  entry.kind == TrashEntityKind.person &&
                  entry.entityId == entityId,
            );
      case TrashEntityKind.birthday:
        return birthdays.any((birthday) => birthday.id == entityId) ||
            trash.any(
              (entry) =>
                  entry.kind == TrashEntityKind.birthday &&
                  entry.entityId == entityId,
            );
      case TrashEntityKind.habit:
        return habits.any((habit) => habit.id == entityId) ||
            trash.any(
              (entry) =>
                  entry.kind == TrashEntityKind.habit &&
                  entry.entityId == entityId,
            );
      case TrashEntityKind.item:
      case TrashEntityKind.diaryBlock:
      case TrashEntityKind.journal:
      case TrashEntityKind.month:
      case TrashEntityKind.week:
      case TrashEntityKind.template:
      case TrashEntityKind.inbox:
        return false;
    }
  }

  Future<bool> purgeTrashEntry(
    String trashId, {
    bool createSafetySnapshot = true,
  }) async {
    final index = trash.indexWhere((entry) => entry.id == trashId);
    if (index < 0) return false;
    if (createSafetySnapshot) {
      await createLocalSnapshot(label: 'Prima di svuotare il Cestino');
    }

    final entry = trash.removeAt(index);
    final stillRecoverable =
        _hasLiveOrRecoverableReference(entry.kind, entry.entityId);
    if (!stillRecoverable && entry.kind == TrashEntityKind.person) {
      await _unlinkPurgedPeople({entry.entityId});
    } else if (!stillRecoverable &&
        entry.kind == TrashEntityKind.birthday) {
      await _unlinkPurgedBirthdays({entry.entityId});
    } else if (!stillRecoverable && entry.kind == TrashEntityKind.habit) {
      await _unlinkPurgedHabits({entry.entityId});
    }
    await _persistEntityMutation(
      type: 'trash',
      id: entry.id,
      deleted: true,
      createAutoSnapshot: false,
    );
    _notifyLifecycleChanged();
    _scheduleMediaMaintenance(delay: const Duration(milliseconds: 300));
    return true;
  }

  Future<int> emptyTrash() async {
    if (trash.isEmpty) return 0;
    await createLocalSnapshot(label: 'Prima di svuotare il Cestino');

    final removed = [...trash];
    final purgedPeople = removed
        .where((entry) => entry.kind == TrashEntityKind.person)
        .map((entry) => entry.entityId)
        .toSet();
    final purgedBirthdays = removed
        .where((entry) => entry.kind == TrashEntityKind.birthday)
        .map((entry) => entry.entityId)
        .toSet();
    final purgedHabits = removed
        .where((entry) => entry.kind == TrashEntityKind.habit)
        .map((entry) => entry.entityId)
        .toSet();
    trash.clear();

    // A historical trash version must not break links when the same logical
    // entity is live again.
    purgedPeople.removeWhere(
      (id) => people.any((person) => person.id == id),
    );
    purgedBirthdays.removeWhere(
      (id) => birthdays.any((birthday) => birthday.id == id),
    );
    purgedHabits.removeWhere(
      (id) => habits.any((habit) => habit.id == id),
    );

    await _unlinkPurgedPeople(purgedPeople);
    await _unlinkPurgedBirthdays(purgedBirthdays);
    await _unlinkPurgedHabits(purgedHabits);
    await _persistEntityMutations(
      [
        for (final entry in removed)
          (type: 'trash', id: entry.id, payload: null, deleted: true),
      ],
      createAutoSnapshot: false,
    );
    _notifyLifecycleChanged();
    _scheduleMediaMaintenance(delay: const Duration(milliseconds: 300));
    return removed.length;
  }
}
