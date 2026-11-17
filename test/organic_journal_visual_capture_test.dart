import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real Flutter UI captures for an isolated Draft PR. No production account,
/// third-party imagery, permissions or Vault content in these screenshots.
const organicJournalCapture =
    bool.fromEnvironment('ANNA_JOURNAL_CAPTURE', defaultValue: false);
const organicJournalPopulated =
    bool.fromEnvironment('ANNA_JOURNAL_POPULATED', defaultValue: false);

void main() {
  testWidgets('Organic iOS Journal More, Settings, Memories screenshot QA',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    await (FontLoader('Manrope')
          ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf')))
        .load();
    await (FontLoader('Lora')
          ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf')))
        .load();
    final icons = await tester.runAsync(() async {
      final file = File('test/fixtures/MaterialIcons-Regular.otf');
      return await file.exists() ? file.readAsBytes() : null;
    });
    if (icons != null) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(icons))))
          .load();
    }

    const channel = MethodChannel('annas_diary/external_calendar');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'status'
          ? <String, Object>{'granted': false}
          : null,
    );
    addTearDown(() =>
        messenger.setMockMethodCallHandler(channel, null));

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
      palette: AgendaPalette.sage,
    );
    if (organicJournalPopulated) {
      final now = DateTime.now();
      final memoryDate = DateTime(now.year - 1, now.month, now.day);
      store.journals[AgendaStore.dateKey(memoryDate)] = DayJournal(
        blocks: [
          DiaryBlock(
            id: 'organic-journal-synthetic-memory',
            type: DiaryBlockType.note,
            createdAt: memoryDate,
            text: 'Una passeggiata insieme nel parco',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 350));
    final navigator = Navigator.of(
      tester.element(find.byType(MainShell)),
    );

    Future<void> capture({
      required Widget screen,
      required Type screenType,
      required String fileName,
    }) async {
      navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(screenType), findsOneWidget);
      if (organicJournalPopulated && screenType == DiaryMemoriesScreen) {
        // Prevent screenshot PASS with an invisible but space-occupying hero.
        expect(
          find.byKey(const ValueKey<String>('memories-editorial-featured')),
          findsOneWidget,
        );
        expect(find.text('Una passeggiata insieme nel parco'), findsWidgets);
        // The true text-only memory must not occupy a photo-sized empty slot.
        expect(
          tester.getSize(find.byKey(
            const ValueKey<String>('memories-editorial-featured'),
          )).height,
          lessThan(250),
        );
      }
      final surface = find.descendant(
        of: find.byType(screenType),
        matching: find.byType(Scaffold),
      ).first;
      await expectLater(
        surface,
        matchesGoldenFile('goldens/$fileName'),
      );
      expect(tester.takeException(), isNull);
      navigator.pop();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 450));
    }

    await capture(
      screen: MoreScreen(store: store),
      screenType: MoreScreen,
      fileName: 'organic_journal_more_390.png',
    );
    await capture(
      screen: SettingsHubScreen(store: store),
      screenType: SettingsHubScreen,
      fileName: 'organic_journal_settings_hub_390.png',
    );
    await capture(
      screen: SettingsScreen(store: store),
      screenType: SettingsScreen,
      fileName: 'organic_journal_settings_profile_390.png',
    );
    await capture(
      screen: ExploreScreen(store: store),
      screenType: ExploreScreen,
      fileName: 'organic_journal_explore_390.png',
    );
    await capture(
      screen: PersonalizationScreen(store: store),
      screenType: PersonalizationScreen,
      fileName: 'organic_journal_personalization_390.png',
    );
    await capture(
      screen: DiaryMemoriesScreen(store: store),
      screenType: DiaryMemoriesScreen,
      fileName: organicJournalPopulated
          ? 'organic_journal_memories_populated_390.png'
          : 'organic_journal_memories_empty_390.png',
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }, skip: !organicJournalCapture,
      timeout: const Timeout(Duration(seconds: 140)));
}
