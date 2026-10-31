part of '../main.dart';

/// v1.08: presentation only. Never alters canonical navigation, models or stores.
abstract final class AnnaMotionV108 {
  static bool enabled(BuildContext context) =>
      AnnaDesignTokens.animationsEnabled(context);

  static Duration duration(BuildContext context, int milliseconds) =>
      enabled(context) ? Duration(milliseconds: milliseconds) : Duration.zero;

  /// Invoke only after a canonical save Future has completed successfully.
  static void showSaveSuccess(BuildContext context) {
    if (!context.mounted) return;
    unawaited(AnnaFeedback.success());
    if (!enabled(context)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final color = Theme.of(context).colorScheme.primary;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        bottom: MediaQuery.paddingOf(overlayContext).bottom + 110,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(overlayContext).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(
                    color: color.withValues(alpha: 0.26),
                    blurRadius: 23,
                    spreadRadius: 5,
                  )],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17, vertical: 11),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, color: color, size: 16),
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: color, size: 29),
                    const SizedBox(width: 8),
                    Icon(Icons.auto_awesome, color: color, size: 13),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 670), () {
      entry.remove();
      entry.dispose();
    });
  }
}

/// Animates the new visible page, keeping the entire existing child subtree
/// (including scroll controllers and StatefulWidgets) mounted across updates.
class AnnaMotionReveal extends StatefulWidget {
  final int token;
  final Widget child;
  final Axis axis;
  const AnnaMotionReveal({
    super.key,
    required this.token,
    required this.child,
    this.axis = Axis.horizontal,
  });
  @override
  State<AnnaMotionReveal> createState() => _AnnaMotionRevealState();
}

class _AnnaMotionRevealState extends State<AnnaMotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 310),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant AnnaMotionReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token == oldWidget.token) return;
    _forward = widget.token > oldWidget.token;
    if (AnnaMotionV108.enabled(context)) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AnnaMotionV108.enabled(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final drift = (1 - t) * (_forward ? 0.022 : -0.022);
        return Opacity(
          opacity: 0.76 + 0.24 * t,
          child: FractionalTranslation(
            translation: widget.axis == Axis.horizontal
                ? Offset(drift, 0) : Offset(0, drift),
            child: child,
          ),
        );
      },
    );
  }
}

/// Entrance runs only for a newly mounted visible item. Delayed work is bounded
/// and cancelled safely by the widget's mounted check.
class AnnaMotionStagger extends StatefulWidget {
  final Widget child;
  final int order;
  const AnnaMotionStagger({
    super.key,
    required this.child,
    required this.order,
  });
  @override
  State<AnnaMotionStagger> createState() => _AnnaMotionStaggerState();
}

class _AnnaMotionStaggerState extends State<AnnaMotionStagger> {
  bool _shown = false;
  bool _scheduled = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AnnaMotionV108.enabled(context)) {
        setState(() => _shown = true);
        return;
      }
      final order = widget.order.clamp(0, 4);
      Future<void>.delayed(Duration(milliseconds: order * 60), () {
        if (mounted) setState(() => _shown = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AnnaMotionV108.enabled(context)) return widget.child;
    return AnimatedSlide(
      duration: AnnaMotionV108.duration(context, 280),
      curve: Curves.easeOutCubic,
      offset: _shown ? Offset.zero : const Offset(0, 0.06),
      child: AnimatedOpacity(
        duration: AnnaMotionV108.duration(context, 280),
        opacity: _shown ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
