import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/home_athkar_context.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

void main() {
  group('athkarPrayerAnchorsFromDashboard', () {
    test('returns null without prayer boundaries', () {
      final HomeDashboard dashboard = HomeDashboard(
        generatedAt: DateTime(2026, 7, 25, 12),
      );
      check(athkarPrayerAnchorsFromDashboard(dashboard)).isNull();
    });

    test('maps fajr isha maghrib and asr from strip', () {
      final DateTime fajr = DateTime(2026, 7, 25, 4, 30);
      final DateTime sunrise = DateTime(2026, 7, 25, 6);
      final DateTime asr = DateTime(2026, 7, 25, 15, 45);
      final DateTime maghrib = DateTime(2026, 7, 25, 19, 10);
      final DateTime isha = DateTime(2026, 7, 25, 20, 40);

      final HomeDashboard dashboard = HomeDashboard(
        generatedAt: DateTime(2026, 7, 25, 12),
        prayerBoundaries: HomePrayerDayBoundaries(
          fajr: fajr,
          sunrise: sunrise,
          maghrib: maghrib,
          isha: isha,
        ),
        todayPrayers: [
          HomePrayerSlot(
            type: PrayerType.asr,
            time: asr,
            isNext: false,
            hasPassed: true,
          ),
        ],
      );

      final AthkarPrayerAnchors? anchors = athkarPrayerAnchorsFromDashboard(
        dashboard,
      );
      check(anchors).isNotNull();
      check(anchors!.fajr).equals(fajr);
      check(anchors.asr).equals(asr);
      check(anchors.maghrib).equals(maghrib);
      check(anchors.isha).equals(isha);
    });
  });
}
