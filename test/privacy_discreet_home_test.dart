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
