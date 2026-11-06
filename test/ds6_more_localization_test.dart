import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('DS6 More premium editorial copy exists in every supported language', () {
    const locales = ['it', 'en', 'es', 'fr', 'pt'];
    for (final code in locales) {
      expect(ds6MoreHeading(code).trim(), isNotEmpty);
      expect(ds6MoreKicker(code).trim(), isNotEmpty);
      expect(ds6MoreIntro(code).trim(), isNotEmpty);
    }
    expect(ds6MoreHeading('it'), contains('mondo'));
    expect(ds6MoreHeading('en'), isNot(ds6MoreHeading('it')));
  });
}
