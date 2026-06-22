import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Production-safe payment boundary until a real provider is integrated.
///
/// Blocks paid charges. Refunds and payouts remain admin/server workflows with
/// manual_pending execution status.
class DisabledPaymentProvider implements PaymentProvider {
  const DisabledPaymentProvider();

  @override
  Future<Either<PaymentFailure, String>> charge({
    required double amountUsd,
    required String currency,
    required String description,
    required String studentId,
  }) async {
    return const Left(GatewayFailure());
  }

  @override
  Future<Either<PaymentFailure, void>> refund({
    required String paymentReference,
    required double amountUsd,
  }) async {
    return const Left(GatewayFailure());
  }
}
