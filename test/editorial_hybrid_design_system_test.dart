import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  Widget withTheme({
    required Color seed,
    required Brightness brightness,
    required Widget child,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        fontFamily: AnnaJournalTypography.uiFamily,
      ),
      home: Scaffold(body: child),
    );
  }

  test('editorial tokens derive from supplied schemes, not hardcoded rose', () {
    final blue = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );
    final sage = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );
    final first = AnnaEditorialColors.fromScheme(blue);
    final second = AnnaEditorialColors.fromScheme(sage);
    expect(first.accent, blue.primary);
    expect(first.ink, blue.onSurface);
    expect(first.canvas, blue.surface);
    expect(second.accent, sage.primary);
    expect(second.ink, sage.onSurface);
    expect(second.canvas, sage.surface);
    expect(second.accent, isNot(first.accent));
    expect(second.canvas, isNot(first.canvas));
  });

  testWidgets('featured card and pill CTA are accessible and tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(withTheme(
      seed: Colors.teal,
      brightness: Brightness.light,
      child: Center(
        child: AnnaEditorialPageLayout(
          child: AnnaEditorialSurface(
            key: const ValueKey<String>('editorial-featured'),
            tone: AnnaEditorialSurfaceTone.featured,
            onTap: () => taps++,
            semanticLabel: 'Apri la giornata',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnnaEditorialHeader(title: 'Il tuo spazio', subtitle: 'Oggi'),
                AnnaEditorialPrimaryAction(
                  label: 'Apri',
                  icon: Icons.arrow_forward,
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Il tuo spazio'), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(48));
    await tester.tap(find.text('Apri'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paired action cards stack at narrow width and remain readable', (tester) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(withTheme(
      seed: Colors.deepPurple,
      brightness: Brightness.dark,
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: SingleChildScrollView(
          child: AnnaEditorialPageLayout(
            child: AnnaEditorialActionPair(
              leading: AnnaEditorialQuickAction(
                icon: Icons.spa_outlined,
                title: 'Benessere personale',
                subtitle: 'Testo lungo e leggibile senza truncation',
                onTap: () {},
              ),
              trailing: AnnaEditorialQuickAction(
                icon: Icons.event_outlined,
                title: 'Appuntamenti importanti',
                subtitle: 'Dettagli della giornata',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Benessere personale'), findsOneWidget);
    expect(find.text('Appuntamenti importanti'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Benessere personale'));
    final second = tester.getTopLeft(find.text('Appuntamenti importanti'));
    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('docked presentation reaches edges and bottom without floating margins', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(),
        bottomNavigationBar: AnnaEditorialDockSurface(
          child: SizedBox(
            height: 56,
            child: Center(child: Text('Navigazione di prova')),
          ),
        ),
      ),
    ));
    final dock = find.byKey(const ValueKey<String>('anna-editorial-anchored-dock'));
    final scaffold = find.byType(Scaffold);
    expect(dock, findsOneWidget);
    expect(tester.getTopLeft(dock).dx, closeTo(tester.getTopLeft(scaffold).dx, 0.1));
    expect(tester.getBottomRight(dock).dx, closeTo(tester.getBottomRight(scaffold).dx, 0.1));
    expect(tester.getBottomRight(dock).dy, closeTo(tester.getBottomRight(scaffold).dy, 0.1));
    expect(tester.takeException(), isNull);
  });
}
