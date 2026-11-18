import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('N18-05 approved Journal memories have no second media or archive owner', () {
    final src = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final first = src.indexOf('  Widget _recallMemoryRow(');
    final last = src.indexOf('  Widget _forYouHero(', first);
    expect(first, greaterThanOrEqualTo(0));
    expect(last, greaterThan(first));
    final discovery = src.substring(first, last);
    expect(discovery, contains('AnnaOrganicPastel.enabled(context)'));
    expect(discovery, contains('AnnaOrganicPaperSurface('));
    expect(discovery, contains("'memories-journal-recall-"));
    expect(discovery, contains('AnnaOrganicJournalFilterPill('));
    expect(discovery, contains('ActionChip('));
    expect(discovery, contains('return Card('));
    expect(discovery, contains('DiaryBlockType.photo'));
    expect(discovery, contains('block.hasPhotoMedia'));
    expect(discovery, contains('_openPhoto(record)'));
    expect(discovery, contains('_openRecord(record)'));
    expect(discovery, contains('view = _DiaryMemoriesView.timeline'));
    expect(discovery, contains('personId: facet.id'));
    expect(discovery, isNot(contains('store.saveJournal(')));
    expect(discovery, isNot(contains('MediaAssetStore.instance.put(')));

    final viewer = File('lib/src/diary/diary_sketchbook.dart').readAsStringSync();
    expect(viewer, contains('class DiaryPhotoViewerScreen'));
    expect(viewer, contains('DiaryZoomableImage('));
    expect(viewer, contains('assetId: block.mediaAssetId'));
  });

  testWidgets('Journal filter pill handles long derived facets at 320dp, 200% text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: AnnaOrganicJournalFilterPill(
              label: 'Una persona con un nome molto molto lungo',
              icon: Icons.person_outline,
              selected: false,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    ));
    expect(find.byType(AnnaOrganicJournalFilterPill), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(AnnaOrganicJournalFilterPill));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
