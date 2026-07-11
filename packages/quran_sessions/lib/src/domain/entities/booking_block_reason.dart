/// Typed reason the booking screen must block submission.
///
/// Business reasons come from `getBookingPricingQuote`. Transport quote
/// failures use [pricingQuoteUnavailable] so Flutter never infers payment state
/// from market-only data.
///
/// `slotUnavailable` is intentionally excluded — it is per-slot and enforced
/// only at `createSessionBooking` time, never on the per-teacher quote.
enum BookingBlockReason {
  none,
  pricingQuoteUnavailable,
  paymentProviderUnavailable,
  bookingDisabledByAdmin,
  pricingConfigMissing,
  teacherNotBookable,
  marketDisabled,
  ;

  static BookingBlockReason fromString(String? raw) {
    return switch (raw) {
      'pricingQuoteUnavailable' => pricingQuoteUnavailable,
      'paymentProviderUnavailable' => paymentProviderUnavailable,
      'bookingDisabledByAdmin' => bookingDisabledByAdmin,
      'pricingConfigMissing' => pricingConfigMissing,
      'teacherNotBookable' => teacherNotBookable,
      'marketDisabled' => marketDisabled,
      _ => none,
    };
  }

  /// True when this reason is not a durable booking block: either the session
  /// is bookable ([none]) or the quote transport failed ([pricingQuoteUnavailable])
  /// and may succeed on retry. Transient reasons keep the teacher discoverable;
  /// the booking screen still resolves a fresh quote before allowing submit.
  bool get isTransient => this == none || this == pricingQuoteUnavailable;

  /// True when this reason must hide the teacher from the discovery list, so a
  /// student never lands on a dead-end booking screen (e.g. paid teacher while
  /// the payment provider is disabled, admin-disabled bookings, market disabled).
  ///
  /// Note: [teacherNotBookable] intentionally does NOT hide the teacher so they
  /// remain discoverable, but their profile will show them as unbookable.
  bool get hidesTeacherFromList => !isTransient && this != teacherNotBookable;
}
