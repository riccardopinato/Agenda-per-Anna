import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const externalCalendarChannel = MethodChannel('annas_diary/external_calendar');

  Future<AgendaStore> pumpCoreShell(
    WidgetTester tester, {
    double textScaleFactor = 1.0,
  }) async {
    await initializeDateFormatting('it_IT', null);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(externalCalendarChannel, (call) async {
      if (call.method == 'status') {
        return <String, Object?>{'granted': false};
      }
      return null;
    });

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    tester.binding.platformDispatcher.textScaleFactorTestValue =
        textScaleFactor;

    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();
    return store;
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(externalCalendarChannel, null);
  });

  testWidgets('core shell meets Flutter accessibility guidelines', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await pumpCoreShell(tester);
    addTearDown(store.dispose);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('core shell remains usable with 200 percent text scaling', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await pumpCoreShell(tester, textScaleFactor: 2.0);
    addTearDown(store.dispose);

    expect(tester.takeException(), isNull);
    expect(find.text('La mia giornata'), findsWidgets);
    expect(find.text('Cattura'), findsOneWidget);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
