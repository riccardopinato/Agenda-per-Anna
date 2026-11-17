import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = <String, dynamic>{
    'space_id': '11111111-1111-1111-1111-111111111111',
    'entry_id': 'diary-note-1',
    'user_id': '22222222-2222-2222-2222-222222222222',
    'kind': 'heart',
  };

  test('confirmed hearts use authoritative server created_at, including UTC', () {
    final reaction = SharedEntryReaction.fromJson({
      ...base,
      'created_at': '2026-11-17T13:42:21+00:00',
    });
    expect(reaction.userId, base['user_id']);
    expect(reaction.entryId, base['entry_id']);
    expect(reaction.kind, 'heart');
    expect(reaction.createdAt, DateTime.utc(2026, 11, 17, 13, 42, 21));
  });

  test('missing or corrupt reaction times are never fabricated as now', () {
    expect(SharedEntryReaction.fromJson(base).createdAt, isNull);
    expect(
      SharedEntryReaction.fromJson({
        ...base,
        'created_at': 'invalid',
      }).createdAt,
      isNull,
    );
  });

  test('heart details are scoped, server-backed and use member names', () {
    final screen = File('lib/src/screens/shared_space.dart').readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final copy = File('lib/src/localization_d3.dart').readAsStringSync();

    expect(screen, contains('Future<void> _openHeartDetails(SharedEntry entry)'));
    expect(screen, contains('listSharedEntryReactions(widget.space.id)'));
    expect(screen, contains('listSharedSpaceMembers(widget.space.id)'));
    expect(screen, contains('reaction.spaceId == widget.space.id'));
    expect(screen, contains('reaction.entryId == entry.id'));
    expect(screen, contains("reaction.kind == 'heart'"));
    expect(screen, contains('reaction.createdAt'));
    expect(screen, contains('created.toLocal()'));
    expect(screen, contains('widget.store.activeAccountId != accountScope'));
    expect(screen, contains('shared-likes-detail-'));
    expect(cloud, contains("'space_id,entry_id,user_id,kind,created_at'"));
    for (final key in const [
      'sharedLikesDetailsTitle',
      'sharedLikesCount',
      'sharedLikesTimeUnknown',
      'sharedLikesLoadFailed',
      'sharedLikesOnlineRequired',
    ]) {
      expect(copy, contains('"$key":'));
    }
  });
}
