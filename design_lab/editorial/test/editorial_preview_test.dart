import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anna_editorial_lab/main.dart';

void main() {
  testWidgets('five symmetric slots preserve nav actions and create', (tester) async {
    await tester.pumpWidget(const EditorialPreview());
    expect(find.text('Anna’s Diary'), findsOneWidget);
    for (final id in ['0', '1', '3', '4']) {
      expect(find.byKey(ValueKey('nav-' + id)), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('nav-create')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-4')));
    await tester.pumpAndSettle();
    expect(find.text('Personalizza la prova'), findsOneWidget);
    expect(find.byKey(const ValueKey('palette-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('palette-1')));
    await tester.pumpAndSettle();
    expect(find.text('Sage'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hero-write')), findsOneWidget);
  });

  testWidgets('navigation is docked edge-to-edge, not a floating capsule', (tester) async {
    await tester.pumpWidget(const EditorialPreview());
    final bar = find.byKey(const ValueKey('nav-anchored-surface'));
    final scaffold = find.byType(Scaffold).first;
    expect(bar, findsOneWidget);

    // Bottom edge and horizontal edges must reach the screen boundary.
    final surfaceLeft = tester.getTopLeft(bar);
    final surfaceRight = tester.getBottomRight(bar);
    final screenLeft = tester.getTopLeft(scaffold);
    final screenRight = tester.getBottomRight(scaffold);
    expect(surfaceLeft.dx, closeTo(screenLeft.dx, .1));
    expect(surfaceRight.dx, closeTo(screenRight.dx, .1));
    expect(surfaceRight.dy, closeTo(screenRight.dy, .1));

    // The raised CTA and all four destinations remain tappable.
    expect(find.byKey(const ValueKey('nav-create')), findsOneWidget);
    for (final id in ['0', '1', '3', '4']) {
      expect(find.byKey(ValueKey('nav-' + id)), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    expect(find.text('Le pagine da ritrovare'), findsOneWidget);
  });

  testWidgets('create menu and local entry work without any account', (tester) async {
    await tester.pumpWidget(const EditorialPreview());
    await tester.tap(find.byKey(const ValueKey('nav-create')));
    await tester.pumpAndSettle();
    expect(find.text('Crea qualcosa'), findsOneWidget);
    await tester.tap(find.text('Pensiero').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('entry-input')), 'Pensiero di prova');
    await tester.tap(find.byKey(const ValueKey('entry-save')));
    await tester.pumpAndSettle();
    expect(find.text('Pensiero di prova'), findsOneWidget);
  });
}
