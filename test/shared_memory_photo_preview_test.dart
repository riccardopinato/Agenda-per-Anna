import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

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

  testWidgets(
      'shared memories use cached remote photo when legacy entry has no thumbnail',
      (tester) async {
    const path = 'shared/space-1/legacy-photo.gif';
    final fullCacheId =
        MediaAssetStore.instance.namedAssetId('remote', path);
    final thumbnailCacheId =
        MediaAssetStore.instance.namedAssetId('remote_thumb', path);

    final imageBytes = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==',
    );
    await MediaAssetStore.instance.putNamed(fullCacheId, imageBytes);

    final entry = SharedEntry(
      id: 'legacy-photo',
      type: SharedEntryType.photo,
      title: 'Foto',
      note: '',
      date: DateTime(2026, 9, 27),
      mediaPath: path,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 240,
          height: 180,
          child: SharedMemoryCover(entry: entry),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(
      await MediaAssetStore.instance.read(thumbnailCacheId),
      isNotNull,
      reason:
          'The remote full image should be converted into a reusable cover cache.',
    );
  });
}
