import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.65 shared sketch permission metadata is backward compatible', () {
    final models = File('lib/src/domain_models.dart').readAsStringSync();

    expect(models, contains('final bool ownerOnlyEdit;'));
    expect(models, contains("this.ownerOnlyEdit = false"));
    expect(models, contains("final String creatorId;"));
    expect(models, contains("'ownerOnlyEdit': ownerOnlyEdit"));
    expect(models, contains("json['ownerOnlyEdit'] as bool? ?? false"));
  });

  test('v0.65 UI keeps locked sketches readable and interactive', () {
    final shared =
        File('lib/src/screens/shared_space.dart').readAsStringSync();

    expect(shared, contains('_canEditSharedEntry'));
    expect(shared, contains('_setSketchPermission'));
    expect(shared, contains('Solo io posso modificare'));
    expect(shared, contains('Tutti possono modificare'));
    expect(shared, contains('SharedSketchViewerScreen'));
    expect(shared, contains('Sola lettura'));
    expect(shared, contains('_sharedInteractionFooter'));
  });

  test('v0.65 server policy enforces creator-only edits', () {
    final sql = File(
      'supabase/migrations/025_noi_permissions_lite_v065.sql',
    ).readAsStringSync();

    expect(sql, contains('ownerOnlyEdit'));
    expect(sql, contains('shared_entry_read_only'));
    expect(sql, contains('only_creator_can_lock_shared_entry'));
    expect(sql, contains('agenda_records_update'));
    expect(sql, contains('agenda_records_delete'));
    expect(sql, contains('private.is_space_member'));
  });

  test('v0.65 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.65.0');
    expect(pubspec, contains('version: 0.65.0+75'));
  });
}
