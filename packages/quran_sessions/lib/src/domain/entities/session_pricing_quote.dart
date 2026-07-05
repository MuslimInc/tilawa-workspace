import 'package:equatable/equatable.dart';

import 'session_price.dart';
import 'session_pricing_type.dart';

/// Server-authoritative pricing preview for a booking (getBookingPricingQuote).
///
/// Resolved from the same admin market config the server uses when creating
/// the booking, so the previewed price always matches the recorded price.
class SessionPricingQuote extends Equatable {
  const SessionPricingQuote({
    required this.pricingType,
    required this.amount,
    required this.currencyCode,
    required this.paymentRequired,
    required this.paymentProviderAvailable,
    this.countryCode,
    this.cityId,
    this.policyVersion,
  });

  final SessionPricingType pricingType;
  final double amount;
  final String currencyCode;

  /// True when the student must pay to confirm this booking.
  final bool paymentRequired;

  /// False while the payment provider gate is disabled server-side. A paid
  /// quote with this false must block submission in the booking UI.
  final bool paymentProviderAvailable;

  final String? countryCode;
  final String? cityId;
  final String? policyVersion;

  bool get isFree => pricingType == SessionPricingType.free;

  /// True when the session is paid but payment cannot currently be taken.
  bool get isPaymentBlocked => paymentRequired && !paymentProviderAvailable;

  /// Display price for the booking price summary; null when free.
  SessionPrice? get price => isFree
      ? null
      : SessionPrice(
          amount: amount,
          currencyCode: currencyCode,
          countryCode: countryCode ?? '',
          cityId: cityId ?? '',
        );

  @override
  List<Object?> get props => [
    pricingType,
    amount,
    currencyCode,
    paymentRequired,
    paymentProviderAvailable,
    countryCode,
    cityId,
    policyVersion,
  ];
}
