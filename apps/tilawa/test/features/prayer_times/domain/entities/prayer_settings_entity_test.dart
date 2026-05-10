import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';

void main() {
  group('PrayerSettingsEntity scheduling location', () {
    test('uses manual saved location before last resolved location', () {
      const settings = PrayerSettingsEntity(
        savedLatitude: 30,
        savedLongitude: 31,
        savedLocationName: 'Manual',
        lastResolvedLatitude: 40,
        lastResolvedLongitude: 41,
        lastResolvedLocationName: 'Auto',
      );

      expect(settings.effectiveSchedulingLatitude, 30);
      expect(settings.effectiveSchedulingLongitude, 31);
      expect(settings.effectiveSchedulingLocationName, 'Manual');
    });

    test(
      'falls back to last resolved location when no manual location exists',
      () {
        const settings = PrayerSettingsEntity(
          lastResolvedLatitude: 40,
          lastResolvedLongitude: 41,
          lastResolvedLocationName: 'Auto',
        );

        expect(settings.effectiveSchedulingLatitude, 40);
        expect(settings.effectiveSchedulingLongitude, 41);
        expect(settings.effectiveSchedulingLocationName, 'Auto');
      },
    );
  });
}
