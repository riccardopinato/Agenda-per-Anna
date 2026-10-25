import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

double contrastRatio(Color a, Color b) {
  final light = max(a.computeLuminance(), b.computeLuminance());
  final dark = min(a.computeLuminance(), b.computeLuminance());
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  test('accent surfaces adapt to every user palette', () {
    final starts = <int>{};
    final chips = <int>{};

    for (final palette in AgendaPalette.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: Brightness.dark,
      );
      final tokens = AccentSurfaceTokens.fromScheme(scheme);
      starts.add(tokens.start.toARGB32());
      chips.add(tokens.chipBackground.toARGB32());
    }

    expect(starts.length, AgendaPalette.values.length);
    expect(chips.length, AgendaPalette.values.length);
  });

  test('accent surfaces keep readable contrast in light and dark themes', () {
    for (final palette in AgendaPalette.values) {
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: palette.seed,
          brightness: brightness,
        );
        final tokens = AccentSurfaceTokens.fromScheme(scheme);

        expect(
          contrastRatio(tokens.start, tokens.foreground),
          greaterThanOrEqualTo(4.5),
          reason: '${palette.name}/${brightness.name} banner start',
        );
        expect(
          contrastRatio(tokens.end, tokens.foreground),
          greaterThanOrEqualTo(4.5),
          reason: '${palette.name}/${brightness.name} banner end',
        );
        expect(
          contrastRatio(tokens.chipBackground, tokens.chipForeground),
          greaterThanOrEqualTo(4.5),
          reason: '${palette.name}/${brightness.name} chip',
        );
      }
    }
  });

  test('accent surfaces respect brightness instead of washing out dark mode', () {
    for (final palette in AgendaPalette.values) {
      final darkScheme = ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: Brightness.dark,
      );
      final lightScheme = ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: Brightness.light,
      );
      final darkTokens = AccentSurfaceTokens.fromScheme(darkScheme);
      final lightTokens = AccentSurfaceTokens.fromScheme(lightScheme);

      expect(
        darkTokens.start.computeLuminance(),
        lessThan(lightTokens.start.computeLuminance()),
      );
      expect(
        darkTokens.end.computeLuminance(),
        lessThan(lightTokens.end.computeLuminance()),
      );
      expect(
        darkTokens.chipBackground.computeLuminance(),
        lessThan(lightTokens.chipBackground.computeLuminance()),
      );
      expect(darkTokens.start.computeLuminance(), lessThan(0.35));
      expect(darkTokens.end.computeLuminance(), lessThan(0.35));
    }
  });
}
