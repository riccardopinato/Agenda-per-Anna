import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const actions = <AnnaContextHelpTopic>[
    AnnaContextHelpTopic(
      id: 'text', icon: Icons.edit_note_outlined, title: 'Nota di diario',
    ),
    AnnaContextHelpTopic(
      id: 'photo', icon: Icons.photo_camera_back_outlined, title: 'Fotografia',
    ),
  ];

  testWidgets('Create help opens on demand, explains date and only available actions',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('it'),
      supportedLocales: AnnaStrings.supportedLocales,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(
        child: AnnaContextHelpButton(
          section: AnnaContextHelpSection.create,
          captureActions: actions,
        ),
      )),
    ));
    await tester.tap(find.byKey(const ValueKey<String>('context-help-create')));
    await tester.pumpAndSettle();
    expect(find.byType(AnnaContextHelpScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('context-help-page-create')),
      findsOneWidget,
    );
    expect(find.text('Data del contenuto'), findsWidgets);
    // The journal guide is a lazily laid-out scrolling ListView. Exercise
    // a real scroll rather than expecting offscreen topics in the tree.
    final noteTopic =
        find.byKey(const ValueKey<String>('context-help-topic-text'));
    await tester.scrollUntilVisible(noteTopic, 220);
    await tester.pumpAndSettle();
    expect(find.text('Nota di diario'), findsOneWidget);
    await tester.tap(noteTopic);
    await tester.pumpAndSettle();
    expect(find.textContaining('Scrivi un pensiero'), findsOneWidget);
    final photoTopic =
        find.byKey(const ValueKey<String>('context-help-topic-photo'));
    await tester.scrollUntilVisible(photoTopic, 220);
    await tester.pumpAndSettle();
    expect(find.text('Fotografia'), findsOneWidget);
    expect(find.text('Vision board'), findsNothing);
    // Guides explain, but have no save button or capture-writer callback.
    expect(find.byType(TextField), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AnnaContextHelpScreen), findsNothing);
  });

  testWidgets('main section help cards are available in Italian and English',
      (tester) async {
    for (final locale in const [Locale('it'), Locale('en')]) {
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(locale.languageCode),
        locale: locale,
        supportedLocales: AnnaStrings.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AnnaContextHelpScreen(
          section: AnnaContextHelpSection.sharedSpace,
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('context-help-page-sharedSpace')),
        findsOneWidget,
      );
      final interactions = find.byKey(
        const ValueKey<String>('context-help-topic-spaceInteractions'),
      );
      await tester.scrollUntilVisible(interactions, 220);
      await tester.pumpAndSettle();
      expect(interactions, findsOneWidget);
      await tester.tap(interactions);
      await tester.pumpAndSettle();
      expect(find.textContaining(
        locale.languageCode == 'it' ? 'Mi piace, commenti' : 'Likes, comments',
      ), findsWidgets);
    }
  });

  test('all canonical Create actions and all main screens have guide coverage', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final help = File('lib/src/contextual_help.dart').readAsStringSync();
    final shell = File('lib/main.dart').readAsStringSync();
    final shared = File('lib/src/screens/shared_space.dart').readAsStringSync();
    final memories = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();

    final actions = RegExp(r'_UnifiedCaptureAction\.(\w+)')
        .allMatches(capture).map((m) => m.group(1)!).toSet();
    expect(actions.length, 13);
    for (final id in {...actions, 'date'}) {
      expect(help, contains("'$id': ["), reason: 'Missing guide for $id');
    }
    for (final code in ['it', 'en', 'es', 'fr', 'pt']) {
      expect(help, contains("'$code': {"));
    }
    expect(shell, contains("part 'src/contextual_help.dart';"));
    expect(capture, contains("'capture-help-pinned-header'"));
    expect(capture, contains('for (final entry in availableActions)'));
    expect(shared, contains('AnnaContextHelpSection.sharedHub'));
    expect(shared, contains('AnnaContextHelpSection.sharedSpace'));
    expect(memories, contains('AnnaContextHelpSection.memories'));
    expect(more, contains('AnnaContextHelpSection.more'));
    expect(help, contains('visibleTopicIds'));
  });
}
