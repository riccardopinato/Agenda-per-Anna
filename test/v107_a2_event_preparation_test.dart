import 'dart:io';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  AgendaItem event({String note = 'Bring passport', ItemType type = ItemType.appointment}) =>
      AgendaItem(
        id: 'preparation-event',
        title: 'Travel appointment',
        note: note,
        date: DateTime(2026, 11, 12),
        type: type,
      );

  test('A2 parses and composes checked and unchecked trailing steps', () {
    const original = 'Bring passport\n\n☐ Tickets\n☑ Insurance';
    final draft = EventPreparationDraft.fromNote(original);
    expect(draft.note, 'Bring passport\n\n');
    expect(draft.steps.map((s) => s.text), ['Tickets', 'Insurance']);
    expect(draft.steps.map((s) => s.completed), [false, true]);
    expect(draft.compose(), original);
    final edited = EventPreparationDraft(note: draft.note, steps: [
      draft.steps.first.copyWith(completed: true),
      draft.steps.last,
    ]);
    expect(edited.compose(), contains('☑ Tickets'));
    expect(edited.compose(), isNot(contains('☐ Tickets')));
  });

  test('A2 never steals nontrailing checkboxes or rewrites plain notes', () {
    const note = '☐ This is part of the freeform text\n\nAn unrelated line.';
    final parsed = EventPreparationDraft.fromNote(note);
    expect(parsed.steps, isEmpty);
    expect(parsed.note, note);
    expect(parsed.compose(), note);
    final withStep = const EventPreparationDraft(
      note: note, steps: [EventPreparationStep('Camera')],
    );
    expect(withStep.compose(), '$note\n\n☐ Camera');
    expect(EventPreparationDraft.fromNote(withStep.compose()).steps.length, 1);
  });

  test('A2 persists only the original event note, no new entity', () async {
    final store = AgendaStore();
    await store.load();
    final source = event();
    await store.upsert(source);
    final original = store.items.single.toJson();

    final result = await saveEventPreparation(
      store,
      source,
      const EventPreparationDraft(
        note: 'Bring passport',
        steps: [
          EventPreparationStep('Print tickets'),
          EventPreparationStep('Charge phone', completed: true),
        ],
      ),
      accountAtOpen: store.activeAccountId,
    );
    expect(result, EventPreparationSaveResult.saved);
    expect(store.items.length, 1);
    final saved = store.items.single;
    expect(saved.note, 'Bring passport\n\n☐ Print tickets\n☑ Charge phone');
    expect(saved.toJson()..remove('note'), original..remove('note'));
    expect(store.journal(source.date).blocks, isEmpty);
    final reopened = EventPreparationDraft.fromNote(saved.note);
    expect(reopened.steps.length, 2);
    expect(reopened.steps.last.completed, isTrue);
    store.dispose();
  });

  test('A2 handles no-op, remote note conflict, account switch and removal', () async {
    final store = AgendaStore();
    await store.load();
    final source = event();
    await store.upsert(source);
    final draft = EventPreparationDraft.fromNote(source.note);
    expect(await saveEventPreparation(
      store, source, draft, accountAtOpen: store.activeAccountId,
    ), EventPreparationSaveResult.unchanged);

    await store.upsert(source.copyWith(note: 'Modified elsewhere'));
    expect(await saveEventPreparation(
      store, source, const EventPreparationDraft(note: 'Older draft', steps: []),
      accountAtOpen: store.activeAccountId,
    ), EventPreparationSaveResult.noteConflict);
    expect(store.items.single.note, 'Modified elsewhere');

    expect(await saveEventPreparation(
      store, source, draft, accountAtOpen: 'different-account',
    ), EventPreparationSaveResult.accountChanged);
    await store.deleteItem(source.id);
    expect(await saveEventPreparation(
      store, source, draft, accountAtOpen: store.activeAccountId,
    ), EventPreparationSaveResult.sourceChanged);
    expect(store.items, isEmpty);
    store.dispose();
  });

  test('A2 entire appointment including checklist survives Trash restoration', () async {
    final store = AgendaStore();
    await store.load();
    final source = event(note: 'Documents\n\n☐ Ticket');
    await store.upsert(source);
    expect(await store.moveItemToTrash(source.id), isTrue);
    final deleted = store.trash.singleWhere((t) => t.entityId == source.id);
    expect(await store.restoreTrashEntry(deleted.id), isTrue);
    expect(store.items.single.note, source.note);
    store.dispose();
  });

  test('A2 source contract keeps checkbox editor private and no task engine', () {
    final source = File('lib/src/event_preparation.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains("part 'src/event_preparation.dart';"));
    expect(planner, contains("'v107-event-preparation-action'"));
    expect(planner, contains('openEventPreparation(context, store, item)'));
    expect(source, contains('store.upsert(current.copyWith(note: nextNote))'));
    expect(source, contains('EventPreparationSaveResult.noteConflict'));
    expect(source, isNot(contains('SharedPreferences.getInstance')));
    expect(source, isNot(contains('CloudSyncService')));
    expect(source, isNot(contains('NotificationService')));
    expect(canPrepareEvent(event(type: ItemType.task)), isFalse);
    expect(canPrepareEvent(event()), isTrue);
  });
}
