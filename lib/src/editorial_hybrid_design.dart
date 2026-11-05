part of '../main.dart';

/// Editorial Hybrid Design System — visual primitives only, no data ownership.
///
/// The official AgendaApp ThemeData / ColorScheme remains the single palette
/// source (including HSV, light/dark/system and delicate/expressive modes).
/// No second router, state store, sync path or preview records are created.
abstract final class AnnaEditorialTokens {
  static const double pageGutter = AnnaDesignTokens.journalPageGutter;
  static const double sectionGap = AnnaDesignTokens.journalSectionGap;
  static const double minTapTarget = AnnaDesignTokens.journalMinTapTarget;
  static const double contentMaxWidth = AnnaDesignTokens.compactContentWidth;

  static const double cardRadius = AnnaDesignTokens.radiusLg;
  static const double heroRadius = AnnaDesignTokens.radiusHero;
  static const double dockTopRadius = 20;
  static const double tileGap = AnnaDesignTokens.spaceSm;

  static const double headerTitle = 36;
  static const double sectionTitle = 21;
  static const double cardTitle = 18;
  static const double bodySize = 15;
  static const double eyebrowTracking = 1.4;
  static const double stackedTileBreakpoint = 340;
}

/// A derived palette, never a hardcoded pink theme or stored preference.
/// Surface blends are intentionally restrained to maintain legibility in
/// customized palettes and both brightness modes.
@immutable
class AnnaEditorialColors {
  final Color accent;
  final Color ink;
  final Color mutedInk;
  final Color canvas;
  final Color card;
  final Color quiet;
  final Color featuredStart;
  final Color featuredEnd;
  final Color dock;
  final Color border;
  final Color shadow;
  final Color onAccent;

  const AnnaEditorialColors({
    required this.accent,
    required this.ink,
    required this.mutedInk,
    required this.canvas,
    required this.card,
    required this.quiet,
    required this.featuredStart,
    required this.featuredEnd,
    required this.dock,
    required this.border,
    required this.shadow,
    required this.onAccent,
  });

  factory AnnaEditorialColors.fromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final surface = dark
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerLowest;

    return AnnaEditorialColors(
      accent: scheme.primary,
      ink: scheme.onSurface,
      mutedInk: scheme.onSurfaceVariant,
      canvas: scheme.surface,
      card: surface,
      quiet: Color.lerp(
        scheme.surfaceContainerLow,
        scheme.primaryContainer,
        dark ? 0.12 : 0.19,
      )!,
      featuredStart: Color.lerp(
        surface,
        scheme.primaryContainer,
        dark ? 0.19 : 0.28,
      )!,
      featuredEnd: Color.lerp(
        surface,
        scheme.primaryContainer,
        dark ? 0.08 : 0.13,
      )!,
      dock: surface,
      border: scheme.outlineVariant.withValues(alpha: dark ? 0.47 : 0.59),
      shadow: scheme.shadow.withValues(alpha: dark ? 0.18 : 0.065),
      onAccent: scheme.onPrimary,
    );
  }

  factory AnnaEditorialColors.of(BuildContext context) =>
      AnnaEditorialColors.fromScheme(Theme.of(context).colorScheme);
}

enum AnnaEditorialSurfaceTone { regular, featured, quiet }

/// Layout constraint only — consumers own scrolling, account and data states.
class AnnaEditorialPageLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AnnaEditorialPageLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AnnaEditorialTokens.pageGutter,
    ),
  });

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AnnaEditorialTokens.contentMaxWidth,
          ),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Large, breathable, accessible title hierarchy from the approved prototype.
/// All text comes from the caller's existing localized and privacy-safe state.
class AnnaEditorialHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  const AnnaEditorialHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null && eyebrow!.isNotEmpty) ...[
          Text(
            eyebrow!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.mutedInk,
              letterSpacing: AnnaEditorialTokens.eyebrowTracking,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AnnaDesignTokens.spaceSm),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  softWrap: true,
                  style: AnnaJournalTypography.editorial(
                    context,
                    size: AnnaEditorialTokens.headerTitle,
                  ).copyWith(
                    height: 1.17,
                    letterSpacing: -1.0,
                    color: colors.ink,
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AnnaDesignTokens.spaceSm),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AnnaDesignTokens.spaceSm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.mutedInk,
              height: 1.52,
            ),
          ),
        ],
      ],
    );
  }
}

