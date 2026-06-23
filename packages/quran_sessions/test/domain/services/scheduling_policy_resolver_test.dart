import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  const resolver = SchedulingPolicyResolver();
  const config = MarketSchedulingConfig.defaults;
  const timezone = 'Asia/Riyadh';

  group('SchedulingPolicyResolver', () {
    test('evaluateFridayBanner shows when Friday and next week empty', () {
      // 2026-01-09 is Friday in Asia/Riyadh
      final decision = resolver.evaluateFridayBanner(
        config: config,
        now: DateTime.utc(2026, 1, 9, 10),
        timezone: timezone,
        nextWeekSlotCount: 0,
        isDismissedForNextWeek: false,
      );

      check(decision).isA<FridayReviewBannerVisible>();
    });

    test('evaluateFridayBanner hidden when next week has slots', () {
      final decision = resolver.evaluateFridayBanner(
        config: config,
        now: DateTime.utc(2026, 1, 9, 10),
        timezone: timezone,
        nextWeekSlotCount: 3,
        isDismissedForNextWeek: false,
      );

      check(decision).isA<FridayReviewBannerHidden>();
    });

    test('weekScopedDashboardEnabled partitions slots', () {
      final now = DateTime.utc(2026, 1, 9, 10);
      final thisStart = DateTime.utc(2026, 1, 7, 7);
      final nextStart = DateTime.utc(2026, 1, 10, 7);
      final slots = [
        TeacherAvailability(
          slotId: 'a',
          teacherId: 't1',
          startsAt: thisStart,
          endsAt: thisStart.add(const Duration(minutes: 30)),
          isBooked: false,
        ),
        TeacherAvailability(
          slotId: 'b',
          teacherId: 't1',
          startsAt: nextStart,
          endsAt: nextStart.add(const Duration(minutes: 30)),
          isBooked: false,
        ),
      ];

      final partition = resolver.partitionBookableSlots(
        config: config,
        slots: slots,
        now: now,
        timezone: timezone,
      );

      check(partition.thisWeek.length).equals(1);
      check(partition.nextWeek.length).equals(1);
    });
  });
}
