part of '../main.dart';

/// Two genuine, equal-sized dashboard tiles; all counts read canonical store.
class AnnaEditorialTodayOverview extends StatelessWidget {
  final AgendaStore store;
  final DateTime selectedDate;
  final bool hideDetails;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenWeek;

  const AnnaEditorialTodayOverview({
    super.key,
    required this.store,
    required this.selectedDate,
    required this.hideDetails,
    required this.onOpenDiary,
    required this.onOpenWeek,
  });

  static int annotatedDays(AgendaStore store, DateTime day) {
    final monday = wrMonday(day);
    var count = 0;
    for (var offset = 0; offset < 7; offset++) {
      final date = DateTime(monday.year, monday.month, monday.day + offset);
      final journal = store.journal(date);
      // Same nonempty predicate as DayHubSnapshot.hasJournalContent.
      if (journal.beautiful.trim().isNotEmpty ||
          journal.note.trim().isNotEmpty ||
          journal.gratitude.any((entry) => entry.trim().isNotEmpty) ||
          journal.mood != null ||
          journal.blocks.any((block) => !block.archived)) {
        count++;
      }
    }
    return count;
  }

  static String weekTitle(BuildContext context) =>
      switch (Localizations.localeOf(context).languageCode) {
        'it' => 'La mia settimana',
        'es' => 'Mi semana',
        'fr' => 'Ma semaine',
        'pt' => 'A minha semana',
        _ => 'My week',
      };

  static String dayCount(BuildContext context, int count) =>
      switch (Localizations.localeOf(context).languageCode) {
        'it' => count == 1 ? '1 giornata annotata' : '$count giornate annotate',
        'es' => count == 1 ? '1 día anotado' : '$count días anotados',
        'fr' => count == 1 ? '1 journée notée' : '$count journées notées',
        'pt' => count == 1 ? '1 dia registado' : '$count dias registados',
        _ => count == 1 ? '1 journal day' : '$count journal days',
      };

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final colors = AnnaEditorialColors.of(context);
    final organic = AnnaOrganicPastel.enabled(context);
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final count = annotatedDays(store, selectedDate);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final side = (constraints.maxWidth - gap) / 2;
        // Squares at normal size; extra height only for narrow/a11y layouts.
        final tileHeight = scale > 1.30
            ? side * 2.12
            : side < 151
                ? side * 1.35
                : side;
        Widget tile({
          required String key,
          required String title,
          required IconData illustration,
          required String detail,
          required String button,
          required VoidCallback onPressed,
        }) {
          final child = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                key: ValueKey<String>(
                  key == 'editorial-today-diary-hero'
                      ? 'editorial-today-diary-title'
                      : '$key-title',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AnnaJournalTypography.editorial(
                  context, size: side < 158 ? 17 : 19,
                ).copyWith(color: colors.ink, height: 1.05),
              ),
              const SizedBox(height: 4),
              AnnaEditorialAccentRule(
                key: key == 'editorial-today-diary-hero'
                    ? const ValueKey<String>('editorial-today-accent-rule')
                    : null,
                margin: EdgeInsets.zero,
              ),
              Expanded(
                child: Center(
                  child: Icon(
                    illustration,
                    size: side < 158 ? 21 : 27,
                    color: colors.accent.withValues(alpha: .85),
                  ),
                ),
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  key: ValueKey<String>('$key-detail'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AnnaJournalTypography.uiFamily,
                    fontSize: 10.5,
                    color: colors.ink,
                  ),
                ),
              const SizedBox(height: 4),
              AnnaEditorialPrimaryAction(
                label: button,
                icon: Icons.arrow_forward_rounded,
                onPressed: onPressed,
              ),
            ],
          );
          return SizedBox(
            key: ValueKey<String>(key),
            height: tileHeight,
            child: organic
                ? AnnaOrganicPaperSurface(
                    tone: AnnaEditorialSurfaceTone.featured,
                    padding: const EdgeInsets.all(9),
                    child: child,
                  )
                : AnnaEditorialSurface(
                    tone: AnnaEditorialSurfaceTone.featured,
                    padding: const EdgeInsets.all(9),
                    child: child,
                  ),
          );
        }
        return Row(
          key: const ValueKey<String>('editorial-today-real-overview'),
          children: [
            Expanded(
              child: tile(
                key: 'editorial-today-diary-hero',
                title: strings.d3('ui5DayDiary'),
                illustration: Icons.menu_book_outlined,
                detail: '',
                button: strings.d3('ui5ShowAll'),
                onPressed: onOpenDiary,
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: tile(
                key: 'editorial-today-week-card',
                title: weekTitle(context),
                illustration: Icons.calendar_view_week_outlined,
                detail: hideDetails ? '•••' : dayCount(context, count),
                button: wrText(context, 'review'),
                onPressed: onOpenWeek,
              ),
            ),
          ],
        );
      },
    );
  }
}
