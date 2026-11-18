import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// N18-04 (approved 18 Nov): grouped Journal capture, canonical writer owner.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => initializeDateFormatting('it', null));
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AnnaEditorialTodayMode.enabled.value = false;
  });
  tearDown(() => AnnaEditorialTodayMode.enabled.value = false);

  Future<void> openCapture(
    WidgetTester tester,
    AgendaStore store, {
    required bool journal,
    required double width,
  }) async {
    AnnaEditorialTodayMode.enabled.value = journal;
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AnnaStrings.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showUnifiedCapture(
                  context,
                  store,
                  initialDate: DateTime(2026, 11, 18),
                  entryPoint: UnifiedCaptureEntryPoint.home,
                ),
                child: const Text('Apri Crea'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri Crea'));
    await tester.pumpAndSettle();
  }

  testWidgets('Journal has stable write/photo/appointment entry actions',
      (tester) async {
    final store = AgendaStore();
    addTearDown(store.dispose);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await openCapture(tester, store, journal: true, width: 390);

    expect(find.text('Inizia da qui'), findsOneWidget);
    expect(find.text('Conserva un’idea'), findsOneWidget);
    for (final action in const <String>['text', 'photo', 'event', 'inbox']) {
      expect(find.byKey(ValueKey<String>('capture-journal-action-$action')),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey<String>(
      'capture-editorial-effective-date',
    )), findsOneWidget);
    expect(find.byType(AnnaOrganicJournalRow), findsWidgets);
    expect(store.items, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Classic keeps original ranked ListTile presentation',
      (tester) async {
    final store = AgendaStore();
    addTearDown(store.dispose);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await openCapture(tester, store, journal: false, width: 320);

    expect(find.byType(AnnaOrganicJournalRow), findsNothing);
    expect(find.text('Inizia da qui'), findsNothing);
    expect(find.byType(ListTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('all thirteen capture actions, writer paths and account gate retained',
      () {
    final source = File('lib/src/unified_capture.dart').readAsStringSync();
    const names = <String>[
      'text', 'voice', 'photo', 'sketch', 'visionBoard', 'templates',
      'inbox', 'task', 'taskFromText', 'checklistFromNote', 'event',
      'birthday', 'person',
    ];
    for (final name in names) {
      expect(source, contains('_UnifiedCaptureAction.$name'),
          reason: 'must preserve canonical $name action');
    }
    expect(source, contains('final journalStartActions = ['));
    expect(source, contains('final journalKeepActions = ['));
    expect(source, contains('final journalPinnedKinds = <_UnifiedCaptureAction>{'));
    expect(source, contains('!journalPinnedKinds'));
    expect(source, contains('if (journalCapture) ...['));
    expect(source, contains('if (!journalCapture)'));
    expect(source, contains('for (var i = 0; i < 4; i++)'));
    expect(source, contains('var showAllActions = false;'));
    expect(source, contains('AnnaContextHelpButton('));
    expect(source, contains('showDatePicker('));
    expect(source, contains('store.activeAccountId != accountAtCaptureOpen'));
    expect(source, contains('_saveUnifiedCaptureText('));
    expect(source, contains('_saveUnifiedCapturePhoto('));
    expect(source, contains('_saveUnifiedCaptureVoice('));
    expect(source, contains('openUnifiedItemComposer('));
    expect(source, contains('VisionBoardFoundation.saveDraft('));
    expect(source, isNot(contains('class NewCaptureStore')));
  });
}
