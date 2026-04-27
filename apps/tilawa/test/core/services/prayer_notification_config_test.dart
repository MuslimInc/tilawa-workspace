import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

void main() {
  group('PrayerNotificationConfig', () {
    group('staticId', () {
      test('returns staticIdBase + prayer.index for fajr', () {
        expect(
          PrayerNotificationConfig.staticId(PrayerType.fajr),
          PrayerNotificationConfig.staticIdBase + PrayerType.fajr.index,
        );
      });

      test('returns staticIdBase + prayer.index for isha', () {
        expect(
          PrayerNotificationConfig.staticId(PrayerType.isha),
          PrayerNotificationConfig.staticIdBase + PrayerType.isha.index,
        );
      });

      test('each prayer yields a unique static ID', () {
        final schedulable = [
          PrayerType.fajr,
          PrayerType.dhuhr,
          PrayerType.asr,
          PrayerType.maghrib,
          PrayerType.isha,
        ];
        final ids = schedulable.map(PrayerNotificationConfig.staticId).toList();
        expect(ids.toSet().length, ids.length, reason: 'IDs must be unique');
      });
    });

    group('dynamicId', () {
      test('returns dynamicIdBase for dayOffset=0, fajr', () {
        expect(
          PrayerNotificationConfig.dynamicId(0, PrayerType.fajr),
          PrayerNotificationConfig.dynamicIdBase + PrayerType.fajr.index,
        );
      });

      test('offsets by 10 per day for same prayer', () {
        final day0 = PrayerNotificationConfig.dynamicId(0, PrayerType.dhuhr);
        final day1 = PrayerNotificationConfig.dynamicId(1, PrayerType.dhuhr);
        expect(day1 - day0, 10);
      });

      test('different prayers on the same day have unique IDs', () {
        final ids = [
          PrayerType.fajr,
          PrayerType.dhuhr,
          PrayerType.asr,
          PrayerType.maghrib,
          PrayerType.isha,
        ].map((p) => PrayerNotificationConfig.dynamicId(0, p)).toList();
        expect(ids.toSet().length, ids.length, reason: 'IDs must be unique');
      });

      test('14 days × 5 prayers all fit below dynamicIdRangeEndExclusive', () {
        for (
          var day = 0;
          day < PrayerNotificationConfig.scheduleDaysAhead;
          day++
        ) {
          for (final prayer in [
            PrayerType.fajr,
            PrayerType.dhuhr,
            PrayerType.asr,
            PrayerType.maghrib,
            PrayerType.isha,
          ]) {
            final id = PrayerNotificationConfig.dynamicId(day, prayer);
            expect(
              id < PrayerNotificationConfig.dynamicIdRangeEndExclusive,
              isTrue,
              reason:
                  'dynamicId($day, $prayer)=$id must be < dynamicIdRangeEndExclusive',
            );
          }
        }
      });
    });

    group('dynamicIdRangeEndExclusive', () {
      test('equals dynamicIdBase + scheduleDaysAhead * 10', () {
        expect(
          PrayerNotificationConfig.dynamicIdRangeEndExclusive,
          PrayerNotificationConfig.dynamicIdBase +
              (PrayerNotificationConfig.scheduleDaysAhead * 10),
        );
      });
    });

    group('constants', () {
      test('channelId is stable', () {
        expect(PrayerNotificationConfig.channelId, 'com.tilawa.app.prayer');
      });

      test('scheduleDaysAhead is 14', () {
        expect(PrayerNotificationConfig.scheduleDaysAhead, 14);
      });

      test('staticIdBase is 2001', () {
        expect(PrayerNotificationConfig.staticIdBase, 2001);
      });

      test('dynamicIdBase is 20000000', () {
        expect(PrayerNotificationConfig.dynamicIdBase, 20000000);
      });
    });
  });
}
