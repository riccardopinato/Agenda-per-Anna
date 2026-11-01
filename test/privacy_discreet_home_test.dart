import 'dart:convert';
import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaItem privateEvent({bool isSensitive = false}) => AgendaItem(
    id: 'private-1',
    title: 'Private conversation',
    note: 'must not be shown on a masked home',
    date: DateTime(2026, 11, 9),
    type: ItemType.appointment,
    start: const TimeOfDay(hour: 19, minute: 0),
    end: const TimeOfDay(hour: 20, minute: 0),
    isSensitive: isSensitive,
  );

  SharedEntry sharedEvent({bool isSensitive = false}) => SharedEntry(
    id: 'shared-1',
    type: SharedEntryType.appointment,
    title: 'Shared conversation',
    note: 'shared but discreet',
    date: DateTime(2026, 11, 9),
    start: const TimeOfDay(hour: 20, minute: 30),
    isSensitive: isSensitive,
  );

  test('personal content and sensitivity are independent dimensions', () {
    final personal = privateEvent(isSensitive: true);
    final ordinary = privateEvent();
    final shared = sharedEvent(isSensitive: true);
    expect(personal.isSensitive, true);
    expect(ordinary.isSensitive, false);
    expect(shared.isSensitive, true);
    expect(UnifiedAgendaEntry.private(personal).isPrivate, true);
    expect(UnifiedAgendaEntry.shared(shared, null).isShared, true);
    expect(isMaskedAgendaEntry(UnifiedAgendaEntry.private(personal)), true);
    expect(isMaskedAgendaEntry(UnifiedAgendaEntry.private(ordinary)), false);
    expect(isMaskedAgendaEntry(UnifiedAgendaEntry.shared(shared, null)), true);
    expect(isMaskedAgendaEntry(UnifiedAgendaEntry.private(ordinary),
      hideAll: true), true);
  });

  test('private appointment flag survives roundtrip, copy and legacy data', () {
    final flagged = privateEvent(isSensitive: true);
    expect(AgendaItem.fromJson(jsonDecode(jsonEncode(flagged.toJson()))
        as Map<String, dynamic>).isSensitive, true);
    expect(flagged.copyWith(title: 'Updated').isSensitive, true);
    final legacy = Map<String, dynamic>.from(flagged.toJson())
      ..remove('isSensitive');
    expect(AgendaItem.fromJson(legacy).isSensitive, false);
  });

  test('shared flag is serializable including cache and preserves legacy', () {
    final flagged = sharedEvent(isSensitive: true);
    expect(SharedEntry.fromJson(flagged.toJson()).isSensitive, true);
    expect(SharedEntry.fromCacheJson(flagged.toCacheJson()).isSensitive, true);
    expect(flagged.copyWith(note: 'changed').isSensitive, true);
    final old = Map<String, dynamic>.from(flagged.toJson())
      ..remove('isSensitive');
    expect(SharedEntry.fromJson(old).isSensitive, false);
  });

  test('new local-only Home discreet flag defaults to masked', () {
    final defaults = const AgendaPreferences();
    expect(defaults.homeDiscreetMode, true);
    expect(defaults.toJson()['homeDiscreetMode'], true);
    expect(AgendaPreferences.fromJson(<String, dynamic>{}).homeDiscreetMode,
        true);
    final ordinary = defaults.copyWith(homeDiscreetMode: false);
    expect(ordinary.homeDiscreetMode, false);
    expect(AgendaPreferences.fromJson(ordinary.toJson()).homeDiscreetMode,
        false);
  });

  test('source contract masks flagged entries and keeps local privacy local', () {
    final unified = File('lib/src/unified_agenda.dart').readAsStringSync();
    final editor = File('lib/src/widgets_editors.dart').readAsStringSync();
    final screen = File('lib/src/planner_views.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final android = File('lib/src/android_calendar_sync.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(unified, contains('requestSensitiveItemAccess(context, store)'));
    expect(unified, contains('final concealed = hideDetails || shared.isSensitive;'));
    expect(editor, contains('final concealed = hideDetails || item.isSensitive;'));
    expect(screen, contains("ValueKey('privacy-home-discreet')"));
    expect(store, contains("'homeDiscreetMode': preferences.homeDiscreetMode"));
    expect(store, contains("..remove('homeDiscreetMode')"));
    expect(android, contains('!item.isSensitive &&'));
    expect(main, contains("part 'src/discreet_privacy.dart';"));
    expect(File('lib/src/discreet_privacy.dart').readAsStringSync(),
        contains('if (!prefs.privacyLockEnabled ||'));
  });

  test('shared feed and memories conceal sensitive records at the source', () {
    final shared = File('lib/src/screens/shared_space.dart').readAsStringSync();
    final memories = File('lib/src/shared_memories.dart').readAsStringSync();
    expect(shared, contains("ValueKey('shared-sensitive-"));
    expect(shared, contains('if (entry.isSensitive) {'));
    expect(shared, contains('await requestSensitiveItemAccess(context, widget.store)'));
    expect(shared, contains('sensitiveAccessGranted: sensitiveAccessGranted'));
    expect(shared, contains('entries.where((entry) => !entry.isSensitive)'));
    expect(memories, contains('.where((entry) => !entry.isSensitive)'));
    expect(shared, contains('isSensitive: existing?.isSensitive ?? false,'));
    expect(shared, contains('if (existing?.isSensitive == true) {'));
  });

  test('external preview contracts redact sensitive records', () {
    final widget = File('lib/src/home_widget_bridge.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    expect(widget, contains('isMaskedAgendaEntry('));
    expect(widget, contains('store.preferences.homeDiscreetMode'));
    expect(widget, contains("nextText = strings.d3('privacy_sensitive')"));
    expect(widget, contains("birthdayText = strings.d3('privacy_sensitive')"));
    expect(store, contains('final safeReminderTitle = item.isSensitive'));
    expect(store, contains('title: safeReminderTitle,'));
    expect(store, contains('_reminderBody(minutes, safeReminderTitle)'));
  });

  test('alternative time views and archive cannot expose sensitive titles', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final archive = File('lib/src/life_archive_domain.dart').readAsStringSync();
    expect(planner, contains('!isMaskedAgendaEntry(entry)'));
    expect(planner, contains('if (isMaskedAgendaEntry(value)) {'));
    expect(planner, contains('events.where((item) => !item.isSensitive).toList()'));
    expect(archive, contains('if (item.isSensitive || item.date.isAfter(end)) continue;'));
  });

  test('archive excludes the contents of a sensitive personal appointment', () {
    final store = AgendaStore();
    store.items.add(privateEvent(isSensitive: true));
    final matches = store.lifeArchiveEntries(
      through: DateTime(2027),
      query: 'Private conversation',
    );
    expect(matches.where((entry) => entry.kind == LifeArchiveKind.agenda),
        isEmpty);
    store.dispose();
  });

  test('sensitive exports demand PIN and explicit unencrypted-file consent', () {
    final backup = File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final translations = File('lib/src/localization_d3.dart').readAsStringSync();
    expect(backup, contains('widget.store.items.any((item) => item.isSensitive)'));
    expect(backup, contains('requestSensitiveItemAccess(context, widget.store)'));
    expect(backup.split('if (!await _confirmSensitiveExport() || !mounted) return;').length - 1,
        3);
    expect(translations, contains('privacy_exportWarningTitle'));
    expect(translations, contains('privacy_exportWarningBody'));
    expect(translations, contains('privacy_exportContinue'));
  });

  test('filter label is Personale, not a security claim', () {
    final code = File('lib/src/localization_d3.dart').readAsStringSync();
    expect(code, contains('"it": "Personale"'));
    expect(code, contains("AgendaContentFilter.privateOnly => d3('privacy_personalFilter')"));
  });

  testWidgets('sensitive private and shared titles are masked in agenda tiles',
      (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: ListView(children: [
          EventTile(store: store, item: privateEvent(isSensitive: true)),
          UnifiedAgendaTile(
            store: store,
            entry: UnifiedAgendaEntry.shared(
                sharedEvent(isSensitive: true), null),
          ),
        ]),
      ),
    ));
    expect(find.text('Private conversation'), findsNothing);
    expect(find.text('Shared conversation'), findsNothing);
    expect(find.text('Sensitive content'), findsNWidgets(2));
    expect(find.text('19:00'), findsNothing);
    expect(find.text('20:30'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('ordinary personal item remains readable outside discreet mode',
      (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: EventTile(store: store, item: privateEvent()),
      ),
    ));
    expect(find.text('Private conversation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('discreet mode hides ordinary personal item previews',
      (tester) async {
    final store = AgendaStore();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: EventTile(store: store, item: privateEvent(),
          hideDetails: true),
      ),
    ));
    expect(find.text('Private conversation'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
