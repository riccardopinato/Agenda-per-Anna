import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';

void main() {
  test('shared realtime record change parses update payload', () {
    final change = SharedRealtimeRecordChange.fromRealtime(
      fallbackSpaceId: 'space-fallback',
      newRecord: {
        'space_id': 'space-a',
        'entity_type': 'shared_entry',
        'entity_id': 'entry-1',
        'payload': {
          'id': 'entry-1',
          'title': 'Aggiornato',
        },
        'client_updated_at': '2026-09-23T14:00:00.000Z',
        'deleted_at': null,
        'updated_by': 'user-b',
      },
      oldRecord: const {},
    );

    expect(change.spaceId, 'space-a');
    expect(change.entityType, 'shared_entry');
    expect(change.entityId, 'entry-1');
    expect(change.payload?['title'], 'Aggiornato');
    expect(change.updatedBy, 'user-b');
    expect(change.deletedAt, isNull);
    expect(change.clientUpdatedAt, DateTime.utc(2026, 9, 23, 14));
  });

  test('shared realtime record change treats physical delete as tombstone', () {
    final change = SharedRealtimeRecordChange.fromRealtime(
      fallbackSpaceId: 'space-a',
      newRecord: const {},
      oldRecord: {
        'space_id': 'space-a',
        'entity_type': 'shared_entry',
        'entity_id': 'entry-deleted',
        'client_updated_at': '2026-09-23T14:10:00.000Z',
      },
    );

    expect(change.entityId, 'entry-deleted');
    expect(change.deletedAt, isNotNull);
    expect(change.payload, isNull);
  });

  test('interaction realtime change exposes insert and delete semantics', () {
    const inserted = SharedRealtimeInteractionChange(
      kind: SharedRealtimeInteractionKind.reaction,
      newRecord: {
        'space_id': 'space-a',
        'entry_id': 'entry-1',
        'user_id': 'user-a',
        'kind': 'heart',
      },
      oldRecord: {},
    );
    const deleted = SharedRealtimeInteractionChange(
      kind: SharedRealtimeInteractionKind.reaction,
      newRecord: {},
      oldRecord: {
        'space_id': 'space-a',
        'entry_id': 'entry-1',
        'user_id': 'user-a',
        'kind': 'heart',
      },
    );

    expect(inserted.deleted, isFalse);
    expect(inserted.record['entry_id'], 'entry-1');
    expect(deleted.deleted, isTrue);
    expect(deleted.record['user_id'], 'user-a');
  });

  test('remote records preserve UTC cursor revision', () {
    final record = CloudRemoteRecord.fromJson({
      'record_key': 'user-a:private:item:item-1',
      'entity_type': 'item',
      'entity_id': 'item-1',
      'payload': {
        'id': 'item-1',
      },
      'client_updated_at': '2026-09-23T15:15:30.125Z',
      'deleted_at': null,
    });

    expect(
      record.clientUpdatedAt,
      DateTime.utc(2026, 9, 23, 15, 15, 30, 125),
    );
  });
}
