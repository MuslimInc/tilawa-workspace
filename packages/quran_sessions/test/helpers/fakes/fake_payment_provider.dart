import 'package:dartz_plus/dartz_plus.dart';

import 'package:quran_sessions/src/boundaries/payment/payment_provider.dart';

/// Returns a deterministic reference string; never contacts a payment gateway.
class FakePaymentProvider implements PaymentProvider {
  int _chargeCount = 0;
  final List<String> refundedReferences = [];
  bool shouldFail = false;

  @override
  Future<Either<PaymentFailure, String>> charge({
    required double amountUsd,
    required String currency,
    required String description,
    required String studentId,
  }) async {
    if (shouldFail) return const Left(ChargeDeclinedFailure());
    _chargeCount++;
    return Right('fake_ref_$_chargeCount');
  }

  @override
  Future<Either<PaymentFailure, void>> refund({
    required String paymentReference,
    required double amountUsd,
  }) async {
    if (shouldFail) return const Left(GatewayFailure());
    refundedReferences.add(paymentReference);
    return const Right(null);
  }
}
