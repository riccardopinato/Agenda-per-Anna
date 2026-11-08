import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// S5 synthetic Flutter layout/semantics coverage; not physical PWA or measured
/// FPS/TTI. No personal records or backend access.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const languages = [
    AppLanguage.italian,
    AppLanguage.english,
    AppLanguage.spanish,
    AppLanguage.french,
    AppLanguage.portuguese,
  ];

  testWidgets('five locales fit responsive editorial primitives at 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final language in languages) {
      final strings = AnnaStrings.forPreference(language);
      var selected = -1;
      var pressed = 0;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(2),
            ),
            child: Builder(builder: (context) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnnaEditorialSectionHeading(
                      title: strings.d3('moreQuickAccess'),
                      action: TextButton(
                        onPressed: () => pressed++,
                        child: Text(strings.d3('ui5Create')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnnaEditorialActionPair(
                      leading: AnnaEditorialQuickAction(
                        icon: Icons.today_outlined,
                        title: strings.navToday,
                        onTap: () => pressed++,
                      ),
                      trailing: AnnaEditorialQuickAction(
                        icon: Icons.photo_outlined,
                        title: strings.navMemories,
                        onTap: () => pressed++,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: AnnaEditorialDockBar.heightFor(context) + 18,
                      child: AnnaEditorialDockBar(
                        selectedPage: 0,
                        onPageSelected: (page) => selected = page,
                        labels: [
                          strings.navToday,
                          strings.navMessages,
                          strings.navMemories,
                          strings.navMore,
                        ],
                        icons: const [
                          Icons.today_outlined, Icons.chat_bubble_outline,
                          Icons.photo_library_outlined, Icons.grid_view_outlined,
                        ],
                        selectedIcons: const [
                          Icons.today, Icons.chat_bubble,
                          Icons.photo_library, Icons.grid_view_rounded,
                        ],
                        semanticIds: const [
                          's5-today', 's5-messages',
                          's5-memories', 's5-more',
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(AnnaEditorialSectionHeading), findsOneWidget);
      expect(find.byType(AnnaEditorialActionPair), findsOneWidget);
      expect(find.byType(AnnaEditorialDockBar), findsOneWidget);
      expect(AnnaEditorialDockBar.heightFor(
          tester.element(find.byType(AnnaEditorialDockBar))),
          greaterThan(60));
      expect(tester.takeException(), isNull, reason: '${language.name} at 320dp x2');

      await tester.ensureVisible(find.byKey(const ValueKey('s5-more')));
      await tester.tap(find.byKey(const ValueKey('s5-more')));
      await tester.pump();
      expect(selected, 3, reason: 'canonical route callback ${language.name}');
      expect(pressed, 0, reason: 'navigation does not activate other actions');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('default-height dock keeps original 60dp contract',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Text(
        AnnaEditorialDockBar.heightFor(context).toStringAsFixed(0),
      )),
    ));
    expect(find.text('60'), findsOneWidget);
  });

  test('navigation owner, reduced motion and large-history perf baseline stay',
      () {
    final shell = File('lib/src/screens/home_inbox_search.dart')
        .readAsStringSync();
    final design = File('lib/src/editorial_hybrid_design.dart')
        .readAsStringSync();
    final perf = File('test/v100_golden_core_cleanup_test.dart')
        .readAsStringSync();

    expect(shell, contains('42 + AnnaEditorialDockBar.heightFor(context)'));
    expect(shell, contains("key: const ValueKey<String>('main-nav-create')"));
    expect(shell, contains('await showUnifiedCapture('));
    expect(design, contains('MediaQuery.textScalerOf(context).scale(16)'));
    expect(design, contains('height: heightFor(context)'));
    expect(design, contains('AnnaDesignTokens.animationsEnabled(context)'));
    expect(perf, contains('const total = 10000'));
    expect(perf, contains('lessThan(const Duration(seconds: 10))'));
  });
}
