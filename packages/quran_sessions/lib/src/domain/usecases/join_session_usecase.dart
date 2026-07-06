import 'package:dartz_plus/dartz_plus.dart';

import '../entities/call_join_request.dart';
import '../entities/quran_session.dart';
import '../entities/session_lifecycle_status.dart';
import '../entities/session_participant_role.dart';
import '../failures/quran_sessions_failure.dart';
import '../providers/auth_session_provider.dart';
import '../repositories/session_repository.dart';
import '../repositories/teacher_profile_repository.dart';
import '../../boundaries/call/session_call_provider.dart';
import '../policies/session_join_policy.dart';
import '../services/quran_session_call_telemetry_coordinator.dart';

/// Joins a session through the injected [SessionCallProvider] gateway.
///
/// Loads session metadata from the repository, validates lifecycle + actor,
/// then builds a server-shaped [CallJoinRequest] (no client-side tokens).
class JoinSessionUseCase {
  const JoinSessionUseCase({
    required this.sessionRepository,
    required this.callProvider,
    required this.authSession,
    required this.teacherProfileRepository,
    this.callTelemetry,
    this.joinPolicy = const SessionJoinPolicy(),
  });

  final SessionRepository sessionRepository;
  final SessionCallProvider callProvider;
  final AuthSessionProvider authSession;
  final TeacherProfileRepository teacherProfileRepository;
  final QuranSessionCallTelemetryCoordinator? callTelemetry;
  final SessionJoinPolicy joinPolicy;

  Future<Either<QuranSessionsFailure, void>> call({
    required String sessionId,
    SessionParticipantRole? role,
    bool forceTakeover = false,
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
        role ?? await _resolveParticipantRole(userId: userId, session: session);

    if (participantRole == null) {
      return const Left(UnauthorizedFailure());
    }

    final teacherAuthUserId = participantRole == SessionParticipantRole.teacher
        ? userId
        : null;

    if (!joinPolicy.canJoin(
      session: session,
      userId: userId,
      now: DateTime.now().toUtc(),
      teacherAuthUserId: teacherAuthUserId,
    )) {
      return const Left(
        InvalidTransitionFailure(
          action: 'join_session',
          actorRole: 'participant',
          reasonCode: 'join_window_closed',
        ),
      );
    }

    final request = CallJoinRequest(
      sessionId: session.id,
      role: participantRole,
      callType: session.callType,
      providerKind: session.callProviderKind,
      joinUrl: session.joinUrl,
      providerSessionId: session.providerSessionId,
      joinToken: session.joinToken,
      forceTakeover: forceTakeover,
    );

    callTelemetry?.recordJoinRequested(
      sessionId: session.id,
      actorId: userId,
      actorRole: participantRole,
    );
    callTelemetry?.bindSession(
      sessionId: session.id,
      actorId: userId,
      actorRole: participantRole,
    );

    try {
      await callProvider.join(request);
      callTelemetry?.recordJoinSucceeded(
        sessionId: session.id,
        actorId: userId,
        actorRole: participantRole,
      );
      return const Right(null);
    } on MeetingLinkUnavailableFailure catch (e) {
      _recordJoinFailed(
        session,
        userId,
        participantRole,
        'meeting_link_unavailable',
      );
      return Left(e);
    } on CallProviderUnavailableFailure catch (e) {
      _recordJoinFailed(
        session,
        userId,
        participantRole,
        e.reasonCode ?? 'provider_unavailable',
      );
      return Left(e);
    } on RtcPermissionDeniedFailure catch (e) {
      _recordJoinFailed(
        session,
        userId,
        participantRole,
        'permission_${e.permission}',
      );
      return Left(e);
    } on RtcCallJoinFailure catch (e) {
      _recordJoinFailed(session, userId, participantRole, e.reasonCode);
      return Left(e);
    } on WebRtcSignalingUnavailableFailure catch (e) {
      _recordJoinFailed(
        session,
        userId,
        participantRole,
        'webrtc_signaling_unavailable',
      );
      return Left(e);
    } on ExternalMeetingLaunchFailure catch (e) {
      _recordJoinFailed(
        session,
        userId,
        participantRole,
        'external_meeting_launch_failed',
      );
      return Left(e);
    } on QuranSessionsFailure catch (e) {
      _recordJoinFailed(
        session,
        userId,
        participantRole,
        e.runtimeType.toString(),
      );
      return Left(e);
    } on Object {
      _recordJoinFailed(session, userId, participantRole, 'unknown_failure');
      // We cannot log easily without injecting a logger here, but mapping to
      // UnknownFailure ensures we don't present a false "No internet connection"
      // to the user when the problem is an SDK crash or permission error.
      return const Left(UnknownFailure());
    }
  }

  void _recordJoinFailed(
    QuranSession session,
    String userId,
    SessionParticipantRole participantRole,
    String reasonCode,
  ) {
    callTelemetry?.recordJoinFailed(
      sessionId: session.id,
      actorId: userId,
      actorRole: participantRole,
      reasonCode: reasonCode,
    );
  }

  Future<SessionParticipantRole?> _resolveParticipantRole({
    required String userId,
    required QuranSession session,
  }) async {
    if (userId == session.studentId) {
      return SessionParticipantRole.student;
    }
    if (userId == session.teacherId) {
      return SessionParticipantRole.teacher;
    }

    final profileResult = await teacherProfileRepository.getProfileById(
      session.teacherId,
    );
    return profileResult.fold(
      (_) => null,
      (profile) =>
          profile.userId == userId ? SessionParticipantRole.teacher : null,
    );
  }
}
