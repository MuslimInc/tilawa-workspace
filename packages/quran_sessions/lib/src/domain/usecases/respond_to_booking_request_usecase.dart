import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';

class RespondToBookingRequestUseCase {
  const RespondToBookingRequestUseCase(this._mutationGateway);

  final SessionMutationGateway _mutationGateway;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String bookingId,
    required bool accept,
    String? reason,
  }) {
    return _mutationGateway.respondToBookingRequest(
      bookingId: bookingId,
      accept: accept,
      reason: reason,
    );
  }
}
