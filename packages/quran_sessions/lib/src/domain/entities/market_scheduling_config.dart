import 'package:equatable/equatable.dart';

import 'scheduling_mode.dart';
import 'weekday.dart';

/// Admin-owned scheduling experiment config resolved per teacher market.
///
/// Distinct from per-teacher [SchedulingPolicy] (min notice / horizon on
/// [WeeklySchedule]). Teachers never choose these values.
class MarketSchedulingConfig extends Equatable {
  const MarketSchedulingConfig({
    required this.schedulingMode,
    required this.weekStartDay,
    required this.weekScopedDashboardEnabled,
    required this.fridayReviewReminderEnabled,
    required this.reminderLocalHour,
    required this.bookingHorizonDays,
    required this.policyVersion,
  });

  final SchedulingMode schedulingMode;
  final Weekday weekStartDay;
  final bool weekScopedDashboardEnabled;
  final bool fridayReviewReminderEnabled;

  /// Local hour (0–23) in the teacher timezone when Friday reminders may show.
  final int reminderLocalHour;
  final int bookingHorizonDays;
  final int policyVersion;

  /// Production-safe defaults — recurring engine with week-scoped dashboard UX.
  static const defaults = MarketSchedulingConfig(
    schedulingMode: SchedulingMode.recurring,
    weekStartDay: Weekday.saturday,
    weekScopedDashboardEnabled: true,
    fridayReviewReminderEnabled: true,
    reminderLocalHour: 10,
    bookingHorizonDays: 30,
    policyVersion: 1,
  );

  MarketSchedulingConfig mergeWith(MarketSchedulingConfig? override) {
    if (override == null) return this;
    return MarketSchedulingConfig(
      schedulingMode: override.schedulingMode,
      weekStartDay: override.weekStartDay,
      weekScopedDashboardEnabled: override.weekScopedDashboardEnabled,
      fridayReviewReminderEnabled: override.fridayReviewReminderEnabled,
      reminderLocalHour: override.reminderLocalHour,
      bookingHorizonDays: override.bookingHorizonDays,
      policyVersion: override.policyVersion,
    );
  }

  @override
  List<Object?> get props => [
    schedulingMode,
    weekStartDay,
    weekScopedDashboardEnabled,
    fridayReviewReminderEnabled,
    reminderLocalHour,
    bookingHorizonDays,
    policyVersion,
  ];
}
