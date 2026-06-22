import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';
import '../value_objects/actor_role.dart';

/// Accepts or rejects a pending reschedule request via Cloud Functions.
class RespondToRescheduleRequestUseCase {
  const RespondToRescheduleRequestUseCase({
    required this._mutationGateway,
  });

  final SessionMutationGateway _mutationGateway;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String requestId,
    required bool accept,
    required ActorRole actorRole,
  }) {
    return _mutationGateway.confirmReschedule(
      requestId: requestId,
      accept: accept,
      actorRole: actorRole,
    );
  }
}