/// Rounded editorial surface with palette-derived fill, delicate outline and
/// restrained shadow. Optional onTap keeps 48dp target; no fixed card height.
class AnnaEditorialSurface extends StatelessWidget {
  final Widget child;
  final AnnaEditorialSurfaceTone tone;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AnnaEditorialSurface({
    super.key,
    required this.child,
    this.tone = AnnaEditorialSurfaceTone.regular,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    final featured = tone == AnnaEditorialSurfaceTone.featured;
    final radius = BorderRadius.circular(
      featured
          ? AnnaEditorialTokens.heroRadius
          : AnnaEditorialTokens.cardRadius,
    );
    final decoration = BoxDecoration(
      borderRadius: radius,
      color: featured
          ? null
          : tone == AnnaEditorialSurfaceTone.quiet
              ? colors.quiet
              : colors.card,
      gradient: featured
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.featuredStart, colors.featuredEnd],
            )
          : null,
      border: Border.all(color: colors.border, width: 0.75),
      boxShadow: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: featured ? 23 : 16,
          offset: Offset(0, featured ? 7 : 5),
        ),
      ],
    );

    return Semantics(
      container: onTap != null,
      button: onTap != null,
      label: semanticLabel,
      child: Container(
        constraints: BoxConstraints(
          minHeight: onTap == null ? 0 : AnnaEditorialTokens.minTapTarget,
        ),
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: padding ??
                  EdgeInsets.all(
                    featured
                        ? AnnaDesignTokens.spaceLg
                        : AnnaDesignTokens.spaceMd,
                  ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A low-chrome call-to-action. Text and action remain owned by the caller.
class AnnaEditorialPrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AnnaEditorialPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    final style = FilledButton.styleFrom(
      backgroundColor: colors.accent,
      foregroundColor: colors.onAccent,
      minimumSize: const Size(
        AnnaEditorialTokens.minTapTarget,
        AnnaEditorialTokens.minTapTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontFamily: AnnaJournalTypography.uiFamily,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

/// Compact editorial feature used in small groups; content grows with text.
class AnnaEditorialQuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const AnnaEditorialQuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    final theme = Theme.of(context);
    return AnnaEditorialSurface(
      onTap: onTap,
      semanticLabel: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: colors.accent),
          const SizedBox(height: AnnaDesignTokens.spaceLg),
          Text(
            title,
            style: AnnaJournalTypography.editorial(
              context,
              size: AnnaEditorialTokens.cardTitle,
            ).copyWith(color: colors.ink),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AnnaDesignTokens.spaceXs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.42,
                color: colors.mutedInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The two-card Hybrid rhythm folds into a column on narrow phones. Consumers
/// supply their real content; this primitive never fabricates demo entries.
class AnnaEditorialActionPair extends StatelessWidget {
  final Widget leading;
  final Widget trailing;

  const AnnaEditorialActionPair({
    super.key,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <
              AnnaEditorialTokens.stackedTileBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leading,
                const SizedBox(height: AnnaEditorialTokens.tileGap),
                trailing,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leading),
              const SizedBox(width: AnnaEditorialTokens.tileGap),
              Expanded(child: trailing),
            ],
          );
        },
      );
}

/// Reusable section heading. Keep caller-owned badges/actions localized.
class AnnaEditorialSectionHeading extends StatelessWidget {
  final String title;
  final Widget? action;

  const AnnaEditorialSectionHeading({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AnnaJournalTypography.editorial(
                context,
                size: AnnaEditorialTokens.sectionTitle,
              ).copyWith(color: colors.ink),
            ),
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AnnaDesignTokens.spaceXs),
          action!,
        ],
      ],
    );
  }
}

/// Presentation-only bottom surface, not a second navigation or Create owner.
/// Place directly in Scaffold.bottomNavigationBar when migrating the real
/// shell: there are NO external bottom/side margins, and SafeArea reserves the
/// gesture inset while retaining background through the device's lower edge.
class AnnaEditorialDockSurface extends StatelessWidget {
  final Widget child;

  const AnnaEditorialDockSurface({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    return Container(
      key: const ValueKey<String>('anna-editorial-anchored-dock'),
      decoration: BoxDecoration(
        color: colors.dock,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AnnaEditorialTokens.dockTopRadius),
        ),
        border: Border(
          top: BorderSide(color: colors.border, width: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: child,
        ),
      ),
    );
  }
