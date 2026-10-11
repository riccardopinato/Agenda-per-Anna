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
  String get d3PlannerNotWrittenYet => _pick(
        en: 'Not written yet',
        it: 'Ancora da scrivere',
        es: 'Aún por escribir',
        fr: 'Pas encore écrit',
        pt: 'Ainda por escrever',
      );

  String d3LinkedCount(int count) => _pick(
        en: '$count linked',
        it: '$count collegati',
        es: '$count vinculados',
        fr: '$count liés',
        pt: '$count ligados',
      );

  String d3BacklinksCount(int count) => _pick(
        en: '$count backlinks',
        it: '$count backlink',
        es: '$count enlaces entrantes',
        fr: '$count liens entrants',
        pt: '$count ligações de retorno',
      );

  String get d3CommentAction => _pick(
        en: 'Comment',
        it: 'Commenta',
        es: 'Comentar',
        fr: 'Commenter',
        pt: 'Comentar',
      );
}
