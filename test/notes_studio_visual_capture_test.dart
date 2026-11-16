import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Real Flutter 390dp screenshot. All records are synthetic in-memory fixtures;
// this does not access personal accounts, private files, Vault or cloud writes.
const captureEnabled =
    bool.fromEnvironment('ANNA_NOTES_STUDIO_CAPTURE', defaultValue: false);
const populated =
    bool.fromEnvironment('ANNA_NOTES_STUDIO_POPULATED', defaultValue: false);

void main() {
  testWidgets('Notes Studio true empty and synthetic populated 390dp captures',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    await (FontLoader('Manrope')
          ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf')))
        .load();
    await (FontLoader('Lora')
          ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf')))
        .load();
    final iconBytes = await tester.runAsync(() async {
      final file = File('test/fixtures/MaterialIcons-Regular.otf');
      return await file.exists() ? file.readAsBytes() : null;
    });
    if (iconBytes != null) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes))))
          .load();
    }

    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    await AnnaEditorialTodayMode.ensureLoaded();
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      onboardingDone: true,
      displayName: 'Giulia',
      palette: AgendaPalette.rose,
    );
    if (populated) {
      final now = DateTime(2026, 11, 16, 12);
      store.inbox.addAll(<InboxEntry>[
        InboxEntry(
          id: 'notes-studio-pinned-fixture',
          text: 'Organizzare le fotografie del weekend',
          createdAt: now,
          pinned: true,
          tags: const ['Ricordi'],
        ),
        InboxEntry(
          id: 'notes-studio-ordinary-fixture',
          text: 'Una nuova idea da scrivere sul diario',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ]);
    }

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Navigator.of(tester.element(find.byType(MainShell))).push(
      MaterialPageRoute<void>(
        builder: (_) => InboxScreen(store: store),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(InboxScreen), findsOneWidget);
    if (populated) {
      expect(find.text('Organizzare le fotografie del weekend'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>(
          'notes-studio-note-notes-studio-pinned-fixture')), findsOneWidget);
    } else {
      expect(find.byKey(const ValueKey<String>('notes-studio-empty')),
          findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await expectLater(
      find.descendant(
        of: find.byType(InboxScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile(populated
          ? 'goldens/notes_studio_inbox_populated_390.png'
          : 'goldens/notes_studio_inbox_empty_390.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }, skip: !captureEnabled, timeout: const Timeout(Duration(seconds: 130)));
}
