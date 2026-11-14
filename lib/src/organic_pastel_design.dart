part of '../main.dart';

/// Original, code-rendered decorative artwork for the Organic Pastel experiment.
/// Pure presentation: never substitutes for personal photos or shared avatars.
abstract final class AnnaOrganicPastel {
  static const Color canvas = Color(0xFFFFF9F3);
  static const Color paper = Color(0xFFFFFDF9);
  static const Color olive = Color(0xFF899657);
  static const Color oliveInk = Color(0xFF526738);
  static const Color ink = Color(0xFF27352C);
  static const Color quietInk = Color(0xFF626C61);
  static const Color border = Color(0xFFE7DED2);
  static const Color peach = Color(0xFFF9DFC8);

  static bool enabled(BuildContext context) =>
      AnnaEditorialTodayMode.enabled.value;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : paper;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSurface
          : ink;

  static Color selection(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFA8B77C)
          : olive;
}

/// Illustration is a lightweight scalable CustomPainter: no new image
/// package, no remote asset dependency, no synthetic user media.
class AnnaOrganicPastelLandscape extends StatelessWidget {
  final double height;
  final double radius;

  const AnnaOrganicPastelLandscape({
    super.key,
    this.height = 96,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            key: const ValueKey<String>('organic-pastel-landscape'),
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _AnnaOrganicPastelLandscapePainter(
                Theme.of(context).brightness,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnaOrganicPastelLandscapePainter extends CustomPainter {
  final Brightness brightness;

  const _AnnaOrganicPastelLandscapePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final dark = brightness == Brightness.dark;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xFF293C3A), Color(0xFF53615D)]
            : const [Color(0xFFFFF8EA), Color(0xFFF3E7CE)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final sun = Paint()
      ..color = dark
          ? const Color(0xFFE6CDA0).withValues(alpha: 0.75)
          : const Color(0xFFF7D9A0);
    canvas.drawCircle(Offset(w * .72, h * .31), h * .17, sun);

    void hill(
      Color color,
      double yLeft,
      double yMid,
      double yRight,
      double curve,
    ) {
      final path = Path()
        ..moveTo(0, h)
        ..lineTo(0, h * yLeft)
        ..quadraticBezierTo(w * .24, h * curve, w * .51, h * yMid)
        ..quadraticBezierTo(w * .79, h * (curve + .035), w, h * yRight)
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    hill(
      dark ? const Color(0xFF647A70) : const Color(0xFFD4DDCF),
      .64, .55, .65, .36,
    );
    hill(
      dark ? const Color(0xFF5A7569) : const Color(0xFFB5C9B6),
      .76, .57, .64, .43,
    );
    hill(
      dark ? const Color(0xFF486E5B) : const Color(0xFF9FB99A),
      .76, .75, .79, .62,
    );
    hill(
      dark ? const Color(0xFF355A49) : const Color(0xFF84A079),
      .93, .79, .90, .73,
    );
    hill(
      dark ? const Color(0xFF2B5140) : const Color(0xFF7D986B),
      .98, .94, .98, .88,
    );

    final grass = Paint()
      ..color = dark ? const Color(0xFF294A3B) : const Color(0xFF68855B)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 27; i++) {
      final x = (i * 67.0 + 19) % w;
      final y = h * (.88 + .08 * sin(i * 2.2));
      canvas.drawLine(Offset(x, y), Offset(x - 2.5, y - 6), grass);
      canvas.drawLine(Offset(x, y), Offset(x + 3.0, y - 7), grass);
    }

    final leaves = Paint()
      ..color = dark ? const Color(0xFFADC092) : const Color(0xFF718D55)
      ..style = PaintingStyle.fill;
    // Restrained corner foliage stays outside the text/content layer.
    for (var i = 0; i < 5; i++) {
      final x = w - 11 - i * 11.0;
      final y = 5 + i * 5.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-.45 + i * .13);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 15, height: 6),
        leaves,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AnnaOrganicPastelLandscapePainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}

/// Real seven-day navigation; all dates use the active locale and canonical
/// PlannerScreen._selectDay owner. It adds no persistent selection state.
class AnnaOrganicPastelWeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  const AnnaOrganicPastelWeekStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(
      selected.year,
      selected.month,
      selected.day - (selected.weekday - DateTime.monday),
    );
    final lang = AnnaStrings.intlLocale(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      key: const ValueKey<String>('organic-pastel-week-strip'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: AnnaOrganicPastel.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? border : AnnaOrganicPastel.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Builder(builder: (context) {
                final date = first.add(Duration(days: i));
                final active = AgendaStore.sameDay(date, selected);
                final label = DateFormat('EEE', lang).format(date);
                return Semantics(
                  button: true,
                  selected: active,
                  label: DateFormat('EEEE d MMMM y', lang).format(date),
                  child: InkWell(
                    key: ValueKey<String>(
                      'organic-week-day-${date.year}-${date.month}-${date.day}',
                    ),
                    onTap: () => onSelected(date),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 48,
                      constraints: const BoxConstraints(minHeight: 54),
                      decoration: BoxDecoration(
                        color: active
                            ? AnnaOrganicPastel.selection(context)
                                .withValues(alpha: dark ? .44 : .38)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: AnnaOrganicPastel.text(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AnnaOrganicPastel.text(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// An explicitly decorative avatar: not a guessed photo of group members.
class AnnaOrganicPastelGroupAvatar extends StatelessWidget {
  const AnnaOrganicPastelGroupAvatar({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AnnaOrganicPastel.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.landscape_outlined,
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurface
              : AnnaOrganicPastel.oliveInk,
          size: 23,
          semanticLabel: null,
        ),
      );
}


/// Compact real-data agenda digest used only when the selected day has actual
/// entries. No invented tasks, no second editor, and no hidden private titles.
class AnnaOrganicPastelAgendaDigest extends StatelessWidget {
  final List<UnifiedAgendaEntry> entries;
  final bool hideDetails;
  final ValueChanged<UnifiedAgendaEntry> onOpenEntry;
  final VoidCallback onOpenDay;

  const AnnaOrganicPastelAgendaDigest({
    super.key,
    required this.entries,
    required this.hideDetails,
    required this.onOpenEntry,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final visible = entries.take(3).toList(growable: false);
    return AnnaEditorialSurface(
      key: const ValueKey<String>('organic-pastel-agenda-digest'),
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.d3('ui5Commitments'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenDay,
                child: Text(strings.d3('ui5ShowAll')),
              ),
            ],
          ),
          for (final entry in visible)
            InkWell(
              onTap: () => onOpenEntry(entry),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Icon(
                      entry.done
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : AnnaOrganicPastel.oliveInk,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hideDetails ? '•••' : entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Bespoke paper surface. Material is retained only as an invisible ink/focus
/// interaction host: visual shape, paper palette and elevation are *not* M3.
/// Keys remain on caller widgets so historic source/widget contracts survive.
class AnnaOrganicPaperSurface extends StatelessWidget {
  final Widget child;
  final AnnaEditorialSurfaceTone tone;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AnnaOrganicPaperSurface({
    super.key,
    required this.child,
    this.tone = AnnaEditorialSurfaceTone.regular,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final featured = tone == AnnaEditorialSurfaceTone.featured;
    final quiet = tone == AnnaEditorialSurfaceTone.quiet;
    final radius = BorderRadius.circular(featured ? 23 : 17);
    final paperTop = dark
        ? (featured ? const Color(0xFF35443B) : const Color(0xFF27352E))
        : featured
            ? const Color(0xFFFBF3E5)
            : quiet
                ? const Color(0xFFF4F2E8)
                : AnnaOrganicPastel.paper;
    final paperBottom = dark
        ? (featured ? const Color(0xFF293C35) : const Color(0xFF26372F))
        : featured
            ? const Color(0xFFF7EBD9)
            : quiet
                ? const Color(0xFFF1EFE2)
                : const Color(0xFFFFFBF4);
    final content = Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            featured ? 18 : 14,
            featured ? 15 : 12,
            featured ? 18 : 14,
            featured ? 15 : 12,
          ),
      child: child,
    );
    return Semantics(
      container: onTap != null,
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [paperTop, paperBottom],
          ),
          border: Border.all(
            color: dark ? const Color(0xFF546556) : AnnaOrganicPastel.border,
            width: .9,
          ),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF6F664F))
                  .withValues(alpha: dark ? .17 : .075),
              blurRadius: featured ? 15 : 10,
              offset: Offset(0, featured ? 6 : 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _AnnaOrganicPaperFibrePainter(dark),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: onTap == null ? 0 : 48,
                    ),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnaOrganicPaperFibrePainter extends CustomPainter {
  final bool dark;
  const _AnnaOrganicPaperFibrePainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dark
          ? const Color(0xFFE2D4AE).withValues(alpha: .022)
          : const Color(0xFF8F816D).withValues(alpha: .048);
    if (size.isEmpty) return;
    // Deterministic, near-invisible fibres — print texture, not noise.
    for (var i = 0; i < 80; i++) {
      final x = ((i * 47 + 13) % 101) / 101 * size.width;
      final y = ((i * 71 + 29) % 103) / 103 * size.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: i.isEven ? 1.15 : .65,
          height: .65,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnnaOrganicPaperFibrePainter previous) =>
      previous.dark != dark;
}

/// Distinct olive action, keeping only the low-level Flutter accessibility
/// and input handling. No Material FilledButton, themed shadow or M3 tokens.
class AnnaOrganicPastelAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool subtle;

  const AnnaOrganicPastelAction({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = subtle
        ? AnnaOrganicPastel.text(context)
        : Colors.white;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: subtle
                  ? null
                  : LinearGradient(
                      colors: dark
                          ? const [Color(0xFF738D57), Color(0xFF566D49)]
                          : const [Color(0xFF849453), Color(0xFF657840)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: subtle
                  ? (dark
                      ? const Color(0xFF405344)
                      : const Color(0xFFEDEDD9))
                  : null,
              border: Border.all(
                color: subtle
                    ? (dark
                        ? const Color(0xFF66775E)
                        : const Color(0xFFCCD0AE))
                    : const Color(0xFF879963),
              ),
              boxShadow: onPressed == null || subtle
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF56693D)
                            .withValues(alpha: dark ? .13 : .16),
                        blurRadius: 9,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AnnaJournalTypography.uiFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ).copyWith(color: foreground),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 17, color: foreground),
                    ],
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

/// Deliberately compact custom shared-space row; the caller still owns all
/// data, membership, read-count, rename and opening callbacks.
class AnnaOrganicPastelGroupRow extends StatelessWidget {
  final String title;
  final String detail;
  final int unread;
  final VoidCallback onOpen;
  final VoidCallback? onRename;
  final String renameTooltip;
  final String renameKey;

  const AnnaOrganicPastelGroupRow({
    super.key,
    required this.title,
    required this.detail,
    required this.unread,
    required this.onOpen,
    required this.onRename,
    required this.renameTooltip,
    required this.renameKey,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : AnnaOrganicPastel.quietInk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnnaOrganicPaperSurface(
        onTap: onOpen,
        semanticLabel: title,
        padding: const EdgeInsets.fromLTRB(10, 9, 7, 9),
        child: Row(
          children: [
            const AnnaOrganicPastelGroupAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AnnaJournalTypography.editorial(
                      context, size: 17,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AnnaOrganicPastel.text(context),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted,
                      height: 1.22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AnnaOrganicPastel.peach,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: AnnaOrganicPastel.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            IconButton(
              key: ValueKey<String>(renameKey),
              tooltip: renameTooltip,
              onPressed: onRename,
              icon: Icon(Icons.more_horiz, size: 21, color: muted),
              constraints: const BoxConstraints(
                minHeight: 48, minWidth: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
