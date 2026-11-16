part of '../main.dart';

/// Original calendar mode selector for the Organic iOS Journal.
/// Unlike Material 3 SegmentedButton, every pixel is under this design's own
/// theme, spacing and palette. Classic retains its pre-existing widget.
class AnnaOrganicCalendarModePicker extends StatelessWidget {
  final bool monthSelected;
  final String monthLabel;
  final String weekLabel;
  final ValueChanged<bool> onSelected;

  const AnnaOrganicCalendarModePicker({
    super.key,
    required this.monthSelected,
    required this.monthLabel,
    required this.weekLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.quiet,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final month in [true, false])
              Expanded(
                child: Semantics(
                  button: true,
                  selected: monthSelected == month,
                  label: month ? monthLabel : weekLabel,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      key: ValueKey<String>(month
                          ? 'organic-calendar-mode-month'
                          : 'organic-calendar-mode-week'),
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      focusColor: colors.accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => onSelected(month),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: monthSelected == month
                              ? colors.card : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: monthSelected == month
                              ? [
                                  BoxShadow(
                                    color: colors.shadow,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              month
                                  ? Icons.calendar_month_outlined
                                  : Icons.view_week_outlined,
                              size: 16,
                              color: monthSelected == month
                                  ? colors.accent : colors.mutedInk,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                month ? monthLabel : weekLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AnnaJournalTypography.uiFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// Calendar notebook shortcuts use the same paper and palette as Organic Today.
/// They are pure presentation over the caller's original month/year routes.
class AnnaOrganicCalendarNotebookLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AnnaOrganicCalendarNotebookLink({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: colors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.quiet,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: colors.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontFamily: AnnaJournalTypography.uiFamily,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 17, color: colors.mutedInk),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A truthful empty-day treatment; the caller supplies the existing
/// localized string and continues to own the canonical agenda.
class AnnaOrganicCalendarEmptyAgenda extends StatelessWidget {
  final String label;

  const AnnaOrganicCalendarEmptyAgenda({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    return AnnaOrganicPaperSurface(
      tone: AnnaEditorialSurfaceTone.quiet,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.quiet,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.event_available_outlined,
                color: colors.accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.ink,
                    fontFamily: AnnaJournalTypography.uiFamily,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    // Notebook body and data ownership stay identical in both themes.
    final notebook = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AnnaEditorialAccentRule(
          key: ValueKey<String>('editorial-calendar-notebook-rule'),
          margin: EdgeInsets.symmetric(horizontal: 30),
        ),
        Padding(padding: padding, child: child),
      ],
    );
    final tone = featured
        ? AnnaEditorialSurfaceTone.featured
        : AnnaEditorialSurfaceTone.regular;
    if (AnnaOrganicPastel.enabled(context)) {
      return AnnaOrganicPaperSurface(
        tone: tone,
        padding: EdgeInsets.zero,
        semanticLabel: semanticLabel,
        child: notebook,
      );
    }
    return AnnaEditorialSurface(
      tone: tone,
      padding: EdgeInsets.zero,
      semanticLabel: semanticLabel,
      child: notebook,
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
          AnnaEditorialDateLabel(
            key: const ValueKey<String>('editorial-calendar-week-date'),
            text: dateRange,
          ),
          const SizedBox(height: 9),
          Text(
            strings.d3('oneWeek'),
            style: AnnaJournalTypography.editorial(
              context, size: AnnaEditorialTokens.sectionTitle,
            ).copyWith(color: colors.ink),
          ),
          // DS6 notebook rhythm: a quiet palette-driven separator keeps the
          // real date, event count and task progress readable as one summary.
          const SizedBox(height: 10),
          const AnnaEditorialAccentRule(
            key: ValueKey<String>('editorial-calendar-week-summary-rule'),
            margin: EdgeInsets.symmetric(horizontal: 0),
          ),
          const SizedBox(height: 10),
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
