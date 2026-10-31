import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it');
  });

  test('one-letter search must match visible title, not hidden note', () {
    final store = AgendaStore();
    store.items.addAll([
      AgendaItem(
        id: 'hidden',
        title: 'Giulia',
        note: 'Caffè sul lago',
        date: DateTime(2026, 10, 30),
        type: ItemType.task,
      ),
      AgendaItem(
        id: 'visible',
        title: 'Cena',
        note: 'Domani',
        date: DateTime(2026, 10, 31),
        type: ItemType.task,
      ),
    ]);

    final oneCharacter = store.approvedPersonalSearch(
      'c',
      kinds: {PersonalSearchKind.agenda},
    );
    expect(oneCharacter.map((hit) => hit.id), ['visible']);
    final longQuery = store.approvedPersonalSearch(
      'caffè',
      kinds: {PersonalSearchKind.agenda},
    );
    expect(longQuery.map((hit) => hit.id), ['hidden']);
    expect(store.approvedSearchMatchEvidence(longQuery.single, 'caffè'),
        'Caffè sul lago');
    store.dispose();
  });

  test('A-Z, newest and oldest order the same canonical hits', () {
    final store = AgendaStore();
    store.items.addAll([
      AgendaItem(
        id: 'casa',
        title: 'Casa',
        note: '',
        date: DateTime(2026, 10, 29),
        type: ItemType.task,
      ),
      AgendaItem(
        id: 'cena',
        title: 'Cena',
        note: '',
        date: DateTime(2026, 10, 28),
        type: ItemType.task,
      ),
      AgendaItem(
        id: 'cinema',
        title: 'Cinema',
        note: '',
        date: DateTime(2026, 10, 30),
        type: ItemType.task,
      ),
    ]);
    List<String> ids(ApprovedSearchSort order) => store
        .approvedPersonalSearch(
          'c',
          kinds: {PersonalSearchKind.agenda},
          sort: order,
        )
        .map((hit) => hit.id)
        .toList();

    expect(ids(ApprovedSearchSort.newest), ['cinema', 'casa', 'cena']);
    expect(ids(ApprovedSearchSort.oldest), ['cena', 'casa', 'cinema']);
    expect(ids(ApprovedSearchSort.alphabetical), ['casa', 'cena', 'cinema']);
    store.dispose();
  });

  test('search order is localized for all supported languages', () {
    for (final lang in ['it', 'en', 'es', 'fr', 'pt']) {
      expect(approvedSearchOrderTitle(lang), isNotEmpty);
      expect(approvedSearchReasonTitle(lang), isNotEmpty);
      for (final choice in ApprovedSearchSort.values) {
        expect(choice.approvedLabel(lang), isNotEmpty);
      }
    }
  });
}
