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
              // One continuous tinted glass surface, not four separate tiles.
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0, .25, .5, .75, 1],
                colors: [
                  for (final index in [0, 1])
                    Color.lerp(
                      scheme.surface,
                      Color.lerp(
                        scheme.primary,
                        AnnaOrganicLiquidTab._pastels[index],
                        .58,
                      ),
                      dark ? .14 : .20,
                    )!.withValues(alpha: dark ? .88 : .77),
                  scheme.surface.withValues(alpha: dark ? .86 : .74),
                  for (final index in [2, 3])
                    Color.lerp(
                      scheme.surface,
                      Color.lerp(
                        scheme.primary,
                        AnnaOrganicLiquidTab._pastels[index],
                        .58,
                      ),
                      dark ? .14 : .20,
                    )!.withValues(alpha: dark ? .88 : .77),
                ],
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

/// Four soft color pools fused into the dock, rather than raised capsules.
/// The selection is signaled by a diffuse glow, icon and text weight only.
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
    final foreground = selected ? scheme.onSurface : scheme.onSurfaceVariant;

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
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              child: AnimatedContainer(
                key: ValueKey<String>('liquid-integrated-tab-$page'),
                duration: duration,
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 48),
                // No outline, individual drop shadow or hard-edged card.
                // The radial wash fades entirely into the shared backdrop.
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.20),
                    radius: .74,
                    stops: const [0, .55, 1],
                    colors: [
                      tint.withValues(
                        alpha: selected ? (dark ? .38 : .34) : 0,
                      ),
                      tint.withValues(
                        alpha: selected ? (dark ? .14 : .12) : 0,
                      ),
                      tint.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(1, 5, 1, 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Color.lerp(foreground, tint, dark ? .16 : .12)!,
                        size: 21,
                      ),
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
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Opaque gel prevents the dock edge or any underlying
                  // line from showing through the Create action.
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(tint, Colors.white, dark ? .13 : .40)!,
                      tint,
                      Color.lerp(tint, scheme.primary, .38)!,
                    ],
                  ),
                  border: Border.all(
                    color: Color.lerp(tint, scheme.surface, dark ? .31 : .67)!,
                    width: 1.3,
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
                      child: Column(
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
