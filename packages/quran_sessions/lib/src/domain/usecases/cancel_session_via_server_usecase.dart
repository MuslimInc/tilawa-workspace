import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../failures/quran_sessions_failure.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import 'cancel_session_usecase.dart';

/// Wraps [CancelSessionUseCase] for bloc wiring (server-delegating repository).
class CancelSessionViaServerUseCase {
  const CancelSessionViaServerUseCase({
    required this._cancelSession,
  });

  final CancelSessionUseCase _cancelSession;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String bookingId,
    required String actorId,
    required ActorRole actorRole,
    required String reason,
    ActionSource source = ActionSource.mobileApp,
  }) {
    return _cancelSession(
      sessionId: bookingId,
      actorRole: actorRole,
      actorId: actorId,
      reason: reason,
      source: source,
    );
  }
}
