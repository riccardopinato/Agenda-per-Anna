part of '../main.dart';

/// v1.05.x iOS Journal design foundations.
///
/// Only view/theme composition. Never owns app data, navigation, cloud state,
/// a palette, or a second way to write diary content.
abstract final class AnnaJournalTypography {
  // Locally bundled OFL-licensed font families, with platform fallbacks for glyphs.
  static const uiFamily = 'Manrope';
  static const editorialFamily = 'Lora';
  static const uiFallback = <String>['Roboto', 'Arial', 'sans-serif'];
  static const editorialFallback = <String>['Georgia', 'serif'];

  static bool _licensesRegistered = false;

  /// Make redistributed SIL OFL notices available in Flutter's license UI.
  /// The files are packaged via pubspec assets; no network is required.
  static void registerLicensesOnce() {
    if (_licensesRegistered) return;
    _licensesRegistered = true;
    LicenseRegistry.addLicense(() async* {
      for (final family in [uiFamily, editorialFamily]) {
        final license = await rootBundle.loadString(
          'assets/fonts/licenses/$family-OFL.txt',
        );
        yield LicenseEntryWithLineBreaks([family], license);
      }
    });
  }

  static TextTheme fromBase(TextTheme base, ColorScheme scheme) {
    final text = base.apply(
      fontFamily: uiFamily,
      fontFamilyFallback: uiFallback,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.08,
        letterSpacing: -1.0,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontSize: 30,
        height: 1.12,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontSize: 17,
        height: 1.24,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.48),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.48),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  static TextStyle editorial(BuildContext context, {double? size}) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineSmall ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
    return base.copyWith(
      fontFamily: editorialFamily,
      fontFamilyFallback: editorialFallback,
      fontSize: size,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: -0.4,
      color: theme.colorScheme.onSurface,
    );
  }
}

abstract final class AnnaJournalTheme {
  /// Decorates the existing Material 3 theme without changing the canonical
  /// ColorScheme / seed. This keeps custom HSV and expressive-intensity logic
  /// from AgendaApp as the only source of appearance preferences.
  static ThemeData apply(ThemeData base) {
    final scheme = base.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final type = AnnaJournalTypography.fromBase(base.textTheme, scheme);
    return base.copyWith(
      textTheme: type,
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: type.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      // Attached navigation stays in the Scaffold bottomNavigationBar;
      // this theme never introduces an overlay/floating dock.
      navigationBarTheme: NavigationBarThemeData(
        height: AnnaDesignTokens.journalDockHeight,
        backgroundColor:
            dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor:
            base.navigationBarTheme.indicatorColor ?? scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AnnaDesignTokens.radiusHero),
          ),
        ),
      ),
    );
  }
}

/// Responsive content width for a later page-by-page migration. Center only
/// on wide displays; the page retains its own scroll and SafeArea behavior.
class AnnaJournalContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const AnnaJournalContent({
    super.key,
    required this.child,
    this.maxWidth = AnnaDesignTokens.compactContentWidth,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AnnaDesignTokens.journalPageGutter,
    ),
  });

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// A large, accessible page header. It does not infer a name, date, or greeting
/// from personal data, and is safe to use when a privacy lock masks details.
class AnnaJournalPageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final bool editorial;

  const AnnaJournalPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.editorial = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null && eyebrow!.isNotEmpty) ...[
          Text(
            eyebrow!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AnnaDesignTokens.spaceXs),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: editorial
                ? AnnaJournalTypography.editorial(context, size: 30)
                : theme.textTheme.headlineMedium,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AnnaDesignTokens.spaceXs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Semantic card primitive: palette-aware in both modes, no hard-coded rose
/// background or opaque white text. The domain tint remains optional.
class AnnaJournalCard extends StatelessWidget {
  final Widget child;
  final AnnaVisualDomain? domain;
  final bool hero;
  final EdgeInsetsGeometry? padding;

  const AnnaJournalCard({
    super.key,
    required this.child,
    this.domain,
    this.hero = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bg = domain?.softSurface(scheme) ??
        (dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest);
    return Material(
      color: bg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          hero ? AnnaDesignTokens.radiusHero : AnnaDesignTokens.radiusLg,
        ),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.35 : 0.5),
        ),
      ),
      child: Padding(
        padding: padding ??
            EdgeInsets.all(
              hero ? AnnaDesignTokens.spaceLg : AnnaDesignTokens.spaceMd,
            ),
        child: child,
      ),
    );
  }
}

/// Section title with optional action. A simple, scalable alternative to
/// fixed-height tile headers and decoration-only icon rows.
class AnnaJournalSectionHeading extends StatelessWidget {
  final String title;
  final Widget? action;

  const AnnaJournalSectionHeading({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      );
}
