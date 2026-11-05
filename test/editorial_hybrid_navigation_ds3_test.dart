import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ids = <String>[
    'main-nav-today',
    'main-nav-messages',
    'main-nav-memories',
    'main-nav-more',
  ];
  const labels = <String>['Oggi', 'Messaggi', 'Ricordi', 'Altro'];
  const icons = <IconData>[
    Icons.today_outlined,
    Icons.chat_bubble_outline,
    Icons.photo_library_outlined,
    Icons.grid_view_outlined,
  ];
  const selectedIcons = <IconData>[
    Icons.today,
    Icons.chat_bubble,
    Icons.photo_library,
    Icons.grid_view_rounded,
  ];

  Widget dockHarness({
    required int selected,
    required ValueChanged<int> onSelect,
    Color seed = Colors.deepPurple,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: AnnaEditorialDockBar(
          selectedPage: selected,
          onPageSelected: onSelect,
          labels: labels,
          icons: icons,
          selectedIcons: selectedIcons,
          semanticIds: ids,
        ),
      ),
    );
  }

  testWidgets('docked navigation reaches the two edges and the device bottom',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(dockHarness(selected: 0, onSelect: (_) {}));
    final surface =
        find.byKey(const ValueKey<String>('anna-editorial-anchored-dock'));
    final scaffold = find.byType(Scaffold).first;
    expect(surface, findsOneWidget);
    expect(tester.getTopLeft(surface).dx,
        closeTo(tester.getTopLeft(scaffold).dx, 0.1));
    expect(tester.getBottomRight(surface).dx,
        closeTo(tester.getBottomRight(scaffold).dx, 0.1));
    expect(tester.getBottomRight(surface).dy,
        closeTo(tester.getBottomRight(scaffold).dy, 0.1));
    expect(find.byKey(const ValueKey<String>('main-nav-create-space')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all four destinations are selectable with their original IDs',
      (tester) async {
    int? tapped;
    await tester.pumpWidget(
      dockHarness(selected: 0, onSelect: (page) => tapped = page),
    );
    for (var page = 0; page < ids.length; page++) {
      expect(find.byKey(ValueKey<String>(ids[page])), findsOneWidget);
      await tester.tap(find.byKey(ValueKey<String>(ids[page])));
      await tester.pump();
      expect(tapped, page);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone and large text keep visible accessible destinations',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final original = dockHarness(
      selected: 2,
      onSelect: (_) {},
      seed: Colors.green,
      brightness: Brightness.dark,
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: original,
      ),
    );
    for (final id in ids) {
      expect(find.byKey(ValueKey<String>(id)), findsOneWidget);
    }
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  test('hybrid is a navigation skin, not a second Create or data owner', () {
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final today = File('lib/src/planner_views.dart').readAsStringSync();
    final design =
        File('lib/src/editorial_hybrid_design.dart').readAsStringSync();

    expect(shell, contains('ValueListenableBuilder<bool>('));
    expect(shell, contains('valueListenable: AnnaEditorialTodayMode.enabled'));
    expect(shell, contains('AnnaEditorialDockBar('));
    expect(shell, contains('NavigationBar(')); // Classic remains available.
    expect(shell, contains("key: const ValueKey<String>('main-editorial-dock')"));
    expect(shell, contains("key: const ValueKey<String>('main-nav-create')"));
    expect(shell, contains('_openCentralCreate'));
    expect(shell, contains('showUnifiedCapture('));
    expect(shell, contains('IndexedStack(index: index, children: pages)'));
    expect(shell, contains('onPageSelected: _selectDestination'));
    expect(shell, contains('_centralCreateButton('));
    expect(design, contains('AnnaEditorialDockSurface('));
    expect(design, isNot(contains('showUnifiedCapture(')));
    expect(design, isNot(contains('setAgendaContentFilter(')));
    expect(today, contains('if (!editorial) ...planningCards'));
    expect(today, contains('if (editorial) ...planningCards'));
    expect(today, contains('AnnaEditorialTodayOverview('));
    expect(today, contains('if (!editorial) ...['));
    expect(today, contains('AgendaContentFilterBar(store: widget.store)'));
  });
}
