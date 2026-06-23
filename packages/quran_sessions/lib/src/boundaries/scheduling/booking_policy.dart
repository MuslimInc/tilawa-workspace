/// Rules that govern whether a booking attempt is permitted.
abstract interface class BookingPolicy {
  /// Returns null if the booking is allowed, or a human-readable reason string
  /// if it is blocked.
  String? validate({
    required String studentId,
    required String teacherId,
    required String slotId,
    required DateTime slotStartsAt,
  });
}

/// Default implementation: allow any booking at least 1 hour in advance.
class DefaultBookingPolicy implements BookingPolicy {
  const DefaultBookingPolicy({this.minimumLeadTime = const Duration(hours: 1)});

  final Duration minimumLeadTime;

  @override
  String? validate({
    required String studentId,
    required String teacherId,
    required String slotId,
    required DateTime slotStartsAt,
  }) {
    if (slotStartsAt.isBefore(DateTime.now().add(minimumLeadTime))) {
      return 'Booking must be made at least $minimumLeadTime before the session.';
    }
    return null;
  }
}
