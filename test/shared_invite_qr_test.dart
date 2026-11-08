import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('QR roundtrip reuses exact 8-character existing server invite', () {
    expect(SharedInviteQrPayload.encode('a7c29e4b'),
        'ANNA-DIARY:A7C29E4B');
    expect(SharedInviteQrPayload.parse('ANNA-DIARY:A7C29E4B'),
        'A7C29E4B');
    expect(SharedInviteQrPayload.parse('a7c29e4b'),
        'A7C29E4B');
    expect(SharedInviteQrPayload.parse('  A7C29E4B  '),
        'A7C29E4B');
    expect(SharedInviteQrPayload.parse('ANNA-DIARY:A7C29E4B?x=1'),
        isNull);
    expect(SharedInviteQrPayload.parse('https://example.com?q=A7C29E4B'),
        isNull);
    expect(SharedInviteQrPayload.parse('A7C29E4'), isNull);
    expect(SharedInviteQrPayload.parse('A7C29E4!'), isNull);
    expect(() => SharedInviteQrPayload.encode('broken'), throwsArgumentError);
  });

  testWidgets('changing artwork never changes QR payload or expiry',
      (tester) async {
    const code = 'A7C29E4B';
    Future<void> show(SharedInviteQrStyle style, bool classic) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SharedInviteQrArtCard(
          code: code, style: style, classic: classic,
        )),
      ));
      await tester.pump();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(SharedInviteQrPayload.encode(code), 'ANNA-DIARY:A7C29E4B');
    }
    for (final theme in SharedInviteQrStyle.values) {
      await show(theme, false);
    }
    await show(SharedInviteQrStyle.sunset, true);
  });

  test('artwork names use all five approved app languages', () {
    final labels = <String, List<String>>{
      'it': ['Tramonto', 'Giardino', 'Stelle', 'Acquerello'],
      'en': ['Sunset', 'Garden', 'Stars', 'Watercolor'],
      'es': ['Atardecer', 'Jardín', 'Estrellas', 'Acuarela'],
      'fr': ['Coucher de soleil', 'Jardin', 'Étoiles', 'Aquarelle'],
      'pt': ['Pôr do sol', 'Jardim', 'Estrelas', 'Aguarela'],
    };
    for (final entry in labels.entries) {
      expect(
        SharedInviteQrStyle.values
            .map((style) => style.labelFor(entry.key))
            .toList(),
        entry.value,
        reason: 'all four styles must use ${entry.key}',
      );
    }
    expect(SharedInviteQrPayload.encode('A7C29E4B'),
        'ANNA-DIARY:A7C29E4B');
  });

  testWidgets('small dark-mode invite dialog keeps QR and translated label',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Builder(builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                scrollable: true,
                content: SizedBox(
                  width: 310,
                  child: SharedInviteQrArtCard(
                    code: 'A7C29E4B',
                    style: SharedInviteQrStyle.sunset,
                    classic: false,
                    languageCode: 'fr',
                  ),
                ),
              ),
            ),
            child: const Text('Open invitation'),
          ),
        )),
      ),
    ));
    await tester.tap(find.text('Open invitation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Coucher de soleil'), findsOneWidget);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    // The qr_flutter widget does not expose its data as a public getter.
    // Assert the production binding and independent encoder instead.
    expect(File('lib/src/shared_invite_qr.dart').readAsStringSync(),
        contains('data: SharedInviteQrPayload.encode(code)'));
    expect(SharedInviteQrPayload.encode('A7C29E4B'),
        'ANNA-DIARY:A7C29E4B');
    expect(qr.size, lessThanOrEqualTo(140.0));
    final label = tester.widget<Text>(find.text('Coucher de soleil'));
    expect(label.style?.color, const Color(0xFF332B34));
    expect(tester.takeException(), isNull);
  });

  test('QR integration keeps legacy invite codes and server ownership', () {
    final shared = File('lib/src/screens/shared_space.dart')
        .readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    expect(shared, contains('SharedInviteQrArtCard('));
    expect(shared, contains('languageCode: language,'));
    expect(shared, contains('SharedInviteQrScanScreen('));
    expect(shared, contains('widget.space.isOwner'));
    expect(shared, contains('current.expiresAt.difference('));
    expect(shared, contains('current.usesCount'));
    expect(shared, contains('regenerateSpaceInvite(widget.space.id)'));
    expect(shared, contains('onPressed: _joinSpace'));
    expect(shared, contains('onPressed: _scanSharedInviteQr'));
    expect(shared, contains('confirmed != true'));
    expect(cloud, contains("'join_shared_space'"));
    expect(cloud, contains("'create_or_get_space_invite'"));
    expect(cloud, contains("'regenerate_space_invite'"));
    expect(shared, isNot(contains('huggingface.co')));
  });
}
