part of '../main.dart';

extension AnnaD3CompletionStrings on AnnaStrings {
  String get d3SketchLabel => _pick(
        en: 'Sketch',
        it: 'Sketch',
        es: 'Boceto',
        fr: 'Croquis',
        pt: 'Esboço',
      );

  String d3SketchPages(int count) => _pick(
        en: 'Sketch · $count pages',
        it: 'Sketch · $count pagine',
        es: 'Boceto · $count páginas',
        fr: 'Croquis · $count pages',
        pt: 'Esboço · $count páginas',
      );

  String d3SketchTimed(String time) => _pick(
        en: 'Sketch · $time',
        it: 'Sketch · $time',
        es: 'Boceto · $time',
        fr: 'Croquis · $time',
        pt: 'Esboço · $time',
      );

  String get d3SketchReset => _pick(
        en: 'Reset',
        it: 'Reimposta',
        es: 'Restablecer',
        fr: 'Réinitialiser',
        pt: 'Repor',
      );
}
