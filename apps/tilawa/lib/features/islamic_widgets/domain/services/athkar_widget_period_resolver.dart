/// The two athkar sets the widget rotates between (spec 041, US3).
enum AthkarWidgetPeriod { morning, evening }

/// Resolved window state for one instant: which set applies, the stable key
/// that anchors per-instance progress, and when the window next flips.
class AthkarWidgetPeriodState {
  const AthkarWidgetPeriodState({
    required this.period,
    required this.periodKey,
    required this.nextTransition,
  });

  final AthkarWidgetPeriod period;

  /// Stable identity of the current window occurrence. Progress persists per
  /// (widget instance, periodKey) and resets when the key changes — including
  /// across midnight for the evening window (03:00 still belongs to the
  /// evening that began at 15:00 the previous day).
  final String periodKey;

  /// First instant of the next window (native hosts schedule a re-render
  /// alarm here so the set flips without the app running).
  final DateTime nextTransition;
}

/// Pure clock-window rules shared by the Dart and native sides.
///
/// Windows are wall-clock (no prayer-time dependency, so the widget works
/// before location setup): morning 04:00–14:59, evening 15:00–03:59.
class AthkarWidgetPeriodResolver {
  const AthkarWidgetPeriodResolver();

  static const int morningStartHour = 4;
  static const int eveningStartHour = 15;

  AthkarWidgetPeriodState resolve(DateTime local) {
    final bool isMorning =
        local.hour >= morningStartHour && local.hour < eveningStartHour;
    if (isMorning) {
      return AthkarWidgetPeriodState(
        period: AthkarWidgetPeriod.morning,
        periodKey: 'M-${_dateKey(local)}',
        nextTransition: DateTime(
          local.year,
          local.month,
          local.day,
          eveningStartHour,
        ),
      );
    }
    // Evening: anchored to the day the window started (15:00). Before 04:00
    // that is the previous calendar day.
    final DateTime anchor = local.hour < morningStartHour
        ? local.subtract(const Duration(days: 1))
        : local;
    return AthkarWidgetPeriodState(
      period: AthkarWidgetPeriod.evening,
      periodKey: 'E-${_dateKey(anchor)}',
      nextTransition: DateTime(
        anchor.year,
        anchor.month,
        anchor.day + 1,
        morningStartHour,
      ),
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
