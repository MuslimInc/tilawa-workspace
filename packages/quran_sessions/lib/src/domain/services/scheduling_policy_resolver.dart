import '../entities/market_scheduling_config.dart';
import '../entities/scheduling_mode.dart';
import '../entities/teacher_availability.dart';
import 'week_calendar.dart';

/// Resolves admin scheduling policy into presentation and bookability rules.
///
/// Phase 1: [SchedulingMode.recurring] only — generation stays on
/// [WeeklySchedule]. This class owns week bucketing and Friday reminder gates.
class SchedulingPolicyResolver {
  const SchedulingPolicyResolver({WeekCalendar? weekCalendar})
    : _weekCalendar = weekCalendar ?? const WeekCalendar();

  final WeekCalendar _weekCalendar;

  MarketSchedulingConfig resolve({
    required MarketSchedulingConfig global,
    MarketSchedulingConfig? marketOverride,
  }) => global.mergeWith(marketOverride);

  /// Phase 1 always uses recurring generation; mode is forwarded for analytics.
  SchedulingMode effectiveBookabilityMode(MarketSchedulingConfig config) =>
      config.schedulingMode;

  ({List<TeacherAvailability> thisWeek, List<TeacherAvailability> nextWeek})
  partitionBookableSlots({
    required MarketSchedulingConfig config,
    required List<TeacherAvailability> slots,
    required DateTime now,
    required String timezone,
  }) {
    if (!config.weekScopedDashboardEnabled) {
      return (thisWeek: slots, nextWeek: const <TeacherAvailability>[]);
    }
    return _weekCalendar.partitionSlots(
      slots: slots,
      now: now,
      timezone: timezone,
      weekStartDay: config.weekStartDay,
    );
  }

  FridayReviewBannerDecision evaluateFridayBanner({
    required MarketSchedulingConfig config,
    required DateTime now,
    required String timezone,
    required int nextWeekSlotCount,
    required bool isDismissedForNextWeek,
  }) {
    if (!config.fridayReviewReminderEnabled) {
      return FridayReviewBannerDecision.hidden;
    }
    if (!_weekCalendar.isFriday(now: now, timezone: timezone)) {
      return FridayReviewBannerDecision.hidden;
    }
    if (!_weekCalendar.isReminderHour(
      now: now,
      timezone: timezone,
      reminderLocalHour: config.reminderLocalHour,
    )) {
      return FridayReviewBannerDecision.hidden;
    }
    if (isDismissedForNextWeek) {
      return FridayReviewBannerDecision.hidden;
    }
    if (nextWeekSlotCount > 0) {
      return FridayReviewBannerDecision.hidden;
    }

    final nextWeek = _weekCalendar.nextWeek(
      now: now,
      timezone: timezone,
      weekStartDay: config.weekStartDay,
    );
    return FridayReviewBannerDecision.visible(nextWeekKey: nextWeek.weekKey);
  }

  String nextWeekKey({
    required MarketSchedulingConfig config,
    required DateTime now,
    required String timezone,
  }) => _weekCalendar
      .nextWeek(
        now: now,
        timezone: timezone,
        weekStartDay: config.weekStartDay,
      )
      .weekKey;
}

/// Whether the Friday in-app review banner should render.
sealed class FridayReviewBannerDecision {
  const FridayReviewBannerDecision();

  static const hidden = FridayReviewBannerHidden();

  factory FridayReviewBannerDecision.visible({required String nextWeekKey}) =>
      FridayReviewBannerVisible(nextWeekKey: nextWeekKey);
}

final class FridayReviewBannerHidden extends FridayReviewBannerDecision {
  const FridayReviewBannerHidden();
}

final class FridayReviewBannerVisible extends FridayReviewBannerDecision {
  const FridayReviewBannerVisible({required this.nextWeekKey});

  final String nextWeekKey;
}
