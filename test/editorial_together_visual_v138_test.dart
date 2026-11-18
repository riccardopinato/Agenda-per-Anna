import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Editorial Together keeps canonical permissions, invites and routes', () {
    final source = File('lib/src/screens/shared_space.dart').readAsStringSync();
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(shell, contains('SharedSpaceHubScreen(store: widget.store)'));
    for (final visual in <String>[
      'together-editorial-hub-hero',
      'together-editorial-empty',
      '_togetherDetailLink(',
      'AnnaOrganicPaperSurface(',
      'AnnaEditorialSurfaceTone.featured',
      'AnnaOrganicPastelGroupRow(',
    ]) {
      expect(source, contains(visual));
    }
    // The compact app bar moves these actions into its existing menu.
    // Assert the exact original callbacks remain reachable, not their layout.
    expect(source, contains("if (value == 'invite') _invite();"));
    expect(source, contains("if (value == 'passwords') _openSharedPasswords();"));
    expect(source, contains("if (widget.space.isOwner)"));
    for (final original in <String>[
      'onPressed: _createSpace',
      'onPressed: _joinSpace',
      'onPressed: _scanSharedInviteQr',
      '_renameSpace(space)',
      'markSharedSpaceRead(',
      'onTap: _openSharedShopping',
      'onTap: _openSharedMemories',
      'onPressed: _openMembers',
      'onRefresh: _refresh',
      'TableCalendar<SharedEntry>',
      'selectedDayPredicate:',
      'eventLoader:',
      '_sharedEntryCard(',
    ]) {
      expect(source, contains(original));
    }
    expect(source, isNot(contains('deleteMasterKey(')));
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('Editorial Together uses tappable paper at 320dp: $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AnnaOrganicPaperSurface(
              tone: AnnaEditorialSurfaceTone.featured,
              onTap: () => opened++,
              child: const Text('Spazio condiviso'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Spazio condiviso'));
      await tester.pump();
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
