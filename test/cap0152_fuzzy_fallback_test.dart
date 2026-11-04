import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('it'));

  test('fuzzy string engine bounds edits, one-char and long input', () {
    expect(annaFuzzyEditDistance('cena', 'cena'), 0);
    expect(annaFuzzyEditDistance('cema', 'cena'), 1);
    expect(annaFuzzyTitleDistance('cenna', 'Cena con Anna'), 1);
    expect(annaFuzzyTitleDistance('ca', 'Cena con Anna'), isNull);
    expect(annaFuzzyTitleDistance('casa', 'Cena con Anna'), isNull);
    expect(annaFuzzyTitleDistance(List.filled(90, 'x').join(), List.filled(90, 'x').join()), isNull);
  });

  test('fuzzy typo is proposed only after exact search, and source is bounded', () {
    final store = AgendaStore();
    store.items.addAll([
      AgendaItem(
        id: 'one', title: 'Cena con Anna', note: '',
        date: DateTime(2026, 11, 4), type: ItemType.task,
      ),
      AgendaItem(
        id: 'two', title: 'Passeggiata al lago', note: '',
        date: DateTime(2026, 11, 3), type: ItemType.task,
      ),
    ]);
    expect(store.approvedPersonalSearch('cenna',
      kinds: {PersonalSearchKind.agenda}).map((x) => x.id), ['one']);
    expect(store.approvedPersonalSearch('Cena',
      kinds: {PersonalSearchKind.agenda}).map((x) => x.id), ['one']);
    expect(store.approvedPersonalSearch('c',
      kinds: {PersonalSearchKind.agenda}).map((x) => x.id), ['one']);
    expect(store.approvedPersonalSearch('xxxxxxxx',
      kinds: {PersonalSearchKind.agenda}), isEmpty);
    store.dispose();
  });

  test('different personal search kind never leaks to fuzzy agenda', () {
    final store = AgendaStore();
    store.items.add(AgendaItem(
      id: 'one', title: 'Cena con Anna', note: '',
      date: DateTime(2026, 11, 4), type: ItemType.task,
    ));
    expect(store.approvedPersonalSearch('cenna',
      kinds: {PersonalSearchKind.diary}), isEmpty);
    store.dispose();
  });
}
