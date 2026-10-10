part of '../main.dart';

enum AgendaContentFilter { all, privateOnly, sharedOnly }

extension AgendaContentFilterUi on AgendaContentFilter {
  String localizedLabel(AnnaStrings strings) => strings.unifiedFilterLabel(this);

  IconData get icon => switch (this) {
        AgendaContentFilter.all => Icons.layers_outlined,
        AgendaContentFilter.privateOnly => Icons.lock_outline,
        AgendaContentFilter.sharedOnly => Icons.favorite_outline,
      };
}

enum AgendaCreationVisibility { privateItem, shared }

class UnifiedAgendaEntry {
  final AgendaItem? privateItem;
  final SharedEntry? sharedEntry;
  final SharedSpace? space;
  final ExternalCalendarEvent? externalEvent;

  const UnifiedAgendaEntry.private(this.privateItem)
      : sharedEntry = null,
        space = null,
        externalEvent = null;

  const UnifiedAgendaEntry.shared(this.sharedEntry, this.space)
      : privateItem = null,
        externalEvent = null;

  const UnifiedAgendaEntry.external(this.externalEvent)
      : privateItem = null,
        sharedEntry = null,
        space = null;

  bool get isShared => sharedEntry != null;
  bool get isPrivate => privateItem != null;
  bool get isExternal => externalEvent != null;

  String get id =>
      privateItem?.id ?? sharedEntry?.id ?? externalEvent!.id;
  String get title =>
      privateItem?.title ?? sharedEntry?.title ?? externalEvent!.title;
  String get note =>
      privateItem?.note ?? sharedEntry?.note ?? externalEvent!.description;
  DateTime get date =>
      privateItem?.date ?? sharedEntry?.date ?? externalEvent!.date;
  TimeOfDay? get start => privateItem != null
      ? privateItem!.start
      : sharedEntry != null
          ? sharedEntry!.start
          : externalEvent!.startTime;
  TimeOfDay? get end => privateItem != null
      ? privateItem!.end
      : sharedEntry != null
          ? sharedEntry!.end
          : externalEvent!.endTime;
  bool get done => privateItem?.done ?? sharedEntry?.done ?? false;

  ItemType get type {
    if (privateItem != null) return privateItem!.type;
    if (sharedEntry != null) {
      return sharedEntry!.type == SharedEntryType.task
          ? ItemType.task
          : ItemType.appointment;
    }
    return ItemType.appointment;
  }

  AgendaCategory get category {
    if (privateItem != null) return privateItem!.category;
    if (sharedEntry != null) return AgendaCategory.couple;
    return AgendaCategory.other;
  }

  String visibilityLabel(AnnaStrings strings) {
    if (isShared) {
      return space?.name.trim().isNotEmpty == true ? space!.name : 'Noi ♡';
    }
    if (isExternal) {
      final name = externalEvent!.calendarName.trim();
      return name.isEmpty ? strings.d3('external_externalCalendar') : name;
    }
    return strings.d3('unified_private');
  }

  int get sortMinutes =>
      start == null ? 24 * 60 + 1 : start!.hour * 60 + start!.minute;
}

List<UnifiedAgendaEntry> agendaEntriesForDayWithExternal(
  AgendaStore store,
  DateTime date,
) {
  final result = <UnifiedAgendaEntry>[
    ...store.unifiedForDay(date),
  ];
  if (store.agendaContentFilter == AgendaContentFilter.all) {
    result.addAll(
      ExternalCalendarService.instance
          .eventsForDay(date)
          .map(UnifiedAgendaEntry.external),
    );
  }
  result.sort((a, b) {
    final aHasTime = a.start != null;
    final bHasTime = b.start != null;
    if (aHasTime && bHasTime) {
      final time = b.sortMinutes.compareTo(a.sortMinutes);
      if (time != 0) return time;
    } else if (aHasTime != bHasTime) {
      return aHasTime ? -1 : 1;
    }
    return b.title.toLowerCase().compareTo(a.title.toLowerCase());
  });
  return List<UnifiedAgendaEntry>.unmodifiable(result);
}

class AgendaContentFilterBar extends StatelessWidget {
  final AgendaStore store;
  final EdgeInsetsGeometry padding;

