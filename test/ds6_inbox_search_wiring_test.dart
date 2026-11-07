import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String file) => File(file).readAsStringSync();

  test('DS6 Inbox premium preserves the canonical record and tag owners', () {
    final inbox = source('lib/src/screens/home_inbox_search.dart');
    expect(inbox, contains("key: const ValueKey<String>('ds6-inbox-search')"));
    expect(inbox, contains('_noteCard('));
    expect(inbox, contains('await store.renameInboxTag(previous, renamed)'));
    expect(inbox, contains('await store.setInboxTags(entry.id, tags'));
    expect(inbox, contains('await store.toggleInboxArchived(entry.id)'));
    expect(inbox, contains('await store.toggleInboxPinned(entry.id)'));
    expect(inbox, contains('Cap0160TagSuggester.forInbox('));
  });

  test('DS6 global search is presentation-only and retains source scope', () {
    final search = source('lib/src/search_connections_domain.dart');
    final policy = source('lib/src/approved_search_policy.dart');
    expect(search, contains('_resultCard('));
    expect(search, contains('widget.store.approvedPersonalSearch('));
    expect(search, contains('approvedSearchMatchEvidence(hit, query)'));
    expect(search, contains('includeArchived: includeArchived'));
    expect(search, contains('sort: sortOrder'));
    expect(policy, contains('hits.removeWhere((hit) => !hit.title.toLowerCase()'));
    expect(policy, contains('ApprovedSearchSort.alphabetical'));
  });

  test('DS6 uses the previously approved create motion, not a duplicate', () {
    final capture = source('lib/src/unified_capture.dart');
    final motion = source('lib/src/motion_v108.dart');
    expect(capture, contains('AnnaMotionV108.duration(context, 416)'));
    expect(motion, contains('AnnaMotionV108.duration(context, 544)'));
    expect(motion, contains('40 + order * 100'));
  });
}
