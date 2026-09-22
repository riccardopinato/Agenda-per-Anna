import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sync health counts private and shared pending work', () async {
    final sharedOperation = SharedPendingOperation(
      action: SharedPendingAction.upsert,
      entityId: 'shared-1',
      payload: SharedEntry(
        id: 'shared-1',
        type: SharedEntryType.task,
        title: 'Noi',
        note: '',
        date: DateTime(2026, 9, 22),
      ).toJson(),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
    );

    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'cloud_sync_queue_v1': jsonEncode({
        'item:private-1': {
          'entityType': 'item',
          'entityId': 'private-1',
          'payload': AgendaItem(
            id: 'private-1',
            title: 'Privato',
            note: '',
            date: DateTime(2026, 9, 22),
            type: ItemType.task,
          ).toJson(),
          'updatedAt': DateTime.utc(2026, 9, 22, 10).toIso8601String(),
          'deleted': false,
          'ownerId': 'user-a',
        },
      }),
      'shared_pending_user-a_space-a': jsonEncode([
        sharedOperation.toJson(),
      ]),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.pendingCloudChanges, 1);
    expect(store.pendingSharedChangeCount, 1);
    expect(store.totalPendingCloudChanges, 2);

    store.dispose();
  });

  test('shared pending badge follows the active account scope', () async {
    final operation = SharedPendingOperation(
      action: SharedPendingAction.delete,
      entityId: 'shared-1',
      updatedAt: DateTime.utc(2026, 9, 22, 12),
    );

    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'shared_pending_user-a_space-a': jsonEncode([
        operation.toJson(),
      ]),
    });

    final store = AgendaStore();
    await store.load();
    expect(store.pendingSharedChangeCount, 1);

    await store.activateCloudAccount('user-b');
    expect(store.pendingSharedChangeCount, 0);

    await store.activateCloudAccount('user-a');
    expect(store.pendingSharedChangeCount, 1);

    store.dispose();
  });

  test('shared unread badge persists and clears per space', () async {
    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'shared_spaces_user-a': jsonEncode([
        {
          'id': 'space-a',
          'owner_id': 'user-a',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 1).toIso8601String(),
        }
      ]),
      'shared_unread_user-a': jsonEncode({'space-a': 2}),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.sharedUnreadCount('space-a'), 2);
    expect(store.totalSharedUnreadCount, 2);

    await store.markSharedSpaceUnread('space-a');
    expect(store.sharedUnreadCount('space-a'), 3);

    final prefs = await SharedPreferences.getInstance();
    expect(
      Map<String, dynamic>.from(
        jsonDecode(prefs.getString('shared_unread_user-a')!) as Map,
      )['space-a'],
      3,
    );

    await store.markSharedSpaceRead('space-a');
    expect(store.sharedUnreadCount('space-a'), 0);
    expect(store.totalSharedUnreadCount, 0);

    store.dispose();
  });

  test('shared unread badge follows account scope', () async {
    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'shared_spaces_user-a': jsonEncode([
        {
          'id': 'space-a',
          'owner_id': 'user-a',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 1).toIso8601String(),
        }
      ]),
      'shared_spaces_user-b': jsonEncode([
        {
          'id': 'space-b',
          'owner_id': 'user-b',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 2).toIso8601String(),
        }
      ]),
      'shared_unread_user-a': jsonEncode({'space-a': 4}),
      'shared_unread_user-b': jsonEncode({'space-b': 1}),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.totalSharedUnreadCount, 4);
    expect(store.sharedUnreadCount('space-a'), 4);

    await store.activateCloudAccount('user-b');
    expect(store.totalSharedUnreadCount, 1);
    expect(store.sharedUnreadCount('space-b'), 1);
    expect(store.sharedUnreadCount('space-a'), 0);

    await store.activateCloudAccount('user-a');
    expect(store.totalSharedUnreadCount, 4);
    expect(store.sharedUnreadCount('space-a'), 4);

    store.dispose();
  });

  test('rich diary blocks preserve sketch text images and strokes', () {
    final journal = DayJournal(
      blocks: [
        DiaryBlock(
          id: 'sketch-1',
          type: DiaryBlockType.sketch,
          createdAt: DateTime.utc(2026, 9, 22, 14, 30),
          pages: [
            const DiarySketchPage(
              id: 'page-1',
              paper: DiarySketchPaper.grid,
              strokes: [
                DiarySketchStroke(
                  tool: DiarySketchTool.pen,
                  colorValue: 0xFF222222,
                  width: 3,
                  points: [
                    DiarySketchPoint(0.1, 0.2),
                    DiarySketchPoint(0.4, 0.5),
                  ],
                ),
              ],
              textElements: [
                DiarySketchTextElement(
                  id: 'text-1',
                  text: 'Ricordo',
                  x: 0.2,
                  y: 0.3,
                  fontSize: 24,
                  colorValue: 0xFFE86D91,
                ),
              ],
              imageElements: [
                DiarySketchImageElement(
                  id: 'image-1',
                  imageBase64: 'AA==',
                  x: 0.15,
                  y: 0.4,
                  width: 0.5,
                  height: 0.3,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final restored = DayJournal.fromJson(journal.toJson());
    final page = restored.blocks.single.pages.single;

    expect(restored.blocks.single.type, DiaryBlockType.sketch);
    expect(page.paper, DiarySketchPaper.grid);
    expect(page.strokes.single.points.length, 2);
    expect(page.textElements.single.text, 'Ricordo');
    expect(page.textElements.single.fontSize, 24);
    expect(page.imageElements.single.width, 0.5);
    expect(page.imageElements.single.imageBase64, 'AA==');
  });


  test('shared photo and sketch metadata survive serialization', () {
    final photo = SharedEntry(
      id: 'photo-1',
      type: SharedEntryType.photo,
      title: 'Una foto',
      note: 'Ricordo insieme',
      date: DateTime(2026, 9, 22),
      mediaPath: 'space-a/photo-1/image.jpg',
      mediaThumbnailBase64: 'AA==',
    );
    final sketch = SharedEntry(
      id: 'sketch-1',
      type: SharedEntryType.sketch,
      title: 'Disegno',
      note: '',
      date: DateTime(2026, 9, 22),
      sketchPages: const [
        DiarySketchPage(
          id: 'page-shared',
          strokes: [
            DiarySketchStroke(
              tool: DiarySketchTool.pen,
              colorValue: 0xFF222222,
              width: 3,
              points: [
                DiarySketchPoint(0.1, 0.1),
                DiarySketchPoint(0.7, 0.7),
              ],
            ),
          ],
        ),
      ],
    );

    final restoredPhoto = SharedEntry.fromJson(photo.toJson());
    final restoredSketch = SharedEntry.fromJson(sketch.toJson());

    expect(restoredPhoto.type, SharedEntryType.photo);
    expect(restoredPhoto.mediaPath, 'space-a/photo-1/image.jpg');
    expect(restoredPhoto.mediaThumbnailBase64, 'AA==');
    expect(restoredSketch.type, SharedEntryType.sketch);
    expect(restoredSketch.sketchPages.single.strokes.single.points.length, 2);
  });

  test('daily agenda orders newest time first', () async {
    final day = DateTime(2026, 9, 22);
    SharedPreferences.setMockInitialValues({
      'items_v1': jsonEncode([
        AgendaItem(
          id: 'morning',
          title: 'Mattina',
          note: '',
          date: day,
          type: ItemType.appointment,
          start: const TimeOfDay(hour: 9, minute: 0),
        ).toJson(),
        AgendaItem(
          id: 'evening',
          title: 'Sera',
          note: '',
          date: day,
          type: ItemType.appointment,
          start: const TimeOfDay(hour: 18, minute: 30),
        ).toJson(),
        AgendaItem(
          id: 'all-day',
          title: 'Tutto il giorno',
          note: '',
          date: day,
          type: ItemType.appointment,
        ).toJson(),
      ]),
    });

    final store = AgendaStore();
    await store.load();
    final ordered = store.unifiedForDay(day);

    expect(
      ordered.map((entry) => entry.id).toList(),
      ['evening', 'morning', 'all-day'],
    );

    store.dispose();
  });

  test('backup metadata reports the current release line', () async {
    final store = AgendaStore();
    await store.load();

    final backup =
        Map<String, dynamic>.from(jsonDecode(store.createBackupJson()) as Map);

    expect(backup['appVersion'], '0.28.0');

    store.dispose();
  });
}
