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
    return Column(
      key: const ValueKey<String>('editorial-today-real-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnaEditorialSurface(
          key: const ValueKey<String>('editorial-today-diary-hero'),
          tone: AnnaEditorialSurfaceTone.featured,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      strings.d3('ui5DayDiary'),
                      key: const ValueKey<String>('editorial-today-diary-title'),
                      softWrap: true,
                      style: AnnaJournalTypography.editorial(
                        context, size: 27,
                      ).copyWith(color: colors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.auto_stories_outlined,
                    key: const ValueKey<String>('editorial-today-diary-icon'),
                    color: colors.accent.withValues(alpha: 0.68),
                    size: 34,
                    semanticLabel: null,
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
