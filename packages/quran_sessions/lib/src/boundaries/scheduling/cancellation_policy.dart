/// Rules governing refund eligibility on cancellation.
abstract interface class CancellationPolicy {
  /// Returns the fraction [0.0–1.0] of the paid amount to refund.
  /// 1.0 = full refund, 0.0 = no refund.
  double refundFraction({
    required DateTime sessionStartsAt,
    required DateTime cancelledAt,
  });

  /// Human-readable summary shown to the student before they confirm.
  String describe();
}

/// 100% refund if cancelled > 24 h before; 0% within 24 h.
class StandardCancellationPolicy implements CancellationPolicy {
  const StandardCancellationPolicy();

  @override
  double refundFraction({
    required DateTime sessionStartsAt,
    required DateTime cancelledAt,
  }) {
    final hoursUntilSession = sessionStartsAt.difference(cancelledAt).inHours;
    return hoursUntilSession >= 24 ? 1.0 : 0.0;
  }

  @override
  String describe() =>
      'Full refund if cancelled more than 24 hours before the session. '
      'No refund within 24 hours.';
}
