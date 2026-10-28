import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('Daily Ritual preferences are backward compatible and bounded', () {
    const defaults = AgendaPreferences();
    expect(defaults.morningRitualEnabled, isFalse);
    expect(defaults.eveningRitualEnabled, isFalse);
    expect(defaults.ritualRemindersEnabled, isFalse);
    expect(defaults.morningRitualHour, 8);
    expect(defaults.eveningRitualHour, 20);
    expect(defaults.eveningRitualMinute, 30);

    final legacy = AgendaPreferences.fromJson(const <String, dynamic>{});
    expect(legacy.morningRitualEnabled, isFalse);
    expect(legacy.eveningRitualEnabled, isFalse);

    final bounded = defaults.copyWith(
      morningRitualHour: 99,
      morningRitualMinute: -4,
      eveningRitualHour: -1,
      eveningRitualMinute: 99,
    );
    expect(bounded.morningRitualHour, 23);
    expect(bounded.morningRitualMinute, 0);
    expect(bounded.eveningRitualHour, 0);
    expect(bounded.eveningRitualMinute, 59);
  });

  test('Daily Ritual preferences survive backup restore', () async {
    final source = AgendaStore();
    await source.savePreferences(
      const AgendaPreferences(
        morningRitualEnabled: true,
        eveningRitualEnabled: true,
        ritualRemindersEnabled: true,
        morningRitualHour: 7,
        morningRitualMinute: 45,
        eveningRitualHour: 21,
        eveningRitualMinute: 15,
      ),
    );

    final backup = await source.createBackupJson();
    final restored = AgendaStore();
    await restored.restoreBackup(backup, merge: false);

    expect(restored.preferences.morningRitualEnabled, isTrue);
    expect(restored.preferences.eveningRitualEnabled, isTrue);
    expect(restored.preferences.ritualRemindersEnabled, isTrue);
    expect(restored.preferences.morningRitualHour, 7);
    expect(restored.preferences.morningRitualMinute, 45);
    expect(restored.preferences.eveningRitualHour, 21);
    expect(restored.preferences.eveningRitualMinute, 15);

    source.dispose();
    restored.dispose();
  });

  test('starting the same ritual twice materializes one diary block', () async {
    final store = AgendaStore();
    await store.load();
    await store.savePreferences(
      const AgendaPreferences(morningRitualEnabled: true),
    );
    final day = DateTime(2026, 10, 23);

    final first = await store.startDailyRitual(day, DailyRitualKind.morning);
    final second = await store.startDailyRitual(day, DailyRitualKind.morning);

    expect(second.id, first.id);
    expect(first.tags, contains('ritual:morning'));
    expect(
      store.journal(day).blocks
          .where((block) => block.tags.contains('ritual:morning')),
      hasLength(1),
    );
    expect(store.hasStartedDailyRitual(day, DailyRitualKind.morning), isTrue);

    store.dispose();
  });

  test('v1.04 release evidence remains historical after later product lines', () {
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();
    final bible = File('docs/PRODUCT_BIBLE.md').readAsStringSync();
    final readme = File('README.md').readAsStringSync();

    expect(
      roadmap,
      contains(
        '| v1.04 | Daily Rituals & Life Flow | Completed — PR #113 merged after 4/4 exact-head gates |',
      ),
    );

    // Product Bible.current is intentionally mutable. The v1.04 regression
    // protects the completed roadmap evidence and unchanged distribution
    // identity, not a header that later approved product lines must advance.
    expect(bible, contains('Distribution identity:** 1.0.0-rc.2+111'));
    expect(readme, contains('## v1.04 — Daily Rituals & Life Flow'));
  });

  test('Daily Ritual UI reuses Today, Diary and NotificationService only', () {
    final ritual = File('lib/src/daily_rituals.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final templates =
        File('lib/src/diary/diary_templates.dart').readAsStringSync();

    expect(ritual, contains('applyDiaryTemplate'));
    expect(ritual, contains('NotificationService.instance.scheduleDaily'));
    expect(ritual, contains("dailyRitualTag(kind)"));
    expect(templates, contains('Iterable<String> extraTags'));
    expect(planner, contains('AgendaStore.sameDay(day, DateTime.now())'));
    expect(planner, contains('DailyRitualCard('));
    expect(settings, contains("'settings-morning-ritual'"));
    expect(settings, contains("'settings-evening-ritual'"));
    expect(settings, contains("'settings-ritual-reminders'"));
    expect(settings, contains('showTimePicker'));
    expect(settings, contains('reconcileDailyRitualReminders'));

    for (final forbidden in <String>[
      'DailyRitualDatabase',
      'DailyRitualRepository',
      'RitualSyncQueue',
      'RitualStore',
    ]) {
      expect(ritual, isNot(contains(forbidden)));
    }

    expect(ritual, isNot(contains("d3('ritualCompleted')")));
    expect(ritual, contains("d3('ritualAlreadyStarted')"));
  });

  test('Daily Ritual copy resolves in all five product languages', () {
    const keys = <String>[
      'ritualsTitle',
      'ritualsTodaySubtitle',
      'ritualMorningTitle',
      'ritualEveningTitle',
      'ritualSuggestedAt',
      'ritualAvailableAt',
      'ritualAlreadyStarted',
      'ritualStarted',
      'ritualStart',
      'ritualMorningReminderTitle',
      'ritualMorningReminderBody',
      'ritualEveningReminderTitle',
      'ritualEveningReminderBody',
      'ritualSettingsTitle',
      'ritualSettingsDescription',
      'ritualMorningEnabled',
      'ritualEveningEnabled',
      'ritualRemindersEnabled',
      'ritualRemindersDescription',
      'ritualMorningTime',
      'ritualEveningTime',
      'ritualNotificationsUnavailable',
    ];

    for (final language in const <AppLanguage>[
      AppLanguage.english,
      AppLanguage.italian,
      AppLanguage.spanish,
      AppLanguage.french,
      AppLanguage.portuguese,
    ]) {
      final strings = AnnaStrings.forPreference(language);
      for (final key in keys) {
        final value = strings.d3(key);
        expect(value, isNot(key), reason: '${language.name}: $key');
        expect(value.trim(), isNotEmpty, reason: '${language.name}: $key');
      }
    }
  });
}
