import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-first DS6 S3 Flutter widget QA. Synthetic guest only: a widget PASS
/// cannot certify installed-PWA sync, real devices, QR, Vault or billing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    AnnaEditorialTodayMode.enabled.value = true;
  });

  tearDown(() {
    AnnaEditorialTodayMode.enabled.value = false;
  });

  testWidgets('Inbox query clears and Classic has no invisible filter',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );
    await store.addInboxEntry('Nota sintetica riunione');
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey<String>('main-nav-more')));
    await tester.pump(const Duration(milliseconds: 550));
    final inbox = find.byKey(const ValueKey<String>('more-inbox'));
    expect(inbox, findsOneWidget);
    await tester.ensureVisible(inbox);
    await tester.tap(inbox);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(InboxScreen), findsOneWidget);

    final query = find.byKey(const ValueKey<String>('ds6-inbox-search'));
    expect(query, findsOneWidget);
    expect(find.text('Nota sintetica riunione'), findsOneWidget);

    await tester.enterText(query, 'nessuna-corrispondenza');
    await tester.pump();
    expect(find.text('Nessun risultato.'), findsOneWidget);
    final clear = find.byKey(
        const ValueKey<String>('ds6-inbox-search-clear'));
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await tester.pump();
    expect(tester.widget<TextField>(query).controller!.text, isEmpty);
    expect(find.text('Nota sintetica riunione'), findsOneWidget);

    await tester.enterText(query, 'nessuna-corrispondenza');
    await tester.pump();
    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pump();
    expect(query, findsNothing);
    expect(find.text('Nota sintetica riunione'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  testWidgets('Global Search controls remain available on narrow Web viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 740),
        textScaler: TextScaler.linear(1.3),
      ),
      child: AgendaApp(store: store, bypassIdentityForTesting: true),
    ));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey<String>('main-nav-more')));
    await tester.pump(const Duration(milliseconds: 550));
    final search = find.byKey(const ValueKey<String>('more-search'));
    await tester.ensureVisible(search);
    await tester.pump();
    await tester.tap(search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(PersonalSearchConnectionsScreen), findsOneWidget);
    expect(find.text('Ordina'), findsWidgets);

    final query = find.byKey(const ValueKey<String>('approved-search-query'));
    await tester.enterText(query, 'prova-inesistente');
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('approved-search-clear')),
        findsOneWidget);
    expect(find.text('Nessun risultato.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  test('Crea retains existing selected date picker and canonical actions', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final motion = File('lib/src/motion_v108.dart').readAsStringSync();

    expect(capture, contains("'capture-effective-date'"));
    expect(capture, contains("'capture-editorial-effective-date'"));
    expect(capture, contains('AnnaEditorialDateLabel('));
    expect(capture, contains('showDatePicker('));
    expect(capture, contains('targetDay = _normalizeUnifiedCaptureDay(changed)'));
    expect(capture, contains('showModalBottomSheet<_UnifiedCaptureAction>'));
    expect(capture, contains('captureCascade: true'));
    expect(capture, contains('AnnaMotionV108.duration(context, 416)'));
    expect(motion, contains('AnnaMotionV108.duration(context, 544)'));
    expect(motion, contains('40 + order * 100'));
    expect(capture, contains('store.addInboxEntry(value)'));
    expect(capture, contains('store.saveJournal('));
    expect(capture, isNot(contains('Supabase')));
  });
}
