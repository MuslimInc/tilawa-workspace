import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/policies/session_join_policy.dart';
import '../../domain/repositories/session_repository.dart';

class ValidateJoinSessionUseCase {
  const ValidateJoinSessionUseCase({
    required this.sessionRepository,
    this.joinPolicy = const SessionJoinPolicy(),
  });

  final SessionRepository sessionRepository;
  final SessionJoinPolicy joinPolicy;

  Future<Either<QuranSessionsFailure, QuranSession>> call({
    required String sessionId,
    required String userId,
    required DateTime now,
  }) async {
    final freshSessionRes = await sessionRepository.getSessionById(sessionId);
    return freshSessionRes.fold(
      (failure) => Left(failure),
      (session) {
        final canJoin = joinPolicy.canJoin(
          session: session,
          userId: userId,
          now: now,
        );
        if (!canJoin) {
          return const Left(
            InvalidTransitionFailure(
              action: 'join_session',
              actorRole: 'participant',
              reasonCode: 'join_not_allowed',
            ),
          );
        }
        return Right(session);
      },
    );
  }
}
