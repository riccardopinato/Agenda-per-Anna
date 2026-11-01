import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C1 permission is not delivery', () {
    expect(assessCapability(supported: false, permissionGranted: true,
      serviceAvailable: true), CapabilityHealthState.unsupported);
    expect(assessCapability(supported: true, permissionGranted: null,
      serviceAvailable: true), CapabilityHealthState.unknown);
    expect(assessCapability(supported: true, permissionGranted: false,
      serviceAvailable: true), CapabilityHealthState.permissionRequired);
    expect(assessCapability(supported: true, permissionGranted: true,
      serviceAvailable: false), CapabilityHealthState.unavailable);
    expect(assessCapability(supported: true, permissionGranted: true,
      serviceAvailable: true, configured: false), CapabilityHealthState.degraded);
    expect(assessCapability(supported: true, permissionGranted: true,
      serviceAvailable: true, error: true), CapabilityHealthState.degraded);
    expect(assessCapability(supported: true, permissionGranted: true,
      serviceAvailable: true), CapabilityHealthState.available);
    expect(CapabilityHealthState.values.map((s) => s.name),
      isNot(contains('healthy')));
  });

  test('C1 supports five product languages and English fallback', () {
    for (final code in ['en', 'it', 'es', 'fr', 'pt']) {
      for (final key in ['title', 'intro', 'notifications', 'reminders',
        'push', 'calendarRead', 'calendarWrite', 'unknown',
        'unsupported', 'permissionRequired', 'degraded', 'unavailable',
        'available', 'nativeOnly', 'notDelivered', 'checkFailed',
        'syncUnknown', 'refresh']) {
        expect(capabilityHealthCopy(code, key), isNotEmpty);
      }
    }
    expect(capabilityHealthCopy('de', 'title'),
      capabilityHealthCopy('en', 'title'));
  });
}
