import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';

class OpenSessionDisputeUseCase {
  const OpenSessionDisputeUseCase({required this._gateway});

  final SessionMutationGateway _gateway;

  static const int minReasonLength = 3;

  Future<Either<QuranSessionsFailure, String>> call({
    required String bookingId,
    required String reason,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.length < minReasonLength) {
      return const Left(
        ValidationFailure(field: 'reason', code: 'too_short'),
      );
    }

    final result = await _gateway.openSessionDispute(
      bookingId: bookingId,
      reason: trimmed,
    );
    return result.map((value) => value.disputeId);
  }
}
