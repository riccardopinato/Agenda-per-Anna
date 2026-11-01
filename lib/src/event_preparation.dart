part of '../main.dart';

/// CAP-0003: checklist encoded as readable lines inside AgendaItem.note.
/// No separate persistence, task ownership, reminder or sharing channel.
class EventPreparationStep {
  final String text;
  final bool completed;

  const EventPreparationStep(this.text, {this.completed = false});

  EventPreparationStep copyWith({bool? completed}) =>
      EventPreparationStep(text, completed: completed ?? this.completed);
}

class EventPreparationDraft {
  final String note;
  final List<EventPreparationStep> steps;

  const EventPreparationDraft({required this.note, required this.steps});

  static bool _isStep(String line) =>
      (line.startsWith('☐ ') || line.startsWith('☑ ')) &&
      line.substring(2).trim().isNotEmpty;

  factory EventPreparationDraft.fromNote(String value) {
    final lines = value.split('\n');
    var first = lines.length;
    while (first > 0 && _isStep(lines[first - 1])) {
      first--;
    }
    if (first == lines.length) {
      return EventPreparationDraft(note: value, steps: const []);
    }
    // Only the trailing checklist belongs to this editor. Arbitrary prose,
    // preexisting inline checkboxes and middle-of-note text stay untouched.
    final body = lines.sublist(0, first).join('\n');
    final steps = lines.sublist(first).map((line) =>
        EventPreparationStep(
          line.substring(2),
          completed: line.startsWith('☑ '),
        )).toList(growable: false);
    return EventPreparationDraft(note: body, steps: steps);
  }

  String compose() {
    final validSteps = steps
        .where((step) => step.text.trim().isNotEmpty)
        .map((step) => (step.completed ? '☑ ' : '☐ ') + step.text.trim())
        .toList(growable: false);
    if (validSteps.isEmpty) return note;
    final separator = note.isEmpty ? '' : note.endsWith('\n\n')
        ? '' : note.endsWith('\n') ? '\n' : '\n\n';
    return note + separator + validSteps.join('\n');
  }
}

bool canPrepareEvent(AgendaItem item) =>
    item.type == ItemType.appointment && item.title.trim().isNotEmpty;

enum EventPreparationSaveResult {
  saved,
  unchanged,
  sourceChanged,
  noteConflict,
  accountChanged,
}

/// An optimistic concurrency check prevents overwriting remote or ordinary
/// editor changes. Writer is the existing canonical AgendaStore.upsert.
Future<EventPreparationSaveResult> saveEventPreparation(
  AgendaStore store,
  AgendaItem source,
  EventPreparationDraft draft, {
  required String? accountAtOpen,
}) async {
  if (store.activeAccountId != accountAtOpen) {
    return EventPreparationSaveResult.accountChanged;
  }
  AgendaItem? current;
  for (final item in store.items) {
    if (item.id == source.id) {
      current = item;
      break;
    }
  }
  if (current == null ||
      !canPrepareEvent(current) ||
      !AgendaStore.sameDay(current.date, source.date) ||
      current.recurrenceIndex != source.recurrenceIndex) {
    return EventPreparationSaveResult.sourceChanged;
  }
  if (current.note != source.note) {
    return EventPreparationSaveResult.noteConflict;
  }
  final nextNote = draft.compose();
  if (nextNote == current.note) return EventPreparationSaveResult.unchanged;
  await store.upsert(
    current.copyWith(note: nextNote),
    synchronizeReminders: false,
  );
  return EventPreparationSaveResult.saved;
}

Future<void> openEventPreparation(
  BuildContext context,
  AgendaStore store,
  AgendaItem item,
) async {
  if (!canPrepareEvent(item)) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _EventPreparationSheet(store: store, item: item),
  );
}

class _EventPreparationSheet extends StatefulWidget {
  final AgendaStore store;
  final AgendaItem item;

  const _EventPreparationSheet({required this.store, required this.item});

  @override
  State<_EventPreparationSheet> createState() =>
      _EventPreparationSheetState();
}

class _EventPreparationSheetState extends State<_EventPreparationSheet> {
  late final TextEditingController _note;
  late final TextEditingController _newStep;
  late final List<EventPreparationStep> _steps;
  String? _accountAtOpen;
  String? _errorKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = EventPreparationDraft.fromNote(widget.item.note);
    _note = TextEditingController(text: draft.note);
    _newStep = TextEditingController();
    _steps = List<EventPreparationStep>.of(draft.steps);
    _accountAtOpen = widget.store.activeAccountId;
  }

  @override
  void dispose() {
    _note.dispose();
    _newStep.dispose();
    super.dispose();
  }

  void _addStep() {
    final text = _newStep.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() {
      _steps.add(EventPreparationStep(text));
      _newStep.clear();
      _errorKey = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final pendingStep = _newStep.text.trim();
    if (pendingStep.isNotEmpty) {
      _steps.add(EventPreparationStep(pendingStep));
      _newStep.clear();
    }
    setState(() { _saving = true; _errorKey = null; });
    try {
      final result = await saveEventPreparation(
        widget.store,
        widget.item,
        EventPreparationDraft(note: _note.text, steps: List.of(_steps)),
        accountAtOpen: _accountAtOpen,
      );
      if (!mounted) return;
      if (result == EventPreparationSaveResult.saved ||
          result == EventPreparationSaveResult.unchanged) {
        Navigator.pop(context);
        return;
      }
      if (result == EventPreparationSaveResult.accountChanged) {
        // Do not expose the previous account's note to the new account.
        _note.clear();
        _steps.clear();
        Navigator.pop(context);
        return;
      }
      setState(() {
        _errorKey = result == EventPreparationSaveResult.noteConflict
            ? 'v107PrepConflict'
            : 'v107PrepMissing';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorKey = 'v107PrepSaveError');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Avoid exceeding the modal's available height when the keyboard opens.
    final height = min(screenHeight * 0.78,
        max(0.0, screenHeight - keyboardInset - 56));
    return Padding(
      padding: EdgeInsets.only(
        left: 18, right: 18, bottom: keyboardInset + 12,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.d3('v107PrepTitle'),
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.item.title, maxLines: 2,
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    key: const ValueKey('v107-prep-note'),
                    controller: _note,
                    readOnly: _saving,
                    maxLines: null,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: strings.d3('v107PrepNotes'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(strings.d3('v107PrepChecklist'),
                    style: Theme.of(context).textTheme.titleMedium),
                  for (var i = 0; i < _steps.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            key: ValueKey('v107-prep-step-$i'),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(_steps[i].text),
                            value: _steps[i].completed,
                            onChanged: _saving ? null : (value) => setState(() {
                              _steps[i] = _steps[i].copyWith(completed: value);
                            }),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.delete,
                          onPressed: _saving ? null : () => setState(() {
                            _steps.removeAt(i);
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('v107-prep-new-step'),
                          controller: _newStep,
                          enabled: !_saving,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addStep(),
                          decoration: InputDecoration(
                            hintText: strings.d3('v107PrepAddHint'),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: strings.d3('v107PrepAdd'),
                        onPressed: _saving ? null : _addStep,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  if (_errorKey != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(strings.d3(_errorKey!),
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(strings.cancel),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('v107-prep-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(strings.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
