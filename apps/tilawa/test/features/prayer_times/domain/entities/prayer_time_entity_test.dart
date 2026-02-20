import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';

void main() {
  group('PrayerTimeEntity', () {
    // Use a fixed date for reliable testing
    final testDate = DateTime(2024);

    // Helper to create entity with times relative to a base time
    PrayerTimeEntity createEntity({
      required DateTime fajr,
      required DateTime sunrise,
      required DateTime dhuhr,
      required DateTime asr,
      required DateTime maghrib,
      required DateTime isha,
      DateTime? midnight,
      DateTime? lastThird,
    }) {
      return PrayerTimeEntity(
        date: testDate,
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        midnight: midnight ?? maghrib.add(const Duration(hours: 4)),
        lastThird: lastThird ?? maghrib.add(const Duration(hours: 8)),
        latitude: 0,
        longitude: 0,
      );
    }

    test('allPrayers returns correct list of prayers', () {
      final PrayerTimeEntity entity = createEntity(
        fajr: testDate.add(const Duration(hours: 5)),
        sunrise: testDate.add(const Duration(hours: 6)),
        dhuhr: testDate.add(const Duration(hours: 12)),
        asr: testDate.add(const Duration(hours: 15)),
        maghrib: testDate.add(const Duration(hours: 18)),
        isha: testDate.add(const Duration(hours: 20)),
        midnight: testDate.add(const Duration(hours: 23, minutes: 30)),
        lastThird: testDate.add(const Duration(days: 1, hours: 2)),
      );

      final List<PrayerTimeItem> prayers = entity.allPrayers;

      expect(prayers.length, 8);
      expect(prayers[0].type, PrayerType.fajr);
      expect(prayers[1].type, PrayerType.sunrise);
      expect(prayers[2].type, PrayerType.dhuhr);
      expect(prayers[3].type, PrayerType.asr);
      expect(prayers[4].type, PrayerType.maghrib);
      expect(prayers[5].type, PrayerType.isha);
      expect(prayers[6].type, PrayerType.midnight);
      expect(prayers[7].type, PrayerType.lastThird);
    });

    // We can't easily mock DateTime.now() inside the entity without refactoring,
    // so we'll construct the entity such that "now" falls in specific ranges relative to the prayer times.
    // However, since we can't control DateTime.now() in the test environment (unless we use a library like clock),
    // we might have flaky tests if we use real DateTime.now().
    //
    // Wait, the Entity uses DateTime.now() internally:
    // final now = DateTime.now();
    //
    // To properly test this without flakiness or refactoring the entity to accept a clock,
    // we should create prayer times relative to the *current* real time.

    final realNow = DateTime.now();

    test(
      'getCurrentOrNextPrayer returns correct prayer when all are in future',
      () {
        final PrayerTimeEntity entity = createEntity(
          fajr: realNow.add(const Duration(hours: 1)),
          sunrise: realNow.add(const Duration(hours: 2)),
          dhuhr: realNow.add(const Duration(hours: 3)),
          asr: realNow.add(const Duration(hours: 4)),
          maghrib: realNow.add(const Duration(hours: 5)),
          isha: realNow.add(const Duration(hours: 6)),
        );

        expect(entity.getCurrentOrNextPrayer()?.type, PrayerType.fajr);
      },
    );

    test('getCurrentOrNextPrayer returns correct next prayer', () {
      // Fajr passed, Sunrise is next
      final PrayerTimeEntity entity = createEntity(
        fajr: realNow.subtract(const Duration(hours: 1)),
        sunrise: realNow.add(const Duration(hours: 1)),
        dhuhr: realNow.add(const Duration(hours: 2)),
        asr: realNow.add(const Duration(hours: 3)),
        maghrib: realNow.add(const Duration(hours: 4)),
        isha: realNow.add(const Duration(hours: 5)),
      );

      expect(entity.getCurrentOrNextPrayer()?.type, PrayerType.sunrise);
    });

    test('getCurrentOrNextPrayer returns Fajr of next day when all passed', () {
      final PrayerTimeEntity entity = createEntity(
        fajr: realNow.subtract(const Duration(hours: 6)),
        sunrise: realNow.subtract(const Duration(hours: 5)),
        dhuhr: realNow.subtract(const Duration(hours: 4)),
        asr: realNow.subtract(const Duration(hours: 3)),
        maghrib: realNow.subtract(const Duration(hours: 2)),
        isha: realNow.subtract(const Duration(hours: 1)),
      );

      final PrayerTimeItem? next = entity.getCurrentOrNextPrayer();
      expect(next?.type, PrayerType.fajr);
      // Verify it's tomorrow (approximately > 12 hours away, or specifically generic future check)
      expect(next?.time.isAfter(realNow), true);
      // Just to be sure it added a day to the passed fajr
      expect(next?.time.difference(entity.fajr).inHours, closeTo(24, 1));
    });

    test('getPreviousPrayer returns null when all are in future', () {
      final PrayerTimeEntity entity = createEntity(
        fajr: realNow.add(const Duration(hours: 1)),
        sunrise: realNow.add(const Duration(hours: 2)),
        dhuhr: realNow.add(const Duration(hours: 3)),
        asr: realNow.add(const Duration(hours: 4)),
        maghrib: realNow.add(const Duration(hours: 5)),
        isha: realNow.add(const Duration(hours: 6)),
      );

      expect(entity.getPreviousPrayer(), isNull);
    });

    test('getPreviousPrayer returns correct previous prayer', () {
      // Fajr and Sunrise passed
      final PrayerTimeEntity entity = createEntity(
        fajr: realNow.subtract(const Duration(hours: 2)),
        sunrise: realNow.subtract(const Duration(hours: 1)),
        dhuhr: realNow.add(const Duration(hours: 1)),
        asr: realNow.add(const Duration(hours: 2)),
        maghrib: realNow.add(const Duration(hours: 3)),
        isha: realNow.add(const Duration(hours: 4)),
      );

      expect(entity.getPreviousPrayer()?.type, PrayerType.sunrise);
    });

    test('getTimeUntilNextPrayer returns correct duration', () {
      final PrayerTimeEntity entity = createEntity(
        fajr: realNow.add(const Duration(hours: 1)),
        sunrise: realNow.add(const Duration(hours: 2)),
        dhuhr: realNow.add(const Duration(hours: 3)),
        asr: realNow.add(const Duration(hours: 4)),
        maghrib: realNow.add(const Duration(hours: 5)),
        isha: realNow.add(const Duration(hours: 6)),
      );

      final Duration? duration = entity.getTimeUntilNextPrayer();
      expect(duration?.inMinutes, closeTo(60, 1)); // Within 1 minute of 1 hour
    });

    test('hasPrayerPassed returns correct boolean', () {
      final PrayerTimeEntity entity = createEntity(
        fajr: realNow.subtract(const Duration(hours: 1)),
        sunrise: realNow.add(const Duration(hours: 1)),
        dhuhr: realNow.add(const Duration(hours: 2)),
        asr: realNow.add(const Duration(hours: 3)),
        maghrib: realNow.add(const Duration(hours: 4)),
        isha: realNow.add(const Duration(hours: 5)),
      );

      expect(entity.hasPrayerPassed(PrayerType.fajr), true);
      expect(entity.hasPrayerPassed(PrayerType.sunrise), false);
    });
  });
}
