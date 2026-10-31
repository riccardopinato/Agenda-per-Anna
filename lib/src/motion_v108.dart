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
                child: Opacity(opacity: value > 1.0 ? 1.0 : value, child: child),
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
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final enabled = AnnaMotionV108.enabled(context);
        final t = enabled
            ? Curves.easeOutCubic.transform(_controller.value)
            : 1.0;
        final drift = enabled ? (1 - t) * (_forward ? 0.022 : -0.022) : 0.0;
        return Opacity(
          opacity: enabled ? 0.76 + 0.24 * t : 1.0,
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
  final bool fan;
  /// Only the approved +Crea sheet uses this top-to-bottom micro-bounce.
  /// All prior calls preserve their original v1.08 animation.
  final bool captureCascade;
  const AnnaMotionStagger({
    super.key,
    required this.child,
    required this.order,
    this.fan = false,
    this.captureCascade = false,
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
      // The prior capture animation delayed every row by 176+100n ms,
      // then moved it by 32% for another 544ms. This felt disconnected
      // from the opening sheet. A shorter overlapping cascade keeps each
      // action responsive while retaining the approved visible micro-bounce.
      final delay = widget.captureCascade
          ? 40 + order * 72
          : order * 60;
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (mounted) setState(() => _shown = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown || !AnnaMotionV108.enabled(context);
    if (widget.captureCascade) {
      return AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, -0.12),
        duration: AnnaMotionV108.duration(context, 420),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: shown ? 1 : 0.976,
          duration: AnnaMotionV108.duration(context, 420),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: AnnaMotionV108.duration(context, 260),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      );
    }
    // The same component serves unrelated, previously approved UI5
    // animations. Their path remains completely unchanged.
    return AnimatedRotation(
      turns: shown || !widget.fan ? 0 : (widget.order - 2) * 0.008,
      duration: AnnaMotionV108.duration(context, 300),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        duration: AnnaMotionV108.duration(context, 280),
        curve: Curves.easeOutCubic,
        offset: shown
            ? Offset.zero
            : widget.fan
                ? Offset((widget.order - 2) * 0.065, 0.10)
                : const Offset(0, 0.06),
        child: AnimatedOpacity(
          duration: AnnaMotionV108.duration(context, 280),
          curve: Curves.easeOutCubic,
          opacity: shown ? 1 : 0,
          child: widget.child,
        ),
      ),
    );
  }
}

/// M16: real photo pair only. The source records and existing detail actions
/// remain canonical; this widget owns only temporary presentation selection.
class AnnaThenNowWipe extends StatefulWidget {
  final DiaryBlock before;
  final DiaryBlock after;
  final String beforeLabel;
  final String afterLabel;
  const AnnaThenNowWipe({
    super.key,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
  });

  @override
  State<AnnaThenNowWipe> createState() => _AnnaThenNowWipeState();
}

class _AnnaThenNowWipeState extends State<AnnaThenNowWipe> {
  bool _showAfter = false;

  Widget _photo(DiaryBlock block) => DiaryMediaImage(
        assetId: block.mediaThumbnailAssetId.isNotEmpty
            ? block.mediaThumbnailAssetId : block.mediaAssetId,
        fallbackBase64: block.imageBase64,
        fit: BoxFit.cover,
      );

  @override
  Widget build(BuildContext context) {
    final enabled = AnnaMotionV108.enabled(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 178,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(child: _photo(widget.before)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _showAfter ? 1 : 0),
                    duration: enabled
                        ? const Duration(milliseconds: 460)
                        : Duration.zero,
                    curve: Curves.easeInOutCubic,
                    builder: (context, fraction, child) => ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction,
                        child: child,
                      ),
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: 178,
                      child: _photo(widget.after),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: Text(widget.beforeLabel),
              selected: !_showAfter,
              onSelected: (_) => setState(() => _showAfter = false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(widget.afterLabel),
              selected: _showAfter,
              onSelected: (_) => setState(() => _showAfter = true),
            ),
          ],
        ),
      ],
    );
  }
}

class AnnaMotionMapEntry extends StatelessWidget {
  final Widget child;
  const AnnaMotionMapEntry({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: AnnaMotionV108.duration(context, 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: value, child: child),
      ),
      child: child,
    );
  }
}

class AnnaMotionMapPin extends StatefulWidget {
  final int count;
  final int order;
  final VoidCallback onPressed;
  const AnnaMotionMapPin({
    super.key,
    required this.count,
    this.order = 0,
    required this.onPressed,
  });
  @override
  State<AnnaMotionMapPin> createState() => _AnnaMotionMapPinState();
}
class _AnnaMotionMapPinState extends State<AnnaMotionMapPin> {
  bool _pressed = false;
  bool _busy = false;
  Future<void> _tap() async {
    if (_busy) return;
    _busy = true;
    unawaited(AnnaFeedback.selection());
    if (AnnaMotionV108.enabled(context)) {
      setState(() => _pressed = true);
      await Future<void>.delayed(const Duration(milliseconds: 155));
    }
    if (!mounted) return;
    setState(() => _pressed = false);
    _busy = false;
    widget.onPressed();
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnnaMotionStagger(
      order: widget.order,
      child: AnimatedScale(
      scale: _pressed ? 1.24 : 1,
      duration: AnnaMotionV108.duration(context, 180),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: AnnaMotionV108.duration(context, 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? <BoxShadow>[BoxShadow(
                  color: color.withValues(alpha: 0.27),
                  blurRadius: 17, spreadRadius: 4)]
              : const <BoxShadow>[],
        ),
        child: IconButton.filled(
          iconSize: 18,
          onPressed: _tap,
          icon: Text('${widget.count}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
      ),
    );
  }
}
