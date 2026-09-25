import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  group('DayTimeline 00-24', () {
    test('covers the complete civil day', () {
      expect(DayTimeline.startHour, 0);
      expect(DayTimeline.endHour, 24);
    });

    test('maps midnight to top and 24:00 to bottom', () {
      expect(DayTimeline.offsetForMinutes(0), 0);
      expect(
        DayTimeline.offsetForMinutes(24 * 60),
        (DayTimeline.endHour - DayTimeline.startHour) *
            DayTimeline.hourHeight,
      );
      expect(
        DayTimeline.offsetForMinutes(12 * 60),
        12 * DayTimeline.hourHeight,
      );
    });

    test('tap mapping progresses chronologically top to bottom', () {
      expect(DayTimeline.minutesForOffset(0), 0);
      expect(
        DayTimeline.minutesForOffset(6 * DayTimeline.hourHeight),
        6 * 60,
      );
      expect(
        DayTimeline.minutesForOffset(18 * DayTimeline.hourHeight),
        18 * 60,
      );
      expect(
        DayTimeline.minutesForOffset(24 * DayTimeline.hourHeight),
        23 * 60 + 45,
      );
    });
  });
}
