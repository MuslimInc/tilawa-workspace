import 'package:dartz_plus/dartz_plus.dart';

import '../entities/call_join_request.dart';
import '../entities/session_lifecycle_status.dart';
import '../entities/session_participant_role.dart';
import '../failures/quran_sessions_failure.dart';
import '../providers/auth_session_provider.dart';
import '../repositories/session_repository.dart';
import '../../boundaries/call/session_call_provider.dart';

/// Joins a session through the injected [SessionCallProvider] gateway.
///
/// Loads session metadata from the repository, validates lifecycle + actor,
/// then builds a server-shaped [CallJoinRequest] (no client-side tokens).
class JoinSessionUseCase {
  const JoinSessionUseCase({
    required this.sessionRepository,
    required this.callProvider,
    required this.authSession,
  });

  final SessionRepository sessionRepository;
  final SessionCallProvider callProvider;
  final AuthSessionProvider authSession;

  Future<Either<QuranSessionsFailure, void>> call({
    required String sessionId,
    SessionParticipantRole? role,
  }) async {
    final userId = authSession.currentUserId;
    if (userId == null || userId.isEmpty) {
      return const Left(UnauthorizedFailure());
    }

    final sessionResult = await sessionRepository.getSessionById(sessionId);
    if (sessionResult.isLeft()) {
      return sessionResult.map((_) => throw StateError('unreachable'));
    }

    final session = sessionResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );

    if (!session.effectiveLifecycleStatus.canJoinSession) {
      return const Left(
        InvalidTransitionFailure(
          action: 'join_session',
          actorRole: 'participant',
          reasonCode: 'join_not_allowed',
        ),
      );
    }

    final participantRole =
        role ??
        (userId == session.teacherId
            ? SessionParticipantRole.teacher
            : userId == session.studentId
            ? SessionParticipantRole.student
            : null);

    if (participantRole == null) {
      return const Left(UnauthorizedFailure());
    }

    final request = CallJoinRequest(
      sessionId: session.id,
      role: participantRole,
      callType: session.callType,
      providerKind: session.callProviderKind,
      joinUrl: session.joinUrl,
      providerSessionId: session.providerSessionId,
      joinToken: session.joinToken,
    );

    try {
      await callProvider.join(request);
      return const Right(null);
    } on MeetingLinkUnavailableFailure catch (e) {
      return Left(e);
    } on CallProviderUnavailableFailure catch (e) {
      return Left(e);
    } on Object {
      return const Left(NetworkFailure());
    }
  }
}
