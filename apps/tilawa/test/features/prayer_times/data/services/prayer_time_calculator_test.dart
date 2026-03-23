import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/data/services/prayer_time_calculator.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';

void main() {
  late PrayerTimeCalculator calculator;

  setUp(() {
    calculator = PrayerTimeCalculator();
  });

  group('PrayerTimeCalculator', () {
    group('Cairo, Egypt - Egyptian Method', () {
      // Cairo coordinates: 30.0444° N, 31.2357° E
      const cairoLatitude = 30.0444;
      const cairoLongitude = 31.2357;

      const egyptianSettings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.egyptian,
      );

      test('calculates prayer times for January 8, 2026', () {
        final date = DateTime(2026, 1, 8);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: cairoLatitude,
          longitude: cairoLongitude,
          date: date,
          settings: egyptianSettings,
        );

        // Verify basic structure
        expect(result.date, equals(date));
        expect(result.latitude, equals(cairoLatitude));
        expect(result.longitude, equals(cairoLongitude));

        // Verify prayer order: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
        expect(
          result.fajr.isBefore(result.sunrise),
          isTrue,
          reason: 'Fajr should be before Sunrise',
        );
        expect(
          result.sunrise.isBefore(result.dhuhr),
          isTrue,
          reason: 'Sunrise should be before Dhuhr',
        );
        expect(
          result.dhuhr.isBefore(result.asr),
          isTrue,
          reason: 'Dhuhr should be before Asr',
        );
        expect(
          result.asr.isBefore(result.maghrib),
          isTrue,
          reason: 'Asr should be before Maghrib',
        );
        expect(
          result.maghrib.isBefore(result.isha),
          isTrue,
          reason: 'Maghrib should be before Isha',
        );

        // Verify reasonable time ranges for Cairo in January
        // Fajr: around 5:15-5:30 AM
        expect(result.fajr.hour, inInclusiveRange(5, 6));

        // Sunrise: around 6:45-7:00 AM
        expect(result.sunrise.hour, inInclusiveRange(6, 7));

        // Dhuhr: around 11:55-12:10 PM
        expect(result.dhuhr.hour, inInclusiveRange(11, 12));

        // Asr: around 2:45-3:00 PM
        expect(result.asr.hour, inInclusiveRange(14, 15));

        // Maghrib: around 5:05-5:20 PM
        expect(result.maghrib.hour, inInclusiveRange(17, 18));

        // Isha (Egyptian method, 17.5° angle): around 6:25-6:45 PM
        expect(result.isha.hour, inInclusiveRange(18, 19));
      });

      test('calculates prayer times for summer date (July 15)', () {
        final date = DateTime(2026, 7, 15);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: cairoLatitude,
          longitude: cairoLongitude,
          date: date,
          settings: egyptianSettings,
        );

        // In summer, days are longer
        // Fajr should be earlier (around 3:15-3:30 AM)
        expect(result.fajr.hour, inInclusiveRange(3, 4));

        // Maghrib should be later (around 7:00 PM)
        expect(result.maghrib.hour, inInclusiveRange(18, 19));

        // Prayer order still valid
        expect(result.fajr.isBefore(result.sunrise), isTrue);
        expect(result.maghrib.isBefore(result.isha), isTrue);
      });
    });

    group('Mecca, Saudi Arabia - Umm Al-Qura Method', () {
      // Mecca coordinates: 21.4225° N, 39.8262° E
      const meccaLatitude = 21.4225;
      const meccaLongitude = 39.8262;

      const ummAlQuraSettings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.ummAlQura,
      );

      test('Isha is 90 minutes after Maghrib for Umm Al-Qura method', () {
        final date = DateTime(2026, 1, 8);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: meccaLatitude,
          longitude: meccaLongitude,
          date: date,
          settings: ummAlQuraSettings,
        );

        // Isha should be exactly 90 minutes after Maghrib for Umm Al-Qura
        final DateTime expectedIsha = result.maghrib.add(
          const Duration(minutes: 90),
        );

        expect(result.isha.hour, equals(expectedIsha.hour));
        expect(result.isha.minute, equals(expectedIsha.minute));
      });

      test('prayer times are in correct order', () {
        final date = DateTime(2026, 1, 8);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: meccaLatitude,
          longitude: meccaLongitude,
          date: date,
          settings: ummAlQuraSettings,
        );

        expect(result.fajr.isBefore(result.sunrise), isTrue);
        expect(result.sunrise.isBefore(result.dhuhr), isTrue);
        expect(result.dhuhr.isBefore(result.asr), isTrue);
        expect(result.asr.isBefore(result.maghrib), isTrue);
        expect(result.maghrib.isBefore(result.isha), isTrue);
      });
    });

    group('Karachi, Pakistan - Karachi Method', () {
      // Karachi coordinates: 24.8607° N, 67.0011° E
      const karachiLatitude = 24.8607;
      const karachiLongitude = 67.0011;

      const karachiSettings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.karachi,
        asrJuristicMethod: AsrJuristicMethod.hanafi,
      );

      test('Hanafi Asr time is later than Shafii', () {
        final date = DateTime(2026, 1, 8);

        const shafiiSettings = PrayerSettingsEntity(
          calculationMethod: CalculationMethod.karachi,
        );

        final PrayerTimeEntity resultHanafi = calculator.calculatePrayerTimes(
          latitude: karachiLatitude,
          longitude: karachiLongitude,
          date: date,
          settings: karachiSettings,
        );

        final PrayerTimeEntity resultShafii = calculator.calculatePrayerTimes(
          latitude: karachiLatitude,
          longitude: karachiLongitude,
          date: date,
          settings: shafiiSettings,
        );

        // Hanafi Asr should be later than Shafii Asr
        expect(
          resultHanafi.asr.isAfter(resultShafii.asr),
          isTrue,
          reason: 'Hanafi Asr should be later than Shafii Asr',
        );
      });
    });

    group('New York, USA - ISNA Method', () {
      // New York coordinates: 40.7128° N, 74.0060° W
      const newYorkLatitude = 40.7128;
      const newYorkLongitude = -74.0060;

      const isnaSettings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.isna,
      );

      test('calculates prayer times for negative longitude', () {
        final date = DateTime(2026, 1, 8);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: newYorkLatitude,
          longitude: newYorkLongitude,
          date: date,
          settings: isnaSettings,
        );

        // Verify all times are valid DateTime objects for the correct date
        expect(result.date, equals(date));
        expect(result.fajr.day, equals(date.day));
        expect(result.isha.day, equals(date.day));

        // Verify coordinates are stored correctly
        expect(result.latitude, equals(newYorkLatitude));
        expect(result.longitude, equals(newYorkLongitude));
      });
    });

    group('Different Calculation Methods', () {
      const testLatitude = 30.0;
      const testLongitude = 31.0;
      final testDate = DateTime(2026, 1, 8);

      test('all calculation methods produce valid prayer times', () {
        for (final CalculationMethod method in CalculationMethod.values) {
          final settings = PrayerSettingsEntity(calculationMethod: method);

          final PrayerTimeEntity result = calculator.calculatePrayerTimes(
            latitude: testLatitude,
            longitude: testLongitude,
            date: testDate,
            settings: settings,
          );

          // All methods should produce valid prayer order
          expect(
            result.fajr.isBefore(result.sunrise),
            isTrue,
            reason: '$method: Fajr should be before Sunrise',
          );
          expect(
            result.sunrise.isBefore(result.dhuhr),
            isTrue,
            reason: '$method: Sunrise should be before Dhuhr',
          );
          expect(
            result.dhuhr.isBefore(result.asr),
            isTrue,
            reason: '$method: Dhuhr should be before Asr',
          );
          expect(
            result.asr.isBefore(result.maghrib),
            isTrue,
            reason: '$method: Asr should be before Maghrib',
          );
          expect(
            result.maghrib.isBefore(result.isha),
            isTrue,
            reason: '$method: Maghrib should be before Isha',
          );
        }
      });

      test('methods using ishaMinutes calculate Isha correctly', () {
        final List<CalculationMethod> methodsWithIshaMinutes = [
          CalculationMethod.ummAlQura,
          CalculationMethod.gulf,
          CalculationMethod.qatar,
        ];

        for (final method in methodsWithIshaMinutes) {
          final settings = PrayerSettingsEntity(calculationMethod: method);

          final PrayerTimeEntity result = calculator.calculatePrayerTimes(
            latitude: testLatitude,
            longitude: testLongitude,
            date: testDate,
            settings: settings,
          );

          // Isha should be 90 minutes after Maghrib for these methods
          final DateTime expectedIsha = result.maghrib.add(
            const Duration(minutes: 90),
          );

          expect(
            result.isha.hour,
            equals(expectedIsha.hour),
            reason: '$method: Isha hour should be 90 min after Maghrib',
          );
          expect(
            result.isha.minute,
            equals(expectedIsha.minute),
            reason: '$method: Isha minute should be 90 min after Maghrib',
          );
        }
      });
    });

    group('Prayer Time Adjustments', () {
      const latitude = 30.0;
      const longitude = 31.0;
      final date = DateTime(2026, 1, 8);

      test('positive adjustments delay prayer times', () {
        const baseSettings = PrayerSettingsEntity(
          calculationMethod: CalculationMethod.egyptian,
        );

        const adjustedSettings = PrayerSettingsEntity(
          calculationMethod: CalculationMethod.egyptian,
          fajrAdjustment: 5,
          dhuhrAdjustment: 5,
          asrAdjustment: 5,
          maghribAdjustment: 5,
          ishaAdjustment: 5,
        );

        final PrayerTimeEntity baseResult = calculator.calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: date,
          settings: baseSettings,
        );

        final PrayerTimeEntity adjustedResult = calculator.calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: date,
          settings: adjustedSettings,
        );

        // Adjusted times should be 5 minutes later
        expect(
          adjustedResult.fajr.difference(baseResult.fajr).inMinutes,
          equals(5),
        );
        expect(
          adjustedResult.dhuhr.difference(baseResult.dhuhr).inMinutes,
          equals(5),
        );
        expect(
          adjustedResult.asr.difference(baseResult.asr).inMinutes,
          equals(5),
        );
        expect(
          adjustedResult.maghrib.difference(baseResult.maghrib).inMinutes,
          equals(5),
        );
        expect(
          adjustedResult.isha.difference(baseResult.isha).inMinutes,
          equals(5),
        );
      });

      test('negative adjustments advance prayer times', () {
        const baseSettings = PrayerSettingsEntity(
          calculationMethod: CalculationMethod.egyptian,
        );

        const adjustedSettings = PrayerSettingsEntity(
          calculationMethod: CalculationMethod.egyptian,
          fajrAdjustment: -3,
        );

        final PrayerTimeEntity baseResult = calculator.calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: date,
          settings: baseSettings,
        );

        final PrayerTimeEntity adjustedResult = calculator.calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: date,
          settings: adjustedSettings,
        );

        // Adjusted Fajr should be 3 minutes earlier
        expect(
          baseResult.fajr.difference(adjustedResult.fajr).inMinutes,
          equals(3),
        );
      });
    });

    group('Date Range Calculation', () {
      const latitude = 30.0;
      const longitude = 31.0;
      const settings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.egyptian,
      );

      test('calculates prayer times for a week', () {
        final startDate = DateTime(2026);
        final endDate = DateTime(2026, 1, 7);

        final List<PrayerTimeEntity> results = calculator
            .calculatePrayerTimesForRange(
              latitude: latitude,
              longitude: longitude,
              startDate: startDate,
              endDate: endDate,
              settings: settings,
            );

        expect(results.length, equals(7));

        // Verify each day has correct date
        for (var i = 0; i < results.length; i++) {
          final DateTime expectedDate = startDate.add(Duration(days: i));
          expect(results[i].date.day, equals(expectedDate.day));
          expect(results[i].date.month, equals(expectedDate.month));
          expect(results[i].date.year, equals(expectedDate.year));
        }
      });

      test('calculates prayer times for a full month', () {
        final startDate = DateTime(2026);
        final endDate = DateTime(2026, 1, 31);

        final List<PrayerTimeEntity> results = calculator
            .calculatePrayerTimesForRange(
              latitude: latitude,
              longitude: longitude,
              startDate: startDate,
              endDate: endDate,
              settings: settings,
            );

        expect(results.length, equals(31));
      });

      test('single day range returns one result', () {
        final date = DateTime(2026);

        final List<PrayerTimeEntity> results = calculator
            .calculatePrayerTimesForRange(
              latitude: latitude,
              longitude: longitude,
              startDate: date,
              endDate: date,
              settings: settings,
            );

        expect(results.length, equals(1));
      });
    });

    group('Edge Cases', () {
      const settings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.egyptian,
      );

      test('handles equator location (0° latitude)', () {
        final date = DateTime(2026, 1, 8);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: 0.0,
          longitude: 31.0,
          date: date,
          settings: settings,
        );

        // Prayer order should still be valid at equator
        expect(result.fajr.isBefore(result.sunrise), isTrue);
        expect(result.maghrib.isBefore(result.isha), isTrue);
      });

      test('handles prime meridian (0° longitude)', () {
        final date = DateTime(2026, 1, 8);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: 51.5,
          longitude: 0.0, // London
          date: date,
          settings: settings,
        );

        expect(result.fajr.isBefore(result.sunrise), isTrue);
        expect(result.maghrib.isBefore(result.isha), isTrue);
      });

      test('handles southern hemisphere', () {
        final date = DateTime(2026, 1, 8); // Summer in southern hemisphere

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: -33.9, // Sydney
          longitude: 151.2,
          date: date,
          settings: settings,
        );

        // Prayer order should still be valid
        expect(result.fajr.isBefore(result.sunrise), isTrue);
        expect(result.maghrib.isBefore(result.isha), isTrue);

        // Verify all prayers are on the correct date
        expect(result.fajr.day, equals(date.day));
        expect(result.isha.day, equals(date.day));
      });

      test('handles leap year date', () {
        final date = DateTime(2024, 2, 29); // Leap year

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: 30.0,
          longitude: 31.0,
          date: date,
          settings: settings,
        );

        expect(result.date, equals(date));
        expect(result.fajr.isBefore(result.sunrise), isTrue);
      });

      test('handles end of year date', () {
        final date = DateTime(2026, 12, 31);

        final PrayerTimeEntity result = calculator.calculatePrayerTimes(
          latitude: 30.0,
          longitude: 31.0,
          date: date,
          settings: settings,
        );

        expect(result.date, equals(date));
        expect(result.fajr.isBefore(result.sunrise), isTrue);
      });
    });
  });
}
