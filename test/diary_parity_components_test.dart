import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('private diary uses the shared composer component', (tester) async {
    final store = AgendaStore();
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiaryMemoryCard(
            store: store,
            date: DateTime(2026, 9, 23),
          ),
        ),
      ),
    );

    expect(find.byType(DiaryComposerSection), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Nota'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sketch'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Foto'), findsOneWidget);

    store.dispose();
  });

  testWidgets('Noi diary uses the same composer component', (tester) async {
    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
    });
    final store = AgendaStore();
    await store.load();

    final space = SharedSpace(
      id: 'space-a',
      ownerId: 'user-a',
      name: 'Noi ♡',
      role: 'owner',
      createdAt: DateTime.utc(2026, 9, 23),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SharedSpaceScreen(
          store: store,
          space: space,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryComposerSection), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Nota'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sketch'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Foto'), findsOneWidget);

    store.dispose();
  });

  testWidgets('shared diary content card exposes the common note actions',
      (tester) async {
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiaryContentCard(
            kind: DiaryContentKind.note,
            title: 'Nota',
            subtitle: 'Nota · 12:00',
            onOpen: () {},
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Modifica'), findsOneWidget);
    expect(find.text('Elimina'), findsOneWidget);

    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('photo card exposes caption replace and delete everywhere',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiaryContentCard(
            kind: DiaryContentKind.photo,
            title: 'Foto',
            subtitle: 'Foto · 12:00',
            onOpen: () {},
            onEditCaption: () {},
            onReplacePhoto: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Modifica didascalia'), findsOneWidget);
    expect(find.text('Sostituisci foto'), findsOneWidget);
    expect(find.text('Elimina'), findsOneWidget);
  });

  testWidgets('sketch card uses the common edit and delete actions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiaryContentCard(
            kind: DiaryContentKind.sketch,
            title: 'Sketch',
            subtitle: 'Sketch · 12:00',
            onOpen: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Modifica'), findsOneWidget);
    expect(find.text('Elimina'), findsOneWidget);
  });
}
