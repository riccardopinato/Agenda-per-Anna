import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v137 album uses genuine memory media and unchanged routes', () {
    final source =
        File('lib/src/diary/editorial_memories.dart').readAsStringSync();
    expect(source, contains('block.hasPhotoMedia'));
    expect(source, contains('DiaryBlockType.sketch'));
    expect(source, contains('_coverPreview(context, record)'));
    expect(source, contains('_openPhoto(record)'));
    expect(source, contains('_openRecord(record)'));
    expect(source, contains('memories-editorial-featured-title'));
    expect(source, contains('MediaQuery.textScalerOf(context).scale(1) > 1.3'));
    expect(source, contains('AnnaOrganicPaperSurface('));
    expect(source, contains('ClipRRect('));
    expect(source, contains("tag: 'v108-photo-\u0024{block.id}'"));
    expect(source, isNot(contains('saveJournal(')));
    expect(source, isNot(contains('MediaAssetStore')));
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('v137 notebook paper responds at 320dp 1.6x $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var selected = false;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnnaOrganicPaperSurface(
                  onTap: () => selected = true,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 120, width: double.infinity),
                      Text('Un ricordo autentico da rileggere'),
                      Text('16 novembre 2026'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Un ricordo autentico da rileggere'));
      await tester.pump();
      expect(selected, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
