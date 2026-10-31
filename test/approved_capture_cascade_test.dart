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
    expect(capture, contains('AnnaMotionV108.duration(context, 360)'));
    expect(capture, contains('captureCascade: true'));
    for (final action in [
      'text', 'photo', 'task', 'voice', 'sketch', 'inbox', 'event',
      'birthday', 'person', 'templates',
    ]) {
      expect(capture, contains('_UnifiedCaptureAction.$action'));
    }
    expect(motion, contains('40 + order * 72'));
    expect(motion, contains('AnnaMotionV108.duration(context, 420)'));
    expect(motion, contains('Curves.easeOutBack'));
    expect(motion, contains('AnimatedScale('));
    expect(motion, contains('scale: shown ? 1 : 0.976'));
    expect(capture, contains('curve: Curves.easeInOutCubic'));
    expect(motion, contains('const Offset(0, -0.12)'));
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
