import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const strings = AnnaStrings('en');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('private diary uses the shared composer component', (tester) async {
    final store = AgendaStore();
    await tester.runAsync(store.load);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: DiaryMemoryCard(
            store: store,
            date: DateTime(2026, 9, 23),
          ),
        ),
      ),
    );

    expect(find.byType(DiaryComposerSection), findsOneWidget);
    expect(find.widgetWithText(FilledButton, strings.d3('note')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sketch'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, strings.d3('photoLabel')), findsOneWidget);

    store.dispose();
  });

  testWidgets('Noi diary uses the same composer component', (tester) async {
    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
    });
    final store = AgendaStore();
    await tester.runAsync(store.load);

    final space = SharedSpace(
      id: 'space-a',
      ownerId: 'user-a',
      name: 'Noi ♡',
      role: 'owner',
      createdAt: DateTime.utc(2026, 9, 23),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: SharedSpaceScreen(
          store: store,
          space: space,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryComposerSection), findsOneWidget);
    expect(find.widgetWithText(FilledButton, strings.d3('note')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sketch'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, strings.d3('photoLabel')), findsOneWidget);

    store.dispose();
  });

  testWidgets('shared diary content card exposes the common note actions',
      (tester) async {
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
    expect(find.text(strings.d3('edit')), findsOneWidget);
    expect(find.text(strings.delete), findsOneWidget);

    await tester.tap(find.text(strings.d3('edit')));
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.delete));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('photo card exposes caption replace and delete everywhere',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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

    expect(find.text(strings.d3('editCaption')), findsOneWidget);
    expect(find.text(strings.d3('replacePhoto')), findsOneWidget);
    expect(find.text(strings.delete), findsOneWidget);
  });

  testWidgets('sketch card uses the common edit and delete actions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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

    expect(find.text(strings.d3('edit')), findsOneWidget);
    expect(find.text(strings.delete), findsOneWidget);
  });
}
