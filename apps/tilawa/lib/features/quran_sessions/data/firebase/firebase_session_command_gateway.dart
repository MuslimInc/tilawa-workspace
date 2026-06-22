import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FirebaseSessionCommandGateway implements SessionCommandGateway {
  const FirebaseSessionCommandGateway();

  @override
  Future<Either<QuranSessionsFailure, void>> capturePayment({
    required String sessionId,
    required String paymentReference,
  }) async => const Left(
    PolicyViolationFailure(
      policyName: 'session_command_gateway',
      detail: 'capture_payment_requires_server_orchestrator',
    ),
  );

  @override
  Future<Either<QuranSessionsFailure, void>> holdSlotSoft({
    required String slotId,
    required Duration ttl,
  }) async => const Left(
    PolicyViolationFailure(
      policyName: 'session_command_gateway',
      detail: 'hold_slot_requires_server_orchestrator',
    ),
  );

  @override
  Future<Either<QuranSessionsFailure, void>> lockSlotHard({
    required String slotId,
  }) async => const Left(
    PolicyViolationFailure(
      policyName: 'session_command_gateway',
      detail: 'lock_slot_requires_server_orchestrator',
    ),
  );

  @override
  Future<Either<QuranSessionsFailure, void>> refundPayment({
    required String sessionId,
    required double fraction,
    required String reason,
  }) async {
    return const Left(
      PolicyViolationFailure(
        policyName: 'payment_refund',
        detail: 'refund_requires_admin_approve_session_refund',
      ),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, void>> releaseSlot({
    required String slotId,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> swapSlot({
    required String oldSlotId,
    required String newSlotId,
  }) async => const Left(
    PolicyViolationFailure(
      policyName: 'session_command_gateway',
      detail: 'swap_slot_requires_reschedule_request_context',
    ),
  );

  @override
  Future<Either<QuranSessionsFailure, void>> voidPayment({
    required String sessionId,
    required String paymentReference,
  }) async => const Left(
    PolicyViolationFailure(
      policyName: 'session_command_gateway',
      detail: 'void_payment_requires_server_orchestrator',
    ),
  );
}
