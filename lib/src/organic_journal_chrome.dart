part of '../main.dart';

/// Organic iOS Journal chrome. Pure Flutter presentation, with no Material 3
/// ListTile/Chip/Card appearance. The Material host remains for routing,
/// accessibility, localization, forms, Vault and reversible Classic mode.
class AnnaOrganicJournalRow extends StatelessWidget {
  final String identifier;
  final IconData icon;
  final AnnaVisualDomain domain;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const AnnaOrganicJournalRow({
    super.key,
    required this.identifier,
    required this.icon,
    required this.domain,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = AnnaOrganicPastel.text(context);
    final quiet = AnnaEditorialColors.of(context).mutedInk;
    final accent = AnnaEditorialColors.of(context).accent;
    return Semantics(
      identifier: identifier,
      button: true,
      label: title,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey<String>(identifier),
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: accent.withValues(alpha: .045),
        focusColor: accent.withValues(alpha: .095),
        borderRadius: BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Row(
              children: [
                AnnaPastelIcon(icon: icon, domain: domain),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AnnaJournalTypography.uiFamily,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AnnaJournalTypography.uiFamily,
                            fontSize: 12.5,
                            height: 1.35,
                            color: quiet,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        size: 19, color: quiet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hairline journal divider, not a Material 3 themed Divider.
class AnnaOrganicJournalRule extends StatelessWidget {
  const AnnaOrganicJournalRule({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 56),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AnnaEditorialColors.of(context)
                  .border.withValues(alpha: .72),
            ),
            child: const SizedBox(height: 1, width: double.infinity),
          ),
        ),
      );
}


/// Year selector for personal anniversary recall. Compact editorial paper pill,
/// with the same keyboard/semantics contract as the Classic chip.
class AnnaOrganicJournalYearPill extends StatelessWidget {
  final int year;
  final bool selected;
  final VoidCallback onTap;

  const AnnaOrganicJournalYearPill({
    super.key,
    required this.year,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$year',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashFactory: NoSplash.splashFactory,
          focusColor: colors.accent.withValues(alpha: .14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? colors.quiet : colors.card,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 1.25 : 1,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 66),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_rounded, size: 16, color: colors.accent),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '$year',
                      style: TextStyle(
                        fontFamily: AnnaJournalTypography.uiFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
