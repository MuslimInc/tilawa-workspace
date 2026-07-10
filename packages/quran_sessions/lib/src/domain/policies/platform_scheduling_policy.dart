/// Platform-wide scheduling defaults — emergency fallbacks when admin config
/// omits a value. Production amounts must come from Tilawa Admin Panel.
abstract final class PlatformSchedulingPolicy {
  /// Slot hold while [SessionLifecycleStatus.pendingPayment] (Q-BK-03).
  static const Duration pendingPaymentSlotHoldTtl = Duration(minutes: 15);

  /// Server dedupe window for booking idempotency keys (Q-BK-04).
  static const Duration bookingIdempotencyDedupeWindow = Duration(hours: 24);

  /// Join window opens this long before [startsAt] (Q-VC-03).
  static const Duration joinWindowLeadTime = Duration(minutes: 15);

  /// Default slot duration when market config omits a value (Q-AV-01).
  static const int defaultSlotDurationMinutes = 60;

  /// Default concurrent upcoming cap when market config omits a value (Q-AV-03).
  static const int defaultMaxConcurrentUpcomingPerStudent = 3;
}
