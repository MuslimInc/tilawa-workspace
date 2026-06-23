import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';
import '../policies/configurable_reschedule_policy.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/actor_role.dart';

/// Requests a reschedule via callable Cloud Functions after policy validation.
class RequestSessionRescheduleViaServerUseCase {
  const RequestSessionRescheduleViaServerUseCase({
    required this._aggregateRepository,
    required this._reschedulePolicy,
    required this._mutationGateway,
  });

  final SessionAggregateRepository _aggregateRepository;
  final ConfigurableReschedulePolicy _reschedulePolicy;
  final SessionMutationGateway _mutationGateway;

  Future<Either<QuranSessionsFailure, RescheduleRequestResult>> call({
    required String bookingId,
    required String newSlotId,
    required DateTime newStartsAt,
    required String reason,
    required ActorRole actorRole,
  }) async {
    final loaded = await _aggregateRepository.getById(bookingId);
    if (loaded.isLeft()) return loaded.map((_) => throw StateError('noop'));
    final aggregate = loaded.fold((_) => throw StateError('noop'), (r) => r);

    final policy = _reschedulePolicy.validate(
      startsAt: aggregate.startsAt,
      currentRescheduleCount: aggregate.rescheduleCount,
    );
    if (policy.isLeft()) return policy.map((_) => throw StateError('noop'));

    return _mutationGateway.requestReschedule(
      bookingId: bookingId,
      newSlotId: newSlotId,
      newStartsAt: newStartsAt,
      reason: reason,
      actorRole: actorRole,
    );
  }
}
