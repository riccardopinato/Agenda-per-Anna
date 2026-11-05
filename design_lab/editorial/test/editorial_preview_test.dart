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
