import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/session_aggregate.dart';
import '../../../domain/entities/session_audit_event.dart';
import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/pending_reschedule_request.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/providers/auth_session_provider.dart';
import '../../../domain/repositories/teacher_profile_repository.dart';
import '../../../domain/usecases/get_pending_reschedule_request_usecase.dart';
import '../../../domain/usecases/get_session_timeline_usecase.dart';
import '../../../domain/usecases/join_session_usecase.dart';
import '../../../domain/usecases/open_session_dispute_usecase.dart';
import '../../../domain/usecases/report_session_concern_usecase.dart';
import '../../../domain/usecases/respond_to_reschedule_request_usecase.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/repositories/session_aggregate_repository.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../domain/value_objects/actor_role.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

typedef OpenExternalMeetingUrl = Future<void> Function(String url);

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this._aggregateRepository,
    required this._getTimeline,
    this._sessionRepository,
    this._joinSession,
    this._openExternalMeetingUrl,
    this._reportConcern,
    this._openDispute,
    this._getPendingReschedule,
    this._respondToReschedule,
    this._authSession,
    this._teacherProfileRepository,
  }) : super(const SessionDetailInitial()) {
    on<SessionDetailLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<SessionDetailJoinRequested>(
      _onJoinRequested,
      transformer: sequential(),
    );
    on<SessionDetailOpenMeetingAgainRequested>(
      _onOpenMeetingAgainRequested,
      transformer: sequential(),
    );
    on<SessionDetailReportSubmitted>(
      _onReportSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailReportAcknowledged>(
      _onReportAcknowledged,
      transformer: sequential(),
    );
    on<SessionDetailDisputeSubmitted>(
      _onDisputeSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailDisputeAcknowledged>(
      _onDisputeAcknowledged,
      transformer: sequential(),
    );
    on<SessionDetailRescheduleRespondSubmitted>(
      _onRescheduleRespondSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailRescheduleRespondAcknowledged>(
      _onRescheduleRespondAcknowledged,
      transformer: sequential(),
    );
  }

  final SessionAggregateRepository _aggregateRepository;
  final GetSessionTimelineUseCase _getTimeline;
  final SessionRepository? _sessionRepository;
  final JoinSessionUseCase? _joinSession;
  final OpenExternalMeetingUrl? _openExternalMeetingUrl;
  final ReportSessionConcernUseCase? _reportConcern;
  final OpenSessionDisputeUseCase? _openDispute;
  final GetPendingRescheduleRequestUseCase? _getPendingReschedule;
  final RespondToRescheduleRequestUseCase? _respondToReschedule;
  final AuthSessionProvider? _authSession;
  final TeacherProfileRepository? _teacherProfileRepository;

  Future<void> _onLoadRequested(
    SessionDetailLoadRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());

    final aggregateResult = await _aggregateRepository.getById(event.bookingId);
    if (aggregateResult.isLeft()) {
      aggregateResult.fold(
        (f) => emit(SessionDetailFailure(f)),
        (_) {},
      );
      return;
    }

    final aggregate = aggregateResult.fold(
      (_) => throw StateError('noop'),
      (r) => r,
    );
    final timelineId = aggregate.sessionId ?? aggregate.id;
    final timelineResult = await _getTimeline(timelineId);
    final timeline = timelineResult.fold(
      (_) => const <SessionAuditEvent>[],
      (events) => events,
    );

    final callContext = await _loadSessionCallContext(
      sessionId: aggregate.sessionId,
    );

    final rescheduleContext = await _loadRescheduleContext(
      aggregate: aggregate,
    );

    emit(
      SessionDetailSuccess(
        aggregate: aggregate,
        timeline: timeline,
        externalMeetingJoinUrl: callContext.externalMeetingJoinUrl,
        callProviderKind: callContext.callProviderKind,
        pendingRescheduleRequest: rescheduleContext.request,
        canRespondToReschedule: rescheduleContext.canRespond,
        isAwaitingRescheduleCounterparty: rescheduleContext.isAwaiting,
      ),
    );
  }

  Future<
    ({
      PendingRescheduleRequest? request,
      bool canRespond,
      bool isAwaiting,
    })
  >
  _loadRescheduleContext({required SessionAggregate aggregate}) async {
    final getPending = _getPendingReschedule;
    if (getPending == null ||
        aggregate.lifecycleStatus != SessionLifecycleStatus.rescheduled) {
      return (request: null, canRespond: false, isAwaiting: false);
    }

    final pendingResult = await getPending(aggregate.id);
    final request = pendingResult.fold((_) => null, (value) => value);
    if (request == null || !request.isPending) {
      return (request: null, canRespond: false, isAwaiting: false);
    }

    final userId = _authSession?.currentUserId;
    if (userId == null || userId.isEmpty) {
      return (request: request, canRespond: false, isAwaiting: false);
    }

    final isRequester = request.requestedByUserId == userId;
    return (
      request: request,
      canRespond: !isRequester,
      isAwaiting: isRequester,
    );
  }

  Future<ActorRole?> _resolveActorRole(SessionAggregate aggregate) async {
    final userId = _authSession?.currentUserId;
    if (userId == null || userId.isEmpty) return null;
    if (userId == aggregate.studentId) return ActorRole.student;
    if (userId == aggregate.teacherId) return ActorRole.teacher;

    final teacherProfiles = _teacherProfileRepository;
    if (teacherProfiles == null) return null;

    final profileResult = await teacherProfiles.getProfileById(
      aggregate.teacherId,
    );
    return profileResult.fold(
      (_) => null,
      (profile) => profile.userId == userId ? ActorRole.teacher : null,
    );
  }

  Future<
    ({
      String? externalMeetingJoinUrl,
      SessionCallProviderKind? callProviderKind,
    })
  >
  _loadSessionCallContext({required String? sessionId}) async {
    final repository = _sessionRepository;
    if (repository == null || sessionId == null || sessionId.isEmpty) {
      return (externalMeetingJoinUrl: null, callProviderKind: null);
    }

    final sessionResult = await repository.getSessionById(sessionId);
    return sessionResult.fold(
      (_) => (externalMeetingJoinUrl: null, callProviderKind: null),
      (session) {
        String? externalMeetingJoinUrl;
        if (session.callType == SessionCallType.externalMeeting &&
            session.callProviderKind == SessionCallProviderKind.external) {
          final url = session.joinUrl?.trim();
          externalMeetingJoinUrl = (url?.isNotEmpty ?? false) ? url : null;
        }
        return (
          externalMeetingJoinUrl: externalMeetingJoinUrl,
          callProviderKind: session.callProviderKind,
        );
      },
    );
  }

  Future<void> _onJoinRequested(
    SessionDetailJoinRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final joinSession = _joinSession;
    final current = state;
    if (joinSession == null || current is! SessionDetailSuccess) return;

    final sessionId = current.aggregate.sessionId;
    if (sessionId == null ||
        !current.aggregate.lifecycleStatus.canJoinSession) {
      return;
    }

    emit(current.copyWith(joinInProgress: true, clearJoinFailure: true));

    final result = await joinSession(sessionId: sessionId);
    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          joinFailure: failure,
          clearJoinInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          clearJoinInProgress: true,
          hasOpenedExternalMeeting: after.isExternalMeeting,
        ),
      ),
    );
  }

  Future<void> _onOpenMeetingAgainRequested(
    SessionDetailOpenMeetingAgainRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final opener = _openExternalMeetingUrl;
    final current = state;
    if (opener == null || current is! SessionDetailSuccess) return;

    final url = current.externalMeetingJoinUrl;
    if (url == null || url.isEmpty) return;

    emit(current.copyWith(joinInProgress: true, clearJoinFailure: true));

    try {
      await opener(url);
      final after = state;
      if (after is! SessionDetailSuccess) return;
      emit(
        after.copyWith(
          clearJoinInProgress: true,
          hasOpenedExternalMeeting: true,
        ),
      );
    } on QuranSessionsFailure catch (failure) {
      final after = state;
      if (after is! SessionDetailSuccess) return;
      emit(
        after.copyWith(
          joinFailure: failure,
          clearJoinInProgress: true,
        ),
      );
    } on Object {
      final after = state;
      if (after is! SessionDetailSuccess) return;
      emit(
        after.copyWith(
          joinFailure: const ExternalMeetingLaunchFailure(),
          clearJoinInProgress: true,
        ),
      );
    }
  }

  Future<void> _onReportSubmitted(
    SessionDetailReportSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final useCase = _reportConcern;
    final current = state;
    if (useCase == null || current is! SessionDetailSuccess) return;

    emit(
      current.copyWith(
        reportInProgress: true,
        clearReportFailure: true,
        clearReportSubmitted: true,
      ),
    );

    final result = await useCase(
      category: event.category,
      description: event.description,
      bookingId: current.aggregate.id,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          reportFailure: failure,
          clearReportInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          reportSubmitted: true,
          clearReportInProgress: true,
        ),
      ),
    );
  }

  void _onReportAcknowledged(
    SessionDetailReportAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearReportSubmitted: true));
  }

  Future<void> _onDisputeSubmitted(
    SessionDetailDisputeSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final useCase = _openDispute;
    final current = state;
    if (useCase == null || current is! SessionDetailSuccess) return;

    emit(
      current.copyWith(
        disputeInProgress: true,
        clearDisputeFailure: true,
        clearDisputeSubmitted: true,
      ),
    );

    final result = await useCase(
      bookingId: current.aggregate.id,
      reason: event.reason,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          disputeFailure: failure,
          clearDisputeInProgress: true,
        ),
      ),
      (disputeId) => emit(
        after.copyWith(
          disputeSubmitted: true,
          clearDisputeInProgress: true,
          aggregate: after.aggregate.copyWith(
            lifecycleStatus: SessionLifecycleStatus.disputed,
          ),
        ),
      ),
    );
  }

  void _onDisputeAcknowledged(
    SessionDetailDisputeAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearDisputeSubmitted: true));
  }

  Future<void> _onRescheduleRespondSubmitted(
    SessionDetailRescheduleRespondSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final respond = _respondToReschedule;
    final current = state;
    if (respond == null || current is! SessionDetailSuccess) return;

    final request = current.pendingRescheduleRequest;
    if (request == null || !current.canRespondToReschedule) return;

    final actorRole = await _resolveActorRole(current.aggregate);
    if (actorRole == null) {
      emit(
        current.copyWith(
          rescheduleRespondFailure: const UnauthorizedFailure(),
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        rescheduleRespondInProgress: true,
        clearRescheduleRespondFailure: true,
        clearRescheduleRespondAccepted: true,
      ),
    );

    final result = await respond(
      requestId: request.requestId,
      accept: event.accept,
      actorRole: actorRole,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    await result.fold(
      (failure) async {
        emit(
          after.copyWith(
            rescheduleRespondFailure: failure,
            clearRescheduleRespondInProgress: true,
          ),
        );
      },
      (aggregate) async {
        emit(
          after.copyWith(
            aggregate: aggregate,
            clearPendingRescheduleRequest: true,
            canRespondToReschedule: false,
            isAwaitingRescheduleCounterparty: false,
            rescheduleRespondAccepted: event.accept,
            clearRescheduleRespondInProgress: true,
          ),
        );
      },
    );
  }

  void _onRescheduleRespondAcknowledged(
    SessionDetailRescheduleRespondAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearRescheduleRespondAccepted: true));
  }
}