  const AgendaContentFilterBar({
    super.key,
    required this.store,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SegmentedButton<AgendaContentFilter>(
        showSelectedIcon: false,
        segments: AgendaContentFilter.values
            .map(
              (value) => ButtonSegment(
                value: value,
                icon: Icon(value.icon, size: 17),
                label: Text(value.localizedLabel(AnnaStrings.of(context))),
              ),
            )
            .toList(),
        selected: {store.agendaContentFilter},
        onSelectionChanged: (value) =>
            store.setAgendaContentFilter(value.first),
      ),
    );
  }
}

class UnifiedAgendaTile extends StatelessWidget {
  final AgendaStore store;
  final UnifiedAgendaEntry entry;
  final bool compact;
  final bool hideDetails;

  const UnifiedAgendaTile({
    super.key,
    required this.store,
    required this.entry,
    this.compact = false,
    this.hideDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final privateItem = entry.privateItem;
    if (privateItem != null) {
      return EventTile(
        store: store,
        item: privateItem,
        compact: compact,
        hideDetails: hideDetails,
      );
    }

    final external = entry.externalEvent;
    if (external != null) {
      final color = external.colorValue == null
          ? Theme.of(context).colorScheme.tertiary
          : Color(external.colorValue! & 0xFFFFFFFF);
      final timeText = external.allDay
          ? AnnaStrings.of(context).d3('editor_allDay')
          : '${formatTime(external.startTime!)}'
              '${external.endTime == null ? '' : ' – ${formatTime(external.endTime!)}'}';
      final details = <String>[
        timeText,
        external.calendarName.trim().isEmpty
            ? AnnaStrings.of(context).d3('external_externalCalendar')
            : external.calendarName,
        if (!hideDetails && external.location.isNotEmpty) external.location,
      ];
      return Card(
        margin: EdgeInsets.only(bottom: compact ? 6 : 10),
        child: ListTile(
          dense: compact,
          contentPadding: EdgeInsets.only(
            left: compact ? 10 : 12,
            right: compact ? 10 : 12,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            foregroundColor: color,
            child: const Icon(Icons.event_available_outlined),
          ),
          title: Text(
            hideDetails
                ? AnnaStrings.of(context).d3('unified_externalHidden')
                : (external.title.trim().isEmpty
                    ? AnnaStrings.of(context).d3('external_untitledEvent')
                    : external.title),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(details.join(' · ')),
          trailing: Tooltip(
            message: AnnaStrings.of(context).d3('unified_readOnly'),
            child: const Icon(Icons.lock_outline, size: 18),
          ),
          onTap: () => openUnifiedAgendaEntry(context, store, entry),
        ),
      );
    }

    final shared = entry.sharedEntry!;
    final color = AgendaCategory.couple.color;
    final timeText = shared.start == null
        ? (shared.type == SharedEntryType.task ? AnnaStrings.of(context).d3('editor_toDo') : AnnaStrings.of(context).d3('editor_allDay'))
        : '${formatTime(shared.start!)}'
            '${shared.end == null ? '' : ' – ${formatTime(shared.end!)}'}';

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.only(
          left: compact ? 10 : 12,
          right: compact ? 4 : 8,
        ),
        leading: shared.type == SharedEntryType.task
            ? Checkbox(
                value: shared.done,
                activeColor: color,
                onChanged: (_) => _toggleSharedAgendaEntry(store, entry),
              )
            : CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                foregroundColor: color,
                child: const Icon(Icons.favorite_outline),
              ),
        title: Text(
          hideDetails ? AnnaStrings.of(context).d3('unified_sharedHidden') : shared.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: shared.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Wrap(
          spacing: 7,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(timeText),
            Text(
              'Noi ♡',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            if (entry.space != null && entry.space!.name != 'Noi ♡')
              Text(
                entry.space!.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onTap: () => openUnifiedAgendaEntry(context, store, entry),
        trailing: PopupMenuButton<String>(
          tooltip: AnnaStrings.of(context).d3('editor_actions'),
          onSelected: (value) async {
            if (value == 'edit') {
              await openUnifiedAgendaEntry(context, store, entry);
            } else if (value == 'private') {
              await _moveSharedAgendaEntryToPrivate(context, store, entry);
            } else if (value == 'delete') {
              await _deleteSharedAgendaEntry(context, store, entry);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text(AnnaStrings.of(context).edit),
              ),
            ),
            PopupMenuItem(
              value: 'private',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_outline),
                title: Text(AnnaStrings.of(context).d3('unified_movePrivate')),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline),
                title: Text(AnnaStrings.of(context).delete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openUnifiedAgendaEntry(
  BuildContext context,
  AgendaStore store,
  UnifiedAgendaEntry entry,
) async {
  if (entry.privateItem != null) {
    await openItemEditor(
      context,
      store,
      entry.date,
      existing: entry.privateItem,
    );
    return;
  }

  if (entry.externalEvent != null) {
    final event = entry.externalEvent!;
    final when = event.allDay
        ? AnnaStrings.of(context).d3('editor_allDay')
        : '${formatTime(event.startTime!)}'
            '${event.endTime == null ? '' : ' – ${formatTime(event.endTime!)}'}';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          event.title.trim().isEmpty
              ? AnnaStrings.of(dialogContext).d3('external_untitledEvent')
              : event.title,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(when, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              event.calendarName.trim().isEmpty
                  ? AnnaStrings.of(dialogContext).d3('external_externalCalendar')
                  : event.calendarName,
            ),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.location),
            ],
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.description),
            ],
            const SizedBox(height: 12),
            Text(
              AnnaStrings.of(dialogContext).d3('unified_externalReadOnly'),
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(dialogContext).close),
          ),
        ],
      ),
    );
    return;
  }

