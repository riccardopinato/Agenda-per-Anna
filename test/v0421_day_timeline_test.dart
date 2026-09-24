import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('day timeline covers the full 00:00-24:00 day', () {
    expect(DayTimeline.startHour, 0);
    expect(DayTimeline.endHour, 24);

    expect(DayTimeline.offsetForMinutes(0), 0);
    expect(
      DayTimeline.offsetForMinutes(12 * 60),
      12 * DayTimeline.hourHeight,
    );
    expect(
      DayTimeline.offsetForMinutes(24 * 60),
      24 * DayTimeline.hourHeight,
    );
  });

  test('timeline minute mapping runs chronologically top to bottom', () {
    expect(DayTimeline.minutesForOffset(0), 0);
    expect(
      DayTimeline.minutesForOffset(6 * DayTimeline.hourHeight),
      6 * 60,
    );
    expect(
      DayTimeline.minutesForOffset(12 * DayTimeline.hourHeight),
      12 * 60,
    );
    expect(
      DayTimeline.minutesForOffset(24 * DayTimeline.hourHeight),
      24 * 60,
    );

    expect(
      DayTimeline.minutesForOffset(18 * DayTimeline.hourHeight),
      greaterThan(
        DayTimeline.minutesForOffset(8 * DayTimeline.hourHeight),
      ),
    );
  });
}
