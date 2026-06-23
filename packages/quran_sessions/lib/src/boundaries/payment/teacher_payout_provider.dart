/// Abstracts the teacher-side payout flow.
///
/// Completely separate from [PaymentProvider] because the timing,
/// currency, and SDK may differ (e.g. Stripe Connect vs. PayPal Payouts).
abstract interface class TeacherPayoutProvider {
  /// Schedules a payout after a session is marked completed.
  Future<void> schedulePayout({
    required String teacherId,
    required double amountUsd,
    required String sessionId,
  });

  /// Cancels a pending payout (e.g. after a dispute).
  Future<void> cancelPayout({required String sessionId});
}
