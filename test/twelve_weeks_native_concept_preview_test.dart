import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Twelve-week concept is native and never selects a diary writer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DiaryTemplatePreset? selected;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(body: Builder(builder: (context) =>
        TextButton(onPressed: () async {
          selected = await showDiaryTemplatePicker(context);
        }, child: const Text('Apri modelli')))),
    ));
    await tester.tap(find.text('Apri modelli'));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('anna-12w-concept-card'));
    await tester.scrollUntilVisible(
      entry,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('anna-12w-native-preview')), findsOneWidget);
    expect(selected, isNull);
    for (var index = 0; index < 3; index++) {
      await tester.ensureVisible(find.byKey(const ValueKey('anna-12w-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anna-12w-next')));
      await tester.pumpAndSettle();
    }
    expect(tester.widget<FilledButton>(
      find.byKey(const ValueKey('anna-12w-simulate'))).onPressed, isNull);
    await tester.ensureVisible(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('anna-12w-simulate')));
    await tester.tap(find.byKey(const ValueKey('anna-12w-simulate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('anna-12w-done')), findsOneWidget);
    expect(selected, isNull);
  });
}
