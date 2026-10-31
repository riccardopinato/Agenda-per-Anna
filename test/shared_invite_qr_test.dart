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
      final image = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(image.data, SharedInviteQrPayload.encode(code));
    }
    for (final theme in SharedInviteQrStyle.values) {
      await show(theme, false);
    }
    await show(SharedInviteQrStyle.sunset, true);
  });

  test('QR integration keeps legacy invite codes and server ownership', () {
    final shared = File('lib/src/screens/shared_space.dart')
        .readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    expect(shared, contains('SharedInviteQrArtCard('));
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
