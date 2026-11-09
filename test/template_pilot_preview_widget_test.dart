import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  testWidgets('Diary template preview cancel keeps selection empty',
      (tester) async {
    DiaryTemplatePreset? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showDiaryTemplatePicker(context);
              },
              child: const Text('Open templates'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open templates'));
    await tester.pumpAndSettle();
    expect(find.text('Diary templates'), findsOneWidget);
    expect(find.text('Free templates'), findsOneWidget);
    await tester.tap(find.text('Morning').last);
    await tester.pumpAndSettle();
    expect(find.text('Preview of editable outline'), findsOneWidget);
    expect(find.text('Use in diary'), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(find.text('Back').last);
    await tester.pumpAndSettle();
    expect(find.text('Diary templates'), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(find.text('Morning').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use in diary'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.id, 'morning');
    expect(selected!.seedText.trim(), isNotEmpty);
    expect(find.text('Diary templates'), findsNothing);
  });
}
