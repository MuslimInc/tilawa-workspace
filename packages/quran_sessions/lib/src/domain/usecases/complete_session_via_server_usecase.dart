import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';
import '../value_objects/actor_role.dart';

/// Marks a session complete via callable Cloud Functions.
class CompleteSessionViaServerUseCase {
  const CompleteSessionViaServerUseCase({
    required this._mutationGateway,
  });

  final SessionMutationGateway _mutationGateway;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String sessionId,
    required ActorRole actorRole,
  }) {
    return _mutationGateway.completeSession(
      sessionId: sessionId,
      actorRole: actorRole,
    );
  }
}
