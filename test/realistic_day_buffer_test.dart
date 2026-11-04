import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('realistic day retains source free time; buffer is user-selected', () {
    final day = DateTime(2026, 11, 4);
    final original = RealisticDayAdvisor.evaluate(
      day:day, visibleEntries: const [], pendingTasks:2,
    );
    final buffered = RealisticDayAdvisor.evaluate(
      day:day, visibleEntries: const [], pendingTasks:2,
      bufferMinutes:60,
    );
    expect(original.freeMinutes, 720);
    expect(buffered.freeMinutes, original.freeMinutes);
    expect(buffered.bufferMinutes, 60);
    expect(buffered.usableMinutes, original.freeMinutes - 60);
    expect(buffered.firstFreeSlot, isNotNull);
  });

  test('buffer is clamped and cannot manufacture negative capacity', () {
    final a=RealisticDayAdvice(
      freeMinutes: 15,pendingTasks:3,reasonCode:'VISIBLE_WINDOW_CONGESTED',
      firstFreeSlot:null,bufferMinutes:60,
    );
    expect(a.usableMinutes,0);
    final b=RealisticDayAdvisor.evaluate(
      day: DateTime(2026,11,4),
      visibleEntries:const [],pendingTasks:0,bufferMinutes:10000);
    expect(b.bufferMinutes,120);
    expect(b.usableMinutes,600);
  });

  test('never estimates task duration from count', () {
    final a=RealisticDayAdvisor.evaluate(
      day:DateTime(2026,11,4),visibleEntries:const [],
      pendingTasks:0,bufferMinutes:30);
    final b=RealisticDayAdvisor.evaluate(
      day:DateTime(2026,11,4),visibleEntries:const [],
      pendingTasks:100,bufferMinutes:30);
    expect(a.usableMinutes,b.usableMinutes);
    expect(a.pendingTasks,0);
    expect(b.pendingTasks,100);
  });
}
