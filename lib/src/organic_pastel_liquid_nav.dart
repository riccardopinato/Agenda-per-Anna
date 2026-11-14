part of '../main.dart';

/// Organic Pastel's liquid-glass navigation experiment.
///
/// Presentation only: no new navigator, Create writer, preference or theme
/// owner. Colors blend with the active ColorScheme (including user HSV).
/// The backdrop is filtered once at dock level rather than once per tab.
class AnnaOrganicLiquidDockSurface extends StatelessWidget {
  final Widget child;

  const AnnaOrganicLiquidDockSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    const radius = BorderRadius.vertical(top: Radius.circular(24));
    return Container(
      key: const ValueKey<String>('anna-editorial-anchored-dock'),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: dark ? .25 : .10),
            blurRadius: 23,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface.withValues(alpha: dark ? .82 : .76),
                  Color.lerp(scheme.surface, scheme.primaryContainer, .15)!
                      .withValues(alpha: dark ? .81 : .71),
                  scheme.surfaceContainerLow
                      .withValues(alpha: dark ? .86 : .77),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? .24 : .83),
                  width: 1.25,
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}

/// Four colored translucent gel capsules that reuse the original page owner.
class AnnaOrganicLiquidTab extends StatelessWidget {
  final int page;
  final bool selected;
  final String label;
  final IconData icon;
  final String semanticId;
  final VoidCallback onTap;

  const AnnaOrganicLiquidTab({
    super.key,
    required this.page,
    required this.selected,
    required this.label,
    required this.icon,
    required this.semanticId,
    required this.onTap,
  });

  static const _pastels = <Color>[
    Color(0xFF9DC4A6), // Oggi: sage
    Color(0xFFF0BAAD), // Messaggi: peach
    Color(0xFFC5B8E9), // Ricordi: lavender
    Color(0xFFAECDE4), // Altro: sky
  ];

  @override
  Widget build(BuildContext context) {
    assert(page >= 0 && page < 4);
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final tint = Color.lerp(scheme.primary, _pastels[page], .58)!;
    final duration = AnnaDesignTokens.animationsEnabled(context)
        ? const Duration(milliseconds: 210)
        : Duration.zero;
    final foreground = scheme.onSurface;

    return Semantics(
      identifier: semanticId,
      label: label,
      button: true,
      selected: selected,
      explicitChildNodes: false,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>(semanticId),
            borderRadius: BorderRadius.circular(19),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: AnimatedScale(
                duration: duration,
                curve: Curves.easeOutBack,
                scale: selected ? 1 : .97,
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, .51, 1],
                      colors: [
                        Color.lerp(scheme.surface, tint, dark ? .31 : .19)!
                            .withValues(alpha: dark ? .94 : .90),
                        tint.withValues(
                          alpha: selected
                              ? (dark ? .68 : .52)
                              : (dark ? .42 : .29),
                        ),
                        Color.lerp(
                          scheme.surfaceContainerLow,
                          tint,
                          selected ? .53 : .32,
                        )!.withValues(alpha: dark ? .91 : .79),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: dark ? (selected ? .45 : .30) : .86,
                      ),
                      width: selected ? 1.4 : .95,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tint.withValues(
                          alpha: selected ? (dark ? .29 : .23) : .10,
                        ),
                        blurRadius: selected ? 13 : 8,
                        offset: Offset(0, selected ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 3,
                        left: 11,
                        right: 11,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: .03),
                                Colors.white.withValues(
                                    alpha: dark ? .42 : .91),
                                Colors.white.withValues(alpha: .03),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(1, 5, 1, 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: foreground, size: 21),
                            const SizedBox(height: 3),
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AnnaJournalTypography.uiFamily,
                                color: foreground,
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Raised single-owner Create action, rendered as a colored glass droplet.
class AnnaOrganicLiquidCreate extends StatelessWidget {
  final String label;
  final bool pressed;
  final bool released;
  final VoidCallback onTap;

  const AnnaOrganicLiquidCreate({
    super.key,
    required this.label,
    required this.pressed,
    required this.released,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final animate = AnnaDesignTokens.animationsEnabled(context);
    final duration = animate ? const Duration(milliseconds: 190) : Duration.zero;
    final tint = Color.lerp(
      scheme.primaryContainer,
      AnnaOrganicPastel.olive,
      .58,
    )!;
    final ink = scheme.onPrimaryContainer;

    return Semantics(
      identifier: 'main-nav-create',
      button: true,
      child: Tooltip(
        message: label,
        child: AnimatedScale(
          scale: pressed && !released && animate ? .91 : 1,
          duration: duration,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            key: const ValueKey<String>('organic-liquid-create-orb'),
            duration: duration,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(
                    alpha: pressed ? .40 : released ? .34 : .27,
                  ),
                  blurRadius: pressed ? 14 : released ? 28 : 20,
                  spreadRadius: released ? 4 : 1,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: dark ? .28 : .13),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(tint, Colors.white, dark ? .13 : .55)!
                            .withValues(alpha: .96),
                        tint.withValues(alpha: dark ? .94 : .84),
                        Color.lerp(tint, scheme.primary, .38)!
                            .withValues(alpha: .90),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: dark ? .53 : .91),
                      width: 1.8,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey<String>('main-nav-create'),
                      onTap: onTap,
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 11,
                              right: 11,
                              top: 6,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: .05),
                                      Colors.white.withValues(
                                        alpha: dark ? .48 : .92,
                                      ),
                                      Colors.white.withValues(alpha: .05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: ink, size: 27),
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AnnaJournalTypography.uiFamily,
                                    color: ink,
                                    fontSize: 10,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
