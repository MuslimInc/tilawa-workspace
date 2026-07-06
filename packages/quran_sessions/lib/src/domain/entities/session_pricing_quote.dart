import 'package:equatable/equatable.dart';

import 'booking_block_reason.dart';
import 'effective_pricing_source.dart';
import 'session_price.dart';
import 'session_pricing_type.dart';

/// Server-authoritative pricing preview for a booking (getBookingPricingQuote).
///
/// Resolved from the same admin market config + teacher override the server
/// uses when creating the booking, so the previewed price always matches the
/// recorded price. The server is the single source of truth: Flutter maps
/// the typed [blockReason] to UI state and never infers it from loose booleans.
class SessionPricingQuote extends Equatable {
  const SessionPricingQuote({
    required this.pricingType,
    required this.amount,
    required this.currencyCode,
    required this.paymentRequired,
    required this.paymentProviderAvailable,
    required this.bookingEnabled,
    required this.quranSessionsEnabled,
    required this.effectivePricingSource,
    required this.blockReason,
    this.countryCode,
    this.cityId,
    this.policyVersion,
  });

  final SessionPricingType pricingType;
  final double amount;
  final String currencyCode;

  /// True when the student must pay to confirm this booking.
  final bool paymentRequired;

  /// False while the payment provider gate is disabled server-side. Kept for
  /// backward compatibility; UI logic should prefer [blockReason].
  final bool paymentProviderAvailable;

  /// Platform + market feature flags reported by the server.
  final bool bookingEnabled;
  final bool quranSessionsEnabled;

  /// Where [amount] was resolved from (mirrors `feeSnapshot.pricingSource`).
  final EffectivePricingSource effectivePricingSource;

  /// Typed booking-block reason; [BookingBlockReason.none] when bookable.
  final BookingBlockReason blockReason;

  final String? countryCode;
  final String? cityId;
  final String? policyVersion;

  bool get isFree => pricingType == SessionPricingType.free;

  /// True when the booking screen must block submission. Derived from the
  /// server-reported [blockReason] (any value other than [none]).
  bool get isPaymentBlocked => blockReason != BookingBlockReason.none;

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
    bookingEnabled,
    quranSessionsEnabled,
    effectivePricingSource,
    blockReason,
    countryCode,
    cityId,
    policyVersion,
  ];
}
