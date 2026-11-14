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
