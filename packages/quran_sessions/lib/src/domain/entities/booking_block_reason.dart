/// Typed reason the booking screen must block submission, derived
/// server-side from `getBookingPricingQuote` and never inferred in Flutter.
///
/// `slotUnavailable` is intentionally excluded — it is per-slot and enforced
/// only at `createSessionBooking` time, never on the per-teacher quote.
enum BookingBlockReason {
  none,
  paymentProviderUnavailable,
  bookingDisabledByAdmin,
  pricingConfigMissing,
  teacherNotBookable,
  marketDisabled,
  /// Alias kept for clarity in switch arms: same meaning as
  /// [paymentProviderUnavailable] when a paid session's market has no
  /// available payment provider.
  ;

  static BookingBlockReason fromString(String? raw) {
    return switch (raw) {
      'paymentProviderUnavailable' => paymentProviderUnavailable,
      'bookingDisabledByAdmin' => bookingDisabledByAdmin,
      'pricingConfigMissing' => pricingConfigMissing,
      'teacherNotBookable' => teacherNotBookable,
      'marketDisabled' => marketDisabled,
      _ => none,
    };
  }
}
