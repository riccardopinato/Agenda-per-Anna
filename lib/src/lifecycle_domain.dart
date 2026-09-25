part of '../main.dart';

const String _trashKey = 'trash_v1';

enum TrashEntityKind {
  item,
  diaryBlock,
  journal,
  month,
  week,
  habit,
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
        TrashEntityKind.inbox => 'Inbox',
      };

  IconData get icon => switch (this) {
        TrashEntityKind.item => Icons.event_outlined,
        TrashEntityKind.diaryBlock => Icons.auto_stories_outlined,
        TrashEntityKind.journal => Icons.menu_book_outlined,
        TrashEntityKind.month => Icons.calendar_month_outlined,
        TrashEntityKind.week => Icons.view_week_outlined,
        TrashEntityKind.habit => Icons.repeat_outlined,
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
    trash.removeWhere((candidate) => candidate.originalKey == entry.originalKey);
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

  Future<bool> restoreTrashEntry(String trashId) async {
    final trashIndex = trash.indexWhere((entry) => entry.id == trashId);
    if (trashIndex < 0) return false;

    final localized = await _localizeTrashEntry(trash[trashIndex]);
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
    await _persistEntityMutation(
      type: 'trash',
      id: entry.id,
      deleted: true,
      createAutoSnapshot: false,
    );
    signals.bumpLifecycle();
    notifyListeners();
    _scheduleMediaMaintenance(delay: const Duration(milliseconds: 300));
    return true;
  }

  Future<int> emptyTrash() async {
    if (trash.isEmpty) return 0;
    await createLocalSnapshot(label: 'Prima di svuotare il Cestino');

    final removed = [...trash];
    trash.clear();
    await _persistEntityMutations(
      [
        for (final entry in removed)
          (type: 'trash', id: entry.id, payload: null, deleted: true),
      ],
      createAutoSnapshot: false,
    );
    signals.bumpLifecycle();
    notifyListeners();
    _scheduleMediaMaintenance(delay: const Duration(milliseconds: 300));
    return removed.length;
  }
}
