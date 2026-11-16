part of '../main.dart';

/// A read-only projection of real, private DayJournal entries.
/// Never includes agenda activities, synthetic test fixtures or archived-only
/// blocks. The source of truth remains AgendaStore.journals.
({int all, int week}) annaTodayAnnotatedDayCounts(
  AgendaStore store,
  DateTime today,
) {
  final monday = wrMonday(today);
  final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
  final startKey = AgendaStore.dateKey(monday);
  final endKey = AgendaStore.dateKey(nextMonday);
  var all = 0;
  var week = 0;
  for (final entry in store.journals.entries) {
    if (!entry.value.hasContent) continue;
    all++;
    if (entry.key.compareTo(startKey) >= 0 &&
        entry.key.compareTo(endKey) < 0) {
      week++;
    }
  }
  return (all: all, week: week);
}

String annaTodayDiaryCountLabel(BuildContext context, int count, {
  bool weekly = false,
}) {
  final language = Localizations.localeOf(context).languageCode;
  final number = weekly ? '$count/7' : '$count';
  return switch (language) {
    'en' => '$number ${count == 1 && !weekly ? 'journal day' : 'journal days'}',
    'es' => '$number ${count == 1 && !weekly ? 'día anotado' : 'días anotados'}',
    'fr' => '$number ${count == 1 && !weekly ? 'journée notée' : 'journées notées'}',
    'pt' => '$number ${count == 1 && !weekly ? 'dia registado' : 'dias registados'}',
    _ => '$number ${count == 1 && !weekly ? 'giornata annotata' : 'giornate annotate'}',
  };
}

/// Two equal-sized editorial tiles: diary and the canonical Weekly Review.
/// Genuine memories are rendered by PlannerScreen immediately AFTER this row.
class AnnaEditorialTodayOverview extends StatelessWidget {
  final AgendaStore store;
  final DateTime today;
  final bool hideDetails;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenWeek;

  const AnnaEditorialTodayOverview({
    super.key,
    required this.store,
    required this.today,
    required this.hideDetails,
    required this.onOpenDiary,
    required this.onOpenWeek,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final counts = annaTodayAnnotatedDayCounts(store, today);
    final start = wrMonday(today);
    final end = DateTime(start.year, start.month, start.day + 6);
    final locale = AnnaStrings.intlLocale(context);
    final range =
        '${DateFormat('d MMM', locale).format(start)} – '
        '${DateFormat('d MMM', locale).format(end)}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxWidth - 10) / 2;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // Approximate squares on a normal phone; grow vertically for 320dp
        // and large accessibility text instead of clipping the CTAs.
        final accessibleHeight = 194 + (scale > 1 ? (scale - 1) * 110 : 0);
        final height = side > accessibleHeight ? side : accessibleHeight;
        return Row(
          key: const ValueKey<String>('editorial-today-real-overview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: height,
                child: _AnnaTodayDashboardTile(
                  key: const ValueKey<String>('editorial-today-diary-hero'),
                  id: 'diary',
                  title: strings.d3('ui5DayDiary'),
                  subtitle: hideDetails
                      ? '•••'
                      : annaTodayDiaryCountLabel(context, counts.all),
                  action: strings.d3('ui5ShowAll'),
                  icon: Icons.menu_book_rounded,
                  onPressed: onOpenDiary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: height,
                child: _AnnaTodayDashboardTile(
                  key: const ValueKey<String>('editorial-today-week-hero'),
                  id: 'week',
                  title: wrText(context, 'myWeek'),
                  subtitle: hideDetails
                      ? '•••'
                      : annaTodayDiaryCountLabel(
                          context, counts.week, weekly: true),
                  metadata: range,
                  action: wrText(context, 'briefReview'),
                  icon: Icons.calendar_month_outlined,
                  onPressed: onOpenWeek,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnnaTodayDashboardTile extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String? metadata;
  final String action;
  final IconData icon;
  final VoidCallback onPressed;

  const _AnnaTodayDashboardTile({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    this.metadata,
    required this.action,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    final organic = AnnaOrganicPastel.enabled(context);
    final ink = organic ? AnnaOrganicPastel.text(context) : colors.ink;
    final titleSize = MediaQuery.sizeOf(context).width <= 350 ? 16.5 : 19.0;
    final keyPrefix = 'editorial-today-$id';
    return AnnaEditorialSurface(
      tone: AnnaEditorialSurfaceTone.featured,
      padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              key: ValueKey<String>('$keyPrefix-title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AnnaJournalTypography.editorial(
                context, size: titleSize,
              ).copyWith(color: ink),
            ),
          ),
          const SizedBox(height: 7),
          AnnaEditorialAccentRule(
            key: ValueKey<String>('$keyPrefix-rule'),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: id == 'diary'
                      ? AnnaOrganicPastel.olive.withValues(alpha: .17)
                      : AnnaOrganicPastel.peach.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 42,
                  height: 38,
                  child: Icon(
                    icon,
                    color: organic
                        ? AnnaOrganicPastel.oliveInk
                        : colors.accent,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          if (metadata != null) ...[
            const SizedBox(height: 4),
            Text(
              metadata!,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ink,
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            subtitle,
            key: ValueKey<String>('$keyPrefix-count'),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ink,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AnnaEditorialPrimaryAction(
              label: action,
              icon: Icons.arrow_forward_rounded,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