  final shared = entry.sharedEntry!;
  final result = await _openSharedEntryEditor(
    context,
    initialDate: shared.date,
    existing: shared,
  );
  if (result == null) return;
  await _saveSharedAgendaEntry(store, entry.space!.id, result);
}

Future<void> _saveSharedAgendaEntry(
  AgendaStore store,
  String spaceId,
  SharedEntry entry,
) async {
  final revision = DateTime.now().toUtc();
  final stamped = entry.copyWith(
    updatedBy: CloudSyncService.instance.userId,
    updatedAt: revision,
    editorName: store.preferences.displayName,
  );
  await store.enqueueSharedUpsert(
    spaceId: spaceId,
    entry: stamped,
    updatedAt: revision,
  );
  if (CloudSyncService.instance.signedIn) {
    await store.flushSharedPendingOperations(spaceId: spaceId);
  }
}

Future<void> _toggleSharedAgendaEntry(
  AgendaStore store,
  UnifiedAgendaEntry entry,
) async {
  final shared = entry.sharedEntry;
  final space = entry.space;
  if (shared == null || space == null) return;
  await _saveSharedAgendaEntry(
    store,
    space.id,
    shared.copyWith(done: !shared.done),
  );
}

Future<SharedSpace?> _chooseSharedSpace(
  BuildContext context,
  AgendaStore store,
) async {
  final spaces = store.sharedAgendaSpaces;
  if (spaces.isEmpty) return null;
  if (spaces.length == 1) return spaces.first;

  return showDialog<SharedSpace>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(AnnaStrings.of(dialogContext).d3('unified_chooseSharedSpace')),
      children: spaces
          .map(
            (space) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, space),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite_outline),
                title: Text(
                  space.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  space.isOwner
                      ? AnnaStrings.of(dialogContext).d3('unified_createdByYou')
                      : AnnaStrings.of(dialogContext).d3('unified_sharedSpace'),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

Future<void> _movePrivateAgendaItemToShared(
  BuildContext context,
  AgendaStore store,
  AgendaItem item,
) async {
  final space = await _chooseSharedSpace(context, store);
  if (!context.mounted || space == null) return;

  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AnnaStrings.of(dialogContext).d3('unified_moveNoiTitle')),
          content: Text(
            AnnaStrings.of(dialogContext).d3('unified_privateSettingsStay'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AnnaStrings.of(dialogContext).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AnnaStrings.of(dialogContext).d3('unified_move')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;

  final shared = SharedEntry(
    id: item.id,
    type: item.type == ItemType.task
        ? SharedEntryType.task
        : SharedEntryType.appointment,
    title: item.title,
    note: item.note,
    date: item.date,
    start: item.start,
    end: item.end,
    done: item.done,
  );
  await _saveSharedAgendaEntry(store, space.id, shared);
  await store.deleteItem(item.id);
}

Future<void> _moveSharedAgendaEntryToPrivate(
  BuildContext context,
  AgendaStore store,
  UnifiedAgendaEntry entry,
) async {
  final shared = entry.sharedEntry;
  final space = entry.space;
  if (shared == null || space == null) return;

  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AnnaStrings.of(dialogContext).d3('unified_movePrivateTitle')),
          content: Text(
            AnnaStrings.of(dialogContext).d3('unified_movePrivateBody'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AnnaStrings.of(dialogContext).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AnnaStrings.of(dialogContext).d3('unified_move')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;

  await store.upsert(
    AgendaItem(
      id: shared.id,
      title: shared.title,
      note: shared.note,
      date: shared.date,
      type: shared.type == SharedEntryType.task
          ? ItemType.task
          : ItemType.appointment,
      category: AgendaCategory.couple,
      start: shared.start,
      end: shared.end,
      done: shared.done,
    ),
  );

  final revision = DateTime.now().toUtc();
  await store.enqueueSharedDelete(
    spaceId: space.id,
    entityId: shared.id,
    updatedAt: revision,
  );
  if (CloudSyncService.instance.signedIn) {
    await store.flushSharedPendingOperations(spaceId: space.id);
  }
}

Future<void> _deleteSharedAgendaEntry(
  BuildContext context,
  AgendaStore store,
  UnifiedAgendaEntry entry,
) async {
  final shared = entry.sharedEntry;
  final space = entry.space;
  if (shared == null || space == null) return;

  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AnnaStrings.of(dialogContext).d3('unified_deleteNoiTitle')),
          content: Text(
            AnnaStrings.of(dialogContext).d3Format(
              'unified_deleteSharedForEveryone',
              {'title': shared.title},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AnnaStrings.of(dialogContext).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AnnaStrings.of(dialogContext).delete),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;

  final revision = DateTime.now().toUtc();
  await store.enqueueSharedDelete(
    spaceId: space.id,
    entityId: shared.id,
    updatedAt: revision,
  );
  if (CloudSyncService.instance.signedIn) {
    await store.flushSharedPendingOperations(spaceId: space.id);
  }
}


Future<void> openUnifiedItemComposer(
  BuildContext context,
  AgendaStore store,
  DateTime initialDate, {
  TimeOfDay? initialTime,
  ItemType? initialType,
}) async {
  final spaces = store.sharedAgendaSpaces;
  if (spaces.isEmpty) {
    await openItemEditor(
      context,
      store,
      initialDate,
      initialTime: initialTime,
      initialType: initialType,
    );
    return;
  }

  final visibility = await showModalBottomSheet<AgendaCreationVisibility>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AnnaStrings.of(sheetContext).d3('unified_whereSave'),
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              AnnaStrings.of(sheetContext).d3('unified_privateDefault'),
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const CircleAvatar(
                child: Icon(Icons.lock_outline),
              ),
              title: Text(
                AnnaStrings.of(sheetContext).d3('unified_private'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(AnnaStrings.of(sheetContext).d3('unified_visibleOnlyAccount')),
              onTap: () => Navigator.pop(
                sheetContext,
                AgendaCreationVisibility.privateItem,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: CircleAvatar(
                backgroundColor:
                    AgendaCategory.couple.color.withValues(alpha: 0.16),
                foregroundColor: AgendaCategory.couple.color,
                child: const Icon(Icons.favorite_outline),
              ),
              title: const Text(
                'Noi ♡',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                AnnaStrings.of(sheetContext).d3('unified_syncedShared'),
              ),
              onTap: () => Navigator.pop(
                sheetContext,
                AgendaCreationVisibility.shared,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (!context.mounted || visibility == null) return;

  if (visibility == AgendaCreationVisibility.privateItem) {
    await openItemEditor(
      context,
      store,
      initialDate,
      initialTime: initialTime,
      initialType: initialType,
    );
    return;
  }

  final targetSpace = await _chooseSharedSpace(context, store);
  if (!context.mounted || targetSpace == null) return;

  final sharedType = switch (initialType) {
    ItemType.task => SharedEntryType.task,
    _ => SharedEntryType.appointment,
  };

  final result = await _openSharedEntryEditor(
    context,
    initialDate: initialDate,
    initialType: sharedType,
    initialTime: initialTime,
  );
  if (result == null) return;

  await _saveSharedAgendaEntry(
    store,
    targetSpace.id,
    result,
  );
}
