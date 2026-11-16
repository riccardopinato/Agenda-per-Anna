part of '../main.dart';

/// Editorial Hybrid composition over the existing day projection.
///
/// This is presentation-only: no synthetic content, alternate repository,
/// capture writer, account, navigation owner or calendar persistence.
class AnnaEditorialTodayOverview extends StatelessWidget {
  final VoidCallback onOpenDiary;

  const AnnaEditorialTodayOverview({
    super.key,
    required this.onOpenDiary,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final colors = AnnaEditorialColors.of(context);
    return Column(
      key: const ValueKey<String>('editorial-today-real-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnaEditorialSurface(
          key: const ValueKey<String>('editorial-today-diary-hero'),
          tone: AnnaEditorialSurfaceTone.featured,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                        context, size: 25,
                      ).copyWith(color: colors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // DS6: notebook emblem uses the existing themed colors.
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.quiet,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      key: const ValueKey<String>('editorial-today-diary-icon'),
                      color: colors.accent,
                      size: 23,
                      semanticLabel: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const AnnaEditorialAccentRule(
                key: ValueKey<String>('editorial-today-accent-rule'),
              ),
              const SizedBox(height: 11),
              AnnaEditorialPrimaryAction(
                label: strings.d3('ui5ShowAll'),
                icon: Icons.arrow_forward_rounded,
                onPressed: onOpenDiary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
