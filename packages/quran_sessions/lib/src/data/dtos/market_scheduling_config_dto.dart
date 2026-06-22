class MarketSchedulingConfigDto {
  const MarketSchedulingConfigDto({
    required this.schedulingMode,
    required this.weekStartDay,
    required this.weekScopedDashboardEnabled,
    required this.fridayReviewReminderEnabled,
    required this.reminderLocalHour,
    required this.bookingHorizonDays,
    required this.policyVersion,
  });

  final String schedulingMode;
  final String weekStartDay;
  final bool weekScopedDashboardEnabled;
  final bool fridayReviewReminderEnabled;
  final int reminderLocalHour;
  final int bookingHorizonDays;
  final int policyVersion;
}
