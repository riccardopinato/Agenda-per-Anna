part of '../main.dart';

/// DS5 visual-only wrapper. The caller retains its original agenda,
/// date selection, editor, persistence, and semantics; no second writer.
class AnnaEditorialCalendarPanel extends StatelessWidget {
  final bool enabled;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final bool featured;

  const AnnaEditorialCalendarPanel({
    super.key,
    required this.enabled,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );
    }
    final colors = AnnaEditorialColors.of(context);
    return AnnaEditorialSurface(
      tone: featured
          ? AnnaEditorialSurfaceTone.featured
          : AnnaEditorialSurfaceTone.regular,
      padding: EdgeInsets.zero,
      semanticLabel: semanticLabel,
      // DS6 notebook binding: subtle themed rule above the SAME calendar.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                colors.card,
                colors.accent.withValues(alpha: 0.55),
                colors.card,
              ]),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// The canonical week data is read only from the existing WeekScreen.
class AnnaEditorialCalendarWeekSummary extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int eventCount;
  final int completedTasks;
  final int totalTasks;

  const AnnaEditorialCalendarWeekSummary({
    super.key,
    required this.start,
    required this.end,
    required this.eventCount,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final colors = AnnaEditorialColors.of(context);
    final dateRange =
        '${DateFormat('d MMM', AnnaStrings.intlLocale(context)).format(start)}'
        ' – ${DateFormat('d MMM yyyy', AnnaStrings.intlLocale(context)).format(end)}';
    return AnnaEditorialSurface(
      tone: AnnaEditorialSurfaceTone.featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateRange,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            strings.d3('oneWeek'),
            style: AnnaJournalTypography.editorial(
              context, size: AnnaEditorialTokens.sectionTitle,
            ).copyWith(color: colors.ink),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: AnnaDesignTokens.spaceSm,
            runSpacing: AnnaDesignTokens.spaceSm,
            children: [
              _MiniPill(
                icon: Icons.event_outlined,
                text: strings.plannerCommitmentsCount(eventCount),
              ),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: totalTasks == 0
                    ? strings.d3('noTasks')
                    : strings.d3Format('taskProgress', {
                        'done': completedTasks,
                        'total': totalTasks,
                      }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
