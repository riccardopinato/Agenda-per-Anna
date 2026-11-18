import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary contextual help is a reusable, non-blocking guide', () {
    final help = File('lib/src/contextual_help.dart').readAsStringSync();
    final app = File('lib/main.dart').readAsStringSync();
    expect(app, contains("part 'src/contextual_help.dart';"));
    expect(help, contains('enum AnnaHelpSection { capture, shared, memories, more }'));
    expect(help, contains('Icons.info_outline_rounded'));
    expect(help, contains("'context-help-"));
    expect(help, contains('ListView('));
    expect(help, contains('SafeArea('));
    expect(help, contains('const BoxConstraints(maxWidth: 700)'));
    expect(help, contains('AnnaOrganicPaperSurface('));
    expect(help, contains('Semantics('));
    expect(help, isNot(contains('SharedPreferences')));
    expect(help, isNot(contains('await store.save')));
  });

  test('capture guide documents every canonical action and filters hidden ones', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final help = File('lib/src/contextual_help.dart').readAsStringSync();
    const actions = [
      'text','photo','task','taskFromText','checklistFromNote',
      'voice','sketch','visionBoard','inbox','event','birthday','person',
      'templates',
    ];
    for (final action in actions) {
      expect(help, contains('captureAction: _UnifiedCaptureAction.$action'));
    }
    expect(capture, contains('section: AnnaHelpSection.capture'));
    expect(capture, contains('captureActions: availableActions.map'));
    expect(help, contains('captureActions!.contains(entry.captureAction)'));
    expect(help, contains('AnnaHelpSection.capture'));
    expect(help, contains('AnnaHelpSection.more'));
    expect(help, contains('AnnaHelpSection.shared'));
    expect(help, contains('AnnaHelpSection.memories'));
  });

  test('top-right help works on all four primary surfaces', () {
    final files = {
      'lib/src/screens/more_screen.dart': 'AnnaHelpSection.more',
      'lib/src/diary/diary_memories.dart': 'AnnaHelpSection.memories',
      'lib/src/screens/shared_space.dart': 'AnnaHelpSection.shared',
    };
    for (final entry in files.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(source, contains('AnnaContextHelpButton('), reason: entry.key);
      expect(source, contains(entry.value), reason: entry.key);
    }
    final shared = File('lib/src/screens/shared_space.dart').readAsStringSync();
    expect('AnnaHelpSection.shared'.allMatches(shared).length, 2);
    final memories = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    expect(memories, contains('actions: editorial'));
    expect(memories, contains('...memoryActions'));
  });

  test('all primary guide items have matching descriptions in five languages', () {
    final source = File('lib/src/contextual_help.dart').readAsStringSync();
    for (final code in const ['it', 'en', 'es', 'fr', 'pt']) {
      expect(source, contains("'$code':"), reason: 'missing $code');
    }
    expect(source, contains('String _annaHelpIntro('));
    expect(source, contains('String _annaHelpTitle('));
    expect(source, contains('String _annaHelpLocale('));
  });
}
