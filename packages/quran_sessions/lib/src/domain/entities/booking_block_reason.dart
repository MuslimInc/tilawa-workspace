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
}
