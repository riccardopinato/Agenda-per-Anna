import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('Concept title, restrictions and default personal title follow locale', () {
    const titles = <String, String>{
      'it': 'Dodici settimane che contano',
      'en': 'Twelve Meaningful Weeks',
      'es': 'Doce semanas con sentido',
      'fr': 'Douze semaines essentielles',
      'pt': 'Doze semanas com significado',
    };
    const defaults = <String, String>{
      'it': 'Le mie dodici settimane',
      'en': 'My twelve weeks',
      'es': 'Mis doce semanas',
      'fr': 'Mes douze semaines',
      'pt': 'As minhas doze semanas',
    };
    for (final language in titles.keys) {
      final strings = AnnaStrings(language);
      expect(annaTwelveWeeksConceptTitle(strings), titles[language]);
      expect(annaTwelveWeeksConceptDefaultTitle(strings), defaults[language]);
      expect(annaTwelveWeeksConceptCatalogSubtitle(strings), isNotEmpty);
      if (language != 'it') {
        expect(
          annaTwelveWeeksConceptCatalogSubtitle(strings),
          isNot(contains('Anteprima privata')),
        );
      }
    }
  });

  testWidgets('English concept initial title matches the selected locale',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: TwelveWeeksConceptPreview(),
      ),
    );
    for (var index = 0; index < 2; index++) {
      await tester.tap(find.byKey(const ValueKey('anna-12w-next')));
      await tester.pumpAndSettle();
    }
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('anna-12w-title')),
    );
    expect(field.controller!.text, 'My twelve weeks');
  });

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
