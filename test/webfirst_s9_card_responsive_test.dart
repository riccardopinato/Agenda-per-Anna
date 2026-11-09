import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S9: preview using synthetic in-memory records. Does not certify real
/// PWA keyboards, account changes, screen readers or external providers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<AgendaStore> syntheticStore() async {
    final store = AgendaStore();
    final day = DateTime.now();
    store.items.add(AgendaItem(
      id: 's9-local-fixture',
      title: 'Synthetic task',
      note: '',
      date: DateTime(day.year, day.month, day.day),
      type: ItemType.task,
      start: const TimeOfDay(hour: 12, minute: 0),
      end: const TimeOfDay(hour: 13, minute: 0),
    ));
    return store;
  }

  for (final locale in const ['it', 'en', 'es', 'fr', 'pt']) {
    testWidgets('S9 card supports $locale at 320dp and 2x text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = await syntheticStore();
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RealisticDayCard(
              store: store,
              snapshot: store.dayHubSnapshot(DateTime.now()),
              hideDetails: false,
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('realistic-day-advice')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('day-buffer-30')), findsOneWidget);
      expect(find.byKey(const ValueKey('realistic-day-nudge-optin')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }

  testWidgets('S9 buffer opt-in is local and leaves canonical task untouched',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = await syntheticStore();
    final original = store.items.single;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(body: SingleChildScrollView(
        child: RealisticDayCard(
          store: store,
          snapshot: store.dayHubSnapshot(DateTime.now()),
          hideDetails: false,
        ),
      )),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final buffer = find.byKey(const ValueKey('day-buffer-30'));
    await tester.ensureVisible(buffer);
    await tester.tap(buffer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((key) => key.startsWith('anna_realistic_buffer_v1_'))
        .toList();
    expect(keys, hasLength(1));
    expect(prefs.getInt(keys.single), 30);
    expect(store.items.single, same(original));
    expect(store.items.single.start, const TimeOfDay(hour: 12, minute: 0));
    expect(store.items.single.end, const TimeOfDay(hour: 13, minute: 0));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
