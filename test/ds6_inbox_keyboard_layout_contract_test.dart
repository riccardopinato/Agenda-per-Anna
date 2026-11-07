import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DS6 Inbox keeps a keyboard-safe compact layout without losing query', () {
    final source = File('lib/src/screens/home_inbox_search.dart')
        .readAsStringSync();
    final start = source.indexOf('class _InboxScreenState');
    final end = source.indexOf('class ArchiveScreen ', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final inbox = source.substring(start, end);

    // This is a source-structure regression guard; visual/device QA remains
    // required for 320dp landscape, large text and the real Android IME.
    expect(inbox, contains('body: LayoutBuilder('));
    expect(inbox, contains('constraints.maxHeight < 360'));
    expect(inbox, contains('if (editorial && !compact)'));
    expect(inbox, contains('if (!compact)'));
    expect(inbox, contains("key: const ValueKey<String>('ds6-inbox-search')"));
    expect(inbox, contains('controller: _noteSearchController'));
    expect(inbox, contains('_noteSearchController.dispose()'));
    expect(inbox, contains('Expanded('));
    expect(inbox, contains('entries.isEmpty'));
  });
}
