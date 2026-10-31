import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('approved +Crea cascade changes presentation, not capture actions', () {
    final capture = read('lib/src/unified_capture.dart');
    final motion = read('lib/src/motion_v108.dart');
    expect(capture, contains('showModalBottomSheet<_UnifiedCaptureAction>'));
    expect(capture, contains('sheetAnimationStyle: AnimationStyle('));
    expect(capture, contains('AnnaMotionV108.duration(context, 416)'));
    expect(capture, contains('captureCascade: true'));
    for (final action in [
      'text', 'photo', 'task', 'voice', 'sketch', 'inbox', 'event',
      'birthday', 'person', 'templates',
    ]) {
      expect(capture, contains('_UnifiedCaptureAction.$action'));
    }
    expect(motion, contains('176 + order * 100'));
    expect(motion, contains('capture ? 544 : 280'));
    expect(motion, contains('Curves.easeOutBack'));
    expect(motion, contains('const Offset(0, -0.32)'));
    expect(motion, contains('this.captureCascade = false'));
    expect(motion, contains('!AnnaMotionV108.enabled(context)'));
  });

  testWidgets('capture cascade respects Reduce Motion without hiding actions',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(body: Column(children: [
          AnnaMotionStagger(
            order: 0,
            captureCascade: true,
            child: Text('Scrivi'),
          ),
          AnnaMotionStagger(
            order: 4,
            captureCascade: true,
            child: Text('Sketch'),
          ),
        ])),
      ),
    ));
    await tester.pump();
    expect(find.text('Scrivi'), findsOneWidget);
    expect(find.text('Sketch'), findsOneWidget);
    for (final element in tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity))) {
      expect(element.opacity, 1.0);
      expect(element.duration, Duration.zero);
    }
  });
}
