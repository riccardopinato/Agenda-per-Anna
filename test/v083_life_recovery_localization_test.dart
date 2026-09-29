import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v0.83 localizes life and recovery vocabulary', () {
    expect(const AnnaStrings('en').importantPeople, 'Important people');
    expect(const AnnaStrings('es').birthdays, 'Cumpleaños');
    expect(const AnnaStrings('fr').workout, 'Entraînement');
    expect(const AnnaStrings('pt').shoppingList, 'Lista de compras');
    expect(const AnnaStrings('it').trashEmpty, 'Il Cestino è vuoto.');
  });

  test('v0.83 localizes canonical enum presentation without changing enums', () {
    expect(
      const AnnaStrings('en').workoutSportLabel(WorkoutSport.running),
      'Running',
    );
    expect(
      const AnnaStrings('es').workoutSportLabel(WorkoutSport.swimming),
      'Natación',
    );
    expect(
      const AnnaStrings('fr').shoppingCategoryLabel(ShoppingCategory.produce),
      'Fruits et légumes',
    );
    expect(
      const AnnaStrings('pt')
          .shoppingCategoryLabel(ShoppingCategory.personalCare),
      'Cuidados pessoais',
    );
  });

  test('secondary life surfaces reuse AnnaStrings and locale-aware dates', () {
    final sources = [
      File('lib/src/screens/people_screen.dart').readAsStringSync(),
      File('lib/src/screens/birthdays_screen.dart').readAsStringSync(),
      File('lib/src/screens/trash_screen.dart').readAsStringSync(),
      File('lib/src/screens/workout_screen.dart').readAsStringSync(),
      File('lib/src/screens/shopping_list_screen.dart').readAsStringSync(),
    ];

    for (final source in sources) {
      expect(source, contains('AnnaStrings.of(context)'));
      expect(source, isNot(contains("'it_IT'")));
      expect(source.toLowerCase(), isNot(contains('easy_localization')));
      expect(source.toLowerCase(), isNot(contains('translation_service')));
    }

    final people = sources[0];
    final birthdays = sources[1];
    final trash = sources[2];
    final workout = sources[3];
    final shopping = sources[4];

    expect(people, contains('strings.importantPeople'));
    expect(people, contains('AnnaStrings.intlLocale(context)'));
    expect(birthdays, contains('strings.birthdays'));
    expect(birthdays, contains('AnnaStrings.intlLocale(context)'));
    expect(trash, contains('strings.trashEntrySubtitle'));
    expect(trash, contains('AnnaStrings.intlLocale(context)'));
    expect(workout, contains('strings.workoutSportLabel'));
    expect(workout, contains('AnnaStrings.intlLocale(context)'));
    expect(shopping, contains('strings.shoppingCategoryLabel'));
  });

  test('v0.83 keeps localization as presentation rather than persistence', () {
    final workoutDomain = File('lib/src/workout_domain.dart').readAsStringSync();
    final shoppingDomain = File('lib/src/shopping_domain.dart').readAsStringSync();

    expect(workoutDomain, isNot(contains('AnnaStrings')));
    expect(shoppingDomain, isNot(contains('AnnaStrings')));
    expect(workoutDomain, contains("type: 'workout_session'"));
    expect(shoppingDomain, contains("type: 'shopping'"));
  });
}