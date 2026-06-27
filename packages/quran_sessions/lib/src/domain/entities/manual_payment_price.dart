import 'package:equatable/equatable.dart';

/// Presentation-only price used to communicate that a session is paid and to
/// show manual / off-app payment instructions during the Egypt Closed Testing
/// pilot.
///
/// This is intentionally separate from the real pricing engine ([SessionPrice]
/// + `teachers/{id}/pricing/{marketId}`). It MUST NOT be read by booking
/// eligibility, booking creation, the payment provider, commission, or
/// refund/payout logic. The booking engine stays internally free; payment is
/// collected off-app, then reviewed before teacher confirmation.
class ManualPaymentPrice extends Equatable {
  const ManualPaymentPrice({
    required this.amountMinor,
    required this.currencyCode,
  });

  /// Integer minor units (e.g. 10000 = 100.00 EGP). Never a floating amount.
  final int amountMinor;

  /// ISO 4217 code, e.g. `EGP`.
  final String currencyCode;

  /// Major-unit value for display/formatting only.
  double get amountMajor => amountMinor / 100;

  @override
  List<Object?> get props => [amountMinor, currencyCode];
}
