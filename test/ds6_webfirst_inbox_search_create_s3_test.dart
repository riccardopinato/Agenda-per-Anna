import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-first DS6 S3: isolated Flutter widget + source regression.
//// Installed PWA acceptance and two-device data/sync remain NOT_VERIFIED.
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

  Widget app(Widget child) => MaterialApp(
    locale: const Locale('it'),
    supportedLocales: const [
      Locale('it'), Locale('en'), Locale('es'), Locale('fr'), Locale('pt'),
    ],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
    ),
    home: child,
  );

  testWidgets('Inbox search has clear action and truthful empty state',
      (tester) async {
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(app(InboxScreen(store: store)));
    await tester.pump();

    final query = find.byKey(const ValueKey<String>('ds6-inbox-search'));
    expect(query, findsOneWidget);
    expect(find.text('Nessun risultato.'), findsNothing);

    await tester.enterText(query, 'query-sintetica');
    await tester.pump();
    expect(find.text('Nessun risultato.'), findsOneWidget);
    final clear = find.byKey(
        const ValueKey<String>('ds6-inbox-search-clear'));
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await tester.pump();
    expect(tester.widget<TextField>(query).controller!.text, isEmpty);
    expect(clear, findsNothing);
    expect(find.text('Nessun risultato.'), findsNothing);

    await tester.enterText(query, 'query-sintetica');
    await tester.pump();
    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pump();
    expect(query, findsNothing);
    expect(find.text('Nessun risultato.'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  testWidgets('Global Search sort label stays visible at 320dp',
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
    await tester.pumpWidget(app(MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 740),
        textScaler: TextScaler.linear(1.3),
      ),
      child: PersonalSearchConnectionsScreen(store: store),
    )));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PersonalSearchConnectionsScreen), findsOneWidget);
    expect(find.text('Ordina'), findsOneWidget);

    final query = find.byKey(const ValueKey<String>('approved-search-query'));
    expect(query, findsOneWidget);
    await tester.enterText(query, 'query-sintetica');
    await tester.pump();
    expect(find.text('Nessun risultato.'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('approved-search-clear')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  test('Classic filter, Crea actions and privacy owners remain canonical', () {
    final inbox = File('lib/src/screens/home_inbox_search.dart')
        .readAsStringSync();
    final search = File('lib/src/search_connections_domain.dart')
        .readAsStringSync();
    final capture = File('lib/src/unified_capture.dart')
        .readAsStringSync();
    final motion = File('lib/src/motion_v108.dart').readAsStringSync();

    expect(inbox, contains("final needle = editorial ? _noteQuery.trim().toLowerCase() : '';"));
    expect(inbox, contains("'ds6-inbox-search-clear'"));
    expect(inbox, contains('strings.v100NoResults'));
    expect(inbox, contains('store.activeInboxEntries'));
    expect(inbox, contains('await store.renameInboxTag(previous, renamed)'));
    expect(search, contains('widget.store.approvedPersonalSearch('));
    expect(search, contains('approvedSearchMatchEvidence(hit, query)'));
    expect(search, contains('sort: sortOrder'));
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
