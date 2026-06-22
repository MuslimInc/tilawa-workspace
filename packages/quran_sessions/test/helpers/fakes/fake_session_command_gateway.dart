import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeSessionCommandGateway implements SessionCommandGateway {
  QuranSessionsFailure? failWith;
  final List<String> calls = [];

  @override
  Future<Either<QuranSessionsFailure, void>> capturePayment({
    required String sessionId,
    required String paymentReference,
  }) async {
    calls.add('capture:$sessionId');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> holdSlotSoft({
    required String slotId,
    required Duration ttl,
  }) async {
    calls.add('hold:$slotId');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> lockSlotHard({
    required String slotId,
  }) async {
    calls.add('lock:$slotId');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> refundPayment({
    required String sessionId,
    required double fraction,
    required String reason,
  }) async {
    calls.add('refund:$sessionId:$fraction');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> releaseSlot({
    required String slotId,
  }) async {
    calls.add('release:$slotId');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> swapSlot({
    required String oldSlotId,
    required String newSlotId,
  }) async {
    calls.add('swap:$oldSlotId:$newSlotId');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> voidPayment({
    required String sessionId,
    required String paymentReference,
  }) async {
    calls.add('void:$sessionId');
    if (failWith != null) return Left(failWith!);
    return const Right(null);
  }
}
