import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';

/// Staging sandbox payment — no real PSP SDK.
///
/// Registered only when Admin platform config enables wallet support.
/// Implements [PaymentProvider] for DI symmetry; use [confirmBookingPayment]
/// for the paid booking flow.
class SandboxPaymentProvider
    implements PaymentProvider, SessionPaymentConfirmation {
  SandboxPaymentProvider(
    this._functions,
    this._sessionPayloadBuilder,
  );

  final FirebaseFunctions _functions;
  final CallableSessionPayloadBuilder _sessionPayloadBuilder;

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

  @override
  Future<Either<QuranSessionsFailure, void>> confirm({
    required String bookingId,
    required String paymentReference,
    required String clientConfirmToken,
  }) => confirmBookingPayment(
    bookingId: bookingId,
    paymentReference: paymentReference,
    clientConfirmToken: clientConfirmToken,
  );

  Future<Either<QuranSessionsFailure, void>> confirmBookingPayment({
    required String bookingId,
    required String paymentReference,
    required String clientConfirmToken,
  }) async {
    try {
      final callable = _functions.httpsCallable('confirmBookingPayment');
      await callable.call<Map<String, dynamic>>(
        await _sessionPayloadBuilder.withSessionEpoch({
          'bookingId': bookingId,
          'paymentReference': paymentReference,
          'clientConfirmToken': clientConfirmToken,
          'idempotencyKey': 'sandbox:$bookingId:$paymentReference',
        }),
      );
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        return const Left(UnauthorizedFailure());
      }
      if (e.code == 'failed-precondition') {
        return const Left(PaymentProviderFailure());
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
