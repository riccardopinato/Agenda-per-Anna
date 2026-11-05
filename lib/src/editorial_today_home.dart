part of '../main.dart';

/// Editorial Hybrid composition over the existing day projection.
///
/// This is presentation-only: no synthetic content, alternate repository,
/// capture writer, account, navigation owner or calendar persistence.
class AnnaEditorialTodayOverview extends StatelessWidget {
  final DayHubSnapshot snapshot;
  final bool hideDetails;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenDay;

  const AnnaEditorialTodayOverview({
    super.key,
    required this.snapshot,
    required this.hideDetails,
    required this.onOpenDiary,
    required this.onOpenCalendar,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final colors = AnnaEditorialColors.of(context);
    final commitments = snapshot.agenda.length + snapshot.birthdays.length;
    final activities = snapshot.workouts.length;
    final privateSummary = snapshot.hasJournalContent
        ? strings.journalStarted
        : strings.journalEmpty;

    return Column(
      key: const ValueKey<String>('editorial-today-real-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnaEditorialSurface(
          key: const ValueKey<String>('editorial-today-diary-hero'),
          tone: AnnaEditorialSurfaceTone.featured,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      strings.d3('ui5DayDiary').toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: AnnaEditorialTokens.eyebrowTracking,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.auto_stories_outlined,
                    color: colors.accent.withValues(alpha: 0.68),
                    size: 40,
                    semanticLabel: null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                strings.d3('ui5DayDiary'),
                style: AnnaJournalTypography.editorial(context, size: 27)
                    .copyWith(color: colors.ink),
              ),
              const SizedBox(height: 12),
              Text(
                hideDetails ? '•••' : privateSummary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.mutedInk,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              AnnaEditorialPrimaryAction(
                label: strings.d3('ui5ShowAll'),
                icon: Icons.arrow_forward_rounded,
                onPressed: onOpenDiary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AnnaDesignTokens.spaceMd),
        AnnaEditorialActionPair(
          leading: AnnaEditorialQuickAction(
            icon: Icons.event_outlined,
            title: strings.d3('ui5Commitments'),
            subtitle: hideDetails ? '•••' : commitments.toString(),
            onTap: onOpenCalendar,
          ),
          trailing: AnnaEditorialQuickAction(
            icon: Icons.directions_run_outlined,
            title: strings.d3('ui5Activities'),
            subtitle: hideDetails ? '•••' : activities.toString(),
            onTap: onOpenDay,
          ),
        ),
      ],
    );
  }
}
