/// Rules governing whether a booking can be rescheduled.
abstract interface class ReschedulePolicy {
  /// Returns null if rescheduling is allowed, or a reason string if blocked.
  String? validate({
    required String bookingId,
    required DateTime currentSessionStartsAt,
    required DateTime newSlotStartsAt,
    required DateTime requestedAt,
    required int totalRescheduleCount,
  });
}

/// Allows one free reschedule > 24 h before the session.
class DefaultReschedulePolicy implements ReschedulePolicy {
  const DefaultReschedulePolicy({this.maxReschedules = 1});

  final int maxReschedules;

  @override
  String? validate({
    required String bookingId,
    required DateTime currentSessionStartsAt,
    required DateTime newSlotStartsAt,
    required DateTime requestedAt,
    required int totalRescheduleCount,
  }) {
    if (totalRescheduleCount >= maxReschedules) {
      return 'You have used all allowed reschedules for this booking.';
    }
    final hoursRemaining = currentSessionStartsAt
        .difference(requestedAt)
        .inHours;
    if (hoursRemaining < 24) {
      return 'Reschedule is not allowed within 24 hours of the session.';
    }
    return null;
  }
}
