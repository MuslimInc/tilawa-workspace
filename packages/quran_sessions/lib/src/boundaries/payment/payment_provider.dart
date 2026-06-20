import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';

/// Typed failure hierarchy for the payment boundary.
///
/// The BLoC layer maps these to [QuranSessionsFailure] subtypes (or handles
/// them directly) before emitting state. Raw strings never reach the UI.
sealed class PaymentFailure extends Equatable {
  const PaymentFailure();

  @override
  List<Object?> get props => [];
}

/// The card or payment method was declined by the gateway.
final class ChargeDeclinedFailure extends PaymentFailure {
  const ChargeDeclinedFailure();
}

/// The user dismissed the payment sheet without completing.
final class ChargeCancelledFailure extends PaymentFailure {
  const ChargeCancelledFailure();
}

/// The payment gateway returned an unexpected error (not a decline).
final class GatewayFailure extends PaymentFailure {
  const GatewayFailure();
}

/// Abstracts the student-facing payment flow.
///
/// The app layer injects a concrete implementation (Stripe, PayPal, etc.)
/// at registration time. This package never imports a payment SDK.
abstract interface class PaymentProvider {
  /// Initiates a payment and returns an opaque [paymentReference] string
  /// that is passed to [BookingRepository.createBooking].
  Future<Either<PaymentFailure, String>> charge({
    required double amountUsd,
    required String currency,
    required String description,
    required String studentId,
  });

  /// Refunds a previously completed charge.
  Future<Either<PaymentFailure, void>> refund({
    required String paymentReference,
    required double amountUsd,
  });
}
