part of '../main.dart';

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
    final start = Color.lerp(scheme.primary, Colors.white, 0.78)!;
    final end = Color.lerp(scheme.primary, Colors.white, 0.90)!;
    final middle = Color.lerp(start, end, 0.5)!;

    final foreground = _bestReadableForeground(middle);
    final secondaryForeground = foreground.withValues(alpha: 0.74);

    final chipBackground = Color.lerp(scheme.primary, Colors.white, 0.88)!;
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
}
