part of '../main.dart';

abstract final class AnnaDesignTokens {
  static const double space2xs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusHero = 28;

  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionStandard = Duration(milliseconds: 180);
  static const Duration motionEmphasis = Duration(milliseconds: 260);

  static const double compactContentWidth = 640;
  static const double readingContentWidth = 760;
  static const double wideBreakpoint = 840;
  static const double railExtendedBreakpoint = 1180;

  static bool animationsEnabled(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false);
  }
}

enum AnnaVisualDomain {
  today,
  calendar,
  memories,
  people,
  shared,
  workout,
  vault,
  ecosystem,
}

extension AnnaVisualDomainUi on AnnaVisualDomain {
  Color accent(ColorScheme scheme) => switch (this) {
        AnnaVisualDomain.today => scheme.primary,
        AnnaVisualDomain.calendar => const Color(0xFF6C8FD8),
        AnnaVisualDomain.memories => const Color(0xFFD88A62),
        AnnaVisualDomain.people => const Color(0xFFD79578),
        AnnaVisualDomain.shared => const Color(0xFFD56A84),
        AnnaVisualDomain.workout => const Color(0xFF6A9F83),
        AnnaVisualDomain.vault => const Color(0xFF776FAF),
        AnnaVisualDomain.ecosystem => const Color(0xFF668E9B),
      };

  Color softSurface(ColorScheme scheme) {
    final target = scheme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
    return Color.lerp(accent(scheme), target, 0.86)!;
  }
}

@immutable
class AccentSurfaceTokens {
  final Color start;
  final Color end;
  final Color foreground;
  final Color secondaryForeground;
  final Color chipBackground;
  final Color chipForeground;
  final Color chipBorder;

  const AccentSurfaceTokens({
    required this.start,
    required this.end,
    required this.foreground,
    required this.secondaryForeground,
    required this.chipBackground,
    required this.chipForeground,
    required this.chipBorder,
  });

  LinearGradient get gradient => LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  factory AccentSurfaceTokens.fromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final blendTarget =
        dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest;
    final start = Color.lerp(scheme.primary, blendTarget, dark ? 0.66 : 0.76)!;
    final end = Color.lerp(scheme.primary, blendTarget, dark ? 0.80 : 0.90)!;
    final middle = Color.lerp(start, end, 0.5)!;

    final foreground = _bestReadableForeground(middle);
    final secondaryForeground = foreground.withValues(alpha: 0.74);

    final chipBackground =
        Color.lerp(scheme.primary, blendTarget, dark ? 0.82 : 0.88)!;
    final chipForeground = _bestReadableForeground(chipBackground);
    final chipBorder =
        Color.lerp(scheme.primary, chipForeground, 0.08)!.withValues(alpha: 0.40);

    return AccentSurfaceTokens(
      start: start,
      end: end,
      foreground: foreground,
      secondaryForeground: secondaryForeground,
      chipBackground: chipBackground,
      chipForeground: chipForeground,
      chipBorder: chipBorder,
    );
  }

  static Color _bestReadableForeground(Color background) {
    final dark = const Color(0xFF2B2327);
    final light = Colors.white;
    return _contrastRatio(background, dark) >=
            _contrastRatio(background, light)
        ? dark
        : light;
  }

  static double _contrastRatio(Color a, Color b) {
    final light = max(a.computeLuminance(), b.computeLuminance());
    final dark = min(a.computeLuminance(), b.computeLuminance());
    return (light + 0.05) / (dark + 0.05);
  }
}

extension AccentSurfaceContext on BuildContext {
  AccentSurfaceTokens get accentSurface =>
      AccentSurfaceTokens.fromScheme(Theme.of(this).colorScheme);

  Color annaDomainAccent(AnnaVisualDomain domain) =>
      domain.accent(Theme.of(this).colorScheme);

  Color annaDomainSurface(AnnaVisualDomain domain) =>
      domain.softSurface(Theme.of(this).colorScheme);
}
