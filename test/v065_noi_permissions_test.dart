import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.65 shared creative permissions are backward compatible', () {
    final legacy = SharedEntry.fromJson({
      'id': 'legacy',
      'type': 'sketch',
      'title': 'Sketch',
      'note': '',
      'date': '2026-09-27T00:00:00.000',
    });

    expect(legacy.membersCanEdit, isTrue);
    expect(legacy.editOwnerId, isEmpty);
    expect(legacy.canEditFor('member-a'), isTrue);

    final locked = legacy.copyWith(
      membersCanEdit: false,
      editOwnerId: 'owner-a',
    );
    expect(locked.canEditFor('owner-a'), isTrue);
    expect(locked.canEditFor('member-b'), isFalse);
    expect(locked.isEditOwner('owner-a'), isTrue);

    final roundTrip = SharedEntry.fromJson(locked.toJson());
    expect(roundTrip.membersCanEdit, isFalse);
    expect(roundTrip.editOwnerId, 'owner-a');
  });

  test('v0.65 media queue preserves permission metadata', () {
    final upload = SharedMediaPendingUpload(
      id: 'upload',
      spaceId: 'space',
      entryId: 'entry',
      title: 'Foto',
      note: '',
      date: DateTime(2026, 9, 27),
      oldMediaPath: '',
      createdAt: DateTime(2026, 9, 27),
      membersCanEdit: false,
      editOwnerId: 'owner-a',
    );
    final restored = SharedMediaPendingUpload.fromJson(upload.toJson());

    expect(restored.membersCanEdit, isFalse);
    expect(restored.editOwnerId, 'owner-a');
  });

  test('v0.65 UI and backend both enforce read-only mode', () {
    final shared =
        File('lib/src/screens/shared_space.dart').readAsStringSync();
    final migration = File(
      'supabase/migrations/025_noi_permissions_lite_v065.sql',
    ).readAsStringSync();
    final mediaMigration = File(
      'supabase/migrations/026_noi_permissions_media_v065.sql',
    ).readAsStringSync();

    expect(shared, contains('_canEditSharedEntry'));
    expect(shared, contains('_setSharedEditPermission'));
    expect(shared, contains('Solo tu puoi modificare'));
    expect(shared, contains('Sola lettura'));
    expect(migration, contains('shared_entry_read_only'));
    expect(migration, contains('agenda_records_shared_entry_permissions'));
    expect(mediaMigration, contains('can_edit_shared_media_object'));
    expect(mediaMigration, contains('shared_media_update_members'));
  });

  test('v0.65 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.72.0');
    expect(pubspec, contains('version: 0.72.0+82'));
  });
}
